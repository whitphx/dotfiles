---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/*.py"
  - "**/*.rs"
  - "**/*.go"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.astro"
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
  - "**/*.sql"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.toml"
  - "**/*.yml"
  - "**/*.yaml"
---

# Comment anti-pattern examples

The rules live in `~/.claude/CLAUDE.md` under "Comment policy". This file holds the worked examples for the anti-patterns named there, under the same names and in the same order.

## Restatement of what the code already says

"Title: at least one non-whitespace character, bounded length, no null bytes" sitting above a schema that pipes `minLength`, `regex`, `maxLength`, `regex` is duplication. The schema is the description. Same for "Combined param schema for `GET /foo/:a/:b` — validates both segments at once" sitting above a `v.object({a, b})`: the schema body says it.

## A claim about code that the code itself is the source of truth for

This is the broader form of "don't quote literal values." It covers:

- Literal values mirroring a constant: "5 MB headroom" above `5 * 1024 * 1024`, ":8787" mirroring a port literal, "`(\"github\" | \"google\")` picklist" mirroring a `v.picklist([...])`, "the typed contract is 200|401" mirroring `if (res.status === ...)` checks.
- Count / cardinality claims: "the only helper shared", "used in two sites below", "all three providers", "the four fields above". The number drifts the moment a fifth one is added.
- Path / endpoint enumerations that mirror routes, exports, or imports: "(`POST /foo`, `GET /bar`)" listing routes that live in another file, "(DocumentSyncRoom, fetch, scheduled)" listing a file's exports.
- Identifier name lists that mirror a schema, picklist, or registry: "providers (github, google)", "the routes (me, logout, identities)".
- Prose enumeration of branch conditions that mirror the `if` / `switch` / SQL `WHERE` clause right below: "Reject when soft-deleting or when workspace_id mismatches" sitting above `if (existing.deleting_at !== null || existing.workspace_id !== workspaceId)`. The branch already enumerates them; the prose just paraphrases the boolean expression. Keep only the *why* (why these conditions collapse to the same response code, why this asymmetry exists), not the enumeration.
- Return-case / precedence enumerations in a docstring that mirror the function's `if A: return X; if B: return Y; return None` ladder. "Precedence: 1. source if provided. 2. processor-wrapped input. 3. raw input. 4. None otherwise." sitting above exactly those four branches. The body *is* the precedence list. Keep the docstring at the concept level ("decides which track leaves the worker") and attach any *why* — "an explicit source supersedes the peer track entirely" — as a one-line comment next to the branch that earned it, not as a 1-2-3-4 list pretending to be specification.

## Justification of a naming or extraction choice

"Named because the call site reads better" / "Extracted because it's reused twice" — the name and the call sites are visible.

## A description of usage that grep can answer

"Used in two sites below" / "Imported by routes/foo.ts" / "Used by routes/X (7 handlers)" — let the reader find usages with their tools.

## Speculation about unimplemented future work

"Phase 1 has 1:1 X:Y; Extension A will expand …" is fine if it explains why an interface shape today is more general than it needs to be; it's noise if it's just describing what isn't built yet.

## Project-internal jargon without an anchor

A first-time reader of the file shouldn't need to know what "Phase 1", "Extension A", or a nicknamed milestone means.

## A convention dressed up as a systematic feature

"To add an endpoint: add the handler to `routes/<url>.ts`, then chain `.route("/", ...)` below" reads like a step-by-step the codebase enforces, when it's just a layout convention nothing actually checks.

## Decorative section dividers

`// --- Schemas ---`, `// --- Routes ---` between groups of declarations add no information; the declarations themselves are already visible.

## A descriptive what-is preamble

A paraphrase of whatever the reader is about to see adds nothing, at every scope:

- File scope: "Type-only export surface for the app's `hc<AppType>()` client" sitting above `export type { AppType } from "./worker"` paraphrases the file name plus the one line below.
- Route handler scope: "Soft-delete a document." / "Push a snapshot into the Durable Object room." / "List active documents in a workspace, in sort order." sitting above `.delete("/api/documents/:id", ...)` / `.put("/api/documents/:id/snapshot", ...)` / `.get("/api/documents", ...)` with `ORDER BY sort_order`. The HTTP verb plus the route URL plus the response shape already says it.
- Block scope: "Update path.", "Insert path.", "Branch on existence with a SELECT first.", "Finalize the document: bump updated_at and clear initializing_at." used as English mini-headings inside a function. These are decorative section dividers in prose form — same problem as `// --- Update ---`, just without the dashes.

## A specific fact you can't cite

"The package emits printable-ASCII strings (typically <20 chars)" — where did the "<20 chars" come from?

## A reference to code that no longer exists in the tree

Phrases like "previously", "the old code", "used to return", "matching what X used to do", "this preserves the old behavior" anchor the comment to a diff the reader cannot see. To them, there is no "previous", so the comment lands mid-air.
