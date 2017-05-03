;;; goal-apl-mode.el --- A major mode for the GOAL APL.

;; Copyright (C) 2017  Jochem Raat <jchmrt@riseup.net>

;; Author: Jochem Raat <jchmrt@riseup.net>
;; Keywords: languages
;; Created: 03 May 2017

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;;
;;; This is a major mode for the GOAL agent-oriented programming
;;; language [https://goalapl.atlassian.net/wiki].
;;;

;;; Code:

(defvar goal-apl-mode-hook nil)

(defvar goal-apl-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for GOAL APL major mode.")

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mod2g\\'" . goal-apl-mode))
(add-to-list 'auto-mode-alist '("\\.act2g\\'" . goal-apl-mode))
(add-to-list 'auto-mode-alist '("\\.mas2g\\'" . goal-apl-mode))

(defvar goal-apl-keyword-regexp
  (regexp-opt '("if" "then"  "forall" "do" "listall" "define" "with"
                "use" "as" "module" "exit" "focus" "order"
                "pre" "post" "when" "launch" "launchpolicy") 'words))

(defvar goal-apl-builtin-regexp
  (regexp-opt '("bel" "goal" "a-goal" "goal-a" "percept"
                "sent" "sent:" "sent?" "sent!") 'words))

(defvar goal-apl-variable-name-regexp
  "\\<[[:upper:]]\\w*\\>")

(defvar goal-apl-action-regexp
  (regexp-opt '("adopt" "drop" "insert" "delete"
                "send" "send:" "send?" "send!" "exit-module")
              'words))

(defvar goal-apl-constant-regexp
  (regexp-opt '("always" "nogoals" "noaction" "never" ; exit option
                "none" "new" "select" "filter"        ; focus option
                "linear" "linearall" "linearrandom"   ; order
                "random" "randomall"                  ;   options
                "all" "allother" "some" "someother"   ; agent
                "self" "this" "main" "init" "event")  ;   selectors
              'words))


(defconst goal-apl-font-lock-keywords
  (list
   `(,goal-apl-keyword-regexp . font-lock-keyword-face)
   `(,goal-apl-builtin-regexp . font-lock-builtin-face)
   `(,goal-apl-variable-name-regexp . font-lock-variable-name-face)
   `(,goal-apl-action-regexp . font-lock-function-name-face)
   `(,goal-apl-constant-regexp . font-lock-constant-face)))

(defvar goal-apl-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; One line comments with '%':
    (modify-syntax-entry ?% "<" st)
    (modify-syntax-entry ?\n ">" st)

    ;; ' is also a string quote:
    (modify-syntax-entry ?' "\"" st)

    ;; '?', ':', '-' and '!' are normal word characters:
    (modify-syntax-entry ?? "w" st)
    (modify-syntax-entry ?: "w" st)
    (modify-syntax-entry ?- "w" st)
    (modify-syntax-entry ?! "w" st)

    ;; '.' is punctuation:
    (modify-syntax-entry ?. "." st)

    st))

(define-derived-mode goal-apl-mode fundamental-mode "GOAL"
  "Major mode for editing GOAL files."
  (set (make-local-variable 'font-lock-defaults)
       '(goal-apl-font-lock-keywords)))


(provide 'goal-apl-mode)
;;; goal-apl-mode.el ends here
