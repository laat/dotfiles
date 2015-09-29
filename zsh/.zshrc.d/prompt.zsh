NEWLINE=$'\n'
#clean prompt with host
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi
PROMPT='%{$fg[$NCOLOR]%}%B%n%b@$FG[145]%m%{$reset_color%}:%{$fg[blue]%}%B%c/%b%{$reset_color%} ${NEWLINE}%(!.#.$) '
