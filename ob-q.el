;;; ob-q.el --- A library to manage remote q sessions with Helm and q-mode  -*- lexical-binding: t; -*-

;; URL: https://github.com/emacs-q/ob-q.el
;; Package-Requires: ((emacs "26.1") (cl-lib "0.6") (org "9.3") (q-mode "0.1") (cl-lib "1.0"))

;;; Requirements:

;; ob-q requires the installation of program q and qcon, and additional q-mode.el for session support and optional helm-q.el
;; for a better session management interface.

;;; Commentary:

;; ob-q is an Emacs Lisp library to provide Org-Babel support for evaluating q source code within .org documents.

;;; Code:

;; The code is automatically generated by function `literate-elisp-tangle' from file `ob-q.org'.
;; It is not designed to be readable by a human.
;; It is generated to load by Emacs directly without depending on `literate-elisp'.
;; you should read file `ob-q.org' to find out the usage and implementation detail of this source file.


(require 'ob)
(require 'ob-ref)
(require 'ob-comint)
(require 'ob-eval)
(require 'q-mode)
(require 'helm-q)

(defvar org-babel-q-eoe "\"org-babel-q-eoe\"" "String to indicate that evaluation has completed.")

(add-to-list 'org-babel-tangle-lang-exts '("q" . "q"))

(defvar org-babel-default-header-args:q '())

(defun org-babel-expand-body:q (body params)
  "Expand BODY according to PARAMS, return the expanded body.
Argument BODY: the code body
Argument PARAMS: the input parameters."
  (require 'q-mode)
  (let ((vars (cdr (assoc :vars params))))
    (concat
     (mapconcat ;; define any variables
      (lambda (pair)
        (format "%s=%S" (car pair) (org-babel-q-var-to-q (cdr pair))))
      vars "\n")
     "\n" body "\n")))

(defun org-babel-execute:q (body params)
  "Execute a block of q code with org-babel.
This function is called by `org-babel-execute-src-block',
Argument BODY: the code body
Argument PARAMS: the input parameters."
  (let* (;; expand the body
         (full-body (org-babel-expand-body:q body params))
         (session-buffer (org-babel-prep-session:q params))
         (raw-results (if session-buffer
                          (org-babel-q-execute-in-session session-buffer full-body params)
                        (org-babel-q-execute-without-session full-body params))))
    (when raw-results
      (org-babel-transfer-results:q raw-results params))))

(defun org-babel-q-execute-without-session (full-body params)
  "Execute code body without a session.
Argument FULL-BODY: the expanded code body
Argument PARAMS: the input parameters."
  (let* ((stdin-file (org-babel-temp-file "q-stdin-")))
    (with-temp-file stdin-file
      (insert full-body))
    (with-temp-buffer
      (call-process-shell-command q-program stdin-file (current-buffer))
      (buffer-string))))

(defun org-babel-q-initiate-session (session)
  "If there is not a current inferior-process-buffer in `SESSION'
then create.  Return the initialized session buffer.
Argument SESSION: session argument."
  (cond ((null session)
         ;; try to use current `q-active-buffer'.
         (if (and q-active-buffer
                  (process-live-p (get-buffer-process q-active-buffer)))
             q-active-buffer
           (call-interactively 'helm-q)
           q-active-buffer))
        ((string= "none" session)
         nil)
        (t )))

(defun org-babel-prep-session:q (params)
  "Prepare SESSION according to the header arguments specified in PARAMS.
Arguments SESSION: the session name.
Arguments PARAMS: the input parameters."
  (let* ((session (cdr (assoc :session params)))
         (session-buffer (org-babel-q-initiate-session session)))
    session-buffer))

(defun org-babel-q-execute-in-session (session-buffer full-body params)
  "Execute code body in a session.
Argument SESSION-BUFFER: the session associated buffer.
Argument FULL-BODY: the expanded code body
Argument PARAMS: the input parameters."
  (let ((results-list
         (org-babel-comint-with-output
             (session-buffer org-babel-q-eoe t full-body)
           (dolist (code (list full-body org-babel-q-eoe))
             (insert (org-babel-chomp code))
             (comint-send-input nil t)))))
    (org-babel-q-remove-prompts-in-result session-buffer results-list)))

(defun org-babel-transfer-results:q (results params)
  "Convert raw results to Emacs Lisp Result.
This function is called by `org-babel-execute-src-block',
Argument RESULTS: the raw results.
Argument PARAMS: the input parameters."
  (let ((result-params (cdr (assq :result-params params))))
    (org-babel-result-cond result-params
      results
      (let ((tmp-file (org-babel-temp-file "q-")))
        (with-temp-file tmp-file (insert results))
        (org-babel-import-elisp-from-file tmp-file)))))

(defun org-babel-q-var-to-q (var)
  "Convert an var into q source code to specify it with the same value.
Argument VAR: a q varaible."
  (format "%S" var))

(defun org-babel-q-remove-prompts-in-result (session-buffer results-list)
  "Remove duplicated prompts in result.
Argument SESSION-BUFFER: the session associated buffer.
Argument RESULTS-LIST: the list of result string."
  (let ((prompt-regexp-to-remove (with-current-buffer session-buffer
                                   comint-prompt-regexp)))
    (with-output-to-string
      (cl-loop for text in results-list
               until (string-match org-babel-q-eoe text)
               do (while (string-match prompt-regexp-to-remove text)
                    (setf text (replace-match "" nil nil text)))
               (princ text)))))


(provide 'ob-q)
;;; ob-q.el ends here
