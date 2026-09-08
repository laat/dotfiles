---
name: skill-me
description: Create or update an agent skill in the dotfiles skills package (~/.dotfiles/skills), so it is shared by Claude Code, Codex, OpenCode and pi. Covers the canonical file location, the Claude Code symlink, frontmatter, the README row, restowing and verifying. Use when asked to "make this a skill", "save this as /name", or to add or edit a skill in the dotfiles.
disable-model-invocation: true
---

# Skill me

Turn the current task, workflow or piece of knowledge into a skill in
`~/.dotfiles/skills`. Paths below are relative to the home directory.
In a prompt, `@~/.dotfiles/skills/` refers to this folder.

## Layout

```
~/.dotfiles/skills/
  README.md                          # table of skills, one row each
  .agents/skills/<name>/SKILL.md     # canonical copy (Codex, OpenCode, pi)
  .claude/skills/<name>              # relative symlink -> ../../.agents/skills/<name>
  .local/bin/<tool>                  # CLI a skill wraps, if any (stowed to ~/.local/bin)
```

Stow links these into `~/.agents/skills/<name>/SKILL.md`,
`~/.claude/skills/<name>` and `~/.local/bin/<tool>`. Claude Code reads only
`~/.claude/skills/`, the others read `~/.agents/skills/`, hence the symlink.

Third-party skills installed with `npx skills` also land in `~/.agents/skills/`
and are tracked in `~/.agents/.skill-lock.json`, not in git. Leave them alone.

## Steps

1. Pick a short kebab-case name. It becomes the slash command (`/<name>`).
   Check `ls ~/.dotfiles/skills/.agents/skills` for a collision.
2. Write `~/.dotfiles/skills/.agents/skills/<name>/SKILL.md`:

   ```markdown
   ---
   name: <name>
   description: <one paragraph: what it does, and when to use it, including the phrases or symptoms that should trigger it>
   disable-model-invocation: true
   ---

   # <Title>

   <body>
   ```

   - `description` is what the agent sees when deciding relevance, so put
     the trigger conditions there, not in the body.
   - `disable-model-invocation: true` makes it user-invoked only
     (`/<name>`). Use it for skills that take actions (edit repos, open
     PRs, run migrations). Omit it for skills that should apply on their own
     (`unslop`, `fetchmd`).
   - Body: enough context to do the task in a fresh session with no
     conversation history. Why the problem exists, the exact target state,
     numbered steps, verify commands, known dead ends and why, links to a
     worked example (a commit or PR URL) and upstream docs.
   - Write in the house style: no mannered prose, short sentences, commands
     in fenced blocks, exact package names and flags.
3. Add the Claude Code symlink, relative, from inside the package:

   ```sh
   cd ~/.dotfiles/skills
   ln -s ../../.agents/skills/<name> .claude/skills/<name>
   ```

4. Add a row to `~/.dotfiles/skills/README.md`, in the table:

   ```
   | `<name>` | own; user-invoked only (`/<name>`); <one-line summary> |
   ```

   For a vendored skill, name the source and licence instead of `own`, and
   say whether it is modified.
5. If the skill wraps a CLI, put the script in `.local/bin/` and mention it
   below the table, as `fetchmd` does.
6. Restow only the skills package and verify the links:

   ```sh
   dotfiles dry-run skills     # expect MKDIR/LINK lines for <name> only
   dotfiles apply skills
   ls -la ~/.claude/skills/<name> ~/.agents/skills/<name>
   head -3 ~/.claude/skills/<name>/SKILL.md
   ```

   `dotfiles` is `~/.dotfiles/stow/bin/dotfiles`, stowed to `~/bin`.
   `dotfiles apply` with no package restows everything; do not use that here.
7. Commit in `~/.dotfiles` only if asked. Convention:
   `feat(skills): add <name>` for new, `refine(skills): ...` for edits.
   A new session picks the skill up; the current one does not reload it.

## Updating an existing skill

Edit the canonical file under `.agents/skills/<name>/SKILL.md`. The symlinks
follow. No restow is needed unless files were added or removed. Update the
README row if the summary changed.
