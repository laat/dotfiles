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

1. **Ensure the latest zizmor.** New releases add audits and fix
   false positives, so an audit from a stale binary is incomplete:

   ```sh
   zizmor --version
   gh api repos/zizmorcore/zizmor/releases/latest --jq .tag_name
   ```

   If they differ, upgrade before auditing (`brew upgrade zizmor`, or
   whatever installed it — check with `which zizmor`), and confirm
   `zizmor --version` now matches. If the upgrade isn't possible (e.g.
   the package manager lags the release), read the newer versions'
   release notes and note in the PR body which version ran and what the
   missing versions would have added.

2. **Baseline.** From the repo root, on a clean working tree:

   ```sh
   GH_TOKEN=$(gh auth token) zizmor --no-progress --format=json . > /tmp/zizmor.json
   GH_TOKEN=$(gh auth token) zizmor --no-progress .
   ```

   The token enables online audits (impostor commits, known-vulnerable and
   stale action refs); without it zizmor falls back to offline mode and
   those rules silently don't run. zizmor collects workflows, composite
   actions, `dependabot.yml`, and pre-commit configs on its own, so pass
   `.`, not a file list. If the repo was triaged with zizmor before, run
   once with `--no-ignores` too, to see what earlier passes suppressed.

3. **Branch**, e.g. `zizmor-audit`.

4. **Safe auto-fixes.** `GH_TOKEN=$(gh auth token) zizmor --fix .` applies
   only fixes marked safe. The token matters here too: the unpinned-uses
   fix resolves tags to commit SHAs via the GitHub API. Review the diff
   anyway. Never use `--fix=all`. Unsafe fixes can change workflow
   behavior, so do those by hand in step 5 where each one gets judged on
   its own.

5. **Manual fixes**, per rule. The common ones:
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

6. **Suppress only real false positives**, each with a reason: inline
   `# zizmor: ignore[rule] <why>` on the flagged line (comma-separate for
   multiple rules), or a `rules.<id>.ignore` entry in `.github/zizmor.yml`
   for whole-file cases. Findings in composite actions (`action.yml`) can
   only be ignored with inline comments; `zizmor.yml` ignore rules don't
   reach them. A finding that's merely annoying to fix is not a false
   positive.

7. **Verify.** Re-run the baseline audit; only findings you deliberately
   left should remain. The exit code makes this scriptable: 0 is clean,
   11–14 mean findings remain, keyed to the highest severity
   (informational through high). The workflows must also still parse:
   `zizmor --strict-collection .` must collect everything without errors,
   and run `actionlint` if it's installed.

8. **PR.** Commit and `gh pr create`. Body: a table of finding, severity,
   and resolution (fixed / suppressed plus why / accepted plus why), and a
   note that the permission and `persist-credentials` changes deserve the
   closest review since they can break workflows that relied on the broad
   defaults.

If the user asks for a stricter pass, re-run with `--persona=pedantic`
(code-smell findings) or `--persona=auditor` (false positives expected).
Default to `regular`; it's what CI should gate on.
