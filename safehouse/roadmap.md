# Roadmap

Hardening that goes beyond hiding paths. Today the sandbox hides secrets it
knows about; these items replace the credentials it can see with read-only
ones, so a misbehaving agent can look but not publish, deploy or delete.

## 1. Read-only npm token

**Now:** safehouse's Node profile grants `~/.npmrc`, and that file holds the
short-lived publish-capable token for `registry.npmjs.org` and a token for
`npm.pkg.github.com`. `npm whoami` works inside the sandbox, so `npm publish`
would too.

**Target:** the sandbox only ever sees read-only tokens.

- Create an npm granular access token with read-only permission, scoped to
  the packages and orgs the agent installs from, and a GitHub token with
  `read:packages` only.
- Put them in `~/.config/safehouse/npmrc` (mode 600, not in the repo).
- In `safehouse-agent`, source an env file with `--env=FILE` that sets
  `NPM_CONFIG_USERCONFIG=$HOME/.config/safehouse/npmrc`. npm and pnpm both
  honour it.
- Deny the real file in `agents.sb`:
  `(deny file-read* (home-literal "/.npmrc"))`.
- Keep `npm login` a host-only step; the sandboxed agent never needs it.

## 2. Read-only cloud identity

**Now:** `~/.config/gcloud`, `~/.azure` and `~/.kube` are denied unless
safehouse runs with `--enable=cloud-credentials`, which exposes the full
personal credentials. So the agent has no cloud access at all, and the only
way to give it some is to give it everything.

**Target:** the agent can read logs, describe resources and `kubectl get`,
with an identity that cannot write.

Prefer short-lived tokens minted on the host at launch over key files:

- **GCP:** a service account with `roles/viewer` (or narrower: logging,
  monitoring, container viewer). The wrapper runs
  `gcloud auth print-access-token --impersonate-service-account=<sa>` on the
  host and passes `CLOUDSDK_AUTH_ACCESS_TOKEN` plus
  `CLOUDSDK_CONFIG=$HOME/.config/safehouse/gcloud` into the sandbox. The
  personal `~/.config/gcloud` stays denied.
- **Kubernetes:** a `ServiceAccount` bound to the `view` ClusterRole, or a
  per-namespace `RoleBinding`. The wrapper runs
  `kubectl create token <sa> --duration=1h` on the host and writes a
  kubeconfig to `~/.config/safehouse/kubeconfig`, passed as `KUBECONFIG`.
- **Azure:** a service principal with the `Reader` role, logged in to a
  separate `AZURE_CONFIG_DIR=$HOME/.config/safehouse/azure`. `az` cannot
  impersonate, so this one is a stored secret; rotate it.

The extra config dirs go in with `--add-dirs` (the CLIs write token caches
there), and the env file is sourced with `--env=FILE`. Commit a template of
the env file, never the values.

## Known gaps, not planned

- No network allowlist. safehouse allows all outbound; workmux's container
  sandbox (`wm-add -S`) is the answer when that matters.
- The agent can write git hooks in the shared `.git`, which run on the host
  later. Same answer.
