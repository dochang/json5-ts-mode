;;; json5-ts-mode.el --- Major mode for JSON5  -*- lexical-binding: t; -*-

;; Copyright (C) 2025 ZHANG Weiyi

;; Author: ZHANG Weiyi <dochang@gmail.com>
;; Version: 0.0.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: json5 languages tree-sitter
;; URL: https://github.com/dochang/json5-ts-mode

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a tree-sitter major mode for editing JSON5 files.

;; Installation:
;;
;; Requirements:
;;
;; To install a tree-sitter grammar, the following tools are required:
;;
;; - Git
;; - C/C++ compiler
;;
;; If your compiler is not `cc', `gcc', `c99', `c++' or `g++', check out the
;; documentation of `treesit-language-source-alist'.
;;
;; Check the availability of `tree-sitter':
;;
;; ```elisp
;; (treesit-available-p) ; should return t
;; ```
;;
;; Install grammar:
;;
;; ```elisp
;; (require 'treesit)
;; (add-to-list 'treesit-language-source-alist
;;              '(json5 "https://github.com/Joakker/tree-sitter-json5"))
;; ```
;;
;; Then run `M-x treesit-install-language-grammar'
;;
;; Install `json5-ts-mode':
;;
;; ```elisp
;; (add-to-list 'load-path "/path/to/json5-ts-mode")
;; (require 'json5-ts-mode)
;; (add-to-list 'auto-mode-alist
;;              '("\\.json5\\'" . json5-ts-mode))
;; ```

;; Customizations:
;;
;; `json5-ts-mode-indent-offset':
;;
;; Number of spaces for each indentation step in `json5-ts-mode'.

;; Limitations:
;;
;; Currently this mode doesn't support multi-line strings because the grammar
;; doesn't support it.

;; License:
;;
;; GPLv3

;;; Code:

(require 'treesit)
(require 'rx)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")

(defgroup json5-ts ()
  "Major mode for editing JSON5 files."
  :group 'languages)

(defcustom json5-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `json5-ts-mode'."
  :package-version '(json5-ts-mode . "0.0.0")
  :type 'integer
  :safe 'integerp
  :group 'json5-ts)

(defvar json5-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_  "_"     table)
    (modify-syntax-entry ?\\ "\\"    table)
    (modify-syntax-entry ?+  "."     table)
    (modify-syntax-entry ?-  "."     table)
    (modify-syntax-entry ?=  "."     table)
    (modify-syntax-entry ?%  "."     table)
    (modify-syntax-entry ?<  "."     table)
    (modify-syntax-entry ?>  "."     table)
    (modify-syntax-entry ?&  "."     table)
    (modify-syntax-entry ?|  "."     table)
    (modify-syntax-entry ?\' "\""    table)
    (modify-syntax-entry ?\240 "."   table)
    (modify-syntax-entry ?/  ". 124b" table)
    (modify-syntax-entry ?*  ". 23"   table)
    (modify-syntax-entry ?\n "> b"  table)
    (modify-syntax-entry ?\^m "> b" table)
    table)
  "Syntax table for `json5-ts-mode'.")

(defvar json5-ts--indent-rules
  `((json5
     ((node-is "}") parent-bol 0)
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((parent-is "object") parent-bol json5-ts-mode-indent-offset)
     ((parent-is "array") parent-bol json5-ts-mode-indent-offset))))

(defvar json5-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'json5
   :feature 'comment
   '((comment) @font-lock-comment-face)
   :language 'json5
   :feature 'bracket
   '((["[" "]" "{" "}"]) @font-lock-bracket-face)
   :language 'json5
   :feature 'constant
   '([(null) (true) (false)] @font-lock-constant-face)
   :language 'json5
   :feature 'delimiter
   '((["," ":"]) @font-lock-delimiter-face)
   :language 'json5
   :feature 'number
   '((number) @font-lock-number-face)
   :language 'json5
   :feature 'string
   '((string) @font-lock-string-face)
   :language 'json5
   :feature 'member
   :override t ; Needed for overriding string face on keys.
   '((member name: (_) @font-lock-property-use-face))
   :language 'json5
   :feature 'error
   :override t
   '((ERROR) @font-lock-warning-face))
  "Font-lock settings for JSON5.")

(defun json5-ts-mode--defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (pcase (treesit-node-type node)
    ((or "member" "object")
     (string-trim (treesit-node-text
                   (treesit-node-child-by-field-name
                    node "name")
                   t)
                  "\"" "\""))))

;;;###autoload
(define-derived-mode json5-ts-mode prog-mode "JSON5"
  "Major mode for editing JSON5, powered by tree-sitter."
  :group 'json5
  :syntax-table json5-ts-mode--syntax-table

  (unless (treesit-ready-p 'json5)
    (error "Tree-sitter for JSON5 isn't available"))

  (treesit-parser-create 'json5)

  ;; Comments.
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "\\(?://+\\|/\\*+\\)\\s *")
  (setq-local comment-end "")

  ;; Electric
  (setq-local electric-indent-chars
              (append "{}[]():;," electric-indent-chars))

  ;; Indent.
  (setq-local treesit-simple-indent-rules json5-ts--indent-rules)

  ;; Navigation.
  (setq-local treesit-defun-type-regexp
              (rx (or "member" "object")))
  (setq-local treesit-defun-name-function #'json5-ts-mode--defun-name)

  ;; Do not set `treesit-thing-settings' on Emacs 29 because it's available
  ;; only on Emacs 30+.
  (when (boundp 'treesit-thing-settings)
    (setq-local treesit-thing-settings
                `((json5
                   (sentence "member")))))

  ;; Font-lock.
  (setq-local treesit-font-lock-settings json5-ts-mode--font-lock-settings)
  (setq-local treesit-font-lock-feature-list
              '((comment constant number member string)
                ()
                (bracket delimiter error)))

  ;; Imenu.
  (setq-local treesit-simple-imenu-settings
              '((nil "\\`member\\'" nil nil)))

  (treesit-major-mode-setup))

(if (treesit-ready-p 'json5)
    (add-to-list 'auto-mode-alist
                 '("\\.json5\\'" . json5-ts-mode)))

(provide 'json5-ts-mode)

;;; json5-ts-mode.el ends here
