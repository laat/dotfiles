---
name: plattform
description: Load NRK platform knowledge from ~/plattform/skills (aks-plattform-* and rke-plattform-* clusters, plattform.azurecr.io, Icinga, vault-config, Akamai, Gorgon) for working without admin rights. Use before deploying to, debugging, or exposing anything on the platform clusters, or when a platform doc claim needs verifying.
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
   usually apply together: `ingress-tls-dns` with `cluster-reach`,
   `registry` with `golden-path-aftercare`. When a platform claim needs
   verification, read `source-map` first.
4. Each skill carries a verified date and verify commands. Platform
   behaviour changes without announcement; run the verify commands before
   relying on a claim.

## Related

`plattform-pr` (house rules for commits and PRs in nrkno/plattform-* and
nrkno/iac-* repos) is a separate, always-on skill and is not part of this
folder.
