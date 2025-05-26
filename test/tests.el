;;; json5-ts-mode-tests.el --- Tests for json5-ts-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2025 ZHANG Weiyi

;; Author: ZHANG Weiyi <dochang@gmail.com>

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.

;; You should have received a copy of the GNU General Public License along with
;; this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Tests for json5-ts-mode

;;; Code:

(require 'ert)
(require 'ert-x)
(when (>= emacs-major-version 30)
  (require 'ert-font-lock))
(require 'treesit)

(progn
  (add-to-list 'treesit-language-source-alist
               '(json5
                 "https://github.com/Joakker/tree-sitter-json5"))
  ;; Install the grammar before loading the library, otherwise Emacs will
  ;; raise a warning.
  (or (treesit-ready-p 'json5 t)
      (treesit-install-language-grammar 'json5)
      (error "cannot install grammer of json5"))
  (require 'json5-ts-mode))

(ert-deftest json5-ts-test-indentation ()
  (skip-unless (treesit-ready-p 'json5 t))
  (ert-test-erts-file (ert-resource-file "indent.erts")))

(ert-deftest json5-ts-test-movement ()
  (skip-unless (treesit-ready-p 'json5 t))
  (ert-test-erts-file (ert-resource-file "movement.erts")))

(ert-deftest json5-ts-test-font-lock ()
  (skip-unless (and (treesit-ready-p 'json5 t)
                    (>= emacs-major-version 30)))
  (let ((treesit-font-lock-level 4))
    (ert-font-lock-test-file (ert-resource-file "font-lock.json5") 'json5-ts-mode)))

(provide 'json5-ts-mode-tests)

;;; json5-ts-mode-tests.el ends here
