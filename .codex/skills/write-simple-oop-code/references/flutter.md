# Flutter and Dart guide

## Choose the smallest suitable boundary

- Keep a widget local when it only renders data and handles simple UI state.
- Introduce a view model or controller when presentation state, asynchronous commands, or duplicate-submission control need an owner independent of the widget.
- Introduce an application use case when a workflow coordinates multiple collaborators or owns a business policy that must be tested independently.
- Introduce a domain object when state has a meaningful invariant or behavior. Do not create entity classes that are only getter bags.
- Introduce a port and adapter for persistence, network, Firebase, MethodChannel, or plugins when the application needs isolation from that effect.
- Avoid creating every layer for a simple screen or one-step operation.

## Preserve Flutter conventions

- Prefer immutable state and explicit loading, success, empty, and failure states.
- Inject dependencies through constructors or providers. Restrict service-locator access to composition roots.
- Keep domain and application policies free of Flutter UI and platform SDK imports.
- Treat background entry points and isolate initialization as explicit, idempotent lifecycles.
- Use `kIsWeb` and supported platform abstractions for code that may compile for web; do not import `dart:io` into a web-reachable library.
- Keep platform-specific behavior behind focused adapters when Android, iOS, and web differ.

## Verify behavior

- Test policies and domain behavior without Flutter bindings where possible.
- Add widget tests for user-visible state and interactions.
- Characterize platform and plugin contracts before moving their boundaries.
- Map tests directly to the issue's completion conditions and run `flutter analyze` plus relevant Flutter tests.
