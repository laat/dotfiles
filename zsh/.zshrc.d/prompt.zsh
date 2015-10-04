#! /bin/zsh
autoload -U colors && colors

autoload -Uz vcs_info
precmd() { vcs_info } 
setopt prompt_subst

zstyle ':vcs_info:*' enable git hg
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true

zstyle ':vcs_info:*' stagedstr '%F{red}✗%f'
zstyle ':vcs_info:*' unstagedstr '%F{red}✗%f'

zstyle ':vcs_info:*' formats "(%b%u%c)"
zstyle ':vcs_info:*' actionformats "(%b%u%c|%a)"

zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

### git: Show marker (T) if there are untracked files in repository
# Make sure you have added staged to your 'formats':  %c
function +vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | fgrep '??' &> /dev/null ; then
        # This will show the marker if there are any untracked files in repo.
        # If instead you want to show the marker only if there are untracked
        # files in $PWD, use:
        #[[ -n $(git ls-files --others --exclude-standard) ]] ; then
        hook_com[unstaged]='%F{red}✗%f'
    fi
}


_lineup=$'\e[1A'
_linedown=$'\e[1B'
_newline=$'\n'
#clean prompt with host
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi
PROMPT="%{$fg[$NCOLOR]%}%B%n%b@$FG[145]%m%{$reset_color%}:%{$fg[blue]%}%B%c/%b%{$reset_color%} ${vcs_info_msg_0_} ${_newline}%(!.#.$) "

## make clock tick
#TMOUT=1
#TRAPALRM() {
#    zle reset-prompt
#}
RPROMPT="%{${_lineup}%}%F{008}[%D{%H:%M:%S}]%f%{${_linedown}%}"
