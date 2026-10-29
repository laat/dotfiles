---
name: sol-loop
description: Have GPT Sol review the current change, fix the findings that hold, and re-review until Sol approves or 3 rounds are used. Trigger when the user says "sol loop" or "codex review loop", or invokes /sol-loop. Runs Sol as a T3 delegated task, or through the codex CLI outside T3. Does not push or post to GitHub unless the user asked.
---

# Sol loop

Arguments: an optional target (a PR number, a branch, a path) and an
optional round limit. Without a target, review the current branch
against its base. Without a limit, 3 rounds. Sol runs at `xhigh`
reasoning effort unless the user names another.

Sol is a second reader: it finds what the author has stopped seeing.
Its findings are claims until checked against the code. The goal is a
correct change, not a larger one. Fix with the smallest edit, and argue
back when a finding is wrong or outside the intent.

## Rounds

- 3 by default. Round 1 reviews the whole change. Later rounds look at
  the open findings and the code changed since the previous round.
- Raise the limit to 5 only when the user asks, or when a P1 or P2 is
  still open with evidence and concerns security, auth, permissions,
  data loss or concurrency.
- End early when a round returns only P3s. Declining a P3, or fixing a
  comment, doc or formatting, does not need another round.
- One reviewer per round. Sol must not start its own subagents.

Keep a ledger across rounds, one line per finding: id, severity,
outcome (fixed, disputed, declined), and token usage if the tool
reports it. Do not estimate usage.

## 1. Pin the change

1. `git status --short`. Leave unrelated changes alone: no stash, no
   reset. If the change's files cannot be told apart from them, ask.
2. `git fetch origin`, then find the base:
   - PR: `gh pr view <n> --json baseRefName,headRefOid`. Check out the
     branch only if the tree is clean, and confirm `HEAD` is the PR head
     or ahead of it by this change only. Base:
     `git merge-base HEAD origin/<baseRefName>`.
   - Branch: `git merge-base HEAD origin/<default branch>`.
   - No remote: a base the user names, or `HEAD` for uncommitted work.
3. The change is base to working tree, untracked files included,
   limited to its paths. Fix one diff command and use it every round.
4. Write down the intent and what is out of scope, one or two sentences.
5. Run the build, lint and tests that cover the change. Do not send Sol
   a change that breaks them. Note failures that were there before, and
   missing checks, in the brief.

## 2. Run Sol

### In T3

1. Call `orchestrator_capabilities` with `search: "sol"`. Take the
   newest Sol model on the codex provider unless the user named one.
   Read the ID from the result; do not hardcode it.
2. Every round is a new `delegate_task` with `role: "review"`,
   `mode: "async"`, `target` set to that provider and model with
   `options: {reasoningEffort: "xhigh"}`, and a new `clientRequestId`.
   Check that the result echoes that model and effort; if the model
   does not offer `xhigh`, say so instead of picking another level.
   Keep the `taskId`. The child gets no history, so
   each brief must stand on its own. Do not continue a review through
   `childThreadId`, `t3_thread_send`, `t3_thread_launch` or
   `create_threads`.
3. End the turn and wait for the completion notice. Do not poll and do
   not start a second reviewer. Do not edit the change's files while
   Sol is reading them.

If the T3 tools are missing from the tool list, call
`orchestrator_capabilities` once directly before concluding they are
not there.

### Outside T3

Use the codex CLI. The newest Sol:

```sh
codex debug models | jq -r '.models[].slug' | grep -m1 sol
```

```sh
S=$(mktemp -d)
# round 1
codex exec -m <model> -c 'model_reasoning_effort="xhigh"' -s read-only -o "$S/review1.md" --json - < "$S/brief1.md" > "$S/review1.jsonl" 2>&1
grep -o '"thread_id":"[^"]*"' "$S/review1.jsonl" | head -1

# round n
codex exec resume <thread_id> -m <model> -c 'model_reasoning_effort="xhigh"' -c 'sandbox_mode="read-only"' -o "$S/reviewN.md" - < "$S/briefN.md" > "$S/reviewN.log" 2>&1
```

`resume` has no `-s`; set the sandbox with `-c`. Give each run a 15
minute timeout. Read the review from the `-o` file, not the JSONL.

If neither route reaches Sol, stop and tell the user. Do not swap in
another model.

A timeout, an error or an empty reply is not approval. Cancel the task,
confirm it stopped, and rerun the round with the ledger.

## 3. The brief

Round 1:

```
Review only. Do not edit files, commit, push, comment on GitHub, or
start subagents.

Repo: <absolute path>
Base: <sha>
Intent: <intent>
Out of scope: <out of scope>
Checks: <command: result, one per line>

The change: `git diff <base> -- <paths>`, plus untracked files from
`git status --short`, read in full. Read the code around the change
and its callers, not only the diff.

Report bugs, callers the change breaks, and behaviour that differs from
the intent. Point out anything added that the intent does not require.
Ignore style unless it hides a bug.

Severity:
P1  the change fails at what the intent says it does.
P2  a bug inside the intent's scope that real use will reach.
P3  the rest: other code paths, rare inputs, minor performance,
    compatibility nobody asked for.

Format:
VERDICT: APPROVE | CHANGES
F1 [P1|P2|P3] <path>:<line> <what goes wrong, and when>. Fix: <suggestion>
Keep finding ids stable across rounds.
```

Later rounds: the round 1 brief, then the ledger (`fixed:`, `disputed:`
with the evidence, `declined:` with the reason), then the diff since
the previous round. Ask Sol to mark each open id `resolved` or
`open: <reason>`, and to review only the open ids and the changed code.

## 4. Answer the findings

Check each finding against the code yourself, and re-grade its
severity by the definitions in the brief, not by Sol's label.

- It holds: make the smallest fix for the case Sol described. Removing
  or narrowing code beats adding new machinery. Add one test that fails
  without the fix when the intent calls for it.
- It does not hold: dispute it with evidence: `path:line`, a test,
  command output.
- P3 or out of scope: decline in one line and list it as a follow-up.

Do not agree to a finding just to end the loop. After fixing, rerun the
checks and `git diff --shortstat <base>`. If the review made the change
bigger, cut it back before the next round.

Start another round only when rounds are left and either a P1 or P2 is
open or behaviour code changed since Sol last approved.

## 5. Stop

Done: Sol approves the current behaviour diff, no P1 or P2 is open, and
you have no concern of your own.

Stuck: a finding is still disputed after two exchanges, or the rounds
ran out. Give both positions in two or three lines each and let the
user decide. Running out of rounds is not approval.

The loop does not push or post. After it ends, push only if the user
asked to push, ship or update the PR. Never post Sol's review as a PR
comment.

Report to the user: rounds, model and effort, what changed because of Sol, diff
size before and after (`--shortstat`), each finding fixed, disputed or
declined with the reason, token usage if the tool reported it (or that
it did not), and whether anything was pushed.

## Known dead ends

- The codex sandbox blocks `go build` and `go vet` (they write to a
  temporary directory), even read-only. Run them yourself and put the
  result in the brief. `go test` works inside it.
- A fix for one finding has introduced the next round's finding more
  than once. That is why later rounds review the changed code, not only
  the open ids.
