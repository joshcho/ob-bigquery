(require 'ob-python)

(defvar ob-num-max-rows 50)
(defvar ob-fmt-string "from google.cloud import bigquery
client = bigquery.Client()
job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
query_job = client.query(
    \"\"\"
%s
\"\"\"
)
results = list(query_job.result())
%s = list(map(lambda row: list(map(lambda val: str(val) if val != '' else \"null\", row.values())), results))
%s[list(results[0].keys())] + %s[:%s]")

(defun ob-bigquery-ctrl-c-ctrl-c ()
  (interactive)
  (let* ((saved-pos (point))
         (begin-pos (re-search-backward "#\\+begin_src \\(sql\\).*\C-j"))
         (lang-pos (match-beginning 1))
         (begin-source-pos (match-end 0))
         (store-var-p (save-excursion (re-search-forward ":store \\([^\s\C-j]*\\)[\s\C-j]"
                                                         (save-excursion (end-of-line)
                                                                         (+ 1 (point)))
                                                         t)))
         (store-var (save-excursion (if (re-search-forward ":store \\([^\s\C-j]*\\)[\s\C-j]"
                                                           (save-excursion (end-of-line)
                                                                           (+ 1 (point)))
                                                           t)
                                        (substring-no-properties (match-string 1))
                                      "table")))
         (end-pos (re-search-forward "\C-j#\\+end_src"))
         (end-source-pos (match-beginning 0))
         (saved-source-block (buffer-substring-no-properties begin-source-pos end-source-pos))
         (saved-block (buffer-substring-no-properties begin-pos end-pos)))
    ;; replace sql block with python block
    (goto-char begin-source-pos)
    (delete-char (- end-source-pos begin-source-pos))
    (insert (format ob-fmt-string saved-source-block store-var
                    (if store-var-p ""
                      "return ")
                    store-var
                    ob-num-max-rows))
    ;; swap in python for lang, run, then swap sql back in
    (goto-char lang-pos)
    (delete-word 1)
    (insert "python")
    (when store-var-p
      (insert " :session "))
    (call-interactively 'org-ctrl-c-ctrl-c)
    (goto-char lang-pos)
    (delete-word 1)
    (insert "sql")
    (when store-var-p
      (delete-char (length " :session ")))
    ;; replace python block with sql block
    (goto-char begin-pos)
    (delete-char (- (save-excursion (re-search-forward "\C-j#\\+end_src"))
                    begin-pos))
    (insert saved-block)
    (goto-char saved-pos)
    ))
