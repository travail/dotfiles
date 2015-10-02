;;; package --- 20_helm.el

;;; Commentary:

;;; Code:

(require 'helm-config)
(helm-mode 1)
(define-key global-map (kbd "C-s") 'helm-swoop)
(define-key global-map (kbd "C-c C-h") 'execute-extended-command)
(define-key helm-map (kbd "C-h") 'delete-backward-char)
(define-key helm-read-file-map (kbd "C-h") 'delete-backward-char)
(define-key helm-find-files-map (kbd "C-h") 'delete-backward-char)
(define-key helm-find-files-map (kbd "TAB") 'helm-execute-persistent-action)
(define-key helm-read-file-map (kbd "TAB") 'helm-execute-persistent-action)

;;; 20_helm.el ends here
