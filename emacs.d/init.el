;;; package --- init.el

;;; Commentary:

;;; Code:

;;
(when (< emacs-major-version 23)
  (defvar user-emacs-directory "~/.emacs.d/"))

;;
(defun add-to-load-path (&rest paths)
  (let (path)
    (dolist (path paths paths)
      (let ((default-directory
              (expand-file-name (concat user-emacs-directory path))))
        (add-to-list 'load-path default-directory)
        (if (fboundp 'normal-top-level-add-subdirs-to-load-path)
            (normal-top-level-add-subdirs-to-load-path))))))

;; add path to packages
(add-to-load-path "lisp/conf" "site-lisp")

;; install el-get if not exist
(setq el-get-dir (locate-user-emacs-file "site-lisp"))
(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.github.com/dimitri/el-get/master/el-get-install.el")
    (goto-char (point-max))
    (eval-print-last-sexp)))
(unless (file-exists-p (locate-user-emacs-file "elpa")) (el-get-elpa-build-local-recipes))

;; el-get
(when load-file-name
  (setq user-emacs-directory (file-name-directory load-file-name)))
(setq el-get-dir (locate-user-emacs-file "site-lisp"))
(require 'el-get)
(el-get-bundle init-loader)
(el-get-bundle exec-path-from-shell)
(el-get-bundle anything)
(el-get-bundle pos-tip)
(el-get-bundle auto-complete)
(el-get-bundle migemo)
(el-get-bundle git-gutter)
(el-get-bundle helm)
(el-get-bundle helm-swoop)
(el-get-bundle wdired)
(el-get-bundle smartparens)
(el-get-bundle flycheck)
(el-get-bundle flycheck-pos-tip)
(el-get-bundle cperl-mode)
(el-get-bundle perl-completion)
(el-get-bundle go-autocomplete)
(el-get-bundle company-go)
(el-get-bundle go-eldoc)
(el-get-bundle ruby-mode)
(el-get-bundle ruby-end)
(el-get-bundle php-mode)
(el-get-bundle scss-mode)
(el-get-bundle js2-mode)
(el-get-bundle js2-highlight-vars)
(el-get-bundle json-mode)
(el-get-bundle web-mode)
(el-get-bundle php-completion)
(el-get-bundle yaml-mode)

(el-get 'sync)

;; setup package
(require 'package)
(add-to-list 'package-archives '("melpa"     . "http://melpa.milkbox.net/packages/"))
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
(package-initialize)

;; init-loader
(setq init-loader-show-log-after-init nil)
(setq init-loader-byte-compile nil)
(setq init-loader-default-regexp "\\(?:^[[:digit:]]\\{2\\}\\).*\\.el\$")
(init-loader-load (locate-user-emacs-file "lisp/conf"))

(exec-path-from-shell-initialize)

;;; init.el ends here
