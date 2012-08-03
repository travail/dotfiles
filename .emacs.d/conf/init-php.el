;; php-mode
(autoload 'php-mode "php-mode")
(setq auto-mode-alist
      (cons '("\\.php\\'" . php-mode) auto-mode-alist))
(setq php-mode-force-pear t)
(add-hook 'php-mode-user-hook
		  '(lambda ()
			 (setq php-manual-path "/usr/local/share/php/doc/html")
			 (setq php-manual-url "http://www.phppro.jp/phpmanual/")))

