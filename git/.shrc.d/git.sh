alias g='git'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcam='git commit -a -m'
alias gd='git diff'
alias gf='git fetch'
alias gst='git status'

alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gunignore='git update-index --no-assume-unchanged'

gi() { curl -L -s https://www.gitignore.io/api/$@ ;}
