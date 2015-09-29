(setq vc-follow-symlinks t) ;; no symlik question at startup
(require 'ob-tangle)
;; (setq debug-on-error t)
(org-babel-load-file
  (expand-file-name "emacs-init.org"
		    user-emacs-directory))
