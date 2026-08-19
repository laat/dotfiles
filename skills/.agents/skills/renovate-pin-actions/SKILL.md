---
name: renovate-pin-actions
description: Set up or fix Renovate-managed GitHub Actions pinning in the current repo — every third-party `uses:` pinned to a digest with an exact patch-version comment that Renovate maintains.
disable-model-invocation: true
---

# Renovate-pinned GitHub Actions

Renovate's github-actions manager reads the comment after a pinned digest as
the version constraint. A major-only comment (`# v7`) lets the digest float
within the major and produces opaque digest-only PRs where you can't tell a
re-release from a new version. An exact comment (`# v7.0.1`) makes Renovate
maintain the comment itself at patch precision, PR titles show the real
version change, and a digest-only PR then means exactly one thing: upstream
re-tagged the same version.

Target state, both parts required:

1. The Renovate config extends `helpers:pinGitHubActionDigests`.
2. Every third-party `uses:` is `owner/repo@<40-hex-sha> # vX.Y.Z`.

## Steps

1. **Inventory.** `grep -rn "uses:" .github/` — workflows *and* composite
   actions (`.github/actions/**/action.yml`), where pins often hide. Skip
   local refs (`./...`) and `docker://` images (Renovate's docker manager
   handles those).

2. **Config.** Find the Renovate config (`renovate.json`, `renovate.json5`,
   `.github/renovate.json*`, or the `renovate` key in `package.json`). Ensure
   `"helpers:pinGitHubActionDigests"` is in `extends`. Without it, Renovate
   unpins digests back to tags on its next PR.

3. **Fix each ref** by case:
   - *Digest with a major- or minor-only comment (or none):* resolve the
     digest to its exact tag —
     `git ls-remote --tags https://github.com/OWNER/REPO | grep ^SHA` —
     and rewrite the comment to the most specific tag (`v2 v2.2 v2.2.0` →
     `# v2.2.0`). Comment-only edit; the digest stays put.
   - *Tag ref (`@v4`, `@v4.2.0`), not yet pinned:* resolve the tag to a
     commit —
     `git ls-remote https://github.com/OWNER/REPO "refs/tags/TAG*"` —
     using the peeled `^{}` sha if one is listed (annotated tags), then
     treat it as the case above.
   - *Digest matching no tag:* upstream moved or deleted the tag. Don't
     guess — flag it and propose bumping digest + comment together to the
     latest release.

4. **Verify.** No under-specified comments remain:
   `grep -rnE '@[0-9a-f]{40} # v[0-9]+(\.[0-9]+)?$' .github/` must be empty,
   and no bare tag refs: `grep -rnE 'uses: [^./][^ ]*@v[0-9]' .github/`.

5. **PR it separately.** State in the PR that a comment-only diff changes
   nothing that runs. After merge, open Renovate digest PRs rebase into
   readable version updates.

Note: with patch-precision comments, action minor/patch bumps follow the
repo's normal `packageRules` grouping (e.g. a "non-major dependencies" group
PR) instead of arriving as standalone digest PRs.
