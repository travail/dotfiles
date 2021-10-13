;;; package --- 20_theme.el

;;; Commentary:

;;; Code:

(add-to-list 'custom-theme-load-path (concat user-emacs-directory "/lisp/theme/solarized"))
(load-theme 'manoj-dark t)
(set-frame-parameter nil 'background-mode 'dark)
(set-terminal-parameter nil 'background-mode 'dark)

;; (load-theme 'misterioso)
;; (custom-theme-set-faces
;;  'misterioso
;;  ;; background
;;  '(cursor ((t (:foreground "#F8F8F0"))))
;;  '(default ((t (:background "#1B1D1E" :foreground "#F8F8F2"))))

;;  ;; current line
;;  '(hl-line ((t (:background "color-238"))))
;;  )

;;; 20_theme.el ends here
