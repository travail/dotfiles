(defalias 'perl-mode 'cperl-mode)
(autoload 'cperl-mode
  "cperl-mode"
  "alternate mode for editing Perl programs" t)

(setq cperl-indent-level 4)
(setq cperl-continued-statement-offset 4)
(setq cperl-brace-offset -4)
(setq cperl-label-offset -4)
(setq cperl-indent-parens-as-block t)
(setq cperl-close-paren-offset -4)
(setq cperl-tab-always-indent t)
(setq cperl-highlight-variables-indiscriminately t)

(require 'cperl-mode)

(add-hook 'cperl-mode-hook
		  '(lambda ()
			 (define-key cperl-mode-map (kbd "M-.")  'cperl-find-module)
			 (define-key cperl-mode-map (kbd "C-c t") 'perltidy-region)
			 (abbrev-mode 1)
			 (set-face-foreground 'font-lock-variable-name-face "yellow")
			 ))

;; source reindent by perltidy
(defun perltidy-region ()
  "Run perltidy on the current region."
  (interactive)
  (save-excursion
	(shell-command-on-region (point) (mark) "perltidy -q" nil t)))
(add-to-list 'auto-mode-alist '("\\.pl$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.pm$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.cgi$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.PL$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.psgi$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.t$" . perl-mode))
(add-to-list 'auto-mode-alist '("\cpanfile$" . perl-mode))

;; yasnippet
(defun yas/perl-package-name ()
  (let ((file-path (file-name-sans-extension (buffer-file-name))))
    (if (string-match "lib/" file-path)
        (replace-regexp-in-string "/" "::"
                                  (car (last (split-string file-path "/lib/"))))
      (file-name-nondirectory file-path))))

;; perl-completion
;; (add-hook 'cperl-mode-hook
;;           '(lambda()
;;              (require 'perl-completion)
;;              (perl-completion-mode t)))

;; (add-hook  'cperl-mode-hook
;;            (lambda ()
;;              (when (require 'auto-complete nil t) ; no error whatever auto-complete.el is not installed.
;;                (auto-complete-mode t)
;;                (make-variable-buffer-local 'ac-sources)
;;                (setq ac-sources
;;                      '(ac-source-perl-completion)))))

;; (require 'set-perl5lib)
(setq cperl-electric-keywords t)
(setq cperl-electric-lbrace-space t)
(setq cperl-font-lock t)
(setq cperl-electric-parens t)
