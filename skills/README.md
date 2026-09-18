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
| `renovate-cleanup` | own; user-invoked only (`/renovate-cleanup`); pins GitHub Actions digests, then sets minimumReleaseAge, rangeStrategy pin, Friday lockFileMaintenance |
| `zizmor` | own; user-invoked only (`/zizmor`); audit GitHub Actions, fix findings, open a PR |
| `plattform` | own; user-invoked only (`/plattform [name...]`); loads private platform knowledge from `~/plattform/skills`, an index plus the SKILL.md files that apply; kept out of context otherwise |
| `skill-me` | own; user-invoked only (`/skill-me`); how to add or update a skill in this package: SKILL.md, symlink, README row, restow |
| `typescript7` | own; user-invoked only (`/typescript7`); TS 6 → 7 migration: alias `typescript` to @typescript/typescript6, install TS 7 as @typescript/native, fix tsc-watch |
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
