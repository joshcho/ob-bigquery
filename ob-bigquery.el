(require 'ob-python)
;; follow instructions on https://cloud.google.com/bigquery/docs/quickstarts/quickstart-client-libraries to set up bigquery for python

;; run this function within org babel code block with sql (it will replace sql and run associated python). note that this calls list on the output, so make sure to add LIMIT to your queries.
(defun org-babel-bigquery-ctrl-c-ctrl-c ()
  (interactive)
  (let ((saved-pos (point)))
    (search-backward-regexp "#\\+begin_src sql.*\C-j")
    (let* ((begin-pos (match-end 0))
           (end-pos (save-excursion (re-search-forward "#\\+end_src")
                                    (- (match-beginning 0) 1)))
           (saved-block (buffer-substring-no-properties begin-pos end-pos))
           (fmt-string "from google.cloud import bigquery
client = bigquery.Client()
job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
query_job = client.query(
    \"\"\"
%s
\"\"\"
)
results = list(query_job.result())
return [list(results[0].keys())] + list(map(lambda row: list(row.values()), results))"))
      (goto-char begin-pos)
      (delete-char (- end-pos begin-pos))
      (insert (format fmt-string saved-block))
      (cl-labels ((replace-lang (from to)
                    (progn
                      (search-backward-regexp (concat "#\\+begin_src " from))
                      (goto-char (match-end 0))
                      (backward-delete-word 1)
                      (insert to))))
        (replace-lang "sql" "python")
        (call-interactively 'org-ctrl-c-ctrl-c)
        (replace-lang "python" "sql"))
      (goto-char begin-pos)
      (let ((new-end-pos (save-excursion (re-search-forward "#\\+end_src")
                                         (- (match-beginning 0) 1))))
        (delete-char (- new-end-pos begin-pos)))
      (insert saved-block)
      (goto-char saved-pos))))
(define-key org-mode-map (kbd "C-c C-e") #'org-babel-bigquery-ctrl-c-ctrl-c)
