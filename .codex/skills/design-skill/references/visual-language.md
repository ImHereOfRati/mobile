# ImHere visual language

## Product direction

- Use Notion as a reference for a quiet white canvas, a clear reading column, restrained dividers, and typography-led grouping.
- Use Toss as a reference for an obvious next action, plain Korean labels, strong status communication, and low-friction mobile flows.
- Use `chamgo/img.png` for the content sequence of search, filters, and list rows. Do not reproduce its device chrome.
- Remove decoration before removing information. Prefer one readable flow to a dashboard of competing cards.

## Color

- Canvas: `#FFFFFF`
- Surface: `#FFFFFF`
- Subtle group fill: `#F7F7F5`
- Primary text: `#191F28`
- Secondary text: `#6B7684`
- Divider: `#E9E9E7`
- Interactive emphasis: existing ImHere blue `#0071E3`
- Soft blue surface: `#EAF4FF`

Use white and neutral gray for structure. Replace the reference UI's black interactive surfaces with ImHere blue while keeping long-form text charcoal for readability.

## Typography

- Use Pretendard for UI and product copy.
- Use 700–800 weight and tight negative tracking for short Korean titles.
- Use one strong title, one concise supporting sentence, then content.
- Keep body copy at least 14px, line height around 1.5–1.65, and avoid low-contrast gray.
- Never split one Korean word across lines. Use keep-all word breaking for Korean UI copy and rewrite copy or adjust layout when the whole word does not fit.
- Let typography create hierarchy before adding borders, shadows, or decorative graphics.

## Components

- Search: a quiet rounded field on the subtle group fill; do not add a shadow.
- Filter: compact horizontal chips; selected state uses blue text on soft blue, inactive state uses subtle gray.
- Cards: use only when a bordered container communicates a real responsibility. Prefer whitespace and dividers for ordinary lists.
- Primary CTA: full-width blue on mobile when it completes the current step.
- Lists: generous tap rows, strong title, muted metadata, restrained blue status.
- Web chrome: native app owns the top app bar and bottom tab navigation. Embedded web routes render neither.
- Feedback: show loading, empty, success, and failure near the action that caused the state.

## Responsive behavior

- Keep one content column on mobile.
- Prefer horizontal scrolling chips over wrapping into unpredictable rows.
- Keep the primary content in a readable single column on desktop unless separate responsibilities truly require columns.
- Do not center a desktop card and call it mobile responsive; re-evaluate density, ordering, sticky controls, and keyboard behavior.
