# React and TypeScript guide

## Express object design idiomatically

- Use function components by default. Object orientation means cohesive responsibilities and collaborations, not class components.
- Keep a component local when it only renders props and owns simple interaction state.
- Introduce a custom hook when lifecycle, asynchronous state, or interaction policy needs a reusable or independently understandable owner.
- Introduce an application service or use case when a workflow coordinates multiple external collaborators or owns framework-independent business rules.
- Introduce a domain object or pure module when data has meaningful invariants or behavior.
- Keep browser APIs, storage, timers, and network clients behind focused boundaries when isolation or substitution is needed.

## Preserve React conventions

- Keep state as close as possible to the component that owns it; lift or globalize it only for an actual shared owner.
- Prefer explicit props and dependencies over hidden module globals or broad context providers.
- Use composition before inheritance and discriminated unions before interacting boolean flags.
- Separate server state, durable client state, and ephemeral UI state by responsibility.
- Do not create one hook per function, split components without a responsibility boundary, or add a state library for convenience alone.
- Avoid speculative generic components and premature design systems. Extract reuse after stable repetition appears.

## Verify behavior

- Test domain rules and use cases without rendering React.
- Test components through user-visible behavior instead of implementation details.
- Cover loading, empty, success, failure, retry, and duplicate-action behavior when relevant.
- Map tests directly to the issue's completion conditions and run the repository's TypeScript, lint, and focused test commands.
