import {
  BRIDGE_CAPABILITIES,
  bridgeContract,
  BridgeRpcRuntime,
  BridgeTimeoutError,
  createExampleValue,
  createMockBridge,
  negotiateBridge,
  type BridgeApi,
  type BridgeMethodResult,
  type BridgeTransport,
} from "./index";

class FakeTransport implements BridgeTransport {
  messages: string[] = [];

  postMessage(message: string) {
    this.messages.push(message);
  }
}

describe("bridge contract", () => {
  it("exposes the complete method and event surface", () => {
    expect(Object.keys(bridgeContract.methods)).toHaveLength(40);
    expect(Object.keys(bridgeContract.events)).toEqual([
      "onAppResumed",
      "onPermissionChanged",
      "onConnectivityChanged",
      "onPushOpened",
      "onGeofenceTriggered",
      "onThemeChanged",
      "onAndroidBackPressed",
    ]);
    expect(BRIDGE_CAPABILITIES).toContain("method:getDeviceContacts");
    expect(BRIDGE_CAPABILITIES).toContain("method:activateWithTerms");
    expect(BRIDGE_CAPABILITIES).toContain("method:updateGeofenceAddress");
    expect(BRIDGE_CAPABILITIES).toContain("event:onAndroidBackPressed");
  });

  it("infers method results from the executable schema", () => {
    expectTypeOf<BridgeMethodResult<"getAuthState">>().toMatchObjectType<{
      authenticated: boolean;
      userStatus: "active" | "inactive" | "pending" | null;
    }>();
    expectTypeOf<
      Parameters<BridgeApi["requestPermission"]>[0]
    >().toMatchObjectType<{
      permission:
        | "batteryOptimization"
        | "locationAlways"
        | "locationWhenInUse"
        | "notification"
        | "contacts";
    }>();
    expectTypeOf<
      Parameters<BridgeApi["registerGeofence"]>[0]
    >().toMatchObjectType<{
      address: string;
      eventType: "arrival" | "both" | "departure";
      repeatType: "custom" | "daily" | "none" | "weekday" | "weekend";
      deviceContactIds: string[];
    }>();
  });
});

describe("bridge version negotiation", () => {
  const handshake: BridgeMethodResult<"getCapabilities"> = {
    bridgeVersion: "1.2.0",
    appVersion: "3.0.0",
    platform: "android",
    capabilities: [...BRIDGE_CAPABILITIES],
  };

  it("accepts a same-major version with required capabilities", () => {
    expect(
      negotiateBridge(handshake, {
        minimumVersion: "1.1.0",
        requiredMethods: ["getAuthState", "requestPermission"],
      }),
    ).toMatchObject({ compatible: true, missingCapabilities: [] });
  });

  it("rejects old, invalid, and major-incompatible versions", () => {
    expect(
      negotiateBridge(
        { ...handshake, bridgeVersion: "1.0.0" },
        { minimumVersion: "1.1.0" },
      ).reason,
    ).toBe("versionTooOld");
    expect(
      negotiateBridge(
        { ...handshake, bridgeVersion: "2.0.0" },
        { minimumVersion: "1.1.0" },
      ).reason,
    ).toBe("majorMismatch");
    expect(
      negotiateBridge(
        { ...handshake, bridgeVersion: "latest" },
        { minimumVersion: "1.1.0" },
      ).reason,
    ).toBe("invalidVersion");
  });

  it("rejects a missing required capability", () => {
    const result = negotiateBridge(
      { ...handshake, capabilities: [] },
      { requiredMethods: ["getAuthState"] },
    );

    expect(result.compatible).toBe(false);
    expect(result.missingCapabilities).toEqual(["method:getAuthState"]);
  });
});

describe("bridge RPC runtime", () => {
  it("correlates a native response to its Promise", async () => {
    const transport = new FakeTransport();
    const runtime = new BridgeRpcRuntime(transport, {
      idFactory: () => "request-1",
    });

    const promise = runtime.call("getAuthState");
    expect(JSON.parse(transport.messages[0])).toEqual({
      kind: "request",
      id: "request-1",
      method: "getAuthState",
    });

    runtime.receive({
      kind: "response",
      id: "request-1",
      result: { authenticated: true, userStatus: "active" },
    });

    await expect(promise).resolves.toEqual({
      authenticated: true,
      userStatus: "active",
    });
  });

  it("turns native error responses into BridgeRpcError", async () => {
    const runtime = new BridgeRpcRuntime(new FakeTransport(), {
      idFactory: () => "request-error",
    });
    const promise = runtime.call("signOut");

    runtime.receive({
      kind: "response",
      id: "request-error",
      error: {
        code: "AUTH_FAILED",
        message: "로그아웃에 실패했습니다.",
      },
    });

    await expect(promise).rejects.toMatchObject({
      code: "AUTH_FAILED",
      message: "로그아웃에 실패했습니다.",
    });
  });

  it("rejects a call when native does not respond before timeout", async () => {
    vi.useFakeTimers();
    const runtime = new BridgeRpcRuntime(new FakeTransport(), {
      timeoutMs: 50,
    });
    const promise = runtime.call("getAppInfo");
    const expectation =
      expect(promise).rejects.toBeInstanceOf(BridgeTimeoutError);

    await vi.advanceTimersByTimeAsync(50);
    await expectation;
    vi.useRealTimers();
  });

  it("delivers and unsubscribes native events", () => {
    const runtime = new BridgeRpcRuntime(new FakeTransport());
    const listener = vi.fn();
    const unsubscribe = runtime.subscribe("onPushOpened", listener);

    runtime.receive({
      kind: "event",
      event: "onPushOpened",
      payload: { path: "/record/notifications" },
    });
    unsubscribe();
    runtime.receive({
      kind: "event",
      event: "onPushOpened",
      payload: { path: "/record" },
    });

    expect(listener).toHaveBeenCalledOnce();
    expect(listener).toHaveBeenCalledWith({ path: "/record/notifications" });
  });
});

describe("browser bridge mock", () => {
  it("can call every method in the contract", async () => {
    const { bridge, calls } = createMockBridge();

    for (const [name, definition] of Object.entries(bridgeContract.methods)) {
      const callable = Reflect.get(bridge, name) as (
        ...args: unknown[]
      ) => Promise<unknown>;
      const args =
        definition.params === null
          ? []
          : [createExampleValue(definition.params)];
      await expect(callable(...args)).resolves.not.toThrow();
    }

    expect(calls).toHaveLength(Object.keys(bridgeContract.methods).length);
  });

  it("returns a realistic handshake and emits typed events", async () => {
    const controller = createMockBridge();
    const listener = vi.fn();
    controller.bridge.events.subscribe("onThemeChanged", listener);

    await expect(controller.bridge.getCapabilities()).resolves.toMatchObject({
      bridgeVersion: bridgeContract.version,
      platform: "browser",
    });

    const emitTheme = controller.emit as unknown as (
      eventName: "onThemeChanged",
      payload: { theme: "dark" | "light" | "system" },
    ) => void;
    emitTheme("onThemeChanged", { theme: "dark" });
    expect(listener).toHaveBeenCalledWith({ theme: "dark" });
  });
});
