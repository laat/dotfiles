# Sourced by safehouse-agent (safehouse package). Append to ro/rw
# (colon-separated) and env_pass (comma-separated). POSIX sh.

# ~/.config/galley read-only: the galley CLI finds the server through
# config.json there. ~/.dotfiles, where the stowed file points, is already
# readable, but sandbox-exec also checks the symlink's own path, so without
# this the CLI falls back to localhost.
# if, not &&: a false test as the file's last command would end the
# set -e wrapper that sources it.
if [ -d "$HOME/.config/galley" ]; then
  ro="$ro:$HOME/.config/galley"
fi
