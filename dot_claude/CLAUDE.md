## Acting on my input

Distinguish observations and questions from directives. If I describe a problem, ask a clarifying question (including questions framed as comments like "hmm, X seems wrong"), or share an observation without explicitly telling you to change something, treat it as discussion: explain, propose options, and wait for me to pick one. Don't assume an observation is permission to make changes, even when auto mode is active. Auto mode means "act on routine work without checking in," not "decide for me on questions I'm still thinking through."

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
- Before hand-rolling non-trivial functionality, also consider platform/built-in APIs and well-known third-party libraries as equal candidates — none is the default. Weigh the tradeoffs for the specific case (e.g. self-implementation tends to give a smaller bundle and less dependency risk, while built-ins/third-parties tend to be more stable, spec-correct, and battle-tested), recommend an approach with the reasoning, and ask the user if the call isn't clear-cut.

## Project scaffolding

When initializing a new project, prefer the ecosystem's official scaffold command over hand-writing project metadata files. Examples:
- Python: `uv init --lib` / `uv init --package` / `uv init --app`
- JS/TS: `pnpm create <template>`, `npm create <template>`, `pnpm dlx degit <template>`
- Rust: `cargo new` / `cargo init`
- Go: `go mod init`

Why: scaffolds encode current best-practice defaults (build-system pins, src-layout, `py.typed`, `.gitignore`, `tsconfig.json`, etc.) and stay in sync with each ecosystem's evolving conventions. Hand-rolled config drifts from those conventions and silently misses small but important details. Layer custom content (extra deps, source files, action.yml, etc.) on top of the scaffold output — don't replace it.

If it's not obvious which scaffold flavor to pick (e.g., `--lib` vs `--package` vs `--app`, or which build backend / template), ask before running. If the directory already has hand-written files when this is realized, the right move is usually to wipe them, run the scaffold cleanly, and re-layer customizations on top — not to try to reconcile after the fact.

## Comment policy

Comments should explain things that the code can't say on its own — non-obvious *why*, hidden constraints, design rationale, race conditions, references to external context (DB invariants, project-specific conventions, future-incompatibility notes that affect today's decisions). Default to writing none.

Do not write comments that:
- **Restate what the code already says.** "Title: at least one non-whitespace character, bounded length, no null bytes" sitting above a schema that pipes `minLength`, `regex`, `maxLength`, `regex` is duplication. The schema is the description. Same for "Combined param schema for `GET /foo/:a/:b` — validates both segments at once" sitting above a `v.object({a, b})`: the schema body says it.
- **Make claims about code that the code itself is the source of truth for.** This is the broader form of "don't quote literal values." It covers:
  - Literal values mirroring a constant: "5 MB headroom" above `5 * 1024 * 1024`, ":8787" mirroring a port literal, "`(\"github\" | \"google\")` picklist" mirroring a `v.picklist([...])`, "the typed contract is 200|401" mirroring `if (res.status === ...)` checks.
  - Count / cardinality claims: "the only helper shared", "used in two sites below", "all three providers", "the four fields above". The number drifts the moment a fifth one is added.
  - Path / endpoint enumerations that mirror routes, exports, or imports: "(`POST /foo`, `GET /bar`)" listing routes that live in another file, "(DocumentSyncRoom, fetch, scheduled)" listing a file's exports.
  - Identifier name lists that mirror a schema, picklist, or registry: "providers (github, google)", "the routes (me, logout, identities)".
  Keep the *why* (sizing rationale, allowlist intent, design constraint), and let the reader read the value / count / list off the code.
- **Justify a naming or extraction choice.** "Named because the call site reads better" / "Extracted because it's reused twice" — the name and the call sites are visible. If the *why* of the name encodes a real concept, the comment can capture that concept; otherwise drop it.
- **Describe usage that grep can answer.** "Used in two sites below" / "Imported by routes/foo.ts" / "Used by routes/X (7 handlers)" — let the reader find usages with their tools.
- **Speculate about unimplemented future work** unless that speculation constrains today's code. "Phase 1 has 1:1 X:Y; Extension A will expand …" is fine if it explains why an interface shape today is more general than it needs to be; it's noise if it's just describing what isn't built yet.
- **Use project-internal jargon (Phase 1 / Extension A / nicknamed milestones) without anchor.** A first-time reader of the file shouldn't need to know what "Phase 1" means. If the term is load-bearing, expand the concept inline; if not, replace with concrete language ("currently") or drop.
- **Repeat cross-file context that already lives at one canonical site.** State the explanation in one place (typically next to the definition / decision) and let other sites point at it briefly.
- **Dress up a convention as a systematic feature.** "To add an endpoint: add the handler to `routes/<url>.ts`, then chain `.route("/", ...)` below" reads like a step-by-step the codebase enforces, when it's just a layout convention nothing actually checks. State the convention if it needs stating; skip the prescriptive instructions the code can't make true.
- **Write decorative section dividers.** `// --- Schemas ---`, `// --- Routes ---` between groups of declarations add no information; the declarations themselves are already visible. If a file is long enough that a reader can't navigate it, that's a signal to split the file, not to add headings.
- **Lead with a descriptive what-is preamble.** "Type-only export surface for the app's `hc<AppType>()` client" sitting above `export type { AppType } from "./worker"` is a paraphrase of the file name plus the one line of code below it. Drop the preamble; keep only the *why* (e.g. why this re-export module exists separately from `worker.ts`).
- **Quote specific facts you can't cite.** "The package emits printable-ASCII strings (typically <20 chars)" — where did the "<20 chars" come from? If you can't point at a doc / README / spec / measurement, drop the number; an unsupported specific looks authoritative and rots silently when the underlying behavior changes. When the fact *is* genuinely useful, leave a citation (link to the package README, a spec section, an issue) so a future reader can verify or update it.

Per-site WHY notes near a tricky branch, a non-obvious cast, a race-condition guard, or a deliberate asymmetry are valuable — keep those.

## GitHub Actions

After editing any GitHub Actions workflow or composite-action file (under `.github/workflows/` or `.github/actions/`), run `actionlint` on the changed files to catch syntax, expression, and shellcheck issues before committing. `actionlint` is installed locally via Homebrew.

## Command permissions

When asking the user for permission to run a non-trivial or complicated command, briefly explain in natural language what the command does and why it is being run, so the user can make an informed decision.
