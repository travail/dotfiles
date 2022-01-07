;;; package --- 40_ts.el

;;; Commentary:

;;; Code

(package-install 'typescript-mode)
(require 'typescript-mode)
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))

;;; 40_ts.el ends here
