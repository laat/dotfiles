. ~/.profile
[[ -f ~/.bash_profile.local ]] && . ~/.bash_profile.local
case $- in *i*) . ~/.bashrc;; esac
