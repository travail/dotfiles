;;; package --- 20_highlight.el

;;; Commentary:

;;; Code:

;; highlight current line
(global-hl-line-mode 1)
(custom-set-faces '(hl-line ((t (:background "color-234")))))

;; highlight brackets, braces
(show-paren-mode t)

;;; 20_highlight.el ends here
