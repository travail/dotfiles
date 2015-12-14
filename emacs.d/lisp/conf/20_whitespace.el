;;; package --- 20_whitespace.el

;;; Commentary:

;;; Code:

(require 'whitespace)
(setq whitespace-style '(face
                         trailing
                         tabs
                         spaces
                         empty
                         space-mark
                         tab-mark
                         ))

(setq whitespace-display-mappings
      '((space-mark ?\u3000 [?\u25a1])
        ;; WARNING: the mapping below has a problem.
        ;; When a TAB occupies exactly one column, it will display the
        ;; character ?\xBB at that column followed by a TAB which goes to
        ;; the next TAB column.
        ;; If this is a problem for you, please, comment the line below.
        (tab-mark ?\t [?\u00BB ?\t] [?\\ ?\t])))

;; Enable Full-width white space visiblel
(setq whitespace-space-regexp "\\(\u3000+\\)")

;; Cleanup on saving
;; (setq whitespace-action '(auto-cleanup))

(global-whitespace-mode 1)

(set-face-attribute 'whitespace-trailing nil
                    :background "black"
                    :foreground "red"
                    :underline t)
(set-face-attribute 'whitespace-tab nil
                    :background "black"
                    :foreground "blue"
                    :underline t)
(set-face-attribute 'whitespace-space nil
                    :background "black"
                    :foreground "yellow"
                    :weight 'bold)
(set-face-attribute 'whitespace-empty nil
                    :background "black")

;;; 20_whitespace.el ends here
