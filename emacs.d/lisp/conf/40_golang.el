;;; package --- 40_golang.el

;;; Commentary:

;;; Code:

(autoload 'go-mode "go-mode")
(add-hook 'go-mode-hook 'company-mode)
(add-hook 'go-mode-hook 'flycheck-mode)
(add-hook 'go-mode-hook (lambda()
                                (add-hook 'before-save-hook 'gofmt-before-save)
                                (local-set-key (kbd "M-.") 'godef-jump)
                                (set (make-local-variable 'company-backends) '(company-go))
                                (company-mode)
                                ))

;;; 40_golang.el ends here
