## Acting on my input

Distinguish observations and questions from directives. If I describe a problem, ask a clarifying question (including questions framed as comments like "hmm, X seems wrong"), or share an observation without explicitly telling you to change something, treat it as discussion: explain, propose options, and wait for me to pick one. Don't assume an observation is permission to make changes, even when auto mode is active. Auto mode means "act on routine work without checking in," not "decide for me on questions I'm still thinking through."

## Git commit policy

When you make code changes that form a coherent, meaningful batch ready for version control, you may ask me whether to commit them. If I agree, create the commit with a descriptive message summarizing the changes.

**Restrictions:**
- Never amend commits unless I explicitly instruct you to for that specific commit
- Never push commits unless I explicitly instruct you to for that specific commit

Note: Permission to amend or push applies only to the particular commit I named in that instruction. It does not carry over to subsequent commits — each commit needs its own explicit instruction.

## Pull request workflow

PR workflow rules (PR sizing and splitting, the mandatory `pr-reviewer` pre-flight review, watching CI after a push, PR description and title conventions, and how to dispose of AI review-bot findings) live in the `pull-requests` skill. Load it before creating a PR, before pushing to a branch that already has one, and when replying to review comments. One rule that comes up constantly in PR threads is broader than this workflow and has its own section below.

## Never speak to other people on my behalf

Anything sent under my name or from my account is me talking, and I do my own talking. This holds on every platform, not only the one where it comes up most often. A GitHub issue, pull request, or review thread is the typical case, and the same rule governs email, Slack and Discord messages, comments on Linear / Jira / Asana / Notion, and anything else a connector, CLI, or API token can post as me. Never send a message, comment, or reply that carries my voice toward another person. That specifically rules out evaluating or praising their work ("good catch", "nice suggestion", "you're right"), thanking or apologizing, agreeing or disagreeing with a proposal, accepting or pushing back on review feedback, and committing me to future work ("I'll do X next", "will follow up"). These are mine to say, and a machine saying them in my name misrepresents me to a person I have a real relationship with.

Objective, checkable statements of fact are fine to send: what an experiment measured, what a benchmark produced, what a test does now, what a commit changed. State them plainly, with no evaluation of the other person attached and no promises appended. "The suite passes with this change, and the test still fails without it" is fine; the same sentence prefixed with "Good call" is not.

When a thread needs a reply that is not pure fact, do not improvise one. Tell me what needs answering, draft the text if that helps, and let me either send it myself or approve it for you to send. Asking is always the cheap, correct move here, and this holds even when I have told you to proceed autonomously: autonomy covers the work, never my voice.

**The exception: when I say so for that message.** Send something in my voice in two cases: I tell you to send a specific message, or I approve a draft to go out in my name. The test is whether I spoke about that particular message, so a standing autonomy grant or a general "go ahead and handle the PR" leaves this rule fully in force, and every further message needs its own approval. Send exactly what I asked for. When I gave you the substance and left the wording to you, show me the text first; send straight away only when I have already told you to.

## Web frontend development

Accessibility and other web frontend rules live in `~/.claude/rules/web-frontend.md`, which loads automatically when a matching file (HTML, JSX/TSX, Vue/Svelte/Astro, CSS) is in play. Read it when working on frontend code that doesn't match those globs.

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

## Markdown style

Don't hard-wrap prose in Markdown files for raw-file readability. Markdown is read rendered, not raw, so write one line per paragraph or list item and let the renderer wrap. Line breaks stay only where they are semantic: code blocks, tables, front matter, and intentional hard breaks.

## Documentation policy

Don't add prose to a README (or any other doc) that restates what the project's own metadata already declares. `peerDependencies` is the source of truth for which versions are supported, and a package manager reports an unmet peer at install time, so a paragraph repeating those ranges duplicates the manifest and goes stale the moment a range changes. The same applies to listing the flags a CLI's `--help` prints, restating a config schema in prose, enumerating a module's exports, and naming an option's default next to the code that sets it. This is the comment policy applied one level out: the bar is whether the text carries something the canonical source cannot.

Documentation earns its place when it says what the metadata cannot. How to use the thing, why a default is what it is, the constraint behind a surprising requirement, the worked example that turns an API into a recipe.

**Changelog entries are an exception, not a loophole.** A changelog addresses a different reader at a different moment: someone deciding whether to take a release, who has not installed it and so cannot read anything off the manifest. Stating new version ranges there, and answering the question the release actually raises for them, is substance rather than duplication.

**When in doubt, leave the doc out and let the metadata speak.** A redundant paragraph is something I then have to ask you to remove, while a missing one costs a sentence to add later.

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

**Cite the document the code is following.** When code implements a shape that an external document specifies (a vendor's docs page, an upstream README's recommended example, an RFC, a spec section, a linked issue), put that link in a comment next to the code that follows it. The point is proof-reading: a reviewer can check the code against its source instead of taking the author's word for how the upstream behaves, and a future maintainer can see whether the upstream has since changed. Link the exact section anchor rather than the document's front page, and pin the link to the version the code actually depends on: for an action pinned to a commit SHA, link that SHA's README section, not the branch tip that will drift away from it. Verify the link resolves before committing it, and when it can't be fetched from the current environment, say so and cite the primary source that was read instead of pasting a URL from memory. This is separate from the attribution rules below, which govern borrowed code and licensing; a file can need both.

**Anchor comments to the narrowest thing they explain.** Place a comment immediately before the specific line, argument, or branch it justifies — not at the head of the enclosing call, block, or function. A note explaining a `--color never` flag belongs directly above the `"--color", "never"` items inside the argument list, not above the `run_command(` call; a note about one condition of a compound `if` belongs on that condition's line if the syntax allows. The reader should never have to scan downward to find which part of the code a comment is talking about, and when the anchor line moves in a refactor, the comment must move with it.

**Write comments in clear, plain English.** A comment is prose for a person, so it should read like one person explaining the code to another. Prefer short declarative sentences over a single long one that carries several subordinate clauses, and prefer the active voice with a concrete subject ("we skip the animation to its end") over the passive ("the arrow is jumped to the end of the animation"). Avoid clauses wedged into the middle of a sentence: "Re-rendering the arrow, which an endpoint moving is enough to do, hands the browser fresh elements" makes the reader hold the sentence open while unpacking the aside, and reads better as two sentences.

**Break comment lines where the sentence breaks.** End each line at a clause or a complete phrase, not wherever the text happens to reach the width limit. A line that ends on "An arrow" or "a slide" with the rest of the noun phrase on the next line makes the reader stitch the phrase back together; a slightly shorter line that ends at the comma does not. The width limit is a ceiling, not a target, and lines of uneven length are fine when each one is a unit of meaning.

## Attribution and licensing

Rules for crediting external projects (when adapted code or a borrowed design needs attribution, how to check the upstream license, where the notice goes, and how to word it as credit rather than a disclaimer) live in the `attribution` skill. Load it when writing code that is structurally derived from an external project, whether I named the source or it surfaced during research.

## Command permissions

When asking the user for permission to run a non-trivial or complicated command, briefly explain in natural language what the command does and why it is being run, so the user can make an informed decision.
