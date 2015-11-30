;;; ob-babel.el --- org-babel functions for babel evaluation

;; Copyright (C) 2015 Sigurd Fosseng

;; Author: Sigurd Fosseng
;; Keywords: literate programming, reproducible research

;; MIT licence

;;; Commentary:

;; babel is cool, but ":wrap SRC js" should not be neccesary

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:babel '())

(defun org-babel-execute:babel (body params)
  (let* ((cmdline (cdr (assoc :cmdline params)))
         (presets (cdr (assoc :presets params)))
         (cmd (concat
               "babel "
               (or cmdline "")
               (when presets (concat "--presets " presets " ")))))
    (message cmd)
    (org-babel-eval cmd body)))

(defun org-babel-prep-session:less (session params)
  (error "babel does not support sessions"))

(eval-after-load "org"
  '(add-to-list 'org-src-lang-modes '("babel" . "javascript")))

(provide 'ob-babel)

;;; ob-babel.el ends here
