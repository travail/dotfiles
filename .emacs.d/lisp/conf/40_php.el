;; php-mode
(autoload 'php-mode "php-mode")
(setq auto-mode-alist
      (cons '("\\.php\\'" . php-mode) auto-mode-alist))
(add-hook 'php-mode-hook
          (lambda()
            (setq tab-width 4)
            (setq indent-tabs-mode nil)
            (setq c-basic-offset 4)
            (c-set-offset 'case-label' 4)
            (c-set-offset 'arglist-intro' 4)
            (c-set-offset 'arglist-cont-nonempty' 4)
            (c-set-offset 'arglist-close' 0)

            (defun ywb-php-lineup-arglist-intro (langelem)
              (save-excursion
                (goto-char (cdr langelem))
                (vector (+ (current-column) c-basic-offset))))
            (defun ywb-php-lineup-arglist-close (langelem)
              (save-excursion
                (goto-char (cdr langelem))
                (vector (current-column))))
            (c-set-offset 'arglist-intro 'ywb-php-lineup-arglist-intro)
            (c-set-offset 'arglist-close 'ywb-php-lineup-arglist-close)

            (require 'php-completion)
            (php-completion-mode t)
            (define-key php-mode-map (kbd "C-c cmp") 'phpcmp-complete)
            (when (require 'auto-complete nil t)
              (make-variable-buffer-local 'ac-sources)
              (add-to-list 'ac-sources 'ac-source-php-completion)
              (auto-complete-mode t)
              )))

;; flymake
(require 'flymake-php)
(eval-after-load 'flymake
  '(progn
     (set-face-background 'flymake-errline "yellow")
     (set-face-background 'flymake-warnline "blue")
     ))
(add-hook 'php-mode-hook 'flymake-php-load)
(defadvice flymake-post-syntax-check (before flymake-force-check-was-interrupted)
  (setq flymake-check-was-interrupted t))
(ad-activate 'flymake-post-syntax-check)

;; collecting all functions for compaletion
(defun my-fetch-php-completions ()
  (if (and (boundp 'my-php-symbol-list)
           my-php-symbol-list)
      my-php-symbol-list

    (message "Fetching completion list...")

    (with-current-buffer
        (url-retrieve-synchronously "http://www.php.net/manual/en/indexes.functions.php")

      (goto-char (point-min))

      (message "Collecting function names...")

      (setq my-php-symbol-list nil)
      (while (re-search-forward "<a[^>]*class=\"index\"[^>]*>\\([^<]+\\)</a>" nil t)
        (push (match-string-no-properties 1) my-php-symbol-list))

      my-php-symbol-list)))
