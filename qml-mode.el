;;; qml-mode.el --- Major mode for editing Qt QML files

;; Copyright (C) 2010 William Xu

;; Author: William Xu <william.xwl@gmail.com>
;; Version: 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
;; MA 02110-1301, USA.

;;; Commentary:

;; This is a simple major mode for editing Qt QML files.

;; Put this file into your load-path and the following into your
;; ~/.emacs:
;;           (autoload 'qml-mode "qml-mode")
;;           (add-to-list 'auto-mode-alist '("\\.qml$" . qml-mode))

;;; Code:

(require 'css-mode)
(require 'js)
(require 'cc-mode)

(defvar qml-import-regexp "^import "
  "Regular expression for finding import statements.")

(defvar qml-keywords
  (concat "\\<" (regexp-opt '("import")) "\\>\\|" js--keyword-re))

(defvar qml-font-lock-keywords
  `(("\\<\\(true\\|false\\|[A-Z][a-zA-Z0-9]*\\.[A-Z][a-zA-Z0-9]*\\)\\>" ; constants
     (0 font-lock-constant-face))
    ("\\<\\([A-Z][a-zA-Z0-9]*\\)\\>"    ; Elements
     (1 font-lock-function-name-face nil t)
     (2 font-lock-function-name-face nil t))
    (,(concat qml-keywords "\\|\\<parent\\>") ; keywords
     (0 font-lock-keyword-face nil t))
    ("\\<\\([a-z][a-zA-Z.]*\\|property .+\\):\\|\\<\\(anchors\\|font\\|origin\\|axis\\)\\>" ; property
     (1 font-lock-variable-name-face nil t)
     (2 font-lock-variable-name-face nil t))
    ("\\<function +\\([a-z][a-zA-Z0-9]*\\)\\>" ; method
     (1 font-lock-function-name-face)))
  "Keywords to highlight in `qml-mode'.")

(defvar qml-mode-syntax-table
  (let ((table (make-syntax-table)))
    (c-populate-syntax-table table)
    table))

;;;###autoload
(define-derived-mode qml-mode css-mode "QML"
  "Major mode for editing Qt QML files.
\\{qml-mode-map}"
  :syntax-table qml-mode-syntax-table
  (setq font-lock-defaults '(qml-font-lock-keywords))
  (set (make-local-variable 'comment-start) "/* ")
  (set (make-local-variable 'comment-end) " */")
  (hs-minor-mode t)
  (run-hooks 'qml-mode-hook))

(define-key qml-mode-map "\M-\C-a" 'qml-beginning-of-defun)
(define-key qml-mode-map "\M-\C-e" 'qml-end-of-defun)
(define-key qml-mode-map "\M-\C-h" 'qml-mark-defun)

(define-key qml-mode-map (kbd "C-M-q") 'qml-indent-exp)
(define-key qml-mode-map (kbd "}") 'qml-indent-close-bracket)

(defconst qml-defun-start-regexp "\{")

(defconst qml-defun-end-regexp "\}")

  ;; Methods dealing with editing entire elements
(defun qml-beginning-of-defun ()
  "Set the pointer at the beginning of the element within which the pointer is
located."
  (interactive)
  (re-search-backward qml-defun-start-regexp)
  (forward-char 1))

(defun qml-end-of-defun ()
  "Set the pointer at the beginning of the element within which the pointer is located."
  (interactive)
  (re-search-forward qml-defun-end-regexp))

(defun qml-mark-defun ()
  "Set the region pointer around element within which the pointer is located."
  (interactive)
  (beginning-of-line)
  (qml-end-of-defun)
  (set-mark (point))
  (qml-beginning-of-defun))

(defun qml-indent-exp ()
  "Properly indents the contents of the element within which the pointer is
currently located."
  (interactive)
  (indent-region (point) (save-excursion (forward-list) (point))))



(defun qml-indent-close-bracket ()
  "Properly indents inputted closing brackets (aligns closing bracket with
element name)."
  (interactive)
  (insert "}")
  (indent-for-tab-command))



  ;; Methods dealing with import statements, borrowed heavily from java-import
  ;; -- and, by extention, javadoc-lookup -- by Christopher Wellons
(defun qml-has-import ()
  "Return t if this source has at least one import statement."
  (save-excursion
    (goto-char (point-min))
    (and (search-forward-regexp qml-import-regexp nil t) t)))

(defun qml-goto-first-import ()
  "Move cursor to the first import statement."
  (goto-char (point-min))
  (search-forward-regexp qml-import-regexp)
  (move-beginning-of-line nil)
  (point))

(defun qml-goto-last-import ()
  "Move cursor to the first import statement."
  (goto-char (point-max))
  (search-backward-regexp qml-import-regexp)
  (move-end-of-line nil)
  (forward-char)
  (point))

;;;###autoload
(defun qml-sort-imports ()
  "Sort the imports in the import section in proper order."
  (interactive)
  (when (qml-has-import)
    (save-excursion
      (sort-lines
        nil
	(qml-goto-first-import)
	(qml-goto-last-import)))))

(defun qml-add-import (class)
  "Insert an import statement at import section at the top of the file."
  (interactive "sClass name: ")
  (save-excursion
    (if (qml-has-import)
	(progn
	  (qml-goto-first-import)
	  (insert "import " class "\n")
	  (qml-sort-imports))
      (progn
	(goto-char (point-min))
	(insert "import " class "\n\n")))))

(provide 'qml-mode)

;;; qml-mode.el ends here
