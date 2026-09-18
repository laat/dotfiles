autoload -U colors && colors
autoload -Uz vcs_info

precmd() {
    vcs_info

    if [[ "$DOCKER_MACHINE_NAME" == "default" ]];
    then
        _DM_NAME="";
    else
        _DM_NAME="$DOCKER_MACHINE_NAME";
    fi
}
setopt prompt_subst

zstyle ':vcs_info:*' enable git hg
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true

zstyle ':vcs_info:*' stagedstr '%F{red}✗%f'
zstyle ':vcs_info:*' unstagedstr "%F{red}⚑%f"

zstyle ':vcs_info:*' formats "(%{$fg_bold[yellow]%}%b%c%u%{$reset_color%})"
zstyle ':vcs_info:*' actionformats "(%{$fg_bold[yellow]%}%b%c%u|%a%{$reset_color%})"

zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-worktree

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

### git: Show a tree icon (nerd font) before the branch in a linked worktree,
# such as the ones workmux makes. In the main worktree the git dir and the
# common dir are the same directory.
function +vi-git-worktree(){
    local gitdir common
    gitdir=$(git rev-parse --path-format=absolute --git-dir 2>/dev/null) || return
    common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if [[ "$gitdir" != "$common" ]]; then
        hook_com[branch]=" ${hook_com[branch]}"
    fi
}


_lineup=$'\e[1A'
_linedown=$'\e[1B'
_newline=$'\n'
#clean prompt with host
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi
: ${PROMPT_USER:=%n}
: ${PROMPT_HOST:=%m}
PROMPT='%{$fg[$NCOLOR]%}%B${PROMPT_USER}%b@$FG[145]${PROMPT_HOST}%{$reset_color%}:%{$fg[blue]%}%B%c/%b%{$reset_color%} ${vcs_info_msg_0_} %{$fg[red]%}${_DM_NAME}%{$reset_color%}${_newline}%(!.#.$) '

RPROMPT='%{${_lineup}%}%F{008}[%D{%H:%M:%S}]%f%{${_linedown}%}'

## make clock tick

# TMOUT=1
# TRAPALRM() {
#     zle reset-prompt
# }
