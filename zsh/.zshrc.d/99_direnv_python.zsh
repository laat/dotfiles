setopt PROMPT_SUBST

show_virtual_env() {
  if [[ "$TERM_PROGRAM" != "vscode" && -n "$VIRTUAL_ENV" && -n "$DIRENV_DIR" ]]; then
    echo "($(basename $VIRTUAL_ENV)) "
  fi
}
PS1='$(show_virtual_env)'$PS1
