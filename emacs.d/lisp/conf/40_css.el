;;; package --- 40_css.el

;;; Commentary:

;;; Code:

(autoload 'css-mode "css-mode")
(setq auto-mode-alist
      (cons '("\\.css\\'" . css-mode) auto-mode-alist))

(autoload 'scss-mode "scss-mode")
(add-to-list 'auto-mode-alist '("\\.scss$" . scss-mode))
(add-to-list 'auto-mode-alist '("\\.css$" . scss-mode))

(defun scss-custom ()
  "scss-mode-hook"
  (and
   (set (make-local-variable 'css-indent-offset) 2)
   (set (make-local-variable 'scss-compile-at-save) nil)
   )
  )
(add-hook 'scss-mode-hook
  '(lambda() (scss-custom)))

;;; 40_css.el ends here
