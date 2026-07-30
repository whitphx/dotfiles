## Acting on my input

Distinguish observations and questions from directives. If I describe a problem, ask a clarifying question (including questions framed as comments like "hmm, X seems wrong"), or share an observation without explicitly telling you to change something, treat it as discussion: explain, propose options, and wait for me to pick one. Don't assume an observation is permission to make changes, even when auto mode is active. Auto mode means "act on routine work without checking in," not "decide for me on questions I'm still thinking through."

## Git commit policy

When I make code changes that form a coherent, meaningful batch ready for version control, I may ask the user if they want to commit these changes to Git. If the user agrees, I will create a commit with a descriptive message summarizing the changes made.

**Restrictions:**
- Never amend commits unless explicitly instructed by the user for that specific commit
- Never push commits unless explicitly instructed by the user for that specific commit

Note: Permission to amend or push applies only to the particular commit the user mentions in their instruction. This permission does not carry over to subsequent commits—each commit requires its own explicit instruction.

## Pull request workflow

When the user has asked for changes to land in a PR — whether by creating one or pushing to a branch with one — CI is part of "done." Treat the work as incomplete until checks are green; this is an extension of the push instruction under "Git commit policy," not a separate authorization.

### PR size

Default to small, self-contained PRs — the smallest chunk that stands on its own and can be reviewed and merged without the others. Reviewer effort is the thing being optimized, and it grows faster than diff size.

A large PR is fine when the changes are genuinely tangled: one purpose, and splitting them would leave a piece that doesn't build, doesn't pass tests, or can't be understood alone. Say that's the case when it is.

When the work isn't tangled, split it — and split it before opening the PR, not after. Typical seams: a refactor or rename carried alongside a behavior change (mechanical part lands first), unrelated fixes batched because they were found together, new infrastructure plus its first consumer, formatting/lint/dependency churn mixed into substantive work. Don't split so far that the reviewer has to hold several PRs in their head at once, or that an intermediate PR is broken.

If you're partway through a change and realize it has grown two purposes, tell me and propose the split rather than continuing to pile onto one branch.

### Pre-flight review

Before creating a PR, and before pushing an update to a branch that already has one, launch the `pr-reviewer` subagent and wait for its report. Pass it the base ref, the branch, the PR number if one exists, and the exact title and body about to be submitted. It reviews the diff and checks the description against the repo's PR template and contributing docs; it is read-only and reports back to you rather than posting anything.

Act on its findings before submitting: fix the 76+ ones, and tell me about anything you decide not to fix and why. Don't skip the review because the change looks small — a one-line diff can still miss a required template section. Skip it only when I explicitly say to.

- After a push to a PR branch, run `gh pr checks <number> --watch` and block on it in this turn. "I'll check later" / "you can verify with `gh ...`" is not acceptable — wait for the result before yielding.
- On failure, read `gh run view <run-id> --log-failed` (not `--log` — the full log eats context for no gain). Read the actual error before reacting; do not pattern-match to a familiar-looking failure or guess from the job name.
- Fix → push → re-watch. Loop until every check is `SUCCESS`. Local lint / typecheck / tests passing is not a substitute — CI runs jobs (matrix builds, integration suites, deploy previews) that can fail when local doesn't.
- If the same check fails three times across your fixes, stop and summarize what you tried. Three same-shape failures usually means the mental model is wrong, and continuing burns turns without converging.
- If a failure is plausibly unrelated to the change (flaky test, infra outage, unrelated job timing out), say so explicitly and ask how to proceed — do not silently retry or rerun jobs to make red go away.

### PR descriptions

Before writing a PR description, check whether the target repository specifies a format. Look for a pull request template (`pull_request_template.md`, `docs/pull_request_template.md`, `.github/pull_request_template.md`, or a `.md` file under `.github/PULL_REQUEST_TEMPLATE/`, `PULL_REQUEST_TEMPLATE/`, `docs/PULL_REQUEST_TEMPLATE/`) and for contribution instructions in developer docs (`README.md`, `CONTRIBUTING.md`, `DEVELOPMENT.md`, or their equivalents). If either exists, **it wins over my defaults below**: keep the template's structure, fill in every section it asks for, and follow whatever style it prescribes — including sections my defaults would otherwise cut, such as a "Test Plan" or a checklist. When the template or instruction offers a free-form field for describing the change and doesn't prescribe a writing style for it, write that field using the default style below. Note when multiple templates exist under a `PULL_REQUEST_TEMPLATE/` directory (GitHub treats them as alternatives) and pick the one matching the change, or ask me if it's ambiguous.

Otherwise, the default: keep PR descriptions short and plain. State the case the PR handles in 1-2 sentences and stop — the diff and tests carry the rest, and the reviewer reads the diff. Include a concrete input/output example only when it *shows* the bug (e.g. two Set-Cookie lines in, one out). Use a numbered list only when the PR genuinely has multiple distinct parts. Cut entirely: "Test Plan" sections, "verified locally" narratives, spec citations, production war stories/provenance, cross-repo references, "no new dependencies" notes, pre-commit/CI assurances — anything provable by the diff or CI is noise in prose. The same economy applies to issue drafts and commit bodies aimed at external maintainers, unless the extra context is load-bearing for a design discussion.

## Web frontend development

When writing web frontend code (HTML, JSX, CSS, etc.), always consider accessibility (a11y):
- Use semantic HTML elements (e.g., `<button>`, `<nav>`, `<main>`) over generic `<div>`/`<span>` where appropriate
- Add `aria-label` to icon-only or visually ambiguous buttons/controls
- Use `aria-pressed` for toggle buttons to expose state to assistive tech
- Always set `type="button"` on `<button>` elements that are not form submit buttons
- Don't rely on `:hover` alone for revealing interactive elements — ensure they are accessible via keyboard (`:focus-visible`, `:focus-within`) and visible on touch devices (`@media (hover: hover)`)
- Ensure form inputs have associated labels

## Coding style
- **Default to libraries / built-ins for non-trivial logic.** "Non-trivial" means: anything beyond a few-line transformation, anything with edge cases that an upstream-tested implementation would already handle (CSRF Origin checks, retry pools, ID generation, URL parsing, OAuth flows, cookie attribute handling, etc.). Before writing a middleware / fetcher / parser / pool from scratch, look for an existing implementation — including framework built-ins (e.g. `hono/csrf`, `hono/cookie`), well-known npm packages (e.g. `nanoid`, `p-limit`, `valibot`), and platform APIs (`URL`, `crypto.subtle`, `AbortSignal.timeout`). Self-implementation is a valid choice but **needs justification**: e.g. the dep is heavy relative to the work, the upstream behavior doesn't fit our exact need, real bundle/perf concerns, etc. State the reasoning if picking self-implementation.
- **Prefer direct library APIs and local explicit code over thin abstraction layers.** Introduce helper utilities only when they encode real policy or repeated complexity. Concrete anti-patterns:
  - One-line wrappers around a library call: `function registerCsrfGuard(app) { app.use("*", csrf({...})) }` adds no signal beyond `app.use("*", csrf({...}))` at the call site.
  - Single-call-site "helpers" that just rename the operation.
  - Single-thing re-export modules that exist only to add a layer of indirection.
  The bar for extraction: does the name encode a *concept* the reader couldn't read off the call site? `generateDocumentSlug()` passes (the call site's intent is "make a slug"; the name lets the implementation evolve independently). `registerCsrfGuard()` doesn't (the call site already says "register the csrf guard" by configuring the middleware).
- **Re-evaluate extractions after each round of edits.** A helper that pulled its weight when the call site was complex may stop pulling it after the call site simplifies. Inline it. The codebase's shape should track its current state, not its history.
- **Self-review meaningful code chunks before calling them done.** After finishing a coherent implementation chunk, re-read the changed code with a cleanup pass specifically for dead code: temporary debug-only APIs, unused helpers, obsolete branches, duplicated constants, logging added only to diagnose the task, and abstractions that no longer pull their weight. Remove those leftovers before finalizing, committing, or asking for review.
  - Committing a working-but-messy state as a checkpoint is fine — reaching correctness through trials and errors is normal, and a commit that captures "this works" is worth having. But the checkpoint is not the end of the work: right after it, re-read the result critically as if someone else wrote it. Beyond dead code, look for the implementation you'd only write while still discovering the requirements — a hand-rolled version of something the stdlib/platform/a package already does, a manual loop with a built-in equivalent, defensiveness guarding a case the final types rule out, a parameter or flag that now has exactly one value, an abstraction shaped for a design that got abandoned. Working is not the same as finished.
- **When you move / rename code, move its co-located test file too.** Tests live next to (and are named after) their subject, not their first home. After extracting `fetchMe` from `AuthContext.tsx` to `me-fetcher.ts`, `AuthContext.test.ts` should become `me-fetcher.test.ts`.

## Backward compatibility

Whether to preserve backward compatibility depends entirely on whether the "legacy" shape has actually shipped:

- **Legacy code is already on `main` (or otherwise released — published package, deployed worker, persisted user data on disk/localStorage/DB that real users have).** Backward compatibility is *very* important. Migrations, fallbacks, dual-read code, and "drop the old key on next read" shims earn their keep here. Don't break a shape that real callers / real stored data depend on.
- **Legacy code only exists earlier in the same unmerged feature branch.** There is no "legacy" — it's just an earlier draft of code I haven't reviewed yet. Migration shims, removal-after-read cleanups, and dual-shape readers are pure technical debt: they exist to honor a contract no one ever consumed. Default to deleting the old shape outright and writing the new code as if the old never existed.

When you face this choice, **prompt me before silently picking the no-compat path.** Even when no-compat is clearly the simpler call, surfacing the decision lets me confirm the branch state matches your assumption (sometimes a "feature branch" change has actually been previewed by a teammate, or the localStorage key is shared with another in-flight branch). A one-line check ("This key only appears in this branch — drop the migration shim?") is cheap; silently shipping a shim I then have to ask you to remove is the failure mode to avoid.

If you're not sure whether something has shipped, default to asking rather than assuming.

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
  - Prose enumeration of branch conditions that mirror the `if` / `switch` / SQL `WHERE` clause right below: "Reject when soft-deleting or when workspace_id mismatches" sitting above `if (existing.deleting_at !== null || existing.workspace_id !== workspaceId)`. The branch already enumerates them; the prose just paraphrases the boolean expression. Keep only the *why* (why these conditions collapse to the same response code, why this asymmetry exists, etc.), not the enumeration.
  - Return-case / precedence enumerations in a docstring that mirror the function's `if A: return X; if B: return Y; return None` ladder. "Precedence: 1. source if provided. 2. processor-wrapped input. 3. raw input. 4. None otherwise." sitting above exactly those four branches. The body *is* the precedence list. Keep the docstring at the concept-level ("decides which track leaves the worker") and attach any *why* — "an explicit source supersedes the peer track entirely" — as a one-line comment next to the branch that earned it, not as a 1-2-3-4 list pretending to be specification.
  Keep the *why* (sizing rationale, allowlist intent, design constraint), and let the reader read the value / count / list off the code.
- **Justify a naming or extraction choice.** "Named because the call site reads better" / "Extracted because it's reused twice" — the name and the call sites are visible. If the *why* of the name encodes a real concept, the comment can capture that concept; otherwise drop it.
- **Describe usage that grep can answer.** "Used in two sites below" / "Imported by routes/foo.ts" / "Used by routes/X (7 handlers)" — let the reader find usages with their tools.
- **Speculate about unimplemented future work** unless that speculation constrains today's code. "Phase 1 has 1:1 X:Y; Extension A will expand …" is fine if it explains why an interface shape today is more general than it needs to be; it's noise if it's just describing what isn't built yet.
- **Use project-internal jargon (Phase 1 / Extension A / nicknamed milestones) without anchor.** A first-time reader of the file shouldn't need to know what "Phase 1" means. If the term is load-bearing, expand the concept inline; if not, replace with concrete language ("currently") or drop.
- **Repeat cross-file context that already lives at one canonical site.** State the explanation in one place (typically next to the definition / decision) and let other sites point at it briefly.
- **Dress up a convention as a systematic feature.** "To add an endpoint: add the handler to `routes/<url>.ts`, then chain `.route("/", ...)` below" reads like a step-by-step the codebase enforces, when it's just a layout convention nothing actually checks. State the convention if it needs stating; skip the prescriptive instructions the code can't make true.
- **Write decorative section dividers.** `// --- Schemas ---`, `// --- Routes ---` between groups of declarations add no information; the declarations themselves are already visible. If a file is long enough that a reader can't navigate it, that's a signal to split the file, not to add headings.
- **Lead with a descriptive what-is preamble.** A paraphrase of whatever the reader is about to see — file, function, route handler, or block — adds nothing. The pattern shows up at every scope:
  - File scope: "Type-only export surface for the app's `hc<AppType>()` client" sitting above `export type { AppType } from "./worker"` paraphrases the file name plus the one line below.
  - Route handler scope: "Soft-delete a document." / "Push a snapshot into the Durable Object room." / "List active documents in a workspace, in sort order." sitting above `.delete("/api/documents/:id", ...)` / `.put("/api/documents/:id/snapshot", ...)` / `.get("/api/documents", ...)` with `ORDER BY sort_order`. The HTTP verb plus the route URL plus the response shape already says it.
  - Block scope: "Update path.", "Insert path.", "Branch on existence with a SELECT first.", "Finalize the document: bump updated_at and clear initializing_at." used as English mini-headings inside a function. These are decorative section dividers in prose form — same problem as `// --- Update ---`, just without the dashes.
  Drop the preamble. Keep only the *why* (a non-obvious response-shape choice, a deliberate cross-handler asymmetry, a race-window the code below addresses, etc.).
- **Quote specific facts you can't cite.** "The package emits printable-ASCII strings (typically <20 chars)" — where did the "<20 chars" come from? If you can't point at a doc / README / spec / measurement, drop the number; an unsupported specific looks authoritative and rots silently when the underlying behavior changes. When the fact *is* genuinely useful, leave a citation (link to the package README, a spec section, an issue) so a future reader can verify or update it.
- **Reference code that no longer exists in the tree.** Phrases like "previously", "the old code", "used to return", "matching what X used to do", "this preserves the old behavior" anchor the comment to a diff the reader cannot see — to them, there is no "previous". They land mid-air. Describe what the code does now, or — if the rationale is non-obvious — the constraint that makes it do that. (Commit messages, PR descriptions, and changelog entries are the right home for "what changed"; comments are not.)

Per-site WHY notes near a tricky branch, a non-obvious cast, a race-condition guard, or a deliberate asymmetry are valuable — keep those.

## Attribution and licensing

When you write code that's structurally derived from an external project — whether the source was named explicitly ("mirror tldraw's pattern", "adapt React Router's loader API") or surfaced during research (a blog post, a reference repo, an upstream example) — treat attribution as part of the work, not an afterthought. The bar is "would a reader of this file know where this idea came from, and would they be able to comply with its license?" If no, add the attribution.

- **Look up the upstream license before assuming MIT.** GitHub's `repos/{owner}/{repo}/license` API returns the SPDX id and the raw text. Most permissive licenses (MIT, BSD, Apache-2.0) require the original copyright + permission notice be preserved in derivative distributions; some (Apache-2.0) also require a NOTICE file and changelog of modifications. Source-available licenses (BUSL, SSPL, tldraw SDK) restrict use entirely — flag those for the user before incorporating.
- **Preserve the upstream notice in a discoverable place.** For one or two adapted files: a top-of-file comment with the license, copyright, and a one-line link is usually enough. For substantial pattern adoption across many files: create a `THIRD_PARTY_NOTICES.md` (or `NOTICE`) at the repo root with the full upstream license text plus a per-file map of what was adapted where, then have each derived file's header point at it.
- **Distinguish "pattern adapted" from "code copied" in the comment.** Independent reimplementations modeled on an upstream design have a softer obligation than copy-pasted code, but both deserve attribution. Saying "patterned after X (MIT, © year holder); reimplemented from scratch" is honest and protects against future readers assuming a copy where there wasn't one.
- **Do this even when both sides are MIT and copyright would technically permit silent reuse.** Attribution is also about traceability for future maintainers — a reader trying to understand why a streaming protocol looks the way it does benefits from knowing the lineage, regardless of legal mechanics.
- **Treat the upstream link as live infrastructure for syncing forward.** This is the often-overlooked second reason attributions matter: the link is a permanent pointer back to a repository whose authors will keep evolving the design — fixing bugs, refactoring, adding modes, hardening edge cases. Months later, when a parser is misbehaving on an input we hadn't considered, the upstream may already have fixed it. When we want to add a feature, the upstream may already have explored the design and discarded the obvious-but-wrong approach. Without the link, every future change is unaided guesswork; with it, we can `git log -- the/upstream/file` against the original repo, read the relevant commits, and pick up the improvement (or learn from a deliberate non-improvement). Concretely, when adding the attribution comment: link to the **specific upstream file** (deep link, not just the repo root); when an upstream file gets renamed or restructured, update the link rather than letting it rot. The whole purpose of leaving these breadcrumbs evaporates if they don't point at anything reachable.
- **Update the project's design doc, not just code comments, when the adoption is architectural.** A comment in one file flags one borrowing; a design-doc paragraph explains why the whole feature's shape mirrors an upstream's.
- **Don't invent license text.** Read it from the upstream repo (the GitHub license API decodes the file from base64 in one call; don't transcribe). Quoting the wrong license in a NOTICE file is worse than quoting none.

If unsure whether a borrowing rises to the level of needing attribution, ask the user — it's the kind of judgment call where their preference (and their tolerance for over- vs under-attribution) matters.

### Attribution wording: credit, don't deflect

How the attribution is phrased matters as much as whether it's there. The respectful framing leads with what the upstream gave you; the disrespectful framing leads with what you didn't take. Avoid disclaimers like "**not a copy**", "**reimplemented from scratch**", "**implementation here is independent**", "**re-implemented from scratch — not a copy — but**" as the headline of an attribution comment. They read as pre-emptive defenses against an imagined copyright accusation, and they undersell the upstream work — the design itself is usually what was borrowed, and the design is what matters.

Frame attribution as credit. Some examples of the right register:

- "Inspired by tldraw/agent-template — that project is where this design first came together."
- "The streaming protocol comes from upstream; the implementation here mostly follows its shape."
- "Largely a port of upstream's `closeAndParseJson` with style adjustments and one bug fix."
- "The section structure (intro + rules with `###` sub-sections), the JSON-actions self-description, and the user-selection idiom are all from upstream."
- "Adapted from upstream's AgentActionUtil; this version is a simpler reimplementation (interface vs class, no mode-specific overrides)."

Calibrate the strength of the verb to the strength of the borrowing:

- **Code copied or near-port** (same algorithm, same data structures, same naming, with cosmetic edits or one bugfix): use "**ported from**", "**closely follows**", "**largely a port of**", "**is a faithful re-rendering of**". Don't soften this with "inspired by" — that under-attributes.
- **Pattern adapted** (same shape and intent, independently authored implementation): "**adapted from**", "**patterned after**", "**follows the design of**".
- **Concept borrowed** (the idea or technique came from upstream, but the code doesn't resemble it): "**inspired by**", "**comes from**", "**informed by**".

When you do need to clarify scope (e.g. "the schemas are mine but the schema-with-meta pattern is theirs"), do it as informative context for readers tracing concepts — not as a hedge to limit your obligation to credit. Phrase it positively: "the **upstream contribution** is the X; the Anipres-specific pieces (Y, Z) are added on top." Not: "X is taken from upstream **but** the Anipres pieces are original."

The bar to check yourself: would the upstream author read this comment and feel credited, or would they feel like the comment is dancing around the borrowing? If the latter, rewrite.

## Command permissions

When asking the user for permission to run a non-trivial or complicated command, briefly explain in natural language what the command does and why it is being run, so the user can make an informed decision.
