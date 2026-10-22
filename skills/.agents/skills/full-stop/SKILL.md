---
name: full-stop
description: Own the work end to end until the pull request is ready for the user to merge, without merging it. Stage it in galley, let the reviewer agents review it, publish it to GitHub, babysit checks and review threads until it is clean, then hand it back. Use only when the user explicitly asks for "full stop" as an instruction, as in "take over, full stop" or "fix this. Full stop.", or invokes /full-stop. For the same flow ending in a merge, see full-send.
---

# Full stop

The user said "full stop" because they are not watching this thread. They want the change taken
to a GitHub pull request that is ready to merge, and they merge it. Your progress updates and your
final message go unread until long after you stop.

If the user did not ask for this in a clear way, do not assume this autonomy: "full stop" is also
punctuation in dictated text. Ask, or work as usual.

You own the work from its current state to a pull request that passes the
[ready gate](#ready-gate). The user grants you permission to:

- publish the pull request to GitHub with `galley pr publish`, without their review in galley;
- rebase the pull request's own branch and let `galley pr wait` force-push it with a lease.

You do not have permission to merge, to turn on auto-merge, or to push to any other branch.

## Flow

1. **Finish the change.** Do the work the user asked for. Commit on a branch with at least one
   commit over the base; if you are on the default branch, create one first.
2. **Prove it.** See [Proof](#proof). Do this before staging, and again for every later change.
3. **Stage it** with the `galley` skill, and turn on auto-publish right after:

   ```sh
   galley pr create --title "..." --body-file - <<'EOF'
   Why the change is needed, what it does, and the proof.
   EOF
   galley pr publish --auto
   ```

   Pass the reviewer flags from the `galley` skill if the user named reviewers. Do not ask the user
   to review in galley; auto-publish replaces that step.
4. **Loop with the reviewer agents** as in the `galley` skill, steps 2 to 5: `galley pr wait`,
   address every thread, wait again. When the reviewer agents are done and the feedback is
   answered, galley publishes and `pr wait` prints `Published to GitHub: <url>`.
5. **Babysit it** with the `babysit` skill, with these changes:
   - Where babysit says push, commit and run `galley pr wait`. It pushes your commits to GitHub.
     Never `git push` or `gh pr edit` yourself.
   - Edit the title and description with `galley pr edit`, then `galley pr wait`.
   - Skip babysit's Merge section.
   - Keep running rounds until the [ready gate](#ready-gate) holds, not only babysit's Done.
6. **Report** as in [Hand back](#hand-back).

In T3 Code (the `t3-code` MCP tools are present):

- After `Published to GitHub: <url>`, call `link_pull_request` with the URL.
- While babysitting, call `watch_pull_request` and end your turn instead of blocking on
  `gh pr checks --watch`. T3 Code wakes you when checks finish, someone comments, or the branch
  conflicts. Keep `galley pr wait` running in the background as well; it reports a merge or close.
- Call `unwatch_pull_request` before the final message, also when you stop early.

## Proof

Proof is evidence you observed yourself in this session: command output, a reproduction, a
screenshot. Use the most direct proof the change allows.

- Bug fix: reproduce the failure, apply the fix, and watch the same reproduction pass.
- Run the checks the repository's CI runs (tests, lint, typecheck, build) locally first.
- If the behaviour has no test and the repository has a test setup, add one focused test that
  fails without the fix.
- UI or runtime behaviour: run the app and look at the change (the `run` skill). Green mocked
  tests do not prove what the user sees.
- Put the proof in the pull request description: what you ran and what it showed.

If you cannot prove a change, say so in the description and in the question to the user. Do not
claim it works.

## Ready gate

All of these hold at the same time:

- The proof covers every change in the pull request, including fixes made during review.
- Every required check is green, and babysit's Done holds.
- All review bots and reviewer agents have finished, and each finding is fixed or answered in a
  written reply.
- No human review still requests changes, and no human thread is unresolved.
- The branch is up to date with its base, and GitHub reports it mergeable:

  ```bash
  gh pr view "$pr" -R "$owner/$repo" --json mergeable,mergeStateStatus
  ```

  Expect `MERGEABLE` and `CLEAN`. On `BEHIND` or `DIRTY`: `git fetch origin`, rebase onto
  `origin/<base>`, resolve conflicts, run the tests again, and run `galley pr wait`, which
  force-pushes with a lease. Then start a new babysit round, since CI runs again.

## Asking the user

A question in a normal message goes unseen, and the thread looks finished. To ask the user
anything, use the harness's question tool, so the thread shows that it is waiting:
`AskUserQuestion` in Claude Code, `request_user_input` in Codex, `question` in opencode.

- Ask only when you cannot continue alone: a product decision, missing access, a reviewer who
  disagrees with the user's stated intent, a failure you cannot fix within the change's scope.
- Put all the context in the question: the pull request URL, what blocks you, what you tried, and
  the options, with your recommendation first.
- If you lack access to something you need, take the safe path: stop and ask. Do not work around
  a sandbox, a protected branch or a missing permission.

## Hand back

When the ready gate holds, end with a short report, so it reads well when the user gets to it:

- the GitHub pull request URL and head SHA;
- one line on what changed and one on how it was proven;
- what the reviewer agents, bots and humans raised, and what you did about it;
- anything you left open, with the thread URL.

Do not merge. The user does.
