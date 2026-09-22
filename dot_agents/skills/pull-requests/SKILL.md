---
name: pull-requests
description: My pull request workflow — PR sizing and splitting, the mandatory pr-reviewer pre-flight review, CI watching after a push, PR description and title conventions, and how to dispose of AI review-bot findings. Load this before creating a pull request, before pushing to a branch that already has one, and when responding to review comments or bot findings.
---

# Pull request rules

When the user has asked for changes to land in a PR — whether by creating one or pushing to a branch with one — CI is part of "done." Treat the work as incomplete until checks are green; this is an extension of the push instruction under "Git commit policy," not a separate authorization.

## PR size

Default to small, self-contained PRs — the smallest chunk that stands on its own and can be reviewed and merged without the others. Reviewer effort is the thing being optimized, and it grows faster than diff size.

A large PR is fine when the changes are genuinely tangled: one purpose, and splitting them would leave a piece that doesn't build, doesn't pass tests, or can't be understood alone. Say that's the case when it is.

When the work isn't tangled, split it — and split it before opening the PR, not after. Typical seams: a refactor or rename carried alongside a behavior change (mechanical part lands first), unrelated fixes batched because they were found together, new infrastructure plus its first consumer, formatting/lint/dependency churn mixed into substantive work. Don't split so far that the reviewer has to hold several PRs in their head at once, or that an intermediate PR is broken.

If you're partway through a change and realize it has grown two purposes, tell me and propose the split rather than continuing to pile onto one branch.

## Pre-flight review

Before creating a PR, and before pushing an update to a branch that already has one, launch the `pr-reviewer` subagent and wait for its report. Pass it the base ref, the branch, the PR number if one exists, and the exact title and body about to be submitted. It reviews the diff and checks the description against the repo's PR template and contributing docs; it is read-only and reports back to you rather than posting anything.

Act on its findings before submitting: fix the 76+ ones, and tell me about anything you decide not to fix and why. Don't skip the review because the change looks small — a one-line diff can still miss a required template section. Skip it only when I explicitly say to.

- After a push to a PR branch, run `gh pr checks <number> --watch --fail-fast --interval 30` as a background command and wait for its result. Background, because a CI run that outlasts your harness's foreground command timeout gets killed partway through the watch, and resuming it by hand turns one blocking call into repeated polling. Backgrounding it is not permission to yield: "I'll check later" / "you can verify with `gh ...`" is not acceptable — wait for the result before reporting back. Stopping at the first failure beats waiting out the rest of a matrix, and the wider interval keeps the streamed output small; exit code 8 means checks are still pending.
- On failure, read `gh run view <run-id> --log-failed` (not `--log` — the full log eats context for no gain). Read the actual error before reacting; do not pattern-match to a familiar-looking failure or guess from the job name.
- Fix → push → re-watch. Loop until every check is `SUCCESS`. Local lint / typecheck / tests passing is not a substitute — CI runs jobs (matrix builds, integration suites, deploy previews) that can fail when local doesn't.
- If the same check fails three times across your fixes, stop and summarize what you tried. Three same-shape failures usually means the mental model is wrong, and continuing burns turns without converging.
- If a failure is plausibly unrelated to the change (flaky test, infra outage, unrelated job timing out), say so explicitly and ask how to proceed — do not silently retry or rerun jobs to make red go away.


## Feedback from AI review bots

Automated reviewers (CodeRabbit, Codex, and the like) comment on my PRs, and their findings are yours to dispose of rather than mine to triage. Assess each one against the code as it stands now, instead of accepting it wholesale or waving it off. A bot reasoning about a stale commit, or about a path the code already rules out, is common; so is a real defect that nothing else caught.

When a finding is valid and still applies, fix it as part of the work, with the same verification any other change gets. Don't ask first.

When a finding is wrong, or describes something already fixed, post a reply saying why and resolve the conversation. Don't leave threads open for me to work through, and don't resolve one silently. Reply with `gh api repos/<owner>/<repo>/pulls/<number>/comments/<comment-id>/replies -f body=...`, then resolve through the GraphQL `resolveReviewThread` mutation, whose thread ID comes from the PR's `reviewThreads`.

Keep those replies to checkable fact: what the current code does, which commit changed it, why the described path cannot happen. The rule in `CLAUDE.md` about not speaking in my voice still governs the wording even though the reader is a machine, because the thread sits under my account and people read it afterwards. Once a human joins the thread it stops being a bot thread, and that rule governs it entirely.

## PR descriptions

Before writing a PR description, check whether the target repository specifies a format. Look for a pull request template (`pull_request_template.md`, `docs/pull_request_template.md`, `.github/pull_request_template.md`, or a `.md` file under `.github/PULL_REQUEST_TEMPLATE/`, `PULL_REQUEST_TEMPLATE/`, `docs/PULL_REQUEST_TEMPLATE/`) and for contribution instructions in developer docs (`README.md`, `CONTRIBUTING.md`, `DEVELOPMENT.md`, or their equivalents). If either exists, **it wins over my defaults below**: keep the template's structure, fill in every section it asks for, and follow whatever style it prescribes — including sections my defaults would otherwise cut, such as a "Test Plan" or a checklist. When the template or instruction offers a free-form field for describing the change and doesn't prescribe a writing style for it, write that field using the default style below. Note when multiple templates exist under a `PULL_REQUEST_TEMPLATE/` directory (GitHub treats them as alternatives) and pick the one matching the change, or ask me if it's ambiguous.

Everything from "Otherwise" onward is my personal taste for clarity and brevity, and it governs only the case where the project gives no instruction. A project's own format always outranks it. Don't quietly trim a required section toward my preferences, don't rename or restructure the template's headings because a shorter form would read better, and don't treat a section the project asks for as padding. When the project's convention and my taste conflict, follow the project and say which rule of mine you set aside, so I can tell it was a deliberate choice rather than a lapse. The same order of precedence holds for the PR title and commit message rules below.

Otherwise, the default: keep PR descriptions short, plain, and structured. Open with a sentence on the problem that existed before the PR, then say what the PR does about it — abstract first, concrete after — and stop — the diff and tests carry the rest, and the reviewer reads the diff. Include a concrete input/output example only when it *shows* the bug (e.g. two Set-Cookie lines in, one out). Use a numbered list only when the PR genuinely has multiple distinct parts. Cut entirely: "Test Plan" sections, "verified locally" narratives, spec citations, production war stories/provenance, cross-repo references, "no new dependencies" notes, pre-commit/CI assurances — anything provable by the diff or CI is noise in prose. The same economy applies to issue drafts and commit bodies aimed at external maintainers, unless the extra context is load-bearing for a design discussion.

**How to tell reviewers to run the tests.** Don't add a "Test Plan" heading of my own. The name reads as a checklist of things I intend to run rather than work already done, and a dedicated section is out of proportion in a description that is otherwise a couple of unheaded paragraphs. What genuinely helps a reviewer is knowing the command that exercises the change, so close the description with one plain sentence naming it, in present tense and phrased as a property of the tests rather than an assurance from me: "`pytest -k asgi-ws` in `packages/cli` runs them." Where a test's discriminating power is not obvious, one clause on what it would catch is worth adding ("which sends a second custom header as a control so the assertion cannot pass vacuously"). Skip the sentence entirely when the command is the repo's single obvious one and the tests sit in the diff. This is the form the "verified locally" narrative cut above should take, not a reinstatement of it.

**A PR description describes the change, never the PR's own revision history.** Write it in the present tense, as the final state of the work, for a reviewer opening the page for the first time. When I ask for a revision (fix the tests, restructure the code, respond to a maintainer's comment), update the description to describe the new state; do not append a note explaining that it changed. Sentences like "Per review feedback, the tests now live in the existing directory", "Updated to address the comments", "Rebased onto main", or "Previously X, now Y" are noise to a fresh reviewer, who never saw the earlier version. Either state the fact plainly as part of what the PR does, or drop it when it only describes a change of approach. The same applies to PR comments: don't post "done, moved it" chatter on a PR nobody has reviewed yet — it clutters the thread with a conversation that has no other participant.

Two exceptions, both narrow. When the PR is already under active review, a note telling a returning reviewer what moved since they last looked is welcome, and a direct reply to their comment is expected. When another in-flight PR references this one, explaining the relationship is worth the space. In both cases prefer a PR comment over the description: a comment is timestamped in the thread, while the description is read as timeless.

**PR titles are commit messages when the repo squash-merges.** Before titling a PR, check two things: whether the project prescribes conventional commits (CONTRIBUTING, commitlint config, semantic-release/release-please setup), and whether it merges PRs by squash (look at recent merged PRs — squash merges appear as single commits titled "PR title (#N)"). If both hold, the PR title *is* the commit message that release automation will parse: it must be a valid conventional-commit subject with the correct type and scope per that repo's rules (e.g. `fix(cli): …`), regardless of what the branch's internal commits look like. Never submit GitHub's auto-generated title derived from the branch name (e.g. "Fix/asgi ws disconnect delivery") — always write the title deliberately.

**Avoid dashes as prose punctuation.** In descriptive text written for humans (PR/issue titles and bodies, review comments, commit messages, docs), do not punctuate sentences with dashes at all: no em-dash "—", and no hyphen standing in for one ("the fix - which is small - does X"). Restructure instead, using commas, parentheses, or separate sentences. Em-dashes in particular read as AI-generated. Hyphens inside compound words ("cold-start", "best-effort") are fine.

**Decorate inline code as code — including in titles.** Anywhere Markdown renders (PR/issue titles and bodies, review comments), wrap code-like tokens in backticks: commands (`uv pip freeze`), flags (`--color never`), identifiers (`scope["path"]`), file paths, header names (`Set-Cookie`). A title like ``fix(cli): force `--color never` on the parsed `uv pip freeze` output`` is right; the bare-text version is not. Plain-text-only contexts (git commit subjects viewed in terminals are still Markdown-rendered by GitHub when they become PR titles — decorate them too).

## Speaking on my behalf

The prohibition on speaking to other people in my voice lives in `~/.claude/CLAUDE.md` under "Never speak to other people on my behalf" and is always loaded. It governs the wording of every reply posted under my account, including replies to review bots.
