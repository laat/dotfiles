---
name: babysit
description: Trigger when the user says babysit, shepherd, watch or keep an eye on a pull request, as a plain word mid-conversation as well as /babysit.
---

# Babysit a pull request

Arguments: `$ARGUMENTS`.

`prctl` in this skill's folder does the reading, waiting and replying. Call it by full path:
`~/.agents/skills/babysit/prctl`. Run it with `-h` for the details; its subcommands are
`status`, `wait` and `reply`.

## Pick the targets

The arguments may hold PR references, instructions, or both. A PR reference is a number, a PR URL
or a branch name. Anything else is an instruction, such as "merge when done". Never pass
instruction text to `prctl` or `gh pr view`.

Targets, in order of preference:

1. The PR references in the arguments.
2. If there are none, the PRs opened or discussed earlier in this conversation.
3. If there are none, the PR for the checked-out branch.

Resolve each target once to its base repository and number, and use `$owner`, `$repo` and `$pr`
everywhere below. Review threads live on the base repository, so do not use the head repository
or `gh repo view`, which reads whatever checkout the current directory is in.

```bash
read -r owner repo pr < <(gh pr view "<reference>" --json url \
  -q '.url | capture("github.com/(?<o>[^/]+)/(?<r>[^/]+)/pull/(?<n>[0-9]+)") | [.o, .r, .n] | @tsv')
```

With several targets, run the rounds per PR, and start the waits for all of them in the same
tool-call block. Fixes are per PR: do not batch a change across repositories without reading each
one.

## Done means

All of these hold at the same time:

- Every check passed or was skipped on purpose.
- No workflow run on the head commit is still queued or in progress.
- No Copilot review is pending.
- The review decision is not `CHANGES_REQUESTED`.
- No comment or review summary still asks for something.
- Every thread you acted on carries your reply saying what changed and in which commit.
- Zero unresolved review threads.

`prctl status` checks all of these except the comments: read those yourself. Pushing a fix is not
the end of a thread. A thread without a reply is still open work, even when the code is already
correct.

## Rounds

Each round:

1. **Read** the PR:

   ```bash
   ~/.agents/skills/babysit/prctl status "$pr" -R "$owner/$repo"
   ```

   It prints the head, merge state, failed and pending checks with links, unfinished workflow
   runs on the head, whether Copilot is pending, every unresolved thread with its id, and the
   comments and review summaries since the head commit. The last line is `done` or
   `not done: <reasons>`. Add `--full` for whole comment bodies, `--all-comments` for comments
   from before the head commit.

   If the PR is a draft, stop and tell the user. `UNKNOWN` mergeability means GitHub has not
   computed it since the last push: read again in a moment.
2. **Act** on what it shows ([Act on findings](#act-on-findings)), then
   [reply and resolve](#reply-and-resolve).
3. **Push** the fixes.
4. **Wait** ([Waiting](#waiting)) until the PR needs you again, then start the next round.

A round that finds problems is never the last one. Stop when `status` prints `done` and no comment
still asks for something.

## Waiting

Never write your own polling or `sleep` loop. Use one watcher per PR, never both on the same PR.

In T3 Code (the `t3-code` MCP tools are present):

- Handle what `status` shows first. Then call `watch_pull_request` and end your turn. T3 Code
  wakes you when a check finishes or fails, someone comments or reviews, or the branch conflicts.
- A wake is news, not a verdict: run `status` again. `watch_pull_request` does not see workflow
  runs outside the check rollup or a pending Copilot review; if those are the only reasons left,
  end your turn and let the next wake come.
- Only the thread that owns the PR watches it. As a delegated child task, never call
  `watch_pull_request`; report back to the parent instead.
- Before your final message or a question to the user, call `unwatch_pull_request`.

Everywhere else, use `prctl wait`:

```bash
~/.agents/skills/babysit/prctl wait "$pr" -R "$owner/$repo" 2>&1
```

- Claude Code: run it with the Monitor tool and `timeout_ms: 3600000`, so each line wakes you.
- A shell tool with a time limit, or a subagent: run it in the foreground with `--timeout 270`
  and a tool timeout above that. On exit 124 run it again; nothing is lost.

It exits when the PR needs you:

| Exit | Last lines say | Do |
|------|----------------|----|
| 0 | `merged`, or `settled` and `done` | stop, or go to the report |
| 1 | `check failed`, new feedback, `conflicts with`, `closed`, or `settled` and `not done` | act, push, wait again |
| 2 | bad input, or another prctl already waits on this PR | fix the call; use the running one |
| 124 | the `--timeout` passed | run it again |

`settled` means nothing was pending for a minute; `wait` holds off until then because later CI
jobs register only when earlier ones finish. It stops waiting for a Copilot review that was not
requested within 10 minutes of the head commit, or not submitted within 30, and says
`waived after waiting`; mention that in the report. It remembers what it has already reported, so
start it again after every push and every exit. The first run for a PR reports only what arrives
after it starts; `status` shows what was already there.

When a wake needs no action, end your turn without a message. Never post or say "still waiting".

## Act on findings

- Bot review summaries (Copilot, CodeRabbit and the like) are hints. Read the code each claim is
  about before changing anything. Drop claims that do not hold, with a reply that says why.
- An `outdated` thread points at code that has changed since the comment. Check whether the
  current head already covers it before doing anything.
- Keep the PR at the size its goal needs. Fix real bugs in the case the PR is for. Decline the
  rest with a written reason and list them as follow-ups: tests nobody needs, guards for cases
  that do not happen, refactors next to the change.
- If the repo commits generated files, regenerate and confirm source and output agree before
  calling a thread handled.
- One small, focused commit per fix. Run the tests or build that cover the change. Push.

## Reply and resolve

Reply on every thread you addressed, with the thread id from `status`:

```bash
~/.agents/skills/babysit/prctl reply <thread-id> --resolve -b 'Fixed in <sha>: <one line on the change>'
~/.agents/skills/babysit/prctl reply <thread-id> -b 'Not changed: <reason>'
```

For a longer reply, pass `--body-file -` and the text on stdin.

- `reply` posts first and resolves second.
- Resolve only once the fix is in the pushed code.
- Threads opened by bots: resolve them yourself.
- Threads opened by humans: leave them for the reviewer. `reply --resolve` refuses these unless
  you add `--human-ok`, which you may only do when the user has said you may resolve human
  threads.

## Merge

Only when the user asked for it, in the arguments or earlier in the conversation. Otherwise stop at
Done and leave merging to them.

Merge per PR once its Done holds, without waiting for the others. Right before merging, run
`git fetch` and check again with `--clean`, which also requires GitHub to report the PR `MERGEABLE`
and `CLEAN`:

```bash
~/.agents/skills/babysit/prctl status "$pr" -R "$owner/$repo" --clean
```

On `BEHIND` or `DIRTY`, rebase onto the base, run the tests, push, and start a new round. Squash by
default and delete the branch. If the repository rejects squash, fall back to a merge commit. Never
pass `--admin` or otherwise bypass branch protection. Confirm the result instead of trusting the
exit code.

```bash
gh pr merge "$pr" -R "$owner/$repo" --squash --delete-branch \
  || gh pr merge "$pr" -R "$owner/$repo" --merge --delete-branch
gh pr view "$pr" -R "$owner/$repo" --json state,mergeCommit -q '"\(.state) \(.mergeCommit.oid)"'
```

Do not merge a PR that still has an unresolved human thread, even if the user said to merge.
Report it instead.

## Final report

Before writing it, run `prctl status` and `git status` again. Report facts only:

- head commit SHA
- failed or pending checks by name, and the count that passed
- number of unresolved threads, with the URLs of any you left open
- tests or builds you ran
- uncommitted local files you left alone
- if merged: the merge commit SHA and whether the branch was deleted

With several PRs, use one table row per PR: repo, number, head, checks summary, unresolved
threads, merge commit.

## If prctl fails

`prctl` needs `python3` and `gh`. If GitHub's GraphQL rate limit is used up
(`gh api rate_limit --jq .resources.graphql`), wait for `reset` with one background command
instead of retrying. If `prctl` itself is broken, fall back to `gh pr view --json`,
`gh pr checks --watch`, `gh run list --commit <head>` and the `reviewThreads` GraphQL connection,
and tell the user that `prctl` failed and how.
