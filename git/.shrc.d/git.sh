#!/bin/sh
alias g='git'
alias gc='git commit -v'
alias gcs='git commit -v -S'
alias gcz='git cz -v'
alias gca='git commit -v -a'
alias gcas='git commit -v -a -S'
alias gcam='git commit -a -m'
alias gcams='git commit -a -m -S'
alias gd='git diff'
alias gf='git fetch'
alias gm='git main'
alias gst='git status -sb'

alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gunignore='git update-index --no-assume-unchanged'

alias gcai='git aia'
alias gci='git ai'

# shellcheck disable=SC2068 disable=SC2145
gi() { curl -L -s https://www.gitignore.io/api/$@ | sed '/^# .*toptal/d' ;}

# gh-stack over HTTPS, everything else over SSH. The ssh ControlMaster in
# .gitconfig leaks the stderr pipe when the remote command fails (fetching a
# branch that does not exist, which `gh stack submit` does for every new
# branch), so gh-stack, which captures git's output, hangs for good. HTTPS
# has no master to wedge, and only gh-stack sees it: plain git keeps the
# 1Password-gated key. Auth is the keychain token, with gh's token as fallback.
gh() {
  if [ "$1" = stack ]; then
    GIT_CONFIG_COUNT=3 \
    GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf GIT_CONFIG_VALUE_0=git@github.com: \
    GIT_CONFIG_KEY_1=url.https://github.com/.insteadOf GIT_CONFIG_VALUE_1=ssh://git@github.com/ \
    GIT_CONFIG_KEY_2=credential.https://github.com.helper GIT_CONFIG_VALUE_2='!gh auth git-credential' \
    command gh "$@"
  else
    command gh "$@"
  fi
}
