;;; ob-less.el --- org-babel functions for less evaluation

;; Copyright (C) 2015 Sigurd Fosseng

;; Author: Sigurd Fosseng
;; Keywords: literate programming, reproducible research

;; MIT licence

;;; Commentary:

;; lessc is cool, but ":wrap SRC css" should not be neccesary

;;; Code:
(require 'ob)

(defvar org-babel-default-header-args:less '())

(defun org-babel-execute:less (body params)
  (let* ((cmdline (cdr (assoc :cmdline params)))
         (cmd (concat "lessc " (or cmdline "") "-")))
    (org-babel-eval cmd body)))

(defun org-babel-prep-session:less (session params)
  (error "lessc does not support sessions"))

(eval-after-load "org"
  '(add-to-list 'org-src-lang-modes '("less" . "less-css")))

(provide 'ob-less)

;;; ob-less.el ends here
