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
| `zizmor` | own; user-invoked only (`/zizmor`); audit GitHub Actions, fix findings, open a PR |
| `skill-me` | own; user-invoked only (`/skill-me`); how to add or update a skill in this package: SKILL.md, symlink, README row, restow |
| `fetchmd` | own; last-resort verbatim URL fetcher, wraps the `fetchmd` uv script in its folder; try WebFetch first |
| `unslop` | [cursor/plugins](https://github.com/cursor/plugins/blob/main/pstack/skills/unslop/SKILL.md) (MIT, see `LICENSE` beside it; vendored unmodified) |
| `technical-writing` | [cursor/plugins](https://github.com/cursor/plugins/blob/main/pstack/skills/technical-writing/SKILL.md) (MIT, see `LICENSE` beside it; vendored unmodified; user-invoked only) |
| `workmux` | [raine/workmux](https://github.com/raine/workmux/blob/main/skills/workmux/SKILL.md) (MIT, see `LICENSE` beside it; vendored unmodified from v0.1.263; user-invoked only) |
| `babysit` | own; user-invoked only (`/babysit <pr>`); watches a PR's checks, comments and review threads until clean, fixes and pushes, replies before resolving. |

Skills marked `own` are dedicated to the public domain under CC0 1.0; each
folder has the `LICENSE`. Vendored skills keep their upstream licence beside
them.

`~/.agents/skills/` is also where the `npx skills` CLI installs third-party
skills, tracked in `~/.agents/.skill-lock.json`. Those coexist with the stowed
ones; only the skills in this package are managed by git.
