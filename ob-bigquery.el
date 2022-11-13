(require 'ob-python)

;; hard cap for display
(defvar ob-max-num-rows 30)
(defvar ob-fmt-string "from google.cloud import bigquery
client = bigquery.Client()
job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
query_job = client.query(
    \"\"\"
%s
\"\"\"
)
results = []
for res in query_job.result():
    if len(results) > %s:
        break
    results += [res]
return [list(results[0].keys())] + list(map(lambda row: list(map(lambda val: val if val else \"null\", row.values())), results))")

(defun ob-bigquery-ctrl-c-ctrl-c ()
  (interactive)
  (let* ((saved-pos (point))
         (begin-pos (re-search-backward "#\\+begin_src \\(sql\\).*\C-j"))
         (lang-pos (match-beginning 1))
         (begin-source-pos (match-end 0))
         (end-pos (re-search-forward "\C-j#\\+end_src"))
         (end-source-pos (match-beginning 0))
         (saved-block (buffer-substring-no-properties begin-source-pos end-source-pos)))
    ;; replace sql block with python block
    (goto-char begin-source-pos)
    (delete-char (- end-source-pos begin-source-pos))
    (insert (format ob-fmt-string saved-block ob-max-num-rows))
    ;; swap in python for lang, run, then swap sql back in
    (goto-char lang-pos)
    (delete-word 1)
    (insert "python")
    (call-interactively 'org-ctrl-c-ctrl-c)
    (goto-char lang-pos)
    (delete-word 1)
    (insert "sql")
    ;; replace python block with sql block
    (goto-char begin-source-pos)
    (delete-char (- (save-excursion (re-search-forward "\C-j#\\+end_src")
                                    (match-beginning 0))
                    begin-source-pos))
    (insert saved-block)
    (goto-char saved-pos)))
