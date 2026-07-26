# Web font assets

`gmarket-sans-medium.woff2` and `gmarket-sans-bold.woff2` are generated from
the existing Flutter assets in `assets/fonts/`.

Run `pnpm font:subset` from `web/` whenever visible source copy changes. The
generator scans React source and locale files, then emits only the glyphs used
by the web application.

Pretendard is bundled from the official `pretendard` package. Its dynamic
Unicode-range CSS keeps Korean font downloads incremental and removes any
runtime CDN dependency.
