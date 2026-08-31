# skills

Agent skills shared across Claude Code, Codex, OpenCode and pi.

The canonical copy lives in `.agents/skills/<name>/SKILL.md`, which Codex,
OpenCode and pi all read from `~/.agents/skills/`. Claude Code only reads
`~/.claude/skills/`, so each skill also gets a relative symlink there:

```sh
ln -s ../../.agents/skills/<name> skills/.claude/skills/<name>
```

Stow links the symlink itself, so both paths resolve to the same directory
and Claude Code loads the skill once.

## Skills

| Skill    | Source |
|----------|--------|
| `renovate-pin-actions` | own; user-invoked only (`/renovate-pin-actions`) |
| `renovate-cleanup` | own; runs `renovate-pin-actions`, then sets minimumReleaseAge, rangeStrategy pin, Friday lockFileMaintenance |
| `zizmor` | own; user-invoked only (`/zizmor`); audit GitHub Actions, fix findings, open a PR |
| `fetchmd` | own; last-resort verbatim URL fetcher, wraps `~/.local/bin/fetchmd`; try WebFetch first |
| `unslop` | [cursor/plugins](https://github.com/cursor/plugins/blob/main/pstack/skills/unslop/SKILL.md) (MIT; vendored unmodified) |
| `technical-writing` | [cursor/plugins](https://github.com/cursor/plugins/blob/main/pstack/skills/technical-writing/SKILL.md) (MIT; vendored unmodified; user-invoked only) |

`~/.agents/skills/` is also where the `npx skills` CLI installs third-party
skills, tracked in `~/.agents/.skill-lock.json`. Those coexist with the stowed
ones; only the skills in this package are managed by git.
