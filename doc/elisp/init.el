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
   (sh . t)
   (ledger . t)
   (org . t)
   (plantuml . t)
   (latex . t)))

(setq org-confirm-babel-evaluate nil)

(setq org-html-postamble (let ((branch (substring (shell-command-to-string "git branch | grep '\*'") 2 -1))
                               (revision (shell-command-to-string "git log --pretty=format:'%h' -n 1"))
                               (tag (substring
                                     (shell-command-to-string "git name-rev --tags --name-only $(git rev-parse HEAD)") 0 -1)))
                            (concat
                             "<p class=\"author\">Author: %a</p>"
                             "<p class=\"date\">Modified: %C</p>"
                             "<p class=\"date\">Branch: " branch "</p>"
                             (if (equal tag "undefined")
                                 (concat "<p class=\"date\">Version: " revision "</p>")
                               (concat "<p class=\"date\">Version: " tag " (" revision ")</p>")))))
