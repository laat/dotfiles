---
name: plattform
description: Load internal platform knowledge from ~/plattform/skills, a private folder of SKILL.md files kept out of context until asked for. Use before deploying to, debugging, or exposing anything on the internal platform clusters, or when a platform doc claim needs verifying.
disable-model-invocation: true
---

# Plattform skills

Hard-won platform knowledge lives in `~/plattform/skills`, one folder per
topic, each with a `SKILL.md`. It is deliberately not registered as Claude
Code skills, so nothing from it is in context until this command runs.

If `~/plattform/skills` does not exist on this machine, say so and stop.

## Steps

1. Read `~/plattform/skills/README.md`. The table lists every skill with a
   one-liner.
2. If arguments were given (`$ARGUMENTS`), read
   `~/plattform/skills/<name>/SKILL.md` for each name, then stop.
3. Otherwise pick the skills that match the task and read those. Several
   usually apply together; the README says which. When a platform claim
   needs verification, start with the skill that maps claims to sources.
4. Each skill carries a verified date and verify commands. Platform
   behaviour changes without announcement; run the verify commands before
   relying on a claim.

## Related

House rules for commits and PRs in the platform repos are a separate,
always-on skill and are not part of this folder.
