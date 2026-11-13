# skills

Agent skills shared across Claude Code, Codex and OpenCode.

The canonical copy lives in `.agents/skills/<name>/SKILL.md`, which Codex and
OpenCode read from `~/.agents/skills/`. Claude Code only reads
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
| `fetchmd` | own; last-resort verbatim URL fetcher, wraps the `fetchmd` uv script in its folder; try WebFetch first |
| `babysit` | own; triggers on "babysit" and similar or `/babysit <pr>`; watches a PR's checks, comments and review threads until clean, fixes and pushes, replies before resolving. Ships `prctl` (status, wait, reply), a stdlib Python script on `gh`. |
| `sol-loop` | own; model-invoked on an explicit "sol loop" or "codex review loop", or `/sol-loop`; GPT Sol reviews the change as a T3 delegated task (codex CLI outside T3), fix what holds, re-review until approved or 3 rounds; pushes only if asked, never posts. |
| `full-stop` | own; model-invoked on an explicit "full stop"; galley stage, reviewer agents, publish, babysit until ready to merge; never merges |
| `full-send` | own; model-invoked on an explicit "full send"; same as `full-stop`, then merges once the merge gate holds |
| `leo` | own; model-invoked on an explicit "leo", "leonardo" or "dicaprio", or `/leo`; judges whether the PR still makes sense (`REBASE`, `REWRITE` or `CLOSE`) before rebasing; pushes only with a lease, never merges or closes |
| `ai-moot` | own; model-invoked on an explicit "ai moot", or `/ai-moot`; Claude Opus and GPT Sol (or members the user names) review in parallel at high effort, fix what holds, re-review until all are satisfied; scores per round go in the PR description |

Skills marked `own` are dedicated to the public domain under CC0 1.0; each
folder has the `LICENSE`. Vendored skills keep their upstream licence beside
them.

`~/.agents/skills/` is also where the `npx skills` CLI installs third-party
skills, tracked in `~/.agents/.skill-lock.json`. Those coexist with the stowed
ones; only the skills in this package are managed by git.
