import {
  BRIDGE_CAPABILITIES,
  BRIDGE_VERSION,
  bridgeContract,
  type BridgeEventName,
  type BridgeEventPayload,
  type BridgeMethodName,
} from "./contract";
import type { BridgeEventBus, NativeBridge } from "./runtime";
import type { Schema } from "./schema";

type MockMethod = (...args: unknown[]) => Promise<unknown>;

export interface MockBridgeCall {
  args: unknown[];
  method: BridgeMethodName;
}

export interface MockBridgeController {
  bridge: NativeBridge;
  calls: MockBridgeCall[];
  emit<Name extends BridgeEventName>(
    eventName: Name,
    payload: BridgeEventPayload<Name>,
  ): void;
  reset(): void;
}

export type MockBridgeOverrides = Partial<Record<BridgeMethodName, MockMethod>>;

export function createExampleValue(value: Schema): unknown {
  switch (value.kind) {
    case "string":
      return "mock";
    case "integer":
    case "number":
      return 1;
    case "boolean":
      return true;
    case "json":
      return {};
    case "enum":
      return value.values[0];
    case "array":
      return [];
    case "nullable":
      return null;
    case "optional":
      return undefined;
    case "object":
      return Object.fromEntries(
        Object.entries(value.properties).flatMap(([key, property]) =>
          property.kind === "optional"
            ? []
            : [[key, createExampleValue(property)]],
        ),
      );
  }
}

export function createMockBridge(
  overrides: MockBridgeOverrides = {},
): MockBridgeController {
  const calls: MockBridgeCall[] = [];
  const listeners = new Map<BridgeEventName, Set<(payload: unknown) => void>>();
  const methodNames = new Set(Object.keys(bridgeContract.methods));

  const subscribe = (
    eventName: BridgeEventName,
    listener: (payload: unknown) => void,
  ) => {
    const eventListeners =
      listeners.get(eventName) ?? new Set<(payload: unknown) => void>();
    eventListeners.add(listener);
    listeners.set(eventName, eventListeners);
    return () => {
      eventListeners.delete(listener);
    };
  };
  const events = { subscribe } as unknown as BridgeEventBus;

  const bridgeTarget: Record<PropertyKey, unknown> = { events };
  const bridge = new Proxy(bridgeTarget, {
    get(target, property, receiver) {
      if (property === "events") return Reflect.get(target, property, receiver);
      if (typeof property !== "string" || !methodNames.has(property)) {
        return Reflect.get(target, property, receiver);
      }

      const methodName = property as BridgeMethodName;
      return async (...args: unknown[]) => {
        calls.push({ method: methodName, args });
        const override = overrides[methodName];
        if (override !== undefined) return override(...args);

        if (methodName === "getCapabilities") {
          return {
            bridgeVersion: BRIDGE_VERSION,
            appVersion: "0.0.0-browser",
            platform: "browser",
            capabilities: [...BRIDGE_CAPABILITIES],
          };
        }

        const result = bridgeContract.methods[methodName].result;
        return result === null ? undefined : createExampleValue(result);
      };
    },
  }) as unknown as NativeBridge;

  return {
    bridge,
    calls,
    emit(eventName, payload) {
      listeners
        .get(eventName)
        ?.forEach((listener) => listener(payload as unknown));
    },
    reset() {
      calls.splice(0);
      listeners.clear();
    },
  };
}
