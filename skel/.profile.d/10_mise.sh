#!/bin/sh
if [ -f "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate "$(basename "${SHELL:-sh}")" 2>/dev/null)" 2>/dev/null || true
  PATH="$HOME/.local/share/mise/shims:$PATH"
  export PATH
fi
