;;; uncomment this line to disable loading of "default.el" at startup
;; (setq inhibit-default-init t)

;;
(add-to-list 'load-path "~/.emacs.d/")
(add-to-list 'load-path "~/.emacs.d/auto-install")

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

;; load configuration files
(add-to-load-path "conf" "elpa")
(load "init-c")
(load "init-html")
(load "init-javascript")
(load "init-perl")
(load "init-php")
(load "init-ruby")
(load "init-yaml")
(load "init-japanese")
;; (load "flymake")

;; auto-install
(require 'auto-install)
(add-to-list 'load-path auto-install-directory)
;;(auto-install-update-emacswiki-package-name t)
(auto-install-compatibility-setup)
(setq ediff-window-setup-function 'ediff-setup-window-plain)

;; auto-complete
(require 'auto-complete-config)
(global-auto-complete-mode 1)
(setq ac-ignore-case t)
(setq ac-delay 0.2)
(setq ac-auto-show-menu 0.2)

;; anything
(require 'anything-startup)

;; anything-exuberant-ctags
(when (require 'anything nil t)
  (require 'anything-exuberant-ctags)
  )
(define-key global-map (kbd "C-c j")  'anything-exuberant-ctags-select-from-here)

;; yasnippet
;; (require 'yasnippet)
;; (yas-global-mode 1)

;; ;; import PATH from shell
;; (defun set-exec-path-from-shell-PATH ()
;;   "Set up Emacs' `exec-path' and PATH environment variable to match that used by the user's shell.

;; This is particularly useful under Mac OSX, where GUI apps are not started from a shell."
;;   (interactive)
;;   (let ((path-from-shell (replace-regexp-in-string "[ \t\n]*$" "" (shell-command-to-string "$SHELL --login -i -c 'echo $PATH'"))))
;;     (setenv "PATH" path-from-shell)
;;     (setq exec-path (split-string path-from-shell path-separator))))

;; (set-exec-path-from-shell-PATH)

;; turn on font-lock mode
(global-font-lock-mode t)

;; enable visual feedback on selections
(setq transient-mark-mode t)

;; highlight current line
;;(global-hl-line-mode 1)
;; highlight brackets, braces
(show-paren-mode t)
;; highlight whitespace
(require 'jaspace)
(setq jaspace-highlight-tags t)

;; trancate lines
(setq truncate-lines nil)
(setq truncate-partial-width-windows nil)

;; width tab key
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; smartparents
(require 'smartparens-config)
(smartparens-global-mode t)

;; do not make backup file '***~'
(setq make-backup-files nil)

;; don't linebreak on scrolling
(setq next-line-add-newlines nil)

;; smooth srcolling
(progn
  (setq scroll-step 1)
  (setq scroll-conservatively 4))

;; file name completion
(setq read-file-name-completion-ignore-case t)
;;(setq completion-ignore-case t)

;; identifying the same name files
(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

(put 'set-goal-column 'disabled nil)

;; key mapping
(define-key global-map (kbd "C-h")  'delete-backward-char)
(define-key global-map (kbd "C-m")  'newline-and-indent)
(define-key global-map (kbd "C-c c") 'comment-or-uncomment-region)
(define-key global-map (kbd "C-c g") 'goto-line)

;; indicate the number of column
(column-number-mode t)

;;; This was installed by package-install.el.
;;; This provides support for the package system and
;;; interfacing with ELPA, the package archive.
;;; Move this code earlier if you want to reference
;;; packages in your .emacs.
;;(when
;;	(load
;;	 (expand-file-name "~/.emacs.d/elpa/package.el"))
;;  (package-initialize))
(when (require 'package nil t)
  (add-to-list 'package-archives
			   '("marmalade" . "http://marmalade-repo.org/packages/"))
  (add-to-list 'package-archives '("ELPA" . "http://tromey.com/elpa/"))
  (package-initialize))
