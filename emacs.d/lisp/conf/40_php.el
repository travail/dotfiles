;;; package --- 40_php.el

;;; Commentary:

;;; Code:

(autoload 'php-mode "php-mode")
(setq auto-mode-alist
      (cons '("\\.php\\'" . php-mode) auto-mode-alist))
(add-hook 'php-mode-hook
          (lambda()
            (setq tab-width 4)
            (setq indent-tabs-mode nil)
            (setq c-basic-offset 4)
            (c-set-offset 'case-label' 4)
            (c-set-offset 'arglist-intro' 4)
            (c-set-offset 'arglist-cont-nonempty' 4)
            (c-set-offset 'arglist-close' 0)

            (defun ywb-php-lineup-arglist-intro (langelem)
              (save-excursion
                (goto-char (cdr langelem))
                (vector (+ (current-column) c-basic-offset))))
            (defun ywb-php-lineup-arglist-close (langelem)
              (save-excursion
                (goto-char (cdr langelem))
                (vector (current-column))))
            (c-set-offset 'arglist-intro 'ywb-php-lineup-arglist-intro)
            (c-set-offset 'arglist-close 'ywb-php-lineup-arglist-close)

            (autoload 'php-completion "php-completion" nil t)
            (php-completion-mode t)
            (when (autoload 'auto-complete "auto-complete" nil t)
              (make-variable-buffer-local 'ac-sources)
              (add-to-list 'ac-sources 'ac-source-php-completion)
              (auto-complete-mode t)
              )
            ))

(add-hook 'php-mode-hook
          (lambda ()
            (cond
             ((executable-find "phpcs")
              (setq flycheck-phpcs-standard "PSR2")
              )
             )
            (cond
             ((executable-find "phpmd")
              (setq flycheck-phpmd-rulesets '("unusedcode"))
              )
             )
            ))

;;; 40_php.el ends here
