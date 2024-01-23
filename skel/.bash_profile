. ~/.profile
# Source a local profile
if [ -f "$HOME/.bash_profile.local" ]; then
    . $HOME/.bash_profile.local
fi
case  $- in *i*) . ~/.bashrc;; esac
