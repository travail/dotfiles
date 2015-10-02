;;; package --- 30_wdired.el

;;; Commentary:

;;; Code:

(setq directory-sep-char ?/)
(define-key dired-mode-map "r" 'wdired-change-to-wdired-mode)

;;; 30_wdired.el ends here
