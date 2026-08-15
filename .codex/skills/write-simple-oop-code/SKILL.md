---
name: write-simple-oop-code
description: Implement and refactor Flutter/Dart and React/TypeScript code in this repository with the simplest design that satisfies the requested behavior, emphasizing Martin Fowler's evolutionary design and safe refactoring and 조영호's responsibility-, role-, and collaboration-driven object design. Use for feature implementation, bug fixes, refactoring, test-driven changes, or architectural decisions that write or modify Flutter or React application code. Do not use for read-only explanations or non-code documentation work.
---

# Write Simple OOP Code

Implement the requested observable behavior with the fewest necessary concepts. Treat simplicity as a small conceptual surface that is easy to understand and change, not merely fewer files or lines.

## Load the relevant framework guide

- Read [references/flutter.md](references/flutter.md) before changing Flutter or Dart code.
- Read [references/react.md](references/react.md) before changing React or TypeScript code.
- Read both when changing a shared contract or implementing the same behavior on mobile and web.

## Apply priorities in this order

1. Satisfy the explicit requirements and completion conditions.
2. Preserve unrelated observable behavior and compatibility.
3. Choose the simplest design that supports the current requirement.
4. Assign cohesive responsibilities and model necessary collaborations.
5. Follow the framework's established conventions and the repository's current architecture.
6. Introduce reuse or abstraction only when present evidence justifies it.

When these priorities conflict, prefer the earlier item and record the tradeoff.

## Use the Fowler and 조영호 lenses

- Apply Fowler's lens: make small, behavior-preserving changes; keep tests close to the behavior; remove concrete code smells; prefer evolutionary design; and avoid speculative capability through YAGNI.
- Apply 조영호's lens: begin with the collaboration needed to fulfill the use case; assign each responsibility to the object best able to own it; expose messages rather than internal data; protect invariants through encapsulation; and use roles or polymorphism only where a real variation exists.
- Do not force classes, inheritance, design patterns, layers, or interfaces to make code appear object-oriented. Functions, hooks, widgets, and plain values are valid when they own a clear responsibility.

## Follow the implementation workflow

1. Inspect the current code, tests, conventions, and worktree before editing.
2. Translate the request into observable behavior and explicit completion conditions.
3. Describe the smallest collaboration needed: caller, responsibility owner, and external effects.
4. Reuse an existing suitable boundary before adding a new one.
5. Implement one vertical slice with explicit dependencies and minimal branching.
6. Verify the completion conditions with focused tests, then run proportional repository checks.
7. Refactor only concrete duplication, unclear responsibility, excessive coupling, or change friction revealed by the implementation.
8. Report behavior delivered, boundary changed, verification evidence, and remaining risk.

## Keep the design honest

- Give each non-trivial object one primary reason to change and a responsibility describable in one sentence.
- Keep behavior with the state and invariant it protects; avoid exposing mutable internals for another object to coordinate.
- Prefer composition and explicit dependencies over inheritance, globals, or hidden service lookup.
- Keep UI objects focused on presentation state and command delegation when business rules become non-trivial.
- Hide network, persistence, browser, and platform SDK effects behind a boundary only when doing so improves substitution, isolation, or testing now.
- Use domain-specific names. Avoid generic `Manager`, `Helper`, `Utils`, or `Common` containers unless their responsibility is genuinely precise.
- Do not introduce an interface with one implementation unless it marks a meaningful external boundary, supports an existing test seam, or represents imminent known variation.
- Do not extract a shared abstraction from coincidentally similar code. Wait until the shared responsibility and variation points are clear.
- Prefer typed outcomes and explicit failure paths over swallowed exceptions, nullable ambiguity, or boolean flag combinations.
- Preserve the repository's architecture unless the requested behavior exposes a concrete design problem that must be addressed.

## Review before completion

Confirm:

- Every requested completion condition has evidence.
- The solution adds no capability that was not requested.
- Each new responsibility has a clear owner.
- Collaborators depend on the smallest stable contract they need.
- Business rules can be tested without rendering UI or invoking real platform infrastructure where practical.
- A future maintainer can explain the change without first understanding speculative layers.
