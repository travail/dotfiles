;; ruby-mode
(autoload 'ruby-mode "ruby-mode")

(setq auto-mode-alist (append '(("Rakefile$" . ruby-mode)) auto-mode-alist))
(setq auto-mode-alist (append '(("Gemfile$" . ruby-mode)) auto-mode-alist))

(require 'ruby-end)
(add-hook 'ruby-mode-hook
          '(lambda ()
             (abbrev-mode 1)))
