---
name: babysit
description: Supervise one pull request until it is ready to merge. Waits on CI, works through review threads and comments, fixes and pushes, then checks everything again. Use when the user asks to babysit, shepherd, watch or keep an eye on a PR until it is green and reviewed.
disable-model-invocation: true
---

# Babysit a pull request

Target: `$ARGUMENTS`. It is a PR number, a PR URL or a branch name. If empty, use the PR for the checked-out branch.

Resolve it once to the base repository and number, then use `$owner`, `$repo` and `$pr` everywhere below. Review threads live on the base repository, so do not use the head repository fields or `gh repo view`, which reads whatever checkout the current directory is in.

```bash
read -r owner repo pr < <(gh pr view "$ARGUMENTS" --json url \
  -q '.url | capture("github.com/(?<o>[^/]+)/(?<r>[^/]+)/pull/(?<n>[0-9]+)") | [.o, .r, .n] | @tsv')
```

Work in rounds. Each round: read status, wait for checks, read the conversation and the review threads, fix what is real, push, then start the next round from the top. A round that finds problems is never the last one.

## Done means

All four hold at the same time:

- Every check passed or is skipped on purpose.
- The review decision does not block merging (no `CHANGES_REQUESTED`).
- No comment or review summary still asks for something.
- Zero unresolved review threads.

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

## Final report

Before writing it, re-run the status, comment and thread queries and run `git status`. Report facts only:

- head commit SHA
- each check by name with its result
- number of unresolved threads
- tests or builds you ran
- uncommitted local files you left alone
