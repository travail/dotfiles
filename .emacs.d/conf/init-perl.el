;; cperl-mode
(defalias 'perl-mode 'cperl-mode)
(autoload 'cperl-mode
  "cperl-mode"
  "alternate mode for editing Perl programs" t)

(setq cperl-auto-newline nil)
(setq cperl-indent-parens-as-block t)
(setq cperl-close-paren-offset -4)
(setq cperl-indent-level 4)
(setq cperl-label-offset -4)
(setq cperl-continued-statement-offset 4)
(setq cperl-highlight-variables-indiscriminately t)
(setq cperl-tab-always-indent nil)
(setq cperl-font-lock t)

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
(setq auto-mode-alist (append '(("\\.pl$" . cperl-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.pm$" . cperl-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.cgi$" . cperl-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.PL$" . cperl-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("\\.psgi$" . cperl-mode)) auto-mode-alist))
