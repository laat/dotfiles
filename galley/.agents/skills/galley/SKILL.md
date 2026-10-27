---
name: galley
description: Stage a pull request in galley, the user's local review server, instead of opening it on GitHub. Use when the user says "stage PR" or "stage a PR". The CLI mirrors `gh pr` and `gh api`; the user reviews in a GitHub-like web UI, you address the feedback, and the user publishes to GitHub, or you do when the user asks.
---

# Stage a PR

`galley` takes `gh`'s subcommands and flags: `galley pr` for `gh pr`, `galley api` for `gh api`.

## Rules

- Do not `git push` or run `gh pr create`. galley publishes, for the user or, when the user asks,
  for you ([Publishing](#publishing)). After that, commit and run `galley pr wait`: it pushes
  your commits, and publishes your edits of the title and description. Never push to GitHub or
  edit the pull request there yourself.
- Do not run `galley pr publish`, `pr close` or `pr review` unless the user asks.
- When `galley` cannot reach the server, as from a sandbox that keeps it out, tell the user what
  it printed and wait for them. Do not work around it: do not start a server yourself, run
  `galley` outside the sandbox, or open the pull request on GitHub.
- Commit on a branch, with at least one commit over the base.
- Signing your commits is optional: commit as git is set up. If `git commit` asks for a
  passphrase, waits for a prompt or fails on signing, commit with
  `git -c commit.gpgsign=false commit …`. galley pushes commits you signed as they are, and signs
  the rest as the user when they publish.
- Write a staged pull request as `s#4` ("s" for staged), to the user and in galley's comments,
  where it links to it. `#4` is GitHub's issue or pull request 4. In commands, `s4` (`galley pr
  wait s4`).
- Never write a staged pull request's number where GitHub shows it: commit messages, the title
  and description, issues and GitHub comments. Refer to a published pull request by its GitHub
  number, an unpublished one by what it does or its branch.
- You may rewrite history (amend, fixup, rebase, reword).
- Resolve the threads you addressed, with `--resolve` on your reply. Leave a thread open when you
  disagree, only partly addressed it, or need the user's answer.

## The loop

1. Stage the branch you are on. If the user said how to review it, add the flag from
   [Reviewer agents](#reviewer-agents).

   In T3 Code (the `t3-code` MCP tools are present), link both ways:

   - From galley to your thread: add `--link t3code://threads/<environmentId>/<threadId>` to
     `galley pr create`, with `environmentId` from `t3_environment_read` and `threadId` the
     `currentThreadId` of `t3_thread_list`. galley never publishes it; `galley pr edit --link`
     changes it.
   - From your thread to galley: as soon as `galley pr create` prints the URL, before anything
     else, call `link_pull_request` with `repository`, `number` and `host` from it
     (`https://<host>/<repository>/pull/<number>`; a port stays in `host`). Do not pass `url`;
     T3 rejects galley's. T3 shows the link, but not the pull request's state. Skip it when the
     URL is not `https`: T3 makes the link `https://` whatever you pass.

   ```sh
   galley pr create --title "Add retry to the uploader" --body-file - <<'EOF'
   Why the change is needed, and what it does.
   EOF
   ```

   Tell the user the URL `galley pr create` printed, that you staged it, and that the reviewer
   agents review it first; do not ask for the user's review yet. Say so if the CLI started the
   server. If the user asked you to publish or merge it, turn on auto-publish now
   ([Publishing](#publishing)).

2. Run `galley pr wait`. It can block for hours. Tell the user you are waiting, and run it the
   way your agent allows:

   - Claude Code, main session: in the background, so you are woken when it returns. Choose the
     tool by who has the next move, because T3 Code shows the thread by it:
     - While the reviewer agents review (steps 2 to 5, and with auto-publish until it is
       published): the Monitor tool, with `galley pr wait --timeout 29m 2>&1` and
       `timeout_ms: 1800000`. T3 Code keeps a thread with a running monitor in Working. A
       background Bash command does not count: T3 Code moves the thread to Active, and it looks
       done. A monitor stops after 30 minutes; on exit code 124, start it again, without a
       message.
     - While you wait for the user (step 6 on): Bash with `run_in_background`, so T3 Code moves
       the thread to Active, where the user sees your request.

     Stop a running monitor with `TaskStop` before you hand the work to the user or ask them
     something; otherwise the thread stays in Working.
   - Claude Code, subagent (a session another agent started): in the foreground with
     `--timeout 270` and a Bash timeout above it, such as 600000, because a background command
     that finishes does not wake an idle subagent. On exit code 124, run it again.
   - Codex: when the tool call returns a session ID, poll it (`write_stdin` with no input,
     `yield_time_ms` up to 300000) until it exits.
   - A shell tool with a time limit (opencode's is 2 minutes unless you pass a larger
     `timeout`): add a `--timeout` under it and under 5 minutes, such as `--timeout 270` with a
     5-minute tool timeout. Most model providers' prompt caches expire after about 5 minutes
     without a call, and a longer wait makes the next call re-send the whole conversation
     uncached. On exit code 124, run it again; nothing is lost.

3. Read what it printed:

   ```
   thread 12 on src/upload.ts:40-42 [unresolved] http://localhost:24823/acme/app/pull/4#discussion_r12
       +  for (let i = 0; i < 3; i++) {
       laat:
         Use the backoff helper here.
   ```

   - `thread <id> on <path>:<lines>`: about those lines; with `(old side)`, about those lines as
     they were before the change. `[unresolved, outdated]`: the code changed since; check whether
     it still applies.
   - The URL at the end opens the thread in the web UI. Give it to the user when you mention or ask
     about a thread.
   - `thread <id> on file <path>`: about the whole file.
   - `thread <id> on the message of commit <sha> "<headline>"`: about that commit's message.
     Reword the commit. `(no longer in the branch)` in place of the headline: a rewrite replaced
     the commit; check whether its new message still has the problem.
   - `(high priority)`, `(medium priority)` or `(low priority)` after the brackets: how much it
     matters, as its author judged it.
   - A ```` ```suggestion ```` block replaces the commented lines. Apply it unless it is wrong.
   - Comments without a thread: about the whole pull request, often the title or description.
   - `This branch conflicts with galley/main …; rebase onto galley/main`: rebase onto it (the
     wait fetched it from galley), resolve the conflicts, run the tests, and wait again. Only
     behind (`mergeStateStatus` `BEHIND`): leave it unless the user asks for a rebase.
   - `Image: <url>`: add `--download-images <dir>` to `pr wait` or `pr view --comments`, and
     read the files it prints.

   `galley pr view --comments` shows the whole conversation (`--json
   reviewThreads,reviews,comments` for JSON).

4. Address every thread, with a change or a reply:

   - Amend or fix up the commit the feedback is about.
   - Edit the title or description with `galley pr edit --title "..." --body-file -`.
   - Reply to every thread with what you did or why not:

     ```sh
     galley pr comment --reply-to 12 --resolve -b "Switched to backoff() in 3f2a1c9."
     galley pr comment --reply-to 15 -b "Out of scope: the parser did this before. Follow-up issue?"
     ```

   - Ask the user in a reply, or with `galley pr comment -b "..."`.

   Keep to what the title and description say. A finding outside the change (a bug that was
   there before, an improvement next to it, a case far from it): reply that it is out of scope,
   propose a follow-up, and leave the thread open. Add no features, refactors or cleanups nobody
   asked for; mention them instead. If each round finds new cases in the same area, propose a
   structural fix to the user before you rewrite.

5. Wait again, and repeat steps 2 to 4 until `pr wait` says the reviewer agents are done with
   your latest commit:

   ```
   The reviewer agents are done with 3f2a1c9 (codex-review found nothing in 3f2a1c9); ask the user to review it: <url>
   ```

   or `No reviewer agent reviews 3f2a1c9; ask the user to review it`.

6. Ask the user to review: the URL, and in a few lines what the reviewer agents found and what
   you changed. Wait again.

7. Loop with the user the same way until `pr wait` prints `Published to GitHub: <url>` or says
   it was closed. After a new commit, ask the user again only once `pr wait` says the reviewer
   agents are done with it. If auto-publish is on, address the feedback and wait; galley
   publishes. With auto-merge, GitHub merges it, not you.

8. After `Published to GitHub: <url>`, tell the user the GitHub URL. In T3 Code, call
   `link_pull_request` with the GitHub URL, which T3 follows to the merge, and, if you linked the
   staged pull request in step 1, `unlink_pull_request` with its `repository`, `number` and
   `host`: T3 never learns that one's state, and it would sit with no status next to the GitHub
   link.

   Then wait again. From now on no reviewer agent reviews your commits, and each commit you wait
   with is pushed to GitHub. Your edits of the title and description (`galley pr edit`) are
   published at your next wait too, like commits, unless the user edited them since publishing:

   - `Merged on GitHub as e468a4e by laat: <url>`: clean up as in [After the merge](#after-the-merge).
   - `Closed on GitHub without merging`: you are done. Leave the branch and worktree unless the
     user says otherwise.
   - New feedback: address it as in step 4, commit, and wait again.
   - `This branch conflicts with galley/main …`: rebase as in step 3 and wait again. The wait
     force-pushes the rebase; do not push it yourself.
   - `Pushed 3f2a1c9 to GitHub: <url>` or `Published the description to GitHub: <url>`: wait
     again.
   - `Could not publish the description to GitHub: …`: nothing on GitHub was changed. Tell the
     user why, and wait again.
   - `Could not push 3f2a1c9 to GitHub: …`: nothing was pushed. Do not push or force-push it
     yourself; the user decides. When it says galley fetched the branch, rebase onto it as it
     says; do not merge it in. Tell the user why, and wait again.

## Publishing

When the user asks you to publish ("publish", "make a real PR", "merge"), turn on auto-publish
right after staging:

```sh
galley pr publish --auto                # publish once the reviewer agents are done
galley pr publish --auto --auto-merge   # and let GitHub merge it once its checks pass
```

Add `--auto-merge` when the user asks you to merge, with the method if they name one
(`--auto-merge rebase`); without a method, galley uses the user's setting. galley publishes once
the reviewer agents are done with your latest commit and you wait with their feedback addressed,
so go through the loop without asking the user to review: where `pr wait` would say the reviewer
agents are done, it prints `Published to GitHub: <url>`. Go on with step 8, and keep running
`galley pr wait` until it prints `Merged on GitHub` or says the pull request was closed.

Run `galley pr publish` without `--auto` only when the user asks you to publish now. It signs
the commits as the user, which may need them to answer a prompt; if signing fails, do what it
says.

After publishing, `pr wait` tells you of a merge or close, a conflict with the base, and
feedback in galley, but not of GitHub's checks and reviews. Those are for another skill, such as
`babysit`, when the user asked you to babysit the pull request. Commit its fixes and run
`galley pr wait`, which pushes them.

Without such a request, leave publishing to the user.

## After the merge

Unless the user wants to keep something:

1. `git fetch origin`, then `git merge --ff-only origin/<base>` where the base is checked out,
   or `git fetch origin <base>:<base>` when it is checked out nowhere.
2. If `pr wait` listed commits GitHub merged it without, keep the branch: those commits are
   only there. Tell the user, and move them onto the merge with the `git rebase --onto` it
   printed and stage them as a new pull request, or ask the user how when it printed none.
   Otherwise remove your worktree and delete the branch with `git branch -D` (`-d` refuses:
   GitHub merged copies of your commits).
3. Rebase your other pull requests that touch the merged files onto `origin/<base>` (compare
   `galley pr diff s4 --name-only`).

## Several pull requests

`galley pr wait s5 s6` returns when one has news and says which. Leave a merged or closed one out
of the next wait.

## Reviewer agents

Codex, Claude and reviewers the user defined review when you wait, until the pull request is
published, and their reviews wake you like the user's. Some review only the title, description
and commit messages, again whenever you change them. One round is one review from each and your
answer. A reviewer agent's approval is not the user's: wait for the user all the same. The
settings decide whether they review, and how many automatic reviews each makes, unless the user
says otherwise when asking you to stage. Add to `galley pr create`:

- "with codex": `--reviewer codex` (as many automatic reviews as the settings allow); "codex 3
  loops" or "3 rounds": `--reviewer codex:3`, at most 3 automatic reviews. The same for
  `claude`, or a reviewer the user defined by its name (`--reviewer house-rules:2`).
- "with codex and claude": `--reviewer codex --reviewer claude`.
- "no review": `--no-review`.
- "all of them", or a name you do not know: `galley reviewers` lists those that review this repository.

## Reference

- `galley browse <path>[:<line>[-<line>]] [--commit <sha>]` prints a link to those lines in the
  web UI. Give it to the user when you point at code.
- The CLI keeps a git remote called `galley`: `galley/<branch>` is what galley fetched from
  GitHub for you to rebase onto, and `git push` from a staged branch goes to galley, not GitHub.
  Leave the remote and the branch's `pushRemote` as they are.
- `galley api <endpoint>` takes GitHub REST paths with `-f`, `-F`, `-X`, `--input` and `--jq`.
  No GraphQL.
- Your comments are attributed to your agent: `claude` in Claude Code, `codex-agent` in Codex,
  `opencode` in opencode. `GALLEY_ACTOR` sets another name.
