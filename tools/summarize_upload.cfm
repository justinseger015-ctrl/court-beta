<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Summary Upload Tool - DocketWatch</title>
    
    <!--- Bootstrap 5 CSS --->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!--- Font Awesome --->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
    
    <!--- jQuery --->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    
    <!--- Bootstrap 5 JS --->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</head>
<body>

<!--- Simple Navigation Bar --->
<nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-sm">
    <div class="container-fluid">
        <a class="navbar-brand fw-bold" href="../index.cfm">
            <i class="fas fa-gavel me-2 text-warning"></i>DocketWatch
        </a>
        <span class="navbar-text text-light">
            <i class="fas fa-file-upload me-2"></i>AI Summary Upload Tool
        </span>
    </div>
</nav>

<div class="container-fluid mt-4">
    <div class="row">
        <div class="col-12">
            <h1 class="mb-4"><i class="fas fa-file-upload me-2"></i>AI Summary Upload Tool</h1>
            <p class="text-muted">Upload a PDF document to generate an AI-powered legal summary with structured fields and QC feedback.</p>
        </div>
    </div>

    <div class="row mt-4">
        <div class="col-lg-6">
            <div class="card mb-4">
                <div class="card-header">
                    <h5 class="mb-0">1. Upload Document</h5>
                </div>
                <div class="card-body">
                    <div id="uploader" class="upload-zone">
                        <i class="fas fa-cloud-upload-alt fa-3x mb-3 text-muted"></i>
                        <p class="mb-2"><strong>Drag PDF here or click to select</strong></p>
                        <p class="text-muted small">Maximum file size: 25 MB</p>
                        <input id="file" type="file" accept="application/pdf" hidden>
                    </div>
                    <div id="fileInfo" class="mt-3 d-none">
                        <div class="alert alert-info mb-0">
                            <i class="fas fa-file-pdf me-2"></i>
                            <strong id="fileName"></strong>
                            <span id="fileSize" class="ms-2 text-muted"></span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0">2. Optional Instructions</h5>
                </div>
                <div class="card-body">
                    <label for="extra" class="form-label">Extra instructions (optional)</label>
                    <textarea id="extra" class="form-control" rows="4" placeholder="Add any specific instructions for the AI summarization (e.g., 'Focus on sentencing details' or 'Highlight any financial terms')"></textarea>
                    <button id="run" class="btn btn-primary btn-lg w-100 mt-3" disabled>
                        <i class="fas fa-brain me-2"></i>Generate AI Summary
                    </button>
                </div>
            </div>
        </div>

        <div class="col-lg-6">
            <div id="processingStatus" class="d-none">
                <div class="card">
                    <div class="card-body text-center py-5">
                        <div class="spinner-border text-primary mb-3" role="status" style="width: 3rem; height: 3rem;">
                            <span class="visually-hidden">Processing...</span>
                        </div>
                        <h5>Processing Document...</h5>
                        <p class="text-muted">This may take 30-60 seconds for OCR and AI analysis</p>
                    </div>
                </div>
            </div>

            <div id="result" class="d-none">
                <div class="card mb-4">
                    <div class="card-header bg-success text-white">
                        <h5 class="mb-0"><i class="fas fa-check-circle me-2"></i>AI Summary Generated</h5>
                    </div>
                    <div class="card-body">
                        <h6 class="text-uppercase text-muted small mb-2">Summary</h6>
                        <div id="summary" class="summary-content"></div>
                        
                        <hr class="my-4">
                        
                        <h6 class="text-uppercase text-muted small mb-2">OCR Text</h6>
                        <div class="ocr-preview">
                            <pre id="ocr" class="ocr-text"></pre>
                        </div>

                        <hr class="my-4">

                        <details id="jsonPanel">
                            <summary class="cursor-pointer user-select-none">
                                <strong><i class="fas fa-code me-2"></i>Details (JSON Fields)</strong>
                            </summary>
                            <div class="mt-3">
                                <div id="fieldsTable"></div>
                                <h6 class="text-uppercase text-muted small mb-2 mt-4">Raw JSON</h6>
                                <pre id="json" class="json-preview"></pre>
                            </div>
                        </details>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0"><i class="fas fa-clipboard-check me-2"></i>Quality Control Feedback</h5>
                    </div>
                    <div class="card-body">
                        <div class="form-check form-switch mb-3">
                            <input class="form-check-input" type="checkbox" id="success" role="switch">
                            <label class="form-check-label" for="success">
                                <strong>Summary is correct and complete</strong>
                            </label>
                        </div>
                        
                        <label for="notes" class="form-label">QC Notes</label>
                        <textarea id="notes" class="form-control" rows="4" placeholder="What was wrong or missing? Any hallucinations or inaccuracies?"></textarea>
                        
                        <button id="saveQc" class="btn btn-success w-100 mt-3">
                            <i class="fas fa-save me-2"></i>Save QC Feedback
                        </button>
                        
                        <div id="qcStatus" class="mt-3 d-none"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
.upload-zone {
    border: 2px dashed #888;
    padding: 48px 24px;
    cursor: pointer;
    text-align: center;
    border-radius: 8px;
    transition: all 0.3s ease;
    background-color: #f8f9fa;
}

.upload-zone:hover {
    border-color: #0d6efd;
    background-color: #e7f1ff;
}

.upload-zone.dragover {
    border-color: #000;
    background-color: #d0e7ff;
}

.summary-content {
    white-space: pre-wrap;
    word-wrap: break-word;
    line-height: 1.6;
}

.ocr-preview {
    max-height: 300px;
    overflow-y: auto;
    background-color: #f8f9fa;
    border-radius: 4px;
    padding: 12px;
}

.ocr-text {
    white-space: pre-wrap;
    word-wrap: break-word;
    font-family: 'Courier New', monospace;
    font-size: 0.85rem;
    margin-bottom: 0;
}

.json-preview {
    white-space: pre-wrap;
    word-wrap: break-word;
    background-color: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 4px;
    padding: 12px;
    font-family: 'Courier New', monospace;
    font-size: 0.85rem;
    max-height: 400px;
    overflow-y: auto;
}

details summary {
    cursor: pointer;
    user-select: none;
    padding: 12px;
    background-color: #f8f9fa;
    border-radius: 4px;
    margin-bottom: 8px;
}

details summary:hover {
    background-color: #e9ecef;
}

.fields-table {
    width: 100%;
    font-size: 0.9rem;
}

.fields-table th {
    background-color: #f8f9fa;
    padding: 8px;
    text-align: left;
    border-bottom: 2px solid #dee2e6;
}

.fields-table td {
    padding: 8px;
    border-bottom: 1px solid #dee2e6;
}

.fields-table tr:last-child td {
    border-bottom: none;
}
</style>

<script>
let currentData = null;

const dz = document.getElementById('uploader');
const fileInput = document.getElementById('file');
const runBtn = document.getElementById('run');
const fileInfo = document.getElementById('fileInfo');
const fileName = document.getElementById('fileName');
const fileSize = document.getElementById('fileSize');

// File selection handling
fileInput.addEventListener('change', () => {
    if (fileInput.files.length > 0) {
        updateFileInfo(fileInput.files[0]);
    }
});

dz.addEventListener('click', () => fileInput.click());

dz.addEventListener('dragover', e => {
    e.preventDefault();
    dz.classList.add('dragover');
});

dz.addEventListener('dragleave', () => {
    dz.classList.remove('dragover');
});

dz.addEventListener('drop', e => {
    e.preventDefault();
    dz.classList.remove('dragover');
    fileInput.files = e.dataTransfer.files;
    if (fileInput.files.length > 0) {
        updateFileInfo(fileInput.files[0]);
    }
});

function updateFileInfo(file) {
    const sizeMB = (file.size / (1024 * 1024)).toFixed(2);
    fileName.textContent = file.name;
    fileSize.textContent = `(${sizeMB} MB)`;
    fileInfo.classList.remove('d-none');
    runBtn.disabled = false;
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

// Main processing
runBtn.onclick = async () => {
    const f = fileInput.files[0];
    if (!f) {
        alert('Please select a PDF file');
        return;
    }

    // Validate file size (25 MB limit)
    if (f.size > 25 * 1024 * 1024) {
        alert('File size exceeds 25 MB limit');
        return;
    }

    // Hide results, show processing
    document.getElementById('result').classList.add('d-none');
    document.getElementById('processingStatus').classList.remove('d-none');
    runBtn.disabled = true;

    const body = new FormData();
    body.append('file', f);
    body.append('extra', document.getElementById('extra').value || '');

    try {
        const r = await fetch('/court-beta/ajax/upload_and_summarize.cfm?bypass=1', { method: 'POST', body });
        const data = await r.json();

        if (data.error) {
            throw new Error(data.error);
        }

        currentData = data;

        // Hide processing, show results
        document.getElementById('processingStatus').classList.add('d-none');
        document.getElementById('result').classList.remove('d-none');

        // Populate summary (handle HTML or plain text)
        const summaryEl = document.getElementById('summary');
        if (data.summary_html && data.summary_html.trim().startsWith('<')) {
            summaryEl.innerHTML = data.summary_html;
        } else {
            summaryEl.textContent = data.summary_text || data.summary_html || 'No summary available';
        }

        // Populate OCR text
        document.getElementById('ocr').textContent = data.ocr_text || 'No OCR text available';

        // Populate JSON
        document.getElementById('json').textContent = JSON.stringify(data, null, 2);

        // Build fields table if fields exist
        if (data.fields && typeof data.fields === 'object') {
            buildFieldsTable(data.fields);
        }

        // Reset QC form
        document.getElementById('success').checked = false;
        document.getElementById('notes').value = '';
        document.getElementById('qcStatus').classList.add('d-none');

    } catch (err) {
        document.getElementById('processingStatus').classList.add('d-none');
        alert('Error processing document: ' + err.message);
        runBtn.disabled = false;
    }
};

function buildFieldsTable(fields) {
    const container = document.getElementById('fieldsTable');
    let html = '<table class="fields-table"><thead><tr><th>Field</th><th>Value</th></tr></thead><tbody>';
    
    for (const [key, value] of Object.entries(fields)) {
        let displayValue;
        if (typeof value === 'object' && value !== null) {
            displayValue = JSON.stringify(value, null, 2);
        } else if (Array.isArray(value)) {
            displayValue = value.join(', ');
        } else {
            displayValue = value;
        }
        
        html += `<tr><td><strong>${escapeHtml(key)}</strong></td><td>${escapeHtml(String(displayValue))}</td></tr>`;
    }
    
    html += '</tbody></table>';
    container.innerHTML = html;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// QC save
document.getElementById('saveQc').onclick = async () => {
    if (!currentData) {
        alert('No summary data to save feedback for');
        return;
    }

    const payload = {
        doc_uid: currentData.doc_uid || null,
        upload_sha256: currentData.upload_sha256 || null,
        success: document.getElementById('success').checked,
        notes: document.getElementById('notes').value || '',
        model_name: currentData.model_name || ''
    };

    try {
        const r = await fetch('/court-beta/ajax/save_qc_feedback.cfm', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const result = await r.json();

        if (result.ok) {
            const statusEl = document.getElementById('qcStatus');
            statusEl.className = 'mt-3 alert alert-success';
            statusEl.innerHTML = '<i class="fas fa-check-circle me-2"></i>QC feedback saved successfully!';
            statusEl.classList.remove('d-none');
        } else {
            throw new Error(result.error || 'Failed to save feedback');
        }
    } catch (err) {
        const statusEl = document.getElementById('qcStatus');
        statusEl.className = 'mt-3 alert alert-danger';
        statusEl.innerHTML = '<i class="fas fa-exclamation-circle me-2"></i>Error: ' + err.message;
        statusEl.classList.remove('d-none');
    }
};
</script>

</body>
</html>
