;;; package --- 40_json.el

;;; Commentary:

;;; Code:

(autoload 'json-mode "json-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.json$" . json-mode))

(add-hook 'json-mode-hook
(lambda ()
  (make-local-variable 'js-indent-level)
  (setq js-indent-level 2)))

;;; 40_json.el ends here
