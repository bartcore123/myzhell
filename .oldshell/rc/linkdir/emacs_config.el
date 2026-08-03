;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; basic emacs configuration to be used in conjunction with prelude       ;;
;; pragmaticemacs.com/installing-and-setting-up-emacs/                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;Add MELPA repository for packages
(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; prelude options                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; install additional packages - add anyto this list that you want to
;; be installed automatically
(prelude-require-packages '(multiple-cursors ess))

;;enable arrow keys
(setq prelude-guru nil)

;;smooth scrolling
(setq prelude-use-smooth-scrolling t)

;;uncomment this to use default theme
;;(disable-theme 'zenburn)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display options                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;enable tool and menu bars - good for beginners
(tool-bar-mode 0)
(menu-bar-mode 0)

;;change highlight colour
(set-face-attribute 'region t :background "#164040")

;;turn off aggressive auto save
(setq prelude-auto-save nil)
(setq
 backup-by-copying t      ;; don't clobber symlinks
 backup-directory-alist
 '(("." . "/tmp/emacs-backups"))    ;; don't litter my fs tree
 delete-old-versions t
 kept-new-versions 6
 kept-old-versions 2
 version-control t)
