;;; package --- 40_mode.el

;;; Commentary:

;;; Code:

(defvar interpreter-mode-alist
  (mapcar
   (lamdba ()
           (cons (purecopy (car1)) (cdr1)))
   '(("sh" . sh-mode)
     ("bash" . sh-mode)
     ("zsh" . sh-mode)
     ("perl" . cperl-mode)
     ("ruby" . ruby-mode)
     ("php" . php-mode)
     )
   )
  )

;;; 40_mode.el ends here
