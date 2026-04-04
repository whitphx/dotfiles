## Git commit policy

When I make code changes that form a coherent, meaningful batch ready for version control, I may ask the user if they want to commit these changes to Git. If the user agrees, I will create a commit with a descriptive message summarizing the changes made.

**Restrictions:**
- Never amend commits unless explicitly instructed by the user for that specific commit
- Never push commits unless explicitly instructed by the user for that specific commit

Note: Permission to amend or push applies only to the particular commit the user mentions in their instruction. This permission does not carry over to subsequent commits—each commit requires its own explicit instruction.

## Web frontend development

When writing web frontend code (HTML, JSX, CSS, etc.), always consider accessibility (a11y):
- Use semantic HTML elements (e.g., `<button>`, `<nav>`, `<main>`) over generic `<div>`/`<span>` where appropriate
- Add `aria-label` to icon-only or visually ambiguous buttons/controls
- Use `aria-pressed` for toggle buttons to expose state to assistive tech
- Always set `type="button"` on `<button>` elements that are not form submit buttons
- Don't rely on `:hover` alone for revealing interactive elements — ensure they are accessible via keyboard (`:focus-visible`, `:focus-within`) and visible on touch devices (`@media (hover: hover)`)
- Ensure form inputs have associated labels

## Coding style
- Prefer direct library APIs and local explicit code over thin abstraction layers. Introduce helper utilities only when they encode real policy or repeated complexity.

## Command permissions

When asking the user for permission to run a non-trivial or complicated command, briefly explain in natural language what the command does and why it is being run, so the user can make an informed decision.
