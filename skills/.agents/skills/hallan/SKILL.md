---
name: hallan
description: Trigger when the user says "hallan", or invokes /hallan.
---

# Hallan

Bring a stale pull request up to date with its base, after deciding whether it should be updated
at all.

A rebase without conflicts says nothing about whether the change is still wanted, still correct,
or already done another way. GitHub's "no conflicts" says no more. So judge the pull request
against how the base has moved, pick a verdict, and rebase and push only when the verdict is
`REBASE`.

The input is a pull request number or URL. With none, use the pull request for the current
branch.

## Rules

- Work from freshly fetched refs. Local branches may be stale.
- Uncommitted or in-progress work in the current checkout belongs to the user. If the checkout is
  dirty, mid-rebase or on another branch, work in a throwaway `git worktree` and remove it when
  done.
- You may rebase the pull request's branch onto its base and push the result to that branch.
  That is the whole mandate. Do not merge, close, retarget to another base, or widen the scope
  without the user's say-so.
- Keep the author's commits: no squashing, rewording or new commits beyond resolving conflicts.
  The branch is theirs, and reviewers may have read it commit by commit.
- Push only with a lease on the head SHA you recorded (command in step 4.6). A plain `--force`
  would destroy commits someone pushed while you worked.
- Post no comments, reviews or labels on the pull request unless the user asked. They notify
  people and cannot be taken back.

## 1. Understand the pull request

1. Read its metadata (leave out `<pr>` for the current branch):

   ```sh
   gh pr view <pr> --json number,url,state,isDraft,baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,isCrossRepository,maintainerCanModify,author,statusCheckRollup,reviewDecision
   ```

   - `state` is `MERGED` or `CLOSED`: report that and stop.
   - `isCrossRepository` is true and `maintainerCanModify` is false: you cannot push to it. You
     can still give a verdict.

2. Fetch the base and the exact head commit. `pull/<number>/head` works for forks too, so no
   extra remote is needed to read the branch:

   ```sh
   git fetch origin <baseRefName> "pull/<number>/head"
   head=<headRefOid>
   base=origin/<baseRefName>
   merge_base=$(git merge-base "$head" "$base")
   ```

   Use `baseRefName`, not an assumed `main`. If the base is another pull request's branch (a
   stack), say so: that branch may need updating first.

3. Read the title, description, linked issues, commit messages, the full diff
   (`gh pr diff <pr>`), the conversation (`gh pr view <pr> --comments`) and inline review threads
   (`gh api repos/{owner}/{repo}/pulls/<number>/comments`). Unaddressed change requests count
   toward the verdict.
4. Write the narrowest goal of the pull request in one or two sentences. Judge the implementation
   against this goal in steps 2 and 3, not against the diff as written.

## 2. See how the base moved

- Read what landed on the base since the merge base, overall and for the files the pull request
  touches:

  ```sh
  git log --stat "$merge_base".."$base"
  git diff "$merge_base" "$base" -- $(gh pr diff <pr> --name-only)
  ```

  A file that moved will not show under its old path. Check the `--stat` output for renames.
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

## 3. Pick a verdict

Pick exactly one:

- `REBASE`: the goal still matters and the implementation still fits. Go to step 4.
- `REWRITE`: the goal still matters, but the implementation no longer fits. Describe the smallest
  rewrite that would work and stop without pushing, unless the user also asked for the rewrite.
- `CLOSE`: replaced by other work, obsolete, heading the wrong way, or no longer worth it. Give
  concrete evidence (commits, pull requests, files) and stop. Do not rebase it, and do not close
  it without the user's explicit permission.

`CLOSE` is a valid outcome; do not avoid it. Age is not a reason to close, and effort already
spent is not a reason to keep.

If you are torn between `REBASE` and another verdict, do not push; put the doubt in the report.
A push restarts CI and can dismiss existing approvals. Not pushing costs nothing.

## 4. Rebase (only on `REBASE`)

1. Check out the recorded head in a throwaway worktree, or on a new local branch if the current
   checkout is clean and free:

   ```sh
   git worktree add --detach <path> "$head"
   ```

2. Rebase: `git rebase "$base"`.
3. Resolve each conflict so it serves the pull request's goal and respects the rules and
   invariants the base introduced since. If a conflict shows a real disagreement about product or
   design direction, stop and revisit the verdict instead of picking a side.
4. Read the result. Check that nothing the pull request meant to do was lost, and that nothing the
   base already did or removed came back:

   ```sh
   git range-diff "$merge_base".."$head" "$base"..HEAD
   git diff "$base"...HEAD
   ```

5. Run the repository's tests, lint and type checks for the touched area. For each failure, run
   the same check on `$base` to tell failures the pull request causes from pre-existing ones.
   Report infrastructure failures as such.
6. Push:

   ```sh
   git push --force-with-lease=<headRefName>:"$head" <remote> HEAD:<headRefName>
   ```

   `<remote>` is `origin` for a branch in the same repository. For a fork, use the fork's URL,
   `git@github.com:<headRepositoryOwner.login>/<headRepository.name>.git`. If the lease is
   rejected, someone pushed meanwhile: fetch, read what arrived, and go back to step 3.
7. Remove the throwaway worktree: `git worktree remove <path>`.

## 5. Report

First line: the verdict (`REBASE`, `REWRITE` or `CLOSE`) and why. Then short points on:

- notable changes on the base since the pull request branched;
- conflicts in meaning found, or that none were found;
- the rebase and push result, with the old and new head SHA, if done;
- checks run and their outcome;
- what still needs deciding or doing, with the pull request URL.

Keep observed facts apart from your judgment. Say plainly what you could not verify.
