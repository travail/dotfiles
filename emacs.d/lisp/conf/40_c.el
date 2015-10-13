;;; package --- 40_c.el

;;; Commentary:

;;; Code:

(autoload 'cc-mode "cc-mode" nil t)
;; Kernighan & Ritchie style
(setq c-default-style "k&r")
(setq auto-mode-alist
	  (append (list (cons "\\.\\(c\\|xs\\)$" 'c-mode))
			  auto-mode-alist))
(add-hook 'c-mode-common-hook
		  '(lambda ()
             (progn
               (c-toggle-hungry-state 1)
               (setq c-basic-offset 2 indent-tabs-mode nil))))

;;; 40_c.el ends here
