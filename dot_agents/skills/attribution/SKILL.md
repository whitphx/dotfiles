---
name: attribution
description: My rules for crediting external projects — when code or a design pattern adapted from an upstream repo, blog post, or reference implementation needs attribution, how to check the upstream license before assuming MIT, where to put the notice, and how to word it as credit rather than a disclaimer. Load this when writing code that is structurally derived from an external project, whether I named the source or it surfaced during research.
---

# Attribution and licensing

When you write code that's structurally derived from an external project — whether the source was named explicitly ("mirror tldraw's pattern", "adapt React Router's loader API") or surfaced during research (a blog post, a reference repo, an upstream example) — treat attribution as part of the work, not an afterthought. The bar is "would a reader of this file know where this idea came from, and would they be able to comply with its license?" If no, add the attribution.

- **Look up the upstream license before assuming MIT.** GitHub's `repos/{owner}/{repo}/license` API returns the SPDX id and the raw text. Most permissive licenses (MIT, BSD, Apache-2.0) require the original copyright + permission notice be preserved in derivative distributions; some (Apache-2.0) also require a NOTICE file and changelog of modifications. Source-available licenses (BUSL, SSPL, tldraw SDK) restrict use entirely — flag those for the user before incorporating.
- **Preserve the upstream notice in a discoverable place.** For one or two adapted files: a top-of-file comment with the license, copyright, and a one-line link is usually enough. For substantial pattern adoption across many files: create a `THIRD_PARTY_NOTICES.md` (or `NOTICE`) at the repo root with the full upstream license text plus a per-file map of what was adapted where, then have each derived file's header point at it.
- **Distinguish "pattern adapted" from "code copied" in the comment.** Independent reimplementations modeled on an upstream design have a softer obligation than copy-pasted code, but both deserve attribution. Saying "patterned after X (MIT, © year holder); reimplemented from scratch" is honest and protects against future readers assuming a copy where there wasn't one.
- **Do this even when both sides are MIT and copyright would technically permit silent reuse.** Attribution is also about traceability for future maintainers — a reader trying to understand why a streaming protocol looks the way it does benefits from knowing the lineage, regardless of legal mechanics.
- **Treat the upstream link as live infrastructure for syncing forward.** This is the often-overlooked second reason attributions matter: the link is a permanent pointer back to a repository whose authors will keep evolving the design — fixing bugs, refactoring, adding modes, hardening edge cases. Months later, when a parser is misbehaving on an input we hadn't considered, the upstream may already have fixed it. When we want to add a feature, the upstream may already have explored the design and discarded the obvious-but-wrong approach. Without the link, every future change is unaided guesswork; with it, we can `git log -- the/upstream/file` against the original repo, read the relevant commits, and pick up the improvement (or learn from a deliberate non-improvement). Concretely, when adding the attribution comment: link to the **specific upstream file** (deep link, not just the repo root); when an upstream file gets renamed or restructured, update the link rather than letting it rot. The whole purpose of leaving these breadcrumbs evaporates if they don't point at anything reachable.
- **Update the project's design doc, not just code comments, when the adoption is architectural.** A comment in one file flags one borrowing; a design-doc paragraph explains why the whole feature's shape mirrors an upstream's.
- **Don't invent license text.** Read it from the upstream repo (the GitHub license API decodes the file from base64 in one call; don't transcribe). Quoting the wrong license in a NOTICE file is worse than quoting none.

If unsure whether a borrowing rises to the level of needing attribution, ask the user — it's the kind of judgment call where their preference (and their tolerance for over- vs under-attribution) matters.

## Attribution wording: credit, don't deflect

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

