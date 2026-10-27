---
name: hallan
description: Trigger when the user says "hallan", or invokes /hallan.
---

# Hallan

A stale pull request has fallen behind its base. Updating it is a decision about whether the
change still makes sense, not only a Git operation. A rebase without conflicts says nothing about
whether the pull request is still wanted, still correct, or already obsolete.

## Permissions

- First run `git fetch origin` (and the head repo's remote, if it is a fork). Never trust local refs.
- Uncommitted or in-progress work in the current checkout belongs to the user. If the checkout
  is dirty or busy, work in a throwaway `git worktree`.
- You may rebase the pull request's own branch and push the result to it.
- You may not merge, close, retarget to another base, or widen the scope without the user's
  explicit say-so.
- Push only with `git push --force-with-lease=<branch>:<old-head-sha>`, never `--force`. If the
  lease is rejected, someone pushed meanwhile: fetch, look at what arrived, and reassess.
- Post no comments on the pull request unless the user asked for that.

## 1. Understand the pull request

1. Find it with `gh pr view <number|url>`, or with no argument for the current branch. Record
   the URL, state (open, closed, merged), base branch, head repo and branch, head SHA, author,
   CI status and review status:

   ```sh
   gh pr view "$pr" --json url,state,baseRefName,headRepository,headRepositoryOwner,headRefName,headRefOid,author,statusCheckRollup,reviewDecision
   ```

2. Read the title, description, linked issues, commit messages, review threads and the full diff
   (`gh pr diff "$pr"`).
3. Write down the narrowest goal of the pull request in one or two sentences. Judge the
   implementation against that goal later.
4. Use the real base from `baseRefName`, not an assumed `main`. Record the merge base:
   `git merge-base <head-sha> origin/<base>`.

## 2. See how the base moved

- Read the commits and diffs on the base since the merge base:
  `git log --stat <merge-base>..origin/<base>`, and `git diff <merge-base> origin/<base> -- <paths>`
  for the files the pull request touches.
- Search for work that replaces or competes with it, by similar titles, same files and same
  behaviour: `gh pr list --state all --search "..."`, `gh search prs --repo <owner/repo> "..."`.
- Look for conflicts in meaning, not only in text:
  - Was the problem already fixed another way?
  - Did the APIs, types, schemas, dependencies or module boundaries it relies on change?
  - Do the pull request and the base now both implement or own the same behaviour?
  - Was the code it touches removed, moved, or deliberately simplified?
  - Would merging bring back behaviour that was removed on purpose, or leave two ways to do
    one thing?
  - Is the gain still worth the cost of maintaining it?
- A clean `git rebase` or GitHub's "no conflicts" is never by itself evidence that the pull
  request is up to date.

## 3. Decide before pushing

Pick exactly one verdict:

- `REBASE`: the goal still matters and the implementation still fits. Go to step 4.
- `REWRITE`: the goal still matters, but the implementation no longer fits. Describe the smallest
  rewrite that would work and stop without pushing, unless the user also asked for the rewrite.
- `CLOSE`: replaced by other work, obsolete, heading the wrong way, or no longer worth it. Give
  concrete evidence (commits, pull requests, files) and stop. Do not rebase it, and do not close
  it without the user's explicit permission.

`CLOSE` is a valid outcome; do not avoid it. Age is not a reason to close, and effort already
spent is not a reason to keep.

## 4. Rebase (only on `REBASE`)

1. Create a local branch or throwaway worktree at the recorded head SHA.
2. Rebase onto `origin/<base>`.
3. Resolve each conflict so it serves the pull request's goal and respects the rules and
   invariants the base introduced since. If a conflict shows a real disagreement about product or
   design direction, stop and revisit the verdict instead of picking a side.
4. Compare and read the result. Check that nothing the pull request meant to do was lost, and
   nothing the base already did or removed came back:

   ```sh
   git range-diff <merge-base>..<old-head> origin/<base>..HEAD
   git diff origin/<base>...HEAD
   ```

5. Run the repository's tests, lint and type checks for the touched area. Say which failures the
   pull request causes and which are pre-existing or infrastructure.
6. Push with the lease from [Permissions](#permissions).

Never merge the pull request.

## 5. Report

First line: the verdict (`REBASE`, `REWRITE` or `CLOSE`) and why. Then short points on:

- notable changes on the base since the pull request branched;
- conflicts in meaning found, or that none were found;
- the rebase and push result, with the new head SHA, if done;
- checks run and their outcome;
- what still needs deciding or doing, with the pull request URL.

Keep observed facts apart from your judgment. Say plainly what you could not verify.
