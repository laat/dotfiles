---
name: safehouse
description: Context for agent-safehouse, the macOS sandbox-exec wrapper that coding agents on this machine run under by default. Use when the user mentions safehouse, sandbox-exec, Seatbelt, the claude-safe/codex-safe/opencode-safe wrappers, the <agent>-unsafe aliases, or when a command fails with "Operation not permitted" on a path that should exist, which is how sandbox denials look from inside.
---

# safehouse

[agent-safehouse](https://agent-safehouse.dev/) wraps a command in a
deny-by-default macOS `sandbox-exec` policy. The workdir (git root of the
current directory) is read-write, installed toolchains and the agent's own
config are readable, the keychain works, and `~/.ssh` keys, `~/.aws`, the
rest of `$HOME` and other repos are not visible. Outbound network is not
restricted.

**You are probably running inside it right now.** `claude`, `cc`, `codex`,
`co`, `opencode` and `oc` are aliased to the sandboxed wrappers, and workmux
worktrees started with `wms` use the `cc-safe` agent. A file or socket that
exists but returns `Operation not permitted` is a sandbox denial, not a
permissions bug in the project. The bare, unsandboxed binaries are
`claude-unsafe`, `codex-unsafe` and `opencode-unsafe`, or the short forms
`ccu`, `cou` and `ocu`.

## Where things are on this machine

Everything is stowed from `~/.dotfiles/safehouse/` (package readme there).

| Path | What |
|---|---|
| `/opt/homebrew/bin/safehouse` | the tool, `brew install eugene1g/safehouse/agent-safehouse` |
| `~/.local/bin/safehouse-agent` | wrapper adding this machine's grants (see below) |
| `~/.local/bin/{claude,codex,opencode}-safe` | symlinks to it, agent picked from the name |
| `~/.config/safehouse/agents.sb` | appended policy: tmux socket allow, `.env` deny |
| `~/.config/safehouse/npmrc` | read-only npm token; when present npm and pnpm use it and `~/.npmrc` is hidden (`npm.sb`). Made by `~/.dotfiles/safehouse/setup/npm-readonly-token`, host only |
| `~/.shrc.d/99_safehouse.sh` | the aliases, loaded last so they override `00_claude.sh` etc. |
| `~/.config/workmux/config.yaml` | `agents.cc-safe`, workmux's sandboxed claude |
| `<repo>/.safehouse` | optional per-repo policy, only loaded with `--trust-workdir-config` |
| `~/.config/safehouse/trusted-workdirs` | repos trusted with `--always-trust-workdir-config` |

The wrapper adds, on top of safehouse's defaults:

- `~/.dotfiles` read-only, because `~/.gitconfig` and most of `~/.config` are
  stow symlinks into it and sandbox-exec checks the resolved path.
- `~/code` and `~/git` read-write, so a session can change and open PRs in
  several repos. The rest of `$HOME` stays hidden.
- `~/.local/bin` read-only. safehouse only lets the sandbox list it and grants
  single binaries per agent, so without this `command -v workmux` fails and
  every hook in `~/.claude/settings.json` reports "workmux: command not found".
- `~/.local/state/workmux` and `~/.cache/workmux` read-write, the tmux socket,
  and `TMUX`/`TMUX_PANE` passed through, so those workmux status hooks work
  from inside.
- `~/.cache/claude-statusline` read-write, where `~/.claude/statusline.sh`
  caches the Fable usage window. safehouse allows only listing `~/.cache`, so
  a tool that needs its own cache dir there needs a grant like this.
- `npm_config_userconfig` pointing at the read-only token file, when it
  exists. `npm publish` fails by design; `npm login` is a host-only step.
- safehouse's `1password` feature: the 1Password agent socket, the app bundle
  and `~/.config/1Password`, so `op-ssh-sign` from `~/.gitconfig` can sign
  commits. Without it every commit fails with "1Password: Could not connect
  to socket". `~/.ssh` stays hidden.

Policy files loaded with `--append-profile` are write-denied as the last rule,
so `agents.sb` cannot be edited from a sandboxed session. Use `claude-unsafe`
for changes to the safehouse package.

## Docs

- `safehouse --help` covers every flag; `--explain` prints the effective
  workdir, grants and selected profiles to stderr; `--stdout -- <cmd>` prints
  the full generated policy, each rule commented with why it exists.
- https://agent-safehouse.dev/docs/ with `default-assumptions.html` (what is
  allowed, opt-in, denied), `options.html`, `customization.html`,
  `debugging.html`, `policy-architecture.html`, and per-agent notes under
  `agent-investigations/` (`claude-code.html`, `codex.html`, `opencode.html`).
- https://agent-safehouse.dev/policy-builder.html and
  https://agent-safehouse.dev/llm-instructions.txt for writing custom rules.
- Source: https://github.com/eugene1g/agent-safehouse

## Debugging a denial

Stream denials while reproducing the failing command:

```sh
/usr/bin/log stream --style compact --predicate 'eventMessage CONTAINS "Sandbox:" AND eventMessage CONTAINS "deny("'
```

Lines read `deny(<pid>) <operation> <path-or-name>`. Then grant the minimum:

- One-off: `safehouse --add-dirs-ro=<path>` or `--add-dirs=<path>` for
  read-write, `--enable=<feature>` for docker, keychain, clipboard, xcode and
  similar (`safehouse --help` lists them).
- For this machine: a rule in `~/.config/safehouse/agents.sb`, for example
  `(allow file-read* (subpath "/path"))` or
  `(allow mach-lookup (global-name "<name>"))`. Later rules win.
- For one repo: a `.safehouse` file in the repo root, run with
  `--trust-workdir-config`.

Do not work around a denial by running the agent unsandboxed unless the user
asks; the denial is the point.
