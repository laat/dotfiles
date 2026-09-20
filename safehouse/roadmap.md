# Roadmap

Hardening that goes beyond hiding paths. Today the sandbox hides secrets it
knows about; these items replace the credentials it can see with read-only
ones, so a misbehaving agent can look but not publish, deploy or delete.

## 1. Read-only npm token (done)

`setup/npm-readonly-token` creates a read-only granular token in
`~/.config/safehouse/npmrc`; `safehouse-agent` passes it as
`npm_config_userconfig` and `npm.sb` hides `~/.npmrc`. Left: GitHub Packages
is a pasted classic PAT, since fine-grained PATs cannot be created from the
CLI, and there is no reminder before the token expires.

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
