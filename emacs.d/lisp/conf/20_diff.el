;;; package --- 20_diff.el

;;; Commentary:

;;; Code:

(defun diff-mode-setup-faces()
  (set-face-attribute 'diff-added nil
                      :foreground "white" :background "dark green")
  (set-face-attribute 'diff-removed nil
                      :foreground "white" :background "dark red")
  (set-face-attribute 'diff-refine-change nil
                      :foreground nil :background nil
                      :weight 'bold :inverse-video t))
(add-hook 'diff-mode-hook 'diff-mode-setup-faces)

(defun diff-mode-refine-automatically()
  (diff-auto-refine-mode t))
(add-hook 'diff-mode-hook 'diff-mode-refine-automatically)

;;; 20_diff.el ends here
