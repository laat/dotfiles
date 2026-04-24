#!/bin/sh

if [ -n "${TERM:-}" ] && command -v infocmp >/dev/null 2>&1; then
  if ! infocmp "$TERM" >/dev/null 2>&1 && infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
  fi
fi
