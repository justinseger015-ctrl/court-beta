Yes. Show JSON as key/value with a collapsible “Details” panel.

Below is a Copilot-ready, stepwise build plan. Use docketwatch.dbo everywhere.

# 1) Purpose

Create a standalone DocketWatch page where a user drags a PDF to get:

* OCR text
* Two-step verified summary
* Optional “extra instructions” input
* QC notes box + Success/Fail toggle
* Collapsible JSON fields view

# 2) DB changes

a) QC feedback table

```sql
CREATE TABLE docketwatch.dbo.summary_qc_feedback (
  id            INT IDENTITY(1,1) PRIMARY KEY,
  doc_uid       UNIQUEIDENTIFIER NULL,    -- if we store the upload as a document
  upload_sha256 CHAR(64) NULL,            -- for de-dup on ad-hoc uploads
  user_name     NVARCHAR(100) NULL,
  success       BIT NOT NULL,
  notes         NVARCHAR(MAX) NULL,
  model_name    NVARCHAR(50) NULL,
  created_at    DATETIME2(7) DEFAULT SYSUTCDATETIME()
);
```

b) Optional: persist upload as a row in `documents` with fk_case NULL so you can reuse downstream tools (fields exist and fit) .

c) Reuse `gemini_api_log` for cost/latency/error logging from this flow (insert one row per model call). Fields already exist: script_name, model_name, input/output tokens, success, error_message, processing_time_ms, cost_estimate, etc. 

# 3) URL and page

* New CFML page: `/tools/summarize_upload.cfm`
* New CFML handler for upload+process: `/ajax/upload_and_summarize.cfm`
* Optional Python microservice: call `summarize_document_event.py` from CF via `cfexecute` or HTTP (keeps Python OCR libs isolated).

# 4) Frontend spec (no external libs)

HTML skeleton:

```html
<!-- /tools/summarize_upload.cfm -->
<div id="uploader" class="dz">
  <p>Drag PDF here or click to select</p>
  <input id="file" type="file" accept="application/pdf" hidden>
</div>

<label>Extra instructions (optional)</label>
<textarea id="extra" rows="4"></textarea>

<button id="run">Summarize</button>

<!-- Results -->
<div id="result" class="hidden">
  <h3>Summary</h3>
  <pre id="summary"></pre>

  <h3>OCR</h3>
  <pre id="ocr"></pre>

  <details id="jsonPanel">
    <summary>Details (JSON fields)</summary>
    <pre id="json"></pre>
  </details>

  <div id="qc">
    <label><input type="checkbox" id="success"> Summary correct</label>
    <label>Notes</label>
    <textarea id="notes" rows="4" placeholder="What was wrong or missing?"></textarea>
    <button id="saveQc">Save QC</button>
  </div>
</div>

<style>
  .dz { border:2px dashed #888; padding:24px; cursor:pointer; text-align:center; }
  .hidden { display:none; }
  pre { white-space:pre-wrap; word-wrap:break-word; }
</style>
```

JS behavior:

```html
<script>
const dz = document.getElementById('uploader');
const fileInput = document.getElementById('file');
const runBtn = document.getElementById('run');

dz.addEventListener('click',()=>fileInput.click());
dz.addEventListener('dragover', e => { e.preventDefault(); dz.style.borderColor='#000'; });
dz.addEventListener('dragleave', ()=> dz.style.borderColor='#888');
dz.addEventListener('drop', e => {
  e.preventDefault();
  fileInput.files = e.dataTransfer.files;
  dz.style.borderColor='#888';
});

runBtn.onclick = async () => {
  const f = fileInput.files[0];
  if (!f) { alert('Select a PDF'); return; }
  const body = new FormData();
  body.append('file', f);
  body.append('extra', document.getElementById('extra').value || '');

  const r = await fetch('/ajax/upload_and_summarize.cfm', { method:'POST', body });
  const data = await r.json(); // see API contract below

  document.getElementById('result').classList.remove('hidden');
  document.getElementById('summary').textContent = data.summary_text || '';
  document.getElementById('ocr').textContent = data.ocr_text || '';
  document.getElementById('json').textContent = JSON.stringify(data, null, 2);

  // QC save
  document.getElementById('saveQc').onclick = async () => {
    const payload = {
      doc_uid: data.doc_uid || null,
      upload_sha256: data.upload_sha256 || null,
      success: document.getElementById('success').checked,
      notes: document.getElementById('notes').value || '',
      model_name: data.model_name || ''
    };
    await fetch('/ajax/save_qc_feedback.cfm', {
      method:'POST',
      headers:{ 'Content-Type':'application/json' },
      body: JSON.stringify(payload)
    });
    alert('Saved');
  };
};
</script>
```

# 5) AJAX: upload_and_summarize.cfm

Responsibilities:

* Accept PDF (multipart).
* Compute SHA-256 for de-dup.
* Call Python worker or inline CF OCR if you must.
* Two-step summarize (extract → verify) using your standard pipeline.
* Insert `gemini_api_log` rows for each LLM call.
* Optionally insert a `documents` row with fk_case NULL; store OCR and summaries back into that row.

CFML outline:

```cfm
<cftry>
  <cfset scriptName = "summarize_upload">
  <cfset uploadDir = "U:/docketwatch/uploads/"> <!-- adjust -->
  <cffile action="upload" filefield="file" destination="#uploadDir#" nameConflict="makeunique">
  <cfset savedPath = cffile.serverFile>
  <cfset absPath   = uploadDir & savedPath>

  <!-- hash -->
  <cfset sha = hash( fileReadBinary(absPath), "SHA-256" )>

  <!-- optional: dedupe by sha -->

  <!-- Call Python worker -->
  <cfexecute name="C:\Python39\python.exe"
             arguments="U:\docketwatch\python\summarize_document_event.py --in ""#absPath#"" --extra ""#urlEncodedFormat(form.extra)#"""
             timeout="1200" variable="pyOut"></cfexecute>

  <!-- Expect JSON back -->
  <cfset data = deserializeJSON(pyOut)>

  <!-- Optionally persist into documents -->
  <!-- INSERT documents (doc_uid, rel_path, ocr_text, summary_ai, summary_ai_html, ai_processed_at, status, error_message) -->
  <!-- Use docketwatch.dbo.documents schema. -->

  <!-- Return merged response -->
  <cfset data.upload_sha256 = sha>
  <cfcontent type="application/json" reset="true"><cfoutput>#serializeJSON(data)#</cfoutput>

  <cfcatch>
    <cfheader statuscode="500" statustext="Error">
    <cfoutput>{"error":"#replace(cfcatch.message,'"','""','all')#"}#chr(10)#</cfoutput>
  </cfcatch>
</cftry>
```

# 6) Python worker: summarize_document_event.py

Adapt the uploaded script to support CLI args `--in` and `--extra`. Pipeline:

1. Load PDF. If text layer exists, extract text; else run OCR at 300 DPI with preprocessing (deskew, binarize) to improve accuracy (see OCR tuning guidance)  .

2. Two-step LLM:

* Step A (extract): structured fields from the doc (date, court, parties, charges, dispositions, orders, amounts).
* Step B (verify/rewrite): produce newsroom-safe summary that cites those extracted fields. Reject hallucinations if fields missing. Log both calls in `gemini_api_log` (success, tokens, cost) .

3. Build response JSON:

```json
{
  "doc_uid": "GUID-or-null",
  "model_name": "gemini-2.5-flash",
  "summary_text": "string",
  "summary_html": "<p>...</p>",
  "ocr_text": "string",
  "fields": {
    "document_type": "Judgment",
    "file_date": "2025-10-16",
    "case_number": "…",
    "court": "…",
    "parties": ["…"],
    "counts": [{"count":3,"statute":"18 USC 2421(a)","disposition":"guilty"}],
    "sentence": {"prison_months":50, "supervised_release_months":60}
  },
  "errors": [],
  "processing_ms": 12345
}
```

CLI sketch:

```py
import argparse, json, time, hashlib, fitz  # PyMuPDF for text layer
from ocr_utils import ocr_pdf_clean_300dpi   # implement preprocessing per guide
from gemini_utils import two_step_summarize, log_gemini  # wraps API + gemini_api_log inserts

ap = argparse.ArgumentParser()
ap.add_argument("--in", dest="infile", required=True)
ap.add_argument("--extra", default="")
args = ap.parse_args()

t0 = time.time()
text = extract_text_or_ocr(args.infile)  # prefer embedded text, else OCR; do cleanup
summary, fields, html = two_step_summarize(text, extra=args.extra)  # model: 2.5-pro

out = dict(
  doc_uid=None, model_name="gemini-2.5-flash",
  summary_text=summary, summary_html=html,
  ocr_text=text, fields=fields, errors=[], processing_ms=int((time.time()-t0)*1000)
)

print(json.dumps(out, ensure_ascii=False))
```

Note: For OCR preprocessing use grayscale, denoise, Otsu, deskew at 300 DPI as recommended to raise accuracy on court scans  .

# 7) API contract (upload_and_summarize.cfm → client)

* Request: `multipart/form-data` with:

  * `file`: PDF
  * `extra`: string (optional)
* Response: JSON payload exactly as in section 6. Include `upload_sha256` added by CF.

# 8) QC save endpoint

`/ajax/save_qc_feedback.cfm`

```cfm
<cfset body = toString(getHttpRequestData().content)>
<cfset p = deserializeJSON(body)>

<cfquery datasource="docketwatch">
INSERT INTO docketwatch.dbo.summary_qc_feedback
(doc_uid, upload_sha256, user_name, success, notes, model_name)
VALUES (<cfqueryparam cfsqltype="cf_sql_varchar" value="#p.doc_uid#">,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#p.upload_sha256#">,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_user#">,
        <cfqueryparam cfsqltype="cf_sql_bit" value="#p.success#">,
        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#p.notes#">,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#p.model_name#">)
</cfquery>
{"ok":true}
```

# 9) Two-step summarize rules (Copilot prompt block)

* Model: gemini-2.5-flash for verify step, gemini-1.5/2.5-flash for extract if cost-sensitive.
* Temperature 0.6. Max tokens ~1000. Use domain guardrails.
* Step A output must be strict JSON with fields listed in section 6.
* Step B must cite only Step A fields. If a field is missing, say “not specified in the document.” No guesses. If conflicts found, prefer exact text quotes from OCR with page/line indices.
* If `extra` exists, apply as constraints, never as facts.

# 10) Logging and telemetry

* On each LLM call, write to `gemini_api_log` with script_name = 'summarize_upload' and model_name used. Capture tokens, success, processing_time_ms, error_message on failure .
* Optionally expose a quick admin view via `v_gemini_daily_usage` for monitoring .

# 11) JSON field viewer

* Use `<details>` as above.
* For a cleaner view later, render a table of key/value from `fields`. Keep raw JSON in `<pre>` for copy.

# 12) Optional: persist document

* If you want the upload available elsewhere, create a `documents` row with:

  * `fk_case` = NULL
  * `rel_path` = `cases\0\uploads\<filename>.pdf` or a dedicated uploads path
  * `ocr_text`, `summary_ai`, `summary_ai_html`, `ai_processed_at` now
* This aligns with the unified `documents` table used across the app   .

# 13) OCR quality notes for Copilot

* Prefer embedded text layer; OCR only missing pages.
* If OCR is needed: 300 DPI, grayscale, denoise, Otsu, deskew, then Tesseract with `--psm 6`. These steps materially improve legal-PDF accuracy  .

# 14) Security

* Validate PDF mime and magic bytes.
* Size cap (e.g., 25 MB).
* Strip EXIF/JS from PDFs or rasterize first if needed.
* Store uploads outside webroot; serve through secured handler.

# 15) Test cases

* Native text PDF vs scanned image PDF.
* 1-page vs multi-page.
* Bad scan with skew.
* Extra instructions present vs absent.
* Force a failure in Step A JSON to confirm error path, logging, and UI still returns OCR.

# 16) Deliverables to generate

* `/tools/summarize_upload.cfm` (HTML+JS above).
* `/ajax/upload_and_summarize.cfm` (CFML stub above).
* `/ajax/save_qc_feedback.cfm` (CFML stub above).
* Python updates to `summarize_document_event.py` per section 6.
* SQL for `summary_qc_feedback`.

This is minimal surface area, uses existing tables for telemetry, and keeps the two-step pipeline consistent with the rest of DocketWatch.
