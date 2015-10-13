;;; package --- 40_perl.el

;;; Commentary:

;;; Code:

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

;; source reindent by perltidy
(defun perltidy-region ()
  "Run perltidy on the current region."
  (interactive)
  (save-excursion
	(shell-command-on-region (point) (mark) "PERL_CARTON_CPANFILE=~/.perl/cpanfile carton exec perltidy -q" nil t)))
(add-to-list 'auto-mode-alist '("\\.pl$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.pm$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.fcgi$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.cgi$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.PL$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.psgi$" . perl-mode))
(add-to-list 'auto-mode-alist '("\\.t$" . perl-mode))
(add-to-list 'auto-mode-alist '("\cpanfile$" . perl-mode))

;; flycheck
(autoload 'flycheck "flycheck" nil t)
(setenv "CATALYST_ENV" (or (getenv "CATALYST_ENV") "development"))
(flycheck-define-checker perl-project-libs
  "A perl syntax checker."
  :command ("perl"
            ;; Specify the directoy where Project::Libs is located to load it,
            ;; since "PERL_CARTON_CPANFILE=/path/to/cpanfile carton exec perl"
            ;; doesn't work as command.
            (eval (concat "-I" (getenv "HOME") "/.perl/local/lib/perl5"))
            "-MProject::Libs lib_dirs => [qw(local/lib/perl5 lib)]"
            "-w" "-c"
            source-inplace)
  :error-patterns ((error line-start
                          (minimal-match (message))
                          " at " (file-name) " line " line
                          (or "." (and ", " (zero-or-more not-newline)))
                          line-end))
  :modes (perl-mode cperl-mode))

;; perl-completion
;; (require 'perl-completion)
;; (add-hook 'cperl-mode-hook
;;           '(lambda()
;;              (perl-completion-mode t)))

;; (add-hook  'cperl-mode-hook
;;            (lambda ()
;;              (when (require 'auto-complete nil t) ; no error whatever auto-complete.el is not installed.
;;                (auto-complete-mode t)
;;                (make-variable-buffer-local 'ac-sources)
;;                (setq ac-sources
;;                      '(ac-source-perl-completion)))))

(add-hook 'cperl-mode-hook
		  '(lambda ()
			 (define-key cperl-mode-map (kbd "C-c t") 'perltidy-region)
             (flycheck-mode t)
             (setq flycheck-checker 'perl-project-libs)
			 ))

;;; 40_perl.el ends here
