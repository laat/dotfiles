import type { Register } from 'claude-code'

// %blaa in the prompt offers zoxide's directories ranked by `fzf --filter`.
// Taking a row writes @<dir>/ over the token, and the engine's own @
// completion carries on from there into the files of that directory.

const MAX_ROWS = 15
const LIST_TTL_MS = 30_000
// ../../x reads better than an absolute path; past that, absolute does.
const MAX_UPS = 2

const segments = (path: string) => path.split('/').filter(Boolean)

// The mention for `dir` as seen from `cwd`: relative when it is close by.
function mention(dir: string, cwd: string): string {
  const from = segments(cwd)
  const to = segments(dir)
  let common = 0
  while (common < from.length && common < to.length && from[common] === to[common]) common++
  const ups = from.length - common
  if (ups > MAX_UPS) return dir
  const rel = [...Array<string>(ups).fill('..'), ...to.slice(common)].join('/')
  return rel === '' ? '.' : rel
}

const tilde = (dir: string, home: string | undefined) =>
  home !== undefined && (dir === home || dir.startsWith(`${home}/`)) ? `~${dir.slice(home.length)}` : dir

export const register: Register = on => {
  let cached: { at: number; list: string } | undefined

  on('prompt.autocomplete', { token: /^%/ }, async ($, e, next) => {
    const now = await $.clock.now()
    if (cached === undefined || now - cached.at > LIST_TTL_MS) {
      const { stdout } = await $.process.run(['zoxide', 'query', '--list'])
      cached = { at: now, list: stdout }
    }

    const ranked = await $.process.run(['fzf', '--filter', e.token.slice(1), '--scheme=path'], {
      stdin: cached.list,
    })
    const [cwd, home] = await Promise.all([$.session.cwd(), $.env.get('HOME')])
    const rows = ranked.stdout
      .split('\n')
      .filter(Boolean)
      .slice(0, MAX_ROWS)
      .map(dir => ({ text: `@${mention(dir, cwd)}/`, label: tilde(dir, home) }))

    const below = await next(e)
    return { suggestions: [...rows, ...below.suggestions] }
  })
}
