---
name: typescript7
description: Migrate a repo from TypeScript 6 to TypeScript 7 (the native compiler) while keeping typescript-eslint, svelte-check and other JS-API consumers working, by aliasing `typescript` to @typescript/typescript6 and installing TS 7 as @typescript/native. Use on a Renovate "update dependency typescript to v7" PR or when lint fails with `Cannot read properties of undefined (reading 'Intrinsic')` after a TS 7 bump.
disable-model-invocation: true
---

# TypeScript 7 migration

## Why the plain bump breaks

`typescript@7` is the native (Go) compiler. Its main export is only
`lib/version.cjs`; the JS compiler API is gone. Anything that does
`require('typescript')` for the API breaks:

- typescript-eslint (peer `typescript >=4.8.4 <6.1.0`) via ts-api-utils:
  `TypeError: Cannot read properties of undefined (reading 'Intrinsic')`
- svelte-check 4.x: `TypeScript 7 support currently requires both TypeScript 7
  and TypeScript 6 installed`
- svelte2tsx, and any other tool that imports `typescript`

The TS 7 announcement's fix is two packages side by side. Reference:
https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/
Worked example: https://github.com/nrkno/pin-chat/pull/590 (commit
`ad961144`, comment explains each choice).

## Target layout

In every package.json that had `"typescript"`:

```json
"@typescript/native": "npm:typescript@7.0.2",
"typescript": "npm:@typescript/typescript6@6.0.2"
```

- `typescript` → `@typescript/typescript6`. Re-exports the TS 6 API
  (depends on `@typescript/old: npm:typescript@^6`), binary is `tsc6`.
  Tools resolving `typescript` by name keep working and see `ts.version` 6.x.
- `@typescript/native` → `typescript@7`. Owns the `tsc` binary, so `tsc -b`,
  `tsc -p`, `check` and `build` scripts run the native compiler unchanged.
- No bin collision: the alias only ships `tsc6`.
- The name `@typescript/native` matters: svelte-check's `--tsgo` resolves
  exactly `@typescript/native` (or `@typescript/native-preview`) and checks
  that its package.json name is `typescript` with major ≥ 7.
- Only add `@typescript/native` where a script runs `tsc` or `tsc-watch`.
  A package that only runs eslint or svelte-check needs just the alias.
- Renovate understands `npm:` aliases; keep the exact pins.

## Steps

1. Check out the Renovate branch (`renovate/typescript-7.x`). Read the failed
   CI log first (`gh run view <id> --log-failed`) to confirm it is the API
   failure above and not a real type error.
2. Rewrite devDependencies as in the layout. Keep keys sorted so prettier
   and the lockfile stay stable.
3. tsc-watch: it defaults to `typescript/bin/tsc`, which the alias package
   does not have (`bin/tsc6` only), so it exits with code 9. Add
   `--compiler @typescript/native/bin/tsc` to every tsc-watch script.
   tsc-watch ≥ 7.2 already parses native `tsc` watch output.
4. Run `npm whoami` first, then `pnpm install`. Confirm:
   `pnpm exec tsc --version` → 7.x, `pnpm exec tsc6 --version` → 6.x.
5. Run build, lint, check, test. Then `pnpm install --frozen-lockfile
   --offline` to confirm the lockfile is what CI will accept.
6. svelte-check: leave it on the default TS 6 path. `--tsgo` (svelte-check
   4.7) spawns native tsc but mis-resolves named exports from `.svelte.ts`
   modules (`Module '"*.svelte"' has no exported member`) and fails on
   `composite` projects (`Composite projects may not disable incremental
   compilation`). It also leaves `.svelte-check/` and `.svelte-kit/`
   scratch dirs; delete them if you tried it. Re-evaluate on a newer
   svelte-check.
7. Document the two-package layout in CLAUDE.md (a short bullet under the
   environment or toolchain section) so nobody "fixes" the alias back.
8. Commit signed, push to the Renovate branch, comment on the PR with what
   changed and why. Renovate stops rebasing the branch once it has a
   non-Renovate commit, which is what you want.

## Verify

- `node -e "console.log(require('typescript').version)"` from a package dir
  prints 6.x (the root has no `typescript`, so run it inside a package).
- `grep -n "typescript@7\|@typescript/typescript6" pnpm-lock.yaml` shows
  both resolved.
- eslint runs without the `Intrinsic` TypeError; svelte-check passes its
  version check (major < 7 on `typescript/package.json`).

## Later

TS 7.1 is expected to ship a new API. When typescript-eslint supports it
(track https://github.com/typescript-eslint/typescript-eslint/issues/10940)
and svelte-check drops the TS 6 requirement, collapse back to a single
`typescript@7` dependency and remove the alias and `--compiler` flags.
