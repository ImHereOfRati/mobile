# Mobile UI and UX QA

## Required viewports

Render and inspect at minimum:

- 320 × 568: small phone and worst-case width
- 360 × 800: common Android viewport
- 390 × 844: common modern phone
- 430 × 932: large phone

Check both the initial viewport and the fully scrolled state. Validate desktop only after all four mobile sizes pass.

## Layout

- No horizontal overflow at any required width.
- No clipped Korean title, placeholder, status, or button label.
- No Korean word is split across two lines at any required width or supported text scale.
- Embedded web routes contain no duplicate global app bar or bottom tab navigation.
- Web-owned fixed controls do not cover the final row, validation error, CTA, or focused input.
- Content respects native-provided insets and `env(safe-area-inset-*)` where the host exposes them.
- Content remains understandable at 200% text zoom and with longer translated copy.

## Interaction

- Every interactive target is at least 44 × 44px.
- Focus order follows visual order and focus remains visible.
- Icon-only actions have accessible Korean names.
- Selected chip, loading, disabled, error, and success states are visually distinct without color alone.
- Keyboard opening does not trap or hide the focused field.
- Back, cancel, retry, and recovery paths remain available.

## Visual hierarchy

- The first viewport reveals the page purpose and the next meaningful action.
- Blue appears on actions and state, not every decorative surface.
- Secondary copy does not compete with the title.
- Whitespace and dividers group ordinary content; cards group only a distinct responsibility.
- Mobile spacing is intentionally compressed rather than proportionally scaled from desktop.

## Verification evidence

Record viewport metrics, screenshots, console errors, automated accessibility results, focused tests, typecheck, lint, and production build status.
