;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(display-battery-mode t)
 '(display-time-mode t)
 '(menu-bar-mode nil)
 '(package-enable-at-startup t)
 '(package-selected-packages
   (quote
    (ace-window ack ada-mode ada-ref-man adaptive-wrap adjust-parens aggressive-indent ahungry-theme all ampc arbitools ascii-art-to-unicode async auctex aumix-mode auto-correct auto-overlays avy bbdb beacon brief buffer-expose bug-hunter caps-lock captain chess cl-generic cl-lib cl-print clipboard-collector cobol-mode coffee-mode compact-docstrings company company-ebdb company-math company-statistics context-coloring crisp csv-mode cycle-quotes darkroom dash dbus-codegen debbugs delight dict-tree diff-hl diffview dired-du dired-git-info disk-usage dismal djvu docbook dts-mode easy-kill ebdb ebdb-gnorb ediprolog eglot el-search eldoc-eval electric-spacing enwc epoch-view ergoemacs-mode excorporate exwm f90-interface-browser filladapt flylisp flymake fountain-mode frame-tabs frog-menu fsm ggtags gited gle-mode gnome-c-style gnorb gnugo gnus-mock gpastel greader heap highlight-escape-sequences hook-helpers html5-schema hydra hyperbole ioccur iterators ivy ivy-explorer javaimp jgraph-mode js2-mode json-mode jsonrpc jumpc kmb landmark let-alist lex lmc load-dir load-relative loc-changes loccur map markchars math-symbol-lists memory-usage metar midi-kbd mines minibuffer-line minimap mmm-mode multishell muse myers nadvice nameless names nhexl-mode nlinum notes-mode ntlm num3-mode oauth2 objed omn-mode on-screen org org-edna orgalist osc other-frame-window pabbrev paced parsec peg pinentry poker posframe psgml python quarter-plane queue rainbow-mode rbit rcirc-color rcirc-menu realgud register-list relint rich-minority rnc-mode rudel scroll-restore sed-mode seq shen-mode sisu-mode smart-yank sml-mode soap-client sokoban sotlisp spinner sql-indent ssh-deploy stream svg svg-clock system-packages tNFA temp-buffer-browse test-simple timerfunctions tiny tramp-theme transcribe trie undo-tree uni-confusables url-http-ntlm validate vcl-mode vdiff vigenere visual-filename-abbrev visual-fill vlf w3 wcheck-mode wconf web-server webfeeder websocket which-key windresize wisi wpuzzle xclip xelb xpm xr yasnippet yasnippet-classic-snippets zones ztree)))
 '(tool-bar-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

```lisp
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)
```
