---
name: zizmor
description: Audit the current repo's GitHub Actions with zizmor, fix the findings, and open a PR. Safe auto-fixes plus reviewed manual fixes; anything left unfixed is justified in the PR body.
disable-model-invocation: true
---

# zizmor audit → PR

zizmor statically analyzes GitHub Actions for security problems: template
injection, credential persistence, over-broad permissions, unpinned or
impostor actions, cache poisoning, and more. The deliverable is a PR, not a
report. Every finding ends up in one of three buckets: fixed in the PR,
suppressed with a written justification, or listed in the PR body as an
accepted risk.

## Steps

1. **Baseline.** From the repo root, on a clean working tree:

   ```sh
   GH_TOKEN=$(gh auth token) zizmor --no-progress --format=json . > /tmp/zizmor.json
   GH_TOKEN=$(gh auth token) zizmor --no-progress .
   ```

   The token enables online audits (impostor commits, known-vulnerable and
   stale action refs); without it those rules silently don't run. zizmor
   collects workflows, composite actions, `dependabot.yml`, and pre-commit
   configs on its own, so pass `.`, not a file list.

2. **Branch**, e.g. `zizmor-audit`.

3. **Safe auto-fixes.** `zizmor --fix .` applies only fixes marked safe.
   Review the diff anyway. Never use `--fix=all`. Unsafe fixes can change
   workflow behavior, so do those by hand in step 4 where each one gets
   judged on its own.

4. **Manual fixes**, per rule. The common ones:
   - *template-injection:* move each `${{ ... }}` in `run:` into an `env:`
     var and reference it as `"$VAR"`. This preserves behavior only if the
     value was already treated as data, so check.
   - *excessive-permissions:* add top-level `permissions: {}` and grant the
     minimum per job. Read each job to see what it actually needs before
     narrowing.
   - *artipacked:* `persist-credentials: false` on `actions/checkout`,
     unless a later step in that job pushes or uses the git credential.
   - *unpinned-uses:* pin to a full digest with an exact version comment.
     The `renovate-pin-actions` skill is the thorough version of this.
   - *cache-poisoning / dangerous-triggers (`pull_request_target`):* no
     mechanical fix. Understand the workflow's trust boundary first; if the
     fix isn't obviously right, leave it and flag it in the PR instead.

5. **Suppress only real false positives**, each with a reason: inline
   `# zizmor: ignore[rule] <why>` on the flagged line, or a scoped entry in
   `.github/zizmor.yml` for whole-file cases. A finding that's merely
   annoying to fix is not a false positive.

6. **Verify.** Re-run the step-1 audit; only findings you deliberately left
   should remain. The workflows must also still parse:
   `zizmor --strict-collection .` must collect everything without errors,
   and run `actionlint` if it's installed.

7. **PR.** Commit and `gh pr create`. Body: a table of finding, severity,
   and resolution (fixed / suppressed plus why / accepted plus why), and a
   note that the permission and `persist-credentials` changes deserve the
   closest review since they can break workflows that relied on the broad
   defaults.

If the user asks for a stricter pass, re-run with `--persona=pedantic`
(code-smell findings) or `--persona=auditor` (false positives expected).
Default to `regular`; it's what CI should gate on.
