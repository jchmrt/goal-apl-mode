;;; goal-apl-mode.el --- A major mode for the GOAL APL.
;;; -*- lexical-binding: t; -*-

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

(defgroup goal-apl nil
  "Options related to the GOAL APL Mode."
  :prefix 'goal-apl-
  :group 'development)

(defcustom goal-apl-highlight-variables-p t
  "Whether to enable the highlighting of variables."
  :type 'boolean
  :options (list t nil)
  :group 'goal-apl :safe t)

(defvar goal-apl-mode-hook nil
  "Hook which will be run whenever goal-apl-mode is enabled.")

(defvar goal-apl--variable-overlays nil
  "List of current overlays used to highlight variables.")
(make-variable-buffer-local 'goal-apl--variable-overlays)

(defvar goal-apl-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap for GOAL APL major mode.")

(add-to-list 'auto-mode-alist '("\\.mod2g\\'" . goal-apl-mode))
(add-to-list 'auto-mode-alist '("\\.act2g\\'" . goal-apl-mode))
(add-to-list 'auto-mode-alist '("\\.mas2g\\'" . goal-apl-mode))

(defvar goal-apl--keyword-regexp
  (regexp-opt '("if" "then"  "forall" "do" "listall" "define" "with"
                "use" "as" "module" "exit" "focus" "order"
                "pre" "post" "when" "launch" "launchpolicy") 'words)
  "A regexp to identify GOAL keywords.")

(defvar goal-apl--builtin-regexp
  (regexp-opt '("bel" "goal" "a-goal" "goal-a" "percept"
                "sent" "sent:" "sent?" "sent!") 'words)
  "A regexp to identify GOAL builtins.")

(defvar goal-apl--variable-name-regexp
  "\\<[[:upper:]]\\w*\\>"
  "A regexp to identify GOAL variable names.")

(defvar goal-apl--action-regexp
  (regexp-opt '("adopt" "drop" "insert" "delete"
                "send" "send:" "send?" "send!" "exit-module")
              'words)
  "A regexp to identify GOAL actions.")

(defvar goal-apl--constant-regexp
  (regexp-opt '("always" "nogoals" "noaction" "never" ; exit option
                "none" "new" "select" "filter"        ; focus option
                "linear" "linearall" "linearrandom"   ; order
                "random" "randomall"                  ;   options
                "all" "allother" "some" "someother"   ; agent
                "self" "this" "main" "init" "event")  ;   selectors
              'words)
  "A regexp to identify GOAL constants.")


(defconst goal-apl-font-lock-keywords
  (list
   `(,goal-apl--keyword-regexp       . font-lock-keyword-face)
   `(,goal-apl--builtin-regexp       . font-lock-builtin-face)
   `(,goal-apl--variable-name-regexp . font-lock-variable-name-face)
   `(,goal-apl--action-regexp        . font-lock-function-name-face)
   `(,goal-apl--constant-regexp      . font-lock-constant-face)))

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

    st)
  "The syntax table for the GOAL APL.")

(define-derived-mode goal-apl-mode fundamental-mode "GOAL"
  "Major mode for editing GOAL files."
  (set (make-local-variable 'font-lock-defaults)
       '(goal-apl-font-lock-keywords))
  (if goal-apl-highlight-variables-p
      (add-hook 'post-command-hook 'goal-apl--highlight-variable-post-command nil t)))

(defconst goal-apl--symbol-border-pattern
  (if (>= emacs-major-version 22) '("\\_<" . "\\_>") '("\\<" . "\\>"))
  "Regexps to identify the start and end of symbols.")

(defun goal-apl--highlight-variable-post-command ()
  "Function run after each command to highlight variable occurences.

Will highlight any occurences of the variable at the point and
it's occurences in the current GOAL statement."
  (if goal-apl-highlight-variables-p
      (goal-apl--highlight-variable)))

(defun goal-apl--variable-p (symbol)
  "Check whether the string SYMBOL is a GOAL variable."
  (let ((case-fold-search nil))
    (string-match goal-apl--variable-name-regexp symbol)))

(defun goal-apl--get-variable-regexp ()
  "Create the regexp for the variable at the point.

Or if the symbol at the point isn't a variable, return nil."
  (let ((symbol (thing-at-point 'symbol)))
    (when (and symbol (goal-apl--variable-p symbol))
      (concat (car goal-apl--symbol-border-pattern)
              (regexp-quote symbol)
              (cdr goal-apl--symbol-border-pattern)))))

(defun goal-apl--highlight-variable ()
  "Highlight all occurences of the variable at the point.

Only highlights the occurences of the variables in the same GOAL
statement, and removes all highlightings if the symbol at the
point isn't a variable."
  (goal-apl--remove-overlays)
  (let ((symbol (goal-apl--get-variable-regexp)))
    (if symbol
        (goal-apl--make-overlays symbol))))

(defun goal-apl--remove-overlays ()
  "Remove all overlays that we have installed."
  (while goal-apl--variable-overlays
    (delete-overlay (pop goal-apl--variable-overlays))))

(defun goal-apl--make-overlays (symbol)
  "Add overlays for all occurrences of SYMBOL in the current statement."
  (let ((bounds (bounds-of-thing-at-point 'sentence))
        (case-fold-search nil))
    (save-excursion
      (goto-char (car bounds))
      (while (re-search-forward symbol (cdr bounds) t)
        (let* ((begin (car (bounds-of-thing-at-point 'symbol)))
              (overlay (make-overlay begin (point))))
          (push overlay goal-apl--variable-overlays)
          (overlay-put overlay 'face 'highlight))))))

(provide 'goal-apl-mode)
;;; goal-apl-mode.el ends here
