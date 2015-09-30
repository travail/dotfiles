;;; uncomment this line to disable loading of "default.el" at startup
;; (setq inhibit-default-init t)

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

;; configuration directories
(add-to-load-path "lisp/conf" "lisp/el-get" "lisp/github")

;; el-get
(when load-file-name
  (setq user-emacs-directory (file-name-directory load-file-name)))
(add-to-list 'load-path (locate-user-emacs-file "lisp/el-get"))
(setq el-get-dir (locate-user-emacs-file "lisp/el-get"))
(require 'el-get)
(el-get-bundle auto-complete)
(el-get-bundle migemo)
(el-get-bundle helm)
(el-get-bundle helm-swoop)
(el-get-bundle smartparens)
(el-get-bundle flymake)
(el-get-bundle flymake-php)
(el-get-bundle flymake-easy)
(el-get-bundle cperl-mode)
(el-get-bundle perl-completion)
(el-get-bundle ruby-mode)
(el-get-bundle ruby-end)
(el-get-bundle php-mode)
(el-get-bundle css-mode)
(el-get-bundle javascript)
(el-get-bundle php-completion)
(el-get-bundle yaml-mode)

(load "init-c")
(load "init-html")
(load "init-javascript")
(load "init-perl")
(load "init-php")
(load "init-ruby")
(load "init-yaml")
(load "init-japanese")
(load "flymake")

;; auto-complete
(require 'auto-complete-config)
(global-auto-complete-mode 1)
(setq ac-ignore-case t)
(setq ac-auto-start 2)
(setq ac-delay 0.05)
(setq ac-auto-show-menu 0.05)

;; migemo
;; (require 'migemo)
;; (setq migemo-command "cmigemo")
;; (setq migemo-options '("-q" "--emacs"))
;; (setq migemo-dictionary "/usr/local/share/migemo/utf-8/migemo-dict")
;; (setq migemo-user-dictionary nil)
;; (setq migemo-regex-dictionary nil)
;; (setq migemo-coding-system 'utf-8-unix)
;; (load-library "migemo")
;; (migemo-init)

;; helm
(require 'helm-config)
(helm-mode +1)
(define-key global-map (kbd "C-s") 'helm-swoop)
(define-key global-map (kbd "C-c C-h") 'execute-extended-command)
(define-key helm-map (kbd "C-h") 'delete-backward-char)
(define-key helm-read-file-map (kbd "C-h") 'delete-backward-char)
(define-key helm-find-files-map (kbd "C-h") 'delete-backward-char)
(define-key helm-find-files-map (kbd "TAB") 'helm-execute-persistent-action)
(define-key helm-read-file-map (kbd "TAB") 'helm-execute-persistent-action)

;; turn on font-lock mode
(global-font-lock-mode t)

;; enable visual feedback on selections
(setq transient-mark-mode t)

;; highlight current line
;;(global-hl-line-mode 1)
;; highlight brackets, braces
(show-paren-mode t)

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
;; (when
;; 	(load
;; 	 (expand-file-name "~/.emacs.d/elpa/package.el"))
;;  (package-initialize))
;; (when (require 'package nil t)
;;   (add-to-list 'package-archives
;; 			   '("marmalade" . "http://marmalade-repo.org/packages/"))
;;   (add-to-list 'package-archives '("ELPA" . "http://tromey.com/elpa/"))
;;   (package-initialize))
