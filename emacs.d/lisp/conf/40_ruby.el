;;; package --- 40_ruby.el

;;; Commentary:

;;; Code:

(autoload 'ruby-mode "ruby-mode")

(setq auto-mode-alist (append '(("Rakefile$" . ruby-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("Gemfile$" . ruby-mode)) auto-mode-alist))

(autoload 'ruby-end "ruby-end" nil t)
(add-hook 'ruby-mode-hook
          '(lambda ()
             (abbrev-mode 1)))

;;; 40_ruby.el ends here
