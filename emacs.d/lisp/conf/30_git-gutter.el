;;; package --- 30_git-gutter.el

;;; Commentary:

;;; Code:

(require 'git-gutter)
(global-git-gutter-mode t)
(global-set-key (kbd "C-x v =") 'git-gutter:popup-hunk)
(global-set-key (kbd "C-x p") 'git-gutter:previous-hunk)
(global-set-key (kbd "C-x n") 'git-gutter:next-hunk)
(global-set-key (kbd "C-x R") 'git-gutter:revert-hunk)

;;; 30_git-gutter.el ends here
