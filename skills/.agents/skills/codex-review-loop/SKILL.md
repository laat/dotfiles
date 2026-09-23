---
name: codex-review-loop
description: Run an independent design and code review of the current change with the codex CLI, fix what it finds, and re-review in the same codex thread until it reports nothing worth fixing or the round limit is reached (default 7). Use when the user asks for a codex review loop, "ask codex for a review", "loop with codex", "astra review", or wants a second-opinion review of a branch, PR or design note before hand-off. Does not commit, push or post to GitHub; the user decides that.
disable-model-invocation: true
---

# Codex review loop

Arguments: an optional target (a PR number, a branch, a path such as a
design note) and an optional round limit. Without a target, review the
current branch against its base. Without a limit, at most 7 rounds.

The loop reviews and fixes, nothing else. It never commits, pushes,
comments on a PR or edits anything outside the working tree. Whether
and when to commit or push between rounds is the user's call; ask only
if a round cannot proceed without it (it can: codex reads the working
tree).

## Why

Codex (the `codex` CLI, model shown as "Astra" in its output) reads the
repository with its own eyes and its own sandbox, so it finds what the
author has stopped seeing: a design note contradicted by the code, a
race in something appended from another goroutine, a lost error on a
partial success. Its findings are hints until read against the code.

## One round

1. Write the prompt to a file in the scratch directory. Ask for:
   - what to read first: `AGENTS.md`, `CLAUDE.md`, the design note the
     change implements, then the diff and the touched packages in full;
   - what to look for: behaviour that contradicts the note, bugs,
     races, lost errors, state left inconsistent after cancel or
     failure, regressions in callers that were refactored, missing
     tests for what could regress, misleading comments or docs;
   - the format: a numbered list of findings tagged `[P1]` must fix,
     `[P2]` should fix, `[P3]` nit, each with a link
     `https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<line>`
     against the exact commit or, for uncommitted work, `<path>:<line>`,
     and one paragraph with the concrete failure scenario; then a
     `Validation` line naming what it ran (`go build`, `go vet`,
     `go test`, or the project's equivalents) and the result; an
     explicit "nothing worth fixing" when that is the case;
   - "Do not post anything to GitHub; write the review to stdout only."
2. Run it. First round starts a thread; later rounds resume it so codex
   keeps its context and can re-check its own findings.

   ```sh
   # round 1
   codex exec -s read-only -o "$S/review1.md" --json - < "$S/prompt1.md" > "$S/review1.jsonl" 2>&1
   grep -o '"thread_id":"[^"]*"' "$S/review1.jsonl" | head -1

   # round n
   codex exec resume <thread_id> -c 'sandbox_mode="read-only"' -o "$S/reviewN.md" - < "$S/promptN.md" > "$S/reviewN.log" 2>&1
   ```

   `resume` has no `-s`; the sandbox is set with `-c`. A round takes a
   few minutes; give the command a 15 minute timeout. Read the review
   from the `-o` file, not from the JSONL.
3. Read each finding against the code before touching anything. Drop a
   claim that does not hold and say so in the next prompt, with the
   reason. Fix the rest: one focused change per finding, with a test
   where the finding is something that could regress. Run the project's
   build, vet and tests and check the exit status directly, not through
   a pipe.
4. Write the next prompt: for each finding, what changed and where
   (function or test name), or why it was not changed. Then ask for a
   re-check of each fix and one more pass over the whole diff, same
   format, and an explicit statement when nothing is left.

## Stop

Stop when codex reports nothing worth fixing and you agree after reading
the code, or when the round limit is reached. At the limit, report what
is still open and why.

Tell the user, at the end, the number of rounds, each round's findings in
one line each, and which findings were dropped and why. Keep the review
files in the scratch directory; they are the record.

## Known dead ends

- Codex's sandbox blocks `go build` and `go vet` (temporary directory
  writes) even in read-only mode; its `Validation` line will say so.
  Run them yourself; `go test` works inside its sandbox.
- Posting codex's review as a PR comment: the user does not want it.
  Findings belong in the fix and in whatever the user writes.
- Trusting round n's "all clear" without re-reading: a fix for one
  finding has introduced the next round's finding more than once
  (routing by the row's host fixed a rename and broke observed-agent
  rows). Ask for the whole-diff pass every round, not just re-checks.

## Worked example

github.com/laat/laatmux pull 12 (2026-09-23): three rounds, four
findings, then two, then none. Each round's fixes are one commit whose
message lists them.
