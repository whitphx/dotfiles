---
name: agent-dispatch
description: "Hand a bounded task to another coding agent — code review, a second opinion, an adversarial discussion, analysis, or a scoped implementation — and run it in its own visible pane when the session is inside Herdr or Orca. Use when the user names another agent (\"ask Codex to…\", \"have Claude review…\"), asks for a second opinion, a comparison, parallel work, or a discussion between agents, or asks to watch an agent work in a pane. Also use before spawning a coding CLI by hand."
---

# Agent Dispatch

Route a task to another agent, keep final judgment yourself, and let the user watch the worker when the terminal can show it.

The pane mechanics belong to the host multiplexer, and each one ships its own skill that matches its installed binary. This skill decides *whether* to dispatch, *where* to send it, and *how* to frame and read back the work. It never restates the host's commands as if they were stable.

## Decide whether to dispatch at all

Dispatch when a second agent genuinely adds something: an independent opinion on a contested call, an adversarial review of your own work, a bounded task that would otherwise cost you a lot of context, or parallel lanes the user asked to watch.

Do the work yourself when it sits on the critical path and waiting would block progress, when the task is smaller than the prompt needed to describe it, or when you would only be relaying the answer you already have.

Never dispatch to avoid a judgment the user asked *you* for.

## Detect the harness

```bash
if [ "${HERDR_ENV:-}" = 1 ]; then echo herdr
elif [ -n "${ORCA_TERMINAL_HANDLE:-}" ]; then echo orca
else echo none
fi
```

Check this before promising the user a pane. Outside both, there is no pane to open.

## Herdr

Print the skill that ships with the installed binary and follow it — it is the authority on command syntax, and it changes with the binary:

```bash
herdr --skill
```

It covers splitting a sibling pane from the caller, starting a named agent of a chosen kind in that pane, prompting it, and waiting on `idle` / `working` / `blocked` / `done`. Read IDs out of the JSON responses rather than predicting them, keep the user's focus where it is unless they asked to move, and leave panes you did not create alone.

Herdr reports server errors as JSON on stderr and exits non-zero, so ordinary shell error handling works.

A `timeout` from `agent start` does not mean the agent failed to start. A coding CLI that opens a trust or approval dialog on first run in a directory is still booting when the startup deadline passes, and the name you asked for is never registered, so every later `agent <name>` call fails with `agent_not_found`. Target the pane id instead, wait for it to reach `idle`, then attach the name:

```bash
herdr agent get <pane-id>
herdr agent rename <pane-id> <name>
```

Read the pane before deciding what the agent is waiting on. A trust prompt, a model picker, and a permission dialog all look like `unknown`, and answering one of them is the user's call, not yours.

An empty read is not evidence that the worker produced nothing. `pane read --source recent-unwrapped` can return zero bytes and exit 0 on a pane whose output `--source visible` shows, because rows drawn on the alternate screen never enter the host scrollback. Retry with `--source visible` before concluding anything, and if a long response is still cut off, grant the worker one explicit file write for its own transcript and read that file. That write is an exception to a read-only scope, so state it in the prompt rather than leaving the worker to infer it.

## Orca

Print the bundled guides, which are version-matched to the installed CLI:

```bash
orca skills get orchestration   # supervised workers, dispatch, gates, coordinator loops
orca skills get orca-cli        # worktrees, terminals, full ownership handoffs
```

Pick `orchestration` when you stay responsible for the outcome and want to supervise, and `orca-cli` when the user is handing the work over entirely.

`orca` exits **0 even when a command fails** and reports the failure as `"ok": false` in its JSON. Branch on `.ok`, never on the exit status.

## Neither harness

Say plainly that no pane is available, then use the host's own subagent mechanism instead of spawning a coding CLI by hand: the Agent tool in Claude Code, `/codex:rescue` where the Codex plugin is installed, or whatever the running host provides.

When the user named a specific agent and the fallback cannot provide it, say which agent is running instead before you dispatch. Substituting a different model silently answers a question the user did not ask.

Spawning a bare CLI in this situation buys nothing over a native subagent and loses the host's permission model.

## Frame the worker's task

A dispatched agent starts without this conversation unless the host explicitly forks it. State all five of these, whatever the harness:

- **Role** — what this worker is for, in one line.
- **Scope** — the exact files or directories it may touch or read.
- **Constraints** — what it must not do, including any of the boundaries below.
- **Output** — the shape you want back, and how short.
- **Verification** — the checks it should run and report.

For a discussion or a second opinion, say what position you already hold and ask it to argue the other side. An agent asked to "review this" agrees far more often than one asked to find the strongest case against a specific claim.

## Read back and judge

Treat the worker's self-report as a claim, not a result. Inspect `git diff` yourself if it edited anything, run the verification locally, and give the user the synthesized answer rather than the raw transcript — they can already see the pane.

When two workers disagree, say so and give your own call. Do not average them.

## Never delegate

Push, deploy, delete, publish, send, or post — these stay with you and need explicit user intent, because a worker in another pane cannot ask the user before acting.

Do not pass secrets, tokens, or personal data into a dispatched prompt. Several agent CLIs take the prompt as a command-line argument, where it is visible to anything that can read the process list.

---

The five-field task contract is inspired by the prompt contract in [tolmachevmaxim/cli-agents](https://github.com/tolmachevmaxim/cli-agents/blob/090ee7ca951012b478ac199ecd930593408e2f75/SKILL.md) (MIT, © 2026 Maxim Tolmachev), which is where that checklist came together for delegating to CLI agents.
