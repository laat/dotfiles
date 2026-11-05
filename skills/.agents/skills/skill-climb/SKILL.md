---
name: skill-climb
description: Improve an existing agent skill by hill-climbing on test runs. Realistic prompts are run through the skill and its previous version in parallel, the outputs are graded by a check script and judged by two models from different providers, the skill is revised from what holds, and the loop repeats until the judges are satisfied. Trigger when the user invokes /skill-climb, or says "skill climb" about a named skill.
disable-model-invocation: true
---

# Skill climb

Hill-climb a skill on evidence. Each iteration runs the same realistic
prompts through the new and the previous version of the skill, grades
the outputs, has independent judges score them, and revises the skill from
the findings that hold. The loop stops when the judges are satisfied, or when
what is left is about the test tooling rather than the skill.

There are three roles:

- You orchestrate: set up the workspace, write prompts and checks, verify
  findings, edit the skill, and report.
- **Runners** are subagents that act as a fresh session using the skill on
  one prompt. They do the work; they do not review.
- **Judges** are two strong models from different providers, by default
  the newest Claude Opus and the newest GPT Sol at high effort. They stand
  in for the human reviewer.

The user names the skill and, optionally, what to focus on. If the skill is
unclear, ask.

## 1. Set up

1. Find the skill's canonical folder (the repo copy, not a stowed or
   installed symlink) and work on a branch or worktree there.
2. Create a workspace outside every repo, so nothing in it gets committed or
   stowed:

   ```sh
   W=~/<skill>-workspace
   mkdir -p $W/evals/files
   cp -rL <skill-folder> $W/skill-v1      # -L: stowed skills are symlinks
   ```

   Each revision gets a new snapshot (`skill-v2`, ...). Runners and judges
   read snapshots, never the installed copy, which may be another version.
3. Make the skill's own scripts work in this environment before measuring
   anything. Run them once on a small input. Fix what is broken (missing
   tools, platform-specific paths); ask the user to install packages that need
   sudo. Runners that fail on setup measure nothing.
4. Fix problems you already know about. Do not hold a known fix back to see
   whether the loop finds it.

## 2. Write the evals

Three to five prompts, the way a real user would write them: their language,
their level of detail, with the data or files they would attach. Cover
different paths through the skill, and include:

- one vague request, where the skill has to choose for the user;
- one prompt that pins down a default (for example "only for PowerPoint"),
  so over-eager behaviour shows;
- a case that exercises the skill's riskiest code (charts with negative or
  missing values, photos, long text).

Put inputs in `$W/evals/files/`. Synthetic stand-ins are fine; say in the
prompt what they show.

`$W/evals/evals.json`:

```json
{
  "skill_name": "<skill>",
  "evals": [
    {"id": 1, "name": "<kebab-name>", "prompt": "<user's words>",
     "expected_output": "<what a good result has>", "files": ["evals/files/..."]}
  ]
}
```

Add fields the grader needs (for example whether an optional deliverable is
expected). Show the user the prompts in a few lines and go ahead unless they
object. Change prompts only between iterations, never during one.

## 3. Run

Layout, one folder per eval and configuration:

```
$W/iteration-N/eval-<id>-<name>/eval_metadata.json      # {"eval_id", "eval_name", "prompt", "assertions": []}
$W/iteration-N/eval-<id>-<name>/<config>/run-1/outputs/
$W/iteration-N/eval-<id>-<name>/<config>/run-1/timing.json
```

`<config>` is `with_skill` (the new snapshot) and `old_skill` (the previous
one). In iteration 1 there is nothing to compare yet: run the current
version only, as the baseline. From iteration 2, run both. When the baseline
snapshot has not changed, copy its runs from the earlier iteration instead
of running them again.

Start every run in the same turn, in parallel, and wait for them all. Give
each runner the same brief, with only the skill path and folder changed:

```
You are a test run for a skill evaluation. Act as an agent receiving the
user request below, with the `<skill>` skill available. Do the work
yourself; start no subagents.

- Skill path: <snapshot>. Read its SKILL.md completely and follow it as if
  it had triggered. Wherever SKILL.md says <installed path>, use the skill
  path instead (the installed copy is a different version).
- Working directory: <run>/outputs/ (absolute paths).
- Input files: <paths, or none>.
- Do not publish anything (no uploads, pushes or messages). Where the skill
  would publish, stop and write the command you would run in notes.md.
- There is no human to answer questions. Where the skill says to ask,
  choose what the user most likely wants and note it.

User request:
"<prompt>"

Leave all deliverables and QA output in the working directory. Write
notes.md: (1) your steps in order, each script run and whether it errored;
(2) anything in SKILL.md that was unclear, wrong, contradictory or missing,
and where you guessed; (3) problems you saw in the output and whether you
fixed them. Write reply.md: the message you would send the user.
```

Do not tell a runner which version it has. When a runner finishes, save its
token count and duration to `timing.json` right away
(`{"total_tokens", "duration_ms", "total_duration_seconds"}`); the
completion notice is the only place they appear.

## 4. Look and grade

1. Look at every output yourself before anyone else does. Render visual
   output to PNG and make one contact sheet per run (all pages or slides on one
   image), so a run can be judged at a glance. Read notes.md: repeated
   confusion across runs points at the skill; helper code that several runs
   wrote themselves belongs in the skill's scripts.
2. Write `$W/check.py`, a script that grades every run of an iteration and
   writes `grading.json` next to `outputs/`:

   ```json
   {"expectations": [{"text": "...", "passed": true, "evidence": "..."}],
    "summary": {"passed": 0, "failed": 0, "total": 0, "pass_rate": 0.0}}
   ```

   Check what can be checked objectively: the files exist, the data matches
   the input, required metadata, accessibility attributes, defaults kept or
   left out as the prompt asked. Each failure found in a review becomes a
   check, so the next iteration shows whether the fix worked. Content
   judgement (is the title true to the data, is the structure right) stays
   with the judges.
3. Aggregate per configuration: mean pass rate, time and tokens, and the delta
   new minus old. Say plainly when checks encode the new version's own rules:
   then part of the gap is the new version obeying itself.
4. When you change the grader, build small fixture runs that must pass and
   must fail, and run the grader on all of them, the earlier fixtures and the
   real runs. A grader change must not change the verdict on a real run
   unless that verdict was wrong.

## 5. Judge

Brief both judges in the same turn, each with its own provider and model at
high reasoning effort. Read the model IDs from the harness; do not hardcode
them. If a judge's model is unavailable, tell the user and stop; do not swap
in another model.

- In T3 Code: call `orchestrator_capabilities` once, then one
  `delegate_task` per judge with `target.providerInstanceId`, `model` and
  the effort option, and a new `clientRequestId`. Check that the result
  echoes the model and effort. End the turn and wait for both notices.
- Elsewhere: run the Claude judge with the subagent tool, and the GPT judge
  with the codex CLI:

  ```sh
  codex debug models | jq -r '.models[].slug' | grep -m1 sol
  codex exec -m <model> -c 'model_reasoning_effort="high"' -s read-only -o "$W/judge-rN.md" - < "$W/brief-rN.md"
  ```

  The read-only sandbox cannot render files, so put the renders in the
  workspace before the brief.

Judges start with no history. Each brief stands alone:

- the user's goal, and that the judges stand in for the human reviewer;
- the paths: repo and skill folder, the snapshots and how to diff them,
  evals.json, check.py, the iteration folders and what is in each run
  (outputs, contact sheets, notes.md, reply.md, grading.json);
- that renders come from <renderer> and may differ from the real target;
- from round 2: every earlier finding and how it was answered (fixed,
  declined with the reason, or a follow-up);
- your own observations, labelled "verify or reject";
- the rules: read-only, no edits, commits, pushes, comments or subagents;
  scratch files in their own folder under /tmp; copy fixture folders to /tmp
  before running the grader, which rewrites grading.json;
- what to deliver:
  1. per eval, a score out of 10 for the new and the old version as the end
     user would receive it, which is better and why, with references to
     pages, slides or lines;
  2. whether each change did what it intended, with evidence, and any rule
     that was over-applied or misread;
  3. bugs or regressions in the diff, ranked, with evidence;
  4. an overall score out of 10 and a clear verdict: satisfied, or exactly
     what must change;
  5. blockers only for what would hurt real use or make the grader rank
     plausible outputs wrongly; everything else as one-line follow-ups.

## 6. Weigh and revise

Read both answers before acting. Check every finding against the files
yourself; a finding is a claim until you have seen it hold. Then tell the
user, briefly:

- the scores per eval and overall, new against old;
- findings that hold, and who raised them;
- where the judges disagree, each position in a line;
- what you will change, and what goes to follow-ups.

A disagreement about a product decision (a default, a size, when to make an
extra file) is the user's call: ask. If the user says to go on, take the
position that keeps more options open, and say which you took.

Revising:

- Generalise. The skill will see many prompts, not these few. A fix that
  only makes the test prompts pass is overfitting.
- Explain why in the skill, not just what. A reason generalises; a bare
  MUST gets followed literally or over-applied.
- Keep the skill lean. Remove instructions that made runners waste time.
- Verify a fact before writing it into the skill. If you cannot verify it
  here (another app, another platform), say "probably", or leave it out.
- New rules have side effects. In the next iteration, look for a rule that was
  over-applied (a caveat on every slide, a shared scale where it hides the
  message, a working note left in a shared document) and narrow it.
- Keep scope where the user set it. Judges suggest more features every
  round; decline in one line and list them as follow-ups.

## 7. Iterate

Each round:

1. Snapshot the revised skill as the next version.
2. Rerun the evals the change affects, or all of them, against the
   baseline. For a change that is fully deterministic (a script fix), rebuilding
   an earlier run's output with the new scripts may be enough; say so.
3. Grade, look, and brief both judges again with a full brief: a new task,
   not a follow-up message.
4. Keep a score table:

   ```markdown
   | Judge | Round 1 | Round 2 |
   | --- | --- | --- |
   | Claude Opus | 7/10 | 8.5/10 |
   | GPT Sol | 7/10 | 8.4/10 |
   ```

   Write `no score` for a judge that gave none; never make one up.

Stop when both judges are satisfied. Also stop and ask the user (wrap up,
one more round, or a fresh iteration of all evals) when:

- the skill has been stable for a round and the remaining blocks are edge
  cases in check.py or the fixtures, not in the skill;
- a judge keeps holding out on something outside the scope;
- rounds stop producing changes that matter to real use.

## 8. Wrap up

- Report: what changed in the skill, the score table, the last iteration's
  pass rates, what was not verified (target apps, platforms), and follow-ups.
- Commit and push only when the user asks, following the repo's own rules.
  Keep the skill changes and the evals in separate commits.
- Offer to keep the evals with the skill, in `<skill-folder>/evals/`:
  evals.json, the input files, check.py (reading evals.json from beside
  itself) and a short README with the eval list, how to run an iteration and
  the grader's known gaps. If the skill lives in a stow package, keep `evals/`
  out of the installed copy with a `.stow-local-ignore` in the package. That
  file replaces stow's default ignore list, so repeat the defaults in it,
  then check with `stow --simulate` that only the eval files drop out.
- Leave the workspace for the user to delete.
