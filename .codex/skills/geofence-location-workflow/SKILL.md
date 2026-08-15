---
name: geofence-location-workflow
description: Use when changing ImHere geofence location selection, reverse geocoding, place names, notification messages, or related browser tests. Enforces the repository's formatting and verification workflow before commits or deployment.
---

# Geofence Location Workflow

Use this skill for changes under `web/src/map`, `web/src/pages/geofence`, the native geofence message formatter, or the related Playwright and Vitest tests.

## Workflow

1. Read the current map proxy, location picker, geofence form/model, native `{location}` formatter, and relevant tests before editing.
2. Preserve the location contract: coordinates are authoritative, reverse geocoding supplies the place name, and the user may edit the resulting name and message.
3. Keep network work behind `MapProxyService`; make failure states explicit and testable.
4. Add or update focused Vitest coverage for place-name extraction, address/coordinate synchronization, message defaults, and manual-edit preservation.
5. Add or update a Playwright scenario that mocks map endpoints and exercises the rendered registration flow on a mobile viewport.

## Formatting gate

After every code-editing pass, run the formatter on only the changed files, then run the repository check:

```powershell
corepack pnpm exec prettier --write <changed-files>
corepack pnpm format:check
```

Do not commit, push, or deploy while `format:check` is failing. Never use broad formatter output as a substitute for inspecting the diff.

## Required verification

Run the smallest relevant checks first, then the full web gates:

```powershell
corepack pnpm exec vitest run <focused-tests>
corepack pnpm e2e
corepack pnpm lint
corepack pnpm typecheck
corepack pnpm test
corepack pnpm build
```

For browser verification, confirm that place name, address, latitude/longitude, and notification message update as one flow; confirm a manually edited message is not overwritten; inspect console errors and mobile overflow.

## Delivery gate

Before reporting completion, verify `git diff --check`, a clean intended worktree, Web CI success, and immutable deployment success. Report any skipped check and its reason explicitly.
