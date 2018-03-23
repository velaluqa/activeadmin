(require 'package)
(package-initialize)

(require 'org)
(require 'ox-html)

(let (load-directory (file-name-directory load-file-name))
  (setq org-ditaa-eps-jar-path (expand-file-name "ditaa0_9.eps.jar" load-directory))
  (setq org-ditaa-jar-path (expand-file-name "ditaa0_9.jar" load-directory)))

(org-babel-do-load-languages
 (quote org-babel-load-languages)
 '((emacs-lisp . t)
   (dot . t)
   (ditaa . t)
   (R . t)
   (python . t)
   (ruby . t)
   (gnuplot . t)
   (clojure . t)
   (shell . t)
   (ledger . t)
   (org . t)
   (plantuml . t)
   (latex . t)))

(setq org-confirm-babel-evaluate nil)

(setq org-html-postamble (let ((branch (getenv "GIT_BRANCH"))
                               (version (getenv "GIT_VERSION")))
                            (concat
                             "<p class=\"author\">Author: %a</p>"
                             "<p class=\"date\">Modified: %C</p>"
                             "<p class=\"date\">Branch: " branch "</p>"
                             "<p class=\"date\">Version: " version "</p>")))
