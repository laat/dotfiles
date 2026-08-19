---
name: renovate-cleanup
description: Bring a repo's Renovate setup to the house standard — pinned GitHub Actions digests (via the renovate-pin-actions skill), minimumReleaseAge matching pnpm (else 1 day), rangeStrategy pin, and weekly lock file maintenance before 5am on Friday.
disable-model-invocation: true
---

# Renovate cleanup

Apply the standard Renovate config to the current repo. Four changes, in order, delivered as one PR.

## 1. Pin GitHub Actions

Follow the `renovate-pin-actions` procedure first. In Claude Code its SKILL.md
is attached to this message via the reference below. In other agents the line
stays literal text, so read `../renovate-pin-actions/SKILL.md` (next to this
file) yourself and follow it. Don't call it through the Skill tool; it is
marked user-invoked only and the call is rejected.

@${CLAUDE_SKILL_DIR}/../renovate-pin-actions/SKILL.md

Its last step says to PR the pinning on its own. Ignore that here: the whole
cleanup goes in one branch and one PR. Put the workflow pinning in its own
commit so the comment-only diff is easy to review, then the config changes
below in a second commit.

## 2. Config changes

Find the Renovate config: `renovate.json`, `renovate.json5`, `.renovaterc`,
`.renovaterc.json`, `.github/renovate.json*`, `.gitlab/renovate.json*`, or the
`renovate` key in `package.json`. If none exists, create `renovate.json` with
`"$schema": "https://docs.renovatebot.com/renovate-schema.json"` and
`"extends": ["config:recommended"]`, then add the keys below.

Set these top-level keys. Overwrite if they exist with other values, say so in
the summary.

```json
{
  "minimumReleaseAge": "1 day",
  "rangeStrategy": "pin",
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 5am on friday"]
  }
}
```

Rules:

- `minimumReleaseAge`: match pnpm if the repo uses it. Look for
  `minimumReleaseAge` in `pnpm-workspace.yaml` or `minimum-release-age` in
  `.npmrc` (both in minutes) and convert: 1440 → `"1 day"`, 4320 → `"3 days"`,
  10080 → `"7 days"`, otherwise `"<n> minutes"` or `"<n> hours"` when it
  divides evenly. If pnpm is in use but the setting isn't written down, take
  pnpm's own default: pnpm 11 defaults to 1440, so `"1 day"`; pnpm 10 and
  older have no cooldown, so use `"1 day"` anyway. No pnpm, or unsure: `"1 day"`.
  Say in the summary where the value came from.
- `lockFileMaintenance`: merge into an existing object, only set `enabled` and
  `schedule`; keep other subkeys the owner already has.
- Use Renovate's natural-language schedule syntax, not cron. If the repo
  already has a `lockFileMaintenance.schedule` that means Friday early
  morning in natural language (`"before 5am on friday"`, `"before 6am on
  friday"`, `"every friday before 5am"`), keep it as is. Only rewrite a
  schedule that is on another day or in cron form.
- Times are in the repo's `timezone`; Renovate defaults to UTC. Don't add a
  `timezone` key on your own, but if there isn't one, mention in the summary
  that 5am is UTC.
- Keep the file's existing style (json vs json5, key order, indentation,
  trailing commas). Don't reformat unrelated lines.
- `rangeStrategy: "pin"` applies to every manager. If the repo publishes a
  package (`package.json` without `"private": true`, or a `pyproject.toml`
  with a build backend), point out that its own `dependencies` ranges will be
  pinned too and let the owner decide.
- If any `package.json` in the repo declares `peerDependencies`, add a
  package rule so those keep a range instead of being pinned to one version:

  ```json
  {
    "matchDepTypes": ["peerDependencies"],
    "rangeStrategy": "widen"
  }
  ```

  Append it to the existing `packageRules` array (create the array if there
  is none). Skip if an equivalent rule is already there.

### No release age for @nrk/ packages

If any `package.json` depends on an `@nrk/`-scoped package, exempt the scope
from the cooldown in both places.

Renovate, append to `packageRules` (skip if an equivalent rule exists):

```json
{
  "description": "Internal packages skip the release age cooldown",
  "matchPackageNames": ["@nrk/*"],
  "minimumReleaseAge": null
}
```

pnpm, if in use, in `pnpm-workspace.yaml` (add the key if missing, append to
the list if present, skip if `@nrk/*` is already there):

```yaml
minimumReleaseAgeExclude:
  - '@nrk/*'
```

If pnpm's `minimumReleaseAge` is only configured in `.npmrc`, put the exclude
in `pnpm-workspace.yaml` anyway; that is where pnpm documents it.

### Fastify major group

If the repo uses fastify (any `package.json` lists `fastify`, `fastify-plugin`,
or a `@fastify/*` package), add this rule to `packageRules` so fastify majors
arrive as one PR and core and plugins move together:

```json
{
  "groupName": "fastify dependencies",
  "groupSlug": "fastify-major",
  "matchUpdateTypes": ["major"],
  "matchPackageNames": ["/fastify/", "/fastify-plugin/", "/@fastify/*/"]
}
```

Skip if a rule with `groupSlug: "fastify-major"` or an equivalent fastify major
group already exists.

### Fold pnpm, eslint and turbo into the non-major group

Look in `packageRules` for an "all non-major dependencies" group (match on
`groupName`, case-insensitive, also "non-major" or "all minor and patch"
variants) and for separate groups that exist only to gather pnpm, eslint, or
turbo packages (`groupName` like `eslint`, `turbo`, `pnpm`, or rules whose
`matchPackageNames` / `matchPackagePatterns` / `matchSourceUrls` only target
those).

If both exist:

1. Delete the pnpm/eslint/turbo rules.
2. Make the non-major group match those packages too. Usually that's just
   removing the exclusion that kept them out: entries like `"!/eslint/"`,
   `"!/^turbo/"`, `"!pnpm"` in `matchPackageNames`, or the deprecated
   `excludePackageNames` / `excludePackagePatterns` keys. If the group uses an
   explicit allow-list instead, add patterns that cover them.
3. Leave other dedicated groups alone (e.g. a `react` or `vitest` group). Only
   pnpm, eslint and turbo are folded in.

If there is no non-major group, don't create one; leave the dedicated groups
and note it in the summary.

## 3. Verify

```sh
npx --yes --package renovate@latest -- renovate-config-validator
```

Must exit 0. Fix whatever it reports before committing. Keep the `@latest`:
a bare `renovate` spec makes npx reuse whichever version it cached first, and
an old validator rejects current keys like `managerFilePatterns`.

## 4. One PR

Open a single PR for everything above. In the description, say that the
workflow changes are comment-only and change nothing that runs.

## 5. Summary

Report:

- which config file was changed, and which keys were added vs overwritten
  (old → new), including where the `minimumReleaseAge` value came from
- whether each optional rule was added: peerDependencies widen, @nrk/
  exemption (Renovate and pnpm), fastify major group
- which package groups were folded into the non-major group
- whether `timezone` is set
- the pin-actions result: refs fixed, anything flagged
