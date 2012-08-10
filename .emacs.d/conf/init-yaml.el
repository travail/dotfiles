;; yaml-mode
(autoload 'yaml-mode "yaml-mode.el" "YAML mode" t)
(add-to-list 'auto-mode-alist '("\\.yaml$" . yaml-mode))
(add-to-list 'auto-mode-alist '("\\.yml$" . yaml-mode))
