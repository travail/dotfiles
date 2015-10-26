;;; package --- 99_keybind.el

;;; Commentary:

;;; Code:

(define-key global-map (kbd "C-h")  'delete-backward-char)
(define-key global-map (kbd "C-m")  'newline-and-indent)
(define-key global-map (kbd "C-c c") 'comment-or-uncomment-region)
(define-key global-map (kbd "C-c g") 'goto-line)
(define-key global-map (kbd "C-c r") 'revert-buffer)

;;; 99_keybind.el ends here
