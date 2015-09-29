alias e=emacs
alias em='emacsclient -nc -a ""'
alias emc='emacsclient -t -a ""'
alias eeval="emacsclient --eval"
alias eframe='emacsclient --alternate-editor "" --create-frame'
alias emasc=emacs
alias emcas=emacs

function efile {
    local cmd="(buffer-file-name (window-buffer))"
    emacsclient --eval "$cmd" | tr -d \"
}

function edir {
    local cmd="(let ((buf-name (buffer-file-name (window-buffer))))
                 (if buf-name (file-name-directory buf-name)))"
    
    emacsclient --eval "$cmd" | tr -d \"
}
