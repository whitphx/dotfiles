---
name: upstream-fixes
description: My rules for when a task works around a problem in someone else's project (a dependency, tool, or service misbehaving) — checking the problem is really upstream's, marking the workaround in our code, offering to contribute the fix back, keeping upstream work out of the current task, and removing the workaround once upstream ships the fix. Load this whenever you add an override or version pin, skip an install script, wrap a tool in a script, patch a dependency, disable a check, or add a retry because something outside the repository misbehaves.
---

# Fixing problems upstream

Sometimes a dependency, tool, or service misbehaves and we work around it in our code. Workarounds include an override or version pin, a skipped install script, a wrapper script, a patch, a disabled check, or a retry. When that happens, consider whether the fix belongs upstream, and ask me before contributing it.

1. **Check that it really is upstream's problem**, not our misuse or configuration.
   - Reproduce it against the latest upstream release or default branch.
   - Search upstream's issues and pull requests for an existing report.
2. **Mark the workaround in our code.** Add a comment saying which upstream problem it works around and when it can be removed. Link the upstream issue once there is one. This is the "why not" comment the comment policy asks for: it stops the next reader from deleting the workaround while it is still needed, and it tells them when they can.
3. **Ask me before contributing.** In your report, say:
   - which project, and what the problem is;
   - what you'd contribute: an issue, a patch or pull request, or a docs fix;
   - whether it's already reported;
   - roughly how much work it is.

   Do this at the end of the task, or at a natural pause. Don't stop the current work to ask. Skip this step when the cause is on our side, or when an existing upstream report already covers it. In that case, just link the report in the comment from step 2.
4. **Do nothing outside the current repository without my approval.** That includes opening issues, posting comments, opening pull requests, and forking repositories. Once approved, anything posted still falls under "Never speak to other people on my behalf": hand me the drafts unless I tell you to post that specific one.
5. **After approval, keep the upstream work separate from the current task.**
   - Hand it to a subagent, or to a separate session for anything long (see the `agent-dispatch` skill), so the current task isn't blocked.
   - Write the issue text and the patch, test the patch against upstream's code, and give me the drafts to post.
   - If the session lacks access to the upstream repository, say so and leave the posting to me rather than working around the access limit.
6. **Remove the workaround once upstream ships the fix.** When you touch code carrying one of these comments, check whether the linked issue is resolved and released; if it is, offer to remove the workaround and bump the dependency.
