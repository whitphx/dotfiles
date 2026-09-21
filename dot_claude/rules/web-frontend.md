---
paths:
  - "**/*.html"
  - "**/*.htm"
  - "**/*.jsx"
  - "**/*.tsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.astro"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
---

# Web frontend rules

## Always consider accessibility (a11y)

- Use semantic HTML elements (e.g., `<button>`, `<nav>`, `<main>`) over generic `<div>`/`<span>` where appropriate
- Add `aria-label` to icon-only or visually ambiguous buttons/controls
- Use `aria-pressed` for toggle buttons to expose state to assistive tech
- Always set `type="button"` on `<button>` elements that are not form submit buttons
- Don't rely on `:hover` alone for revealing interactive elements — ensure they are accessible via keyboard (`:focus-visible`, `:focus-within`) and visible on touch devices (`@media (hover: hover)`)
- Ensure form inputs have associated labels

## Adding more rules to this file

When new web frontend guidance gets added (state management conventions, styling patterns, bundler config, etc.), add it as its own H2 section in this file. Keep each rule short, with at least one concrete *what to do instead* example where applicable.
