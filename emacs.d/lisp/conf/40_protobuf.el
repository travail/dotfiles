;;; package --- 40_protobuf.el

;;; Commentary:

;;; Code:

(autoload 'protobuf-mode "protobuf-mode" nil t)
(setq auto-mode-alist
      (append (list (cons "\\.\\(proto\\)$" 'protobuf-mode))
              auto-mode-alist))
(add-hook 'before-save-hook 'gofmt-before-save)

;;; 40_protobuf.el ends here
