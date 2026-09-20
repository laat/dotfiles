---
name: babysit
description: Supervise one or more pull requests until they are ready to merge. Waits on CI, works through review threads and comments, fixes and pushes, replies on and resolves every thread it handled, then checks everything again. Merges only when asked. Use whenever the user says babysit, shepherd, watch or keep an eye on a PR, also as a plain word mid-conversation and not only as /babysit.
---

# Babysit a pull request

Arguments: `$ARGUMENTS`.

## Pick the targets

The arguments may hold PR references, instructions, or both. A PR reference is a number, a PR URL or a branch name. Anything else is an instruction, such as "merge when done". Never pass instruction text to `gh pr view`.

Targets, in order of preference:

1. The PR references in the arguments.
2. If there are none, the PRs opened or discussed earlier in this conversation.
3. If there are none, the PR for the checked-out branch.

Resolve each target once to its base repository and number, then use `$owner`, `$repo` and `$pr` everywhere below. Review threads live on the base repository, so do not use the head repository fields or `gh repo view`, which reads whatever checkout the current directory is in.

```bash
read -r owner repo pr < <(gh pr view "<reference>" --json url \
  -q '.url | capture("github.com/(?<o>[^/]+)/(?<r>[^/]+)/pull/(?<n>[0-9]+)") | [.o, .r, .n] | @tsv')
```

With several targets, run the rounds below per PR. The PRs are independent, so run the watchers for all of them in the same tool-call block. Fixes are per PR: do not batch a change across repositories without reading each one.

Work in rounds. Each round: read status, wait for checks, read the conversation and the review threads, fix what is real, push, then start the next round from the top. A round that finds problems is never the last one.

## Done means

All four hold at the same time:

- Every check passed or is skipped on purpose.
- The review decision does not block merging (no `CHANGES_REQUESTED`).
- No comment or review summary still asks for something.
- Every thread you acted on carries your reply saying what changed and in which commit.
- Zero unresolved review threads.

Pushing a fix is not the end of a thread. A thread without a reply is still open work, even when the code is already correct.

## Read the PR

```bash
gh pr view "$pr" -R "$owner/$repo" --json number,url,state,isDraft,headRefName,baseRefName,headRefOid,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup
```

If `isDraft` is true, stop and tell the user. `mergeable` and `mergeStateStatus` are computed lazily after each push and read `UNKNOWN` in the meantime. That means "not computed yet", not a verdict. Wait a moment and read again.

## Wait for checks

Block on the watcher instead of sleeping in a loop. Give the command a ten-minute timeout. If it times out while checks are still running, run it again.

```bash
gh pr checks "$pr" -R "$owner/$repo" --watch --fail-fast
```

The watcher returning is a hint, not a verdict. Later-stage jobs such as deploys and e2e runs are added to the check rollup only when their upstream job finishes, so the watcher can exit 0 between polls while work is still pending. After it returns, read the PR again. If any check is still `PENDING`, `QUEUED` or `IN_PROGRESS`, run the watcher again. Only a status read with nothing pending counts as checks finished.

## Read comments and review summaries

```bash
gh pr view "$pr" -R "$owner/$repo" --json comments,reviews --jq '
  (.comments[] | {at: .createdAt, who: .author.login, state: "COMMENT", body}),
  (.reviews[]  | {at: .submittedAt, who: .author.login, state, body})
  | "\(.at) \(.who) [\(.state)]\n\(.body)\n"'
```

## Read inline review threads

`gh pr view` does not expose these. Query the `reviewThreads` connection over GraphQL and page through it. Output is one unresolved thread per line: thread id, outdated flag, file:line, last author, last comment url, first 120 characters of the last comment.

```bash
cursor=null
while :; do
  page=$(gh api graphql -F owner="$owner" -F repo="$repo" -F pr="$pr" -F cursor="$cursor" -f query='
    query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          reviewThreads(first: 100, after: $cursor) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id isResolved isOutdated path line
              comments(last: 1) { nodes { author { login } body createdAt url } }
            }
          }
        }
      }
    }')
  jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved | not)
    | .comments.nodes[0] as $c
    | [.id, (if .isOutdated then "outdated" else "current" end),
       "\(.path):\(.line // "-")", ($c.author.login // "ghost"), $c.url,
       ($c.body | gsub("\\s+"; " ") | .[0:120])]
    | @tsv' <<<"$page"
  cursor=$(jq -r '.data.repository.pullRequest.reviewThreads.pageInfo
    | if .hasNextPage then .endCursor else empty end' <<<"$page")
  [ -n "$cursor" ] || break
done
```

## Act on findings

- Bot review summaries (CodeRabbit, Copilot and the like) are hints. Read the code each claim is about before changing anything. Drop claims that do not hold.
- An outdated thread points at code that has changed since the comment. Check whether the current head already covers it before doing anything.
- If the repo commits generated files, regenerate and confirm source and output agree before calling a thread handled.
- One small, focused commit per fix. Run the tests or build that cover the change. Push. Go back to reading the PR.

## Reply and resolve

Reply on every thread you addressed. The comment id is the digits after `discussion_r` in the last comment's url.

```bash
gh api -X POST "/repos/$owner/$repo/pulls/$pr/comments/<comment-id>/replies" \
  -f body='Addressed in <sha>: <one-line summary of the change>'
```

```bash
gh api graphql -F id=<thread-id> -f query='
  mutation($id: ID!) {
    resolveReviewThread(input: {threadId: $id}) { thread { id isResolved } }
  }'
```

Rules:

- Reply first, resolve second.
- Resolve only after the fix is confirmed in the pushed code.
- Threads opened by bots: resolve them yourself.
- Threads opened by humans: leave them to the reviewer unless the user has explicitly said you may resolve them.

## Merge

Only when the user asked for it, in the arguments or earlier in the conversation. Otherwise stop at Done and leave merging to them.

Merge once Done holds for that PR, per PR, without waiting for the others. Squash by default and delete the branch. If the repository rejects squash, fall back to a merge commit. Then confirm the result instead of trusting the exit code.

```bash
gh pr merge "$pr" -R "$owner/$repo" --squash --delete-branch \
  || gh pr merge "$pr" -R "$owner/$repo" --merge --delete-branch
gh pr view "$pr" -R "$owner/$repo" --json state,mergeCommit -q '"\(.state) \(.mergeCommit.oid)"'
```

Do not merge a PR that still has an unresolved human thread, even if the user said to merge. Report it instead.

## Final report

Before writing it, re-run the status, comment and thread queries and run `git status`. Report facts only:

- head commit SHA
- each check by name with its result
- number of unresolved threads
- tests or builds you ran
- uncommitted local files you left alone
- if merged: the merge commit SHA and whether the branch was deleted

With several PRs, use one table row per PR: repo, number, head, checks summary, unresolved threads, merge commit. Name every failed or pending check. Passing checks may be summarised as a count.
