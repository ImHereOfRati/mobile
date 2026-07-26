# Bridge compatibility policy

The TypeScript contract in `src/contract.ts` is the single source of truth.
Flutter models are generated from it and committed so both runtimes review the
same change.

Bridge versions use `major.minor.patch`.

- A major change may remove or reinterpret methods, fields, or events. Web and
  Flutter must ship together, and older apps show the native force-update
  screen.
- A minor change is additive. New methods, events, optional fields, and enum
  values require a capability check until the minimum supported app catches up.
- A patch change fixes behavior without changing the serialized shape.

At startup, React calls `getCapabilities()` and receives `bridgeVersion`,
`appVersion`, `platform`, and `capabilities`. It compares that response with
`MINIMUM_BRIDGE_VERSION` and the methods required by the current web release.
An invalid version, a different major, an older version, or a missing required
capability is incompatible. F05 maps that result to the native force-update
screen.

RPC messages are JSON:

```text
React -> Flutter: { kind: "request", id, method, params? }
Flutter -> React: { kind: "response", id, result }
Flutter -> React: { kind: "response", id, error: { code, message, details? } }
Flutter -> React: { kind: "event", event, payload? }
```

The correlation `id` is opaque. Flutter must return it unchanged. Access tokens
may cross the bridge, but refresh tokens never do.
