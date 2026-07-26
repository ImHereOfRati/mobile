import {
  bridgeContract,
  type BridgeApi,
  type BridgeEventName,
  type BridgeEventPayload,
  type BridgeMethodArgs,
  type BridgeMethodName,
  type BridgeMethodResult,
} from "./contract";

export interface BridgeTransport {
  postMessage(message: string): void;
}

export interface BridgeRuntimeOptions {
  idFactory?: () => string;
  timeoutMs?: number;
}

export interface BridgeEventBus {
  subscribe<Name extends BridgeEventName>(
    eventName: Name,
    listener: (payload: BridgeEventPayload<Name>) => void,
  ): () => void;
}

export type NativeBridge = BridgeApi & {
  events: BridgeEventBus;
};

interface RpcErrorPayload {
  code: string;
  details?: unknown;
  message: string;
}

interface RpcRequest {
  id: string;
  kind: "request";
  method: BridgeMethodName;
  params?: unknown;
}

interface RpcSuccessResponse {
  id: string;
  kind: "response";
  result: unknown;
}

interface RpcErrorResponse {
  error: RpcErrorPayload;
  id: string;
  kind: "response";
}

interface RpcEvent {
  event: BridgeEventName;
  kind: "event";
  payload?: unknown;
}

type NativeMessage = RpcSuccessResponse | RpcErrorResponse | RpcEvent;

interface PendingCall {
  reject: (reason: Error) => void;
  resolve: (value: unknown) => void;
  timeout: ReturnType<typeof setTimeout>;
}

export class BridgeRpcError extends Error {
  constructor(
    message: string,
    readonly code: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = "BridgeRpcError";
  }
}

export class BridgeTimeoutError extends Error {
  constructor(
    readonly method: BridgeMethodName,
    readonly timeoutMs: number,
  ) {
    super(`Bridge method ${method} timed out after ${timeoutMs}ms`);
    this.name = "BridgeTimeoutError";
  }
}

export class BridgeRuntimeDestroyedError extends Error {
  constructor() {
    super("Bridge runtime was destroyed");
    this.name = "BridgeRuntimeDestroyedError";
  }
}

function defaultIdFactory() {
  return (
    globalThis.crypto?.randomUUID?.() ??
    `bridge-${Date.now()}-${Math.random().toString(36).slice(2)}`
  );
}

function parseNativeMessage(message: string | unknown): NativeMessage {
  const parsed: unknown =
    typeof message === "string" ? JSON.parse(message) : message;
  if (typeof parsed !== "object" || parsed === null || !("kind" in parsed)) {
    throw new BridgeRpcError(
      "Invalid native bridge message",
      "INVALID_MESSAGE",
      parsed,
    );
  }

  return parsed as NativeMessage;
}

export class BridgeRpcRuntime {
  private readonly idFactory: () => string;
  private readonly timeoutMs: number;
  private readonly pending = new Map<string, PendingCall>();
  private readonly listeners = new Map<
    BridgeEventName,
    Set<(payload: unknown) => void>
  >();
  private destroyed = false;

  constructor(
    private readonly transport: BridgeTransport,
    options: BridgeRuntimeOptions = {},
  ) {
    this.idFactory = options.idFactory ?? defaultIdFactory;
    this.timeoutMs = options.timeoutMs ?? 10_000;
  }

  call<Name extends BridgeMethodName>(
    method: Name,
    ...args: BridgeMethodArgs<Name>
  ): Promise<BridgeMethodResult<Name>> {
    if (this.destroyed) {
      return Promise.reject(new BridgeRuntimeDestroyedError());
    }

    const id = this.idFactory();
    const request: RpcRequest = {
      kind: "request",
      id,
      method,
      ...(args.length === 0 ? {} : { params: args[0] }),
    };

    return new Promise<BridgeMethodResult<Name>>((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pending.delete(id);
        reject(new BridgeTimeoutError(method, this.timeoutMs));
      }, this.timeoutMs);

      this.pending.set(id, {
        resolve: (value) => resolve(value as BridgeMethodResult<Name>),
        reject,
        timeout,
      });

      try {
        this.transport.postMessage(JSON.stringify(request));
      } catch (error) {
        clearTimeout(timeout);
        this.pending.delete(id);
        reject(error instanceof Error ? error : new Error(String(error)));
      }
    });
  }

  subscribe<Name extends BridgeEventName>(
    eventName: Name,
    listener: (payload: BridgeEventPayload<Name>) => void,
  ) {
    const untypedListener = listener as unknown as (payload: unknown) => void;
    const listeners =
      this.listeners.get(eventName) ?? new Set<(payload: unknown) => void>();
    listeners.add(untypedListener);
    this.listeners.set(eventName, listeners);

    return () => {
      listeners.delete(untypedListener);
      if (listeners.size === 0) this.listeners.delete(eventName);
    };
  }

  receive(message: string | unknown) {
    const parsed = parseNativeMessage(message);

    if (parsed.kind === "event") {
      this.listeners
        .get(parsed.event)
        ?.forEach((listener) => listener(parsed.payload));
      return;
    }

    const pendingCall = this.pending.get(parsed.id);
    if (pendingCall === undefined) return;

    clearTimeout(pendingCall.timeout);
    this.pending.delete(parsed.id);

    if ("error" in parsed) {
      pendingCall.reject(
        new BridgeRpcError(
          parsed.error.message,
          parsed.error.code,
          parsed.error.details,
        ),
      );
      return;
    }

    pendingCall.resolve(parsed.result);
  }

  destroy() {
    if (this.destroyed) return;
    this.destroyed = true;

    for (const pendingCall of this.pending.values()) {
      clearTimeout(pendingCall.timeout);
      pendingCall.reject(new BridgeRuntimeDestroyedError());
    }
    this.pending.clear();
    this.listeners.clear();
  }
}

export function createNativeBridge(runtime: BridgeRpcRuntime): NativeBridge {
  const methods = new Set(Object.keys(bridgeContract.methods));
  const target: Record<PropertyKey, unknown> = {
    events: {
      subscribe: runtime.subscribe.bind(runtime),
    },
  };

  return new Proxy(target, {
    get(currentTarget, property, receiver) {
      if (property === "events") {
        return Reflect.get(currentTarget, property, receiver);
      }

      if (typeof property === "string" && methods.has(property)) {
        return (...args: unknown[]) =>
          Reflect.apply(runtime.call, runtime, [property, ...args]);
      }

      return Reflect.get(currentTarget, property, receiver);
    },
  }) as unknown as NativeBridge;
}

declare global {
  interface Window {
    ImHereBridge?: BridgeTransport;
    __imhereBridgeReceive?: (message: string | unknown) => void;
  }
}

export function createWindowBridge(options: BridgeRuntimeOptions = {}) {
  const transport = globalThis.window?.ImHereBridge;
  if (transport === undefined) {
    throw new BridgeRpcError(
      "Native JavaScriptChannel is not available",
      "CHANNEL_UNAVAILABLE",
    );
  }

  const runtime = new BridgeRpcRuntime(transport, options);
  globalThis.window.__imhereBridgeReceive = (message) =>
    runtime.receive(message);

  return {
    bridge: createNativeBridge(runtime),
    destroy() {
      runtime.destroy();
      delete globalThis.window.__imhereBridgeReceive;
    },
    runtime,
  };
}
