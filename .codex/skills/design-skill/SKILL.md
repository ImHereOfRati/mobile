---
name: design-skill
description: "Design, implement, and review ImHere Flutter and React user interfaces with the repository's mobile-first visual system: white surfaces, charcoal typography, neutral gray structure, and the existing #0071E3 blue for interactive emphasis. Use for new screens, UI/UX changes, responsive layout work, design-system components, typography, navigation, forms, lists, cards, empty/loading/error states, or visual QA. Always prioritize the mobile viewport and touch experience before tablet or desktop layouts."
---

# ImHere Mobile-first Design

Design the smallest mobile experience that makes the user's next action obvious. Treat desktop as a progressive expansion of the proven mobile information hierarchy, never as the source layout to shrink.

For React routes embedded in the native app, design content only. The native shell owns the top app bar and bottom tab navigation. Do not duplicate either control in the web DOM unless the user explicitly requests a standalone web shell.

## Read the project design references

- Read [references/visual-language.md](references/visual-language.md) before creating or restyling any screen.
- Read [references/mobile-qa.md](references/mobile-qa.md) before implementation and again before reporting completion.
- Use `chamgo/img.png` as layout inspiration only. Do not copy its brand, content, or assets.

## Follow this priority order

1. Mobile task completion and readable information hierarchy
2. Touch accessibility, safe areas, keyboard behavior, and scroll recovery
3. Consistent typography, spacing, components, and interaction feedback
4. Tablet adaptation
5. Desktop density and multi-column expansion

When mobile and desktop needs conflict, preserve the mobile experience and add a desktop-only enhancement behind a `min-width` query.

## Implement mobile first

1. Identify the primary mobile task and the one action that completes it.
2. Write base styles for 320–430px without a desktop layout assumption.
3. Keep the title, essential context, and primary action discoverable in the initial viewport when the task allows it.
4. Use shared components only after a responsibility repeats across screens.
5. Add tablet and desktop layout changes with `min-width` media queries.
6. Preserve existing behavior, routes, accessibility names, and platform contracts.
7. Validate the actual rendered UI at the required mobile sizes before checking desktop.

## Apply interaction rules

- Respect native-provided safe-area or content insets without drawing a second app bar or tab bar.
- Reserve content space for every web-owned fixed or floating control; never hide content behind it.
- Keep touch targets at least 44px and separate adjacent destructive or irreversible actions.
- Keep inputs visible when the software keyboard opens and allow the focused field and its error to scroll above fixed controls.
- Use blue for primary actions, selected states, key status, and focused controls. Do not use blue as decorative noise.
- Use motion only to explain state or continuity, honor reduced motion, and keep completion possible without animation.
- Prefer familiar mobile patterns and plain Korean labels over novel gestures or icon-only actions.

## Report completion

State:

- Primary mobile task preserved or improved
- Viewports rendered and inspected
- Overflow, fixed-control clearance, touch-target, and safe-area results
- Accessibility and automated verification performed
- Desktop adaptations added after mobile validation
