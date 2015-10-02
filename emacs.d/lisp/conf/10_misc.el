;;; package --- 10_misc.el

;;; Commentary:

;;; Code:

;; turn on font-lock mode
(global-font-lock-mode t)

;; enable visual feedback on selections
(setq transient-mark-mode t)

;; width tab key
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; do not make backup file '***~'
(setq make-backup-files nil)

;; file name completion
(setq read-file-name-completion-ignore-case t)

(put 'set-goal-column 'disabled nil)

;; indicate the number of column
(column-number-mode t)

;;; 10_misc.el ends here
