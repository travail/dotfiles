;; ruby-mode
(autoload 'ruby-mode "ruby-mode")

(setq auto-mode-alist (append '(("Rakefile$" . cperl-mode)) auto-mode-alist))

;; ruby-electric.el
(require 'ruby-electric)
(add-hook 'ruby-mode-hook '(lambda () (ruby-electric-mode t)))