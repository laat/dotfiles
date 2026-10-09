---
name: safehouse
description: Context for agent-safehouse, the macOS sandbox-exec wrapper that coding agents on this machine run under by default. Covers what it hides, what this machine grants on top, and how to trace a denial and add a grant. Use when the user mentions safehouse, sandbox-exec, Seatbelt, the claude-safe/codex-safe/opencode-safe wrappers or the claude-unsafe/ccu aliases, asks to give the sandbox access to a path, socket or tool, or when a command fails with "Operation not permitted" on a path that exists, "command not found" for a tool the host has, or exit 255 from git over ssh. Those are how sandbox denials look from inside.
---

# safehouse

[agent-safehouse](https://agent-safehouse.dev/) wraps a command in a
deny-by-default macOS `sandbox-exec` policy. The workdir (git root of the
current directory) is read-write, installed toolchains and the agent's own
config are readable, the keychain works, and `~/.ssh`, `~/.aws` and the rest
of `$HOME` are not visible. Outbound network is not restricted.

**You are probably running inside it right now.** `claude`, `cc`, `codex`,
`co`, `opencode` and `oc` are aliased to the sandboxed wrappers, and workmux
worktrees started with `wms` use the `cc-safe` agent. A file or socket that
exists but returns `Operation not permitted` is a sandbox denial, not a
permissions bug in the project. The bare, unsandboxed binaries are
`claude-unsafe`, `codex-unsafe` and `opencode-unsafe`, or `ccu`, `cou` and
`ocu`.

The policy is fixed when the agent starts. A grant added during a session
applies to the next sandboxed launch, not the current one. Policy files
loaded with `--append-profile` are write-denied as the last rule, so changes
to the safehouse package go through `claude-unsafe`.

## Where things are on this machine

Everything is stowed from `~/.dotfiles/safehouse/` (`readme.md` there).

| Path | What |
|---|---|
| `/opt/homebrew/bin/safehouse` | the tool, `brew install eugene1g/safehouse/agent-safehouse` |
| `~/.local/bin/safehouse-agent` | wrapper adding this machine's grants, each explained in its header comment |
| `~/.local/bin/{claude,codex,opencode}-safe` | symlinks to it, agent picked from the name |
| `~/.config/safehouse/agents.sb` | appended rules: tmux socket, shell startup chain, `*.local-secrets` and `.env` denies |
| `~/.config/safehouse/agent.d/*.sh` | drop-ins from other stow packages; they append to the wrapper's `ro`, `rw` (colon-separated) and `env_pass` (comma-separated) |
| `~/.config/safehouse/npmrc` | read-only npm token, made on the host by `~/.dotfiles/safehouse/setup/npm-readonly-token` |
| `~/.profile.local-secrets` | host-only tokens, denied inside. New tokens go here, not in `~/.profile.local` |
| `~/.shrc.d/99_safehouse.sh` | the aliases, loaded last so they override `00_claude.sh` etc. |
| `~/.config/laatmux/config.yaml` | `agents.cc-safe`, laatmux's sandboxed claude (personal, not in the repo) |
| `<repo>/.safehouse` | optional per-repo config, loaded only when the repo is trusted |
| `~/.config/safehouse/trusted-workdirs` | trusted repos, one path per line |

## What the wrapper grants

On top of safehouse's defaults. Read the wrapper's header comment before
removing or loosening one.

| Grant | Symptom without it |
|---|---|
| `~/.dotfiles` and `~/.dotfiles-*` read-only | git and stowed config fail; sandbox-exec checks the symlink target |
| `~/code` and `~/git` read-write | sibling repos are invisible |
| `~/.local/bin` read-only | hooks print "workmux: command not found" |
| workmux state and cache dirs, tmux socket, `TMUX`/`TMUX_PANE` | workmux status hooks fail silently |
| `~/.cache/claude-statusline` read-write | the status line can't cache; safehouse only lets the sandbox list `~/.cache` |
| `shell-init` feature plus the startup chain in `agents.sb` | "~/.bashrc: Operation not permitted" at start, host aliases missing |
| `.env` files git tracks in the workdir's repo | committed `.env` files are unreadable |
| `1password` feature | commits fail with "1Password: Could not connect to socket" |
| `GIT_SSH_COMMAND`: 1Password agent, a copy of `known_hosts`, `ControlMaster=no` | git over ssh has no key and exits 255 |
| `clipboard` feature | `pbcopy` and `pbpaste` fail |
| mise shims appended to `PATH` | mise-only tools such as `terraform` are not found |
| `npm_config_userconfig` pointing at the read-only token | npm and pnpm can't reach private scopes |
| `agent.d/*.sh` drop-ins | work-specific grants from a private `~/.dotfiles-*` repo are missing |
| `~/.codex` read-write | codex started from another agent's sandbox can't load its config or login |
| inside the sandbox the wrapper starts the agent directly, codex with its own sandbox off | `codex` from inside fails with "sandbox_apply: Operation not permitted" |

## Denied on purpose

Don't grant these unless the user asks to change the policy:

- `~/.ssh`. The host's ControlMaster is a pre-authenticated session and is
  never shared, so every sandboxed push pays the handshake. Host aliases from
  `~/.ssh/config` don't resolve; remotes need real hostnames.
- `~/.profile.local-secrets` and gitignored `.env` files. A repo's
  `.safehouse` can't lift the `.env` deny, because safehouse applies it before
  the `--append-profile` files.
- `~/.npmrc` when the read-only token exists. `npm publish` and `npm login`
  are host-only.
- Cloud credentials (`~/.config/gcloud`, `~/.azure`, `~/.kube`).
  `--enable=cloud-credentials` exposes the full personal ones;
  `~/.dotfiles/safehouse/roadmap.md` has the read-only plan.
- Exec of setuid binaries such as `/bin/ps` (`forbidden-exec-sugid`), which
  is why `codex` runs with `--no-daemon`.

## Docs

- `safehouse --help` covers every flag; `--explain` prints the effective
  workdir, grants and selected profiles to stderr; `--stdout -- <cmd>` prints
  the full generated policy, each rule commented with why it exists.
- https://agent-safehouse.dev/docs/: `default-assumptions.html` (what is
  allowed, opt-in, denied), `options.html`, `customization.html`,
  `debugging.html`, `policy-architecture.html`, and per-agent notes under
  `agent-investigations/` (`claude-code.html`, `codex.html`, `opencode.html`).
- https://agent-safehouse.dev/policy-builder.html and
  https://agent-safehouse.dev/llm-instructions.txt for writing custom rules.
- Source: https://github.com/eugene1g/agent-safehouse

## Debugging a denial

1. Stream denials while the failing command is reproduced:

   ```sh
   /usr/bin/log stream --style compact --predicate 'eventMessage CONTAINS "Sandbox:" AND eventMessage CONTAINS "deny("'
   ```

   Lines read `deny(<pid>) <operation> <path-or-name>`. `log stream` needs an
   admin account; if it prints "Must be admin", ask the user to run it.
2. If the path is under "Denied on purpose", stop and tell the user.
3. Grant the minimum, in the narrowest place:
   - One-off: `safehouse --add-dirs-ro=<path>`, `--add-dirs=<path>` for
     read-write, `--enable=<feature>` for docker, keychain, xcode and similar
     (`safehouse --help` lists them).
   - This machine: a directory in the wrapper's `ro` or `rw`, a drop-in in
     `~/.config/safehouse/agent.d/` if it is work-specific, or a rule in
     `agents.sb` such as `(allow file-read* (subpath "/path"))` or
     `(allow mach-lookup (global-name "<name>"))`. Later rules win.
   - One repo: a `.safehouse` in the repo root with `add-dirs-ro=`,
     `add-dirs=`, `enable=` or `append-profile=` lines. The wrapper doesn't
     forward safehouse flags, so trust it with
     `SAFEHOUSE_TRUST_WORKDIR_CONFIG=1` or an entry in `trusted-workdirs`.
4. Restart the sandboxed agent and rerun the failing command. If it still
   fails, go back to step 1.

Do not work around a denial by running the agent unsandboxed unless the user
asks; the denial is the point.
