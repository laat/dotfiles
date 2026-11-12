---
name: ai-moot
description: Trigger when the user says "ai moot", or invokes /ai-moot.
---

# AI moot

Strong models from more than one provider look at the same request in parallel, usually a review
or feedback on a change. You brief them, weigh what they say, act on what holds, and report.

## 1. Get the work ready first

The moot reviews the current state of the work, so bring it up to date before you brief
anyone:

- Address open review comments on the pull request, if there is one.
- Fix the issues you already know about.
- Run the build, lint and tests that cover the change, and note the results.

Do not hold back a known fix to see whether the moot finds it. That wastes a round.

Exception: if the user wants to throw the implementation away and explore other approaches, do
not fix code that is about to be replaced.

## 2. Pick the members

One model per model family, at high reasoning effort.

- If the user named members, use those.
- Otherwise use four: the newest Claude Opus, the newest Claude Fable, the newest GPT Sol and
  the newest GPT Astra. Read the model IDs from the harness; do not hardcode them.

If a member is unavailable, tell the user and stop. Do not swap in another model or provider.

## 3. Brief them

In T3 Code:

1. Call `orchestrator_capabilities` to find the providers and models.
2. Start one `delegate_task` per member, all in the same turn, each with its own provider and
   model, `options: {reasoningEffort: "high"}`, and a new `clientRequestId`. Check that each
   result echoes the model and effort you asked for.
3. End the turn and wait for the completion notices. Do not poll.

Elsewhere, run a member the harness offers with its own subagent tool (Opus and Fable in Claude
Code), and reach Sol and Astra through the codex CLI as the `sol-loop` skill does for Sol.

Each delegate starts with no history, so the brief must stand on its own:

- the user's request, in their words where it matters;
- the repository path, the base, and how to see the change (a diff command or a PR number);
- the intent, and what is out of scope;
- the check results from step 1.

For a review or feedback, the work is read-only. Tell them so: no edits, commits, pushes, GitHub
comments or subagents.

For a code review, ask each delegate for a score out of 10 along with its findings.

## 4. Weigh the answers

Read every answer before acting. Check each finding against the code yourself; a finding is a
claim until you have seen it hold. Then sum up for the user:

- findings that hold, and who raised them;
- where the delegates disagree, with each position in a line or two;
- the next steps you recommend.

## 5. Act and go again

Make the changes you agree with, rerun the checks, and start a fresh review with every member.
Keep going until every delegate is satisfied.

A round is one full review pass by the moot. A fresh review after fixes is a new round. Each
round is a new `delegate_task` with a full brief; add what changed since the last round and how
you answered each finding (fixed, or declined with the reason).

Keep the scope where the user set it. Delegates will suggest extra features, refactors and
hardening nobody asked for, more of it with every round. Decline those in one line and list them
as follow-ups. If a delegate keeps holding out on something outside the scope, stop and give the
user both positions instead of growing the change.

## 6. Report

For a code review, record the scores per round. If a delegate gave no score, write `no score`.
Never make one up.

If the work ends in a pull request, put this section in its description, above the closing line
that names the model and harness (or at the end, if there is no such line):

```markdown
## AI moot review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus | 7/10 | 9/10 |
| Claude Fable | 8/10 | 9/10 |
| GPT Sol | 8/10 | 10/10 |
| GPT Astra | 7/10 | 9/10 |
```

For an open pull request, edit the description (`gh pr edit`, or `galley pr edit` if galley owns
the PR). Do not post the results as a comment.

With no pull request, put the same section in your final reply instead.
