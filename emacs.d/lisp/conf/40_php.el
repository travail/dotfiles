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

            (require 'php-completion)
            (php-completion-mode t)
            (when (require 'auto-complete nil t)
              (make-variable-buffer-local 'ac-sources)
              (add-to-list 'ac-sources 'ac-source-php-completion)
              (auto-complete-mode t)
              )))

(add-hook 'php-mode-hook
          (lambda ()
            (setq flycheck-phpcs-standard "PSR2")
            (setq flycheck-phpmd-rulesets '("unusedcode"))
            (setq flycheck-php-phpmd-executable "~/bin/phpmd")
            (setq flycheck-php-phpcs-executable "~/bin/phpcs")
            ))

;;; 40_php.el
