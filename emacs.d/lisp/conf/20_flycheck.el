;;; package --- : 20_flycheck.el

;;; Commentary:

;;; Code:

(require 'flycheck)
(add-hook 'after-init-hook #'global-flycheck-mode)

(eval-after-load 'flycheck
  '(custom-set-variables
    '(flycheck-display-errors-function #'flycheck-pos-tip-error-messages)))

;; Ruby
(add-hook 'ruby-mode-hook 'flycheck-mode)

;;; 20_flycheck.el ends here
