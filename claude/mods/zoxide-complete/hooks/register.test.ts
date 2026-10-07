import { expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'

const HOME = '/Users/me'

// fzf answers `ranked` whatever zoxide listed; tests run no processes.
function world(on: On, cwd: string, ranked: string[]) {
  mock.clock(on)
  mock.env(on, { HOME })
  on('session.cwd', () => ({ value: cwd }))
  on('process.run', ($, e) => ({
    value: {
      exitCode: 0,
      stdout: e.argv[0] === 'fzf' ? ranked.map(d => `${d}\n`).join('') : '',
      stderr: '',
      isStdoutTruncated: false,
      isStderrTruncated: false,
    },
  }))
  on('prompt.autocomplete', () => ({ suggestions: [] }))
}

const ask = (token: string) => ({ text: `see ${token}`, cursor: 4 + token.length, token, start: 4 })

test('a nearby directory is mentioned relative to the cwd', async ($, on) => {
  world(on, `${HOME}/.dotfiles`, [`${HOME}/code/blaabok`, `${HOME}/.dotfiles/git`])
  const { suggestions } = await $.prompt.autocomplete(ask('%blaa'))
  expect(suggestions).toEqual([
    { text: '@../code/blaabok/', label: '~/code/blaabok' },
    { text: '@git/', label: '~/.dotfiles/git' },
  ])
})

test('a far directory is mentioned by its absolute path', async ($, on) => {
  world(on, `${HOME}/code/.worktrees/repo/branch`, [`${HOME}/code/blaabok`])
  const { suggestions } = await $.prompt.autocomplete(ask('%blaa'))
  expect(suggestions).toEqual([{ text: `@${HOME}/code/blaabok/`, label: '~/code/blaabok' }])
})

test('the cwd itself is @./', async ($, on) => {
  world(on, `${HOME}/code/blaabok`, [`${HOME}/code/blaabok`])
  const { suggestions } = await $.prompt.autocomplete(ask('%blaa'))
  expect(suggestions[0]?.text).toBe('@./')
})

test('tokens without the % lead get no rows', async ($, on) => {
  world(on, HOME, [`${HOME}/code/blaabok`])
  const { suggestions } = await $.prompt.autocomplete(ask('@blaa'))
  expect(suggestions).toEqual([])
})
