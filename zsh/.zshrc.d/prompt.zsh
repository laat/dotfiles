autoload -U colors && colors

# Hex colours (Catppuccin Mocha) rather than ANSI names, so the prompt looks
# the same in terminals with harsh default palettes, such as T3 Code's.
# Without truecolor, zsh/nearcolor maps them to the nearest 256-colour entry.
[[ $COLORTERM == (24bit|truecolor) ]] || zmodload zsh/nearcolor
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

zstyle ':vcs_info:*' stagedstr '%F{#f38ba8}✗%f'
zstyle ':vcs_info:*' unstagedstr "%F{#f38ba8}⚑%f"

zstyle ':vcs_info:*' formats "(%B%F{#f9e2af}%b%c%u%f%%b)"
zstyle ':vcs_info:*' actionformats "(%B%F{#f9e2af}%b%c%u|%a%f%%b)"

zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-worktree

### git: Show marker (T) if there are untracked files in repository
# Make sure you have added staged to your 'formats':  %c
function +vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git --no-optional-locks status --porcelain | fgrep '??' &> /dev/null ; then
        # This will show the marker if there are any untracked files in repo.
        # If instead you want to show the marker only if there are untracked
        # files in $PWD, use:
        #[[ -n $(git ls-files --others --exclude-standard) ]] ; then
        hook_com[unstaged]='%F{#f38ba8}✗%f'
    fi
}

### git: Show a tree icon (nerd font) before the branch in a linked worktree,
# such as the ones laatmux makes. In the main worktree the git dir and the
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
PROMPT='%{$fg[$NCOLOR]%}%B${PROMPT_USER}%b@$FG[145]${PROMPT_HOST}%{$reset_color%}:%F{#89b4fa}%B%c/%b%f ${vcs_info_msg_0_} %F{#f38ba8}${_DM_NAME}%f${_newline}%(!.#.$) '

RPROMPT='%{${_lineup}%}%F{008}[%D{%H:%M:%S}]%f%{${_linedown}%}'

## make clock tick

# TMOUT=1
# TRAPALRM() {
#     zle reset-prompt
# }
