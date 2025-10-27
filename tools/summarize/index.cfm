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
        <a class="navbar-brand fw-bold" href="/court-beta/index.cfm">
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
                    <div class="card-header bg-primary text-white">
                        <h5 class="mb-0"><i class="fas fa-cog fa-spin me-2"></i>Processing Document</h5>
                    </div>
                    <div class="card-body">
                        <p class="text-muted mb-4">Estimated time: 30-60 seconds</p>
                        
                        <!-- Stage 1: OCR -->
                        <div class="progress-stage" id="stage-ocr">
                            <div class="stage-header">
                                <div class="stage-icon">
                                    <i class="fas fa-file-pdf"></i>
                                </div>
                                <div class="stage-info">
                                    <h6 class="mb-0">OCR Text Extraction</h6>
                                    <small class="text-muted">Reading document content...</small>
                                </div>
                                <div class="stage-status">
                                    <div class="spinner-border spinner-border-sm text-primary" role="status">
                                        <span class="visually-hidden">Processing...</span>
                                    </div>
                                </div>
                            </div>
                            <div class="progress mt-2">
                                <div class="progress-bar progress-bar-striped progress-bar-animated" style="width: 0%"></div>
                            </div>
                        </div>

                        <!-- Stage 2: Extraction -->
                        <div class="progress-stage" id="stage-extraction">
                            <div class="stage-header">
                                <div class="stage-icon">
                                    <i class="fas fa-search"></i>
                                </div>
                                <div class="stage-info">
                                    <h6 class="mb-0">AI Field Extraction</h6>
                                    <small class="text-muted">Identifying key information...</small>
                                </div>
                                <div class="stage-status">
                                    <i class="fas fa-clock text-muted"></i>
                                </div>
                            </div>
                            <div class="progress mt-2">
                                <div class="progress-bar progress-bar-striped progress-bar-animated" style="width: 0%"></div>
                            </div>
                        </div>

                        <!-- Stage 3: Summary -->
                        <div class="progress-stage" id="stage-summary">
                            <div class="stage-header">
                                <div class="stage-icon">
                                    <i class="fas fa-brain"></i>
                                </div>
                                <div class="stage-info">
                                    <h6 class="mb-0">Summary Generation</h6>
                                    <small class="text-muted">Creating readable summary...</small>
                                </div>
                                <div class="stage-status">
                                    <i class="fas fa-clock text-muted"></i>
                                </div>
                            </div>
                            <div class="progress mt-2">
                                <div class="progress-bar progress-bar-striped progress-bar-animated" style="width: 0%"></div>
                            </div>
                        </div>

                        <!-- Stage 4: Verification -->
                        <div class="progress-stage" id="stage-verification">
                            <div class="stage-header">
                                <div class="stage-icon">
                                    <i class="fas fa-shield-alt"></i>
                                </div>
                                <div class="stage-info">
                                    <h6 class="mb-0">FACT_GUARD Verification</h6>
                                    <small class="text-muted">Validating accuracy...</small>
                                </div>
                                <div class="stage-status">
                                    <i class="fas fa-clock text-muted"></i>
                                </div>
                            </div>
                            <div class="progress mt-2">
                                <div class="progress-bar progress-bar-striped progress-bar-animated" style="width: 0%"></div>
                            </div>
                        </div>

                        <div class="mt-3 text-center">
                            <small class="text-muted"><i class="fas fa-info-circle me-1"></i>Processing stages run sequentially for accuracy</small>
                        </div>
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

                        <details id="detailsPanel" open>
                            <summary class="cursor-pointer user-select-none">
                                <strong><i class="fas fa-info-circle me-2"></i>Structured Details</strong>
                            </summary>
                            <div class="mt-3">
                                <div id="structuredDetails"></div>
                            </div>
                        </details>

                        <details id="technicalPanel" class="mt-3">
                            <summary class="cursor-pointer user-select-none">
                                <strong><i class="fas fa-code me-2"></i>Technical Data (For Debugging)</strong>
                            </summary>
                            <div class="mt-3">
                                <div id="verificationInfo" class="mb-3"></div>
                                <h6 class="text-uppercase text-muted small mb-2">Processing Metadata</h6>
                                <div id="metadataInfo" class="metadata-box mb-3"></div>
                                <h6 class="text-uppercase text-muted small mb-2">Raw JSON Response</h6>
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

<!--- Error Modal --->
<div class="modal fade" id="errorModal" tabindex="-1" aria-labelledby="errorModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header bg-danger text-white">
                <h5 class="modal-title" id="errorModalLabel">
                    <i class="fas fa-exclamation-circle me-2"></i>Error
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="errorModalBody">
                An error occurred.
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" id="retryButton" style="display: none;">
                    <i class="fas fa-redo me-2"></i>Try Again
                </button>
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

.summary-section {
    margin-bottom: 1.5rem;
}

.summary-heading {
    font-size: 1rem;
    font-weight: 600;
    text-transform: uppercase;
    color: #495057;
    margin-bottom: 0.75rem;
    padding-bottom: 0.5rem;
    border-bottom: 2px solid #e9ecef;
}

.summary-list {
    list-style-type: disc;
    margin-left: 1.5rem;
    margin-bottom: 0;
}

.summary-list li {
    margin-bottom: 0.5rem;
    line-height: 1.5;
}

.summary-list li:last-child {
    margin-bottom: 0;
}

.summary-content p {
    margin-bottom: 0.75rem;
    line-height: 1.6;
}

.summary-content p:last-child {
    margin-bottom: 0;
}

.progress-stage {
    margin-bottom: 1.5rem;
    padding: 1rem;
    background-color: #f8f9fa;
    border-radius: 8px;
    transition: all 0.3s ease;
}

.progress-stage.active {
    background-color: #e7f1ff;
    border: 2px solid #0d6efd;
}

.progress-stage.completed {
    background-color: #d1e7dd;
    border: 2px solid #198754;
}

.progress-stage.error {
    background-color: #f8d7da;
    border: 2px solid #dc3545;
}

.stage-header {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.stage-icon {
    flex-shrink: 0;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background-color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2rem;
    color: #6c757d;
}

.progress-stage.active .stage-icon {
    background-color: #0d6efd;
    color: #fff;
}

.progress-stage.completed .stage-icon {
    background-color: #198754;
    color: #fff;
}

.progress-stage.error .stage-icon {
    background-color: #dc3545;
    color: #fff;
}

.stage-info {
    flex-grow: 1;
}

.stage-info h6 {
    margin-bottom: 0.25rem;
    font-size: 0.95rem;
}

.stage-info small {
    font-size: 0.85rem;
}

.stage-status {
    flex-shrink: 0;
}

.progress {
    height: 8px;
    background-color: #e9ecef;
}

.progress-stage.completed .progress-bar {
    width: 100% !important;
    background-color: #198754;
}

.detail-section {
    margin-bottom: 1.25rem;
    padding: 1rem;
    background-color: #f8f9fa;
    border-left: 4px solid #0d6efd;
    border-radius: 4px;
}

.detail-section h6 {
    font-size: 0.9rem;
    font-weight: 600;
    color: #0d6efd;
    margin-bottom: 0.75rem;
    text-transform: uppercase;
}

.detail-row {
    display: flex;
    padding: 0.5rem 0;
    border-bottom: 1px solid #dee2e6;
}

.detail-row:last-child {
    border-bottom: none;
}

.detail-label {
    flex: 0 0 180px;
    font-weight: 600;
    color: #495057;
}

.detail-value {
    flex: 1;
    color: #212529;
}

.detail-list {
    list-style: none;
    padding-left: 0;
    margin-bottom: 0;
}

.detail-list li {
    padding: 0.25rem 0;
    padding-left: 1.5rem;
    position: relative;
}

.detail-list li:before {
    content: "\2192";
    position: absolute;
    left: 0;
    color: #0d6efd;
    font-weight: bold;
}

.metadata-box {
    background-color: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 4px;
    padding: 1rem;
}

.metadata-box .badge {
    font-size: 0.85rem;
    padding: 0.35rem 0.65rem;
}

.verification-badge {
    display: inline-block;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-weight: 600;
    margin-bottom: 0.5rem;
}

.verification-badge.passed {
    background-color: #d1e7dd;
    color: #0f5132;
    border: 2px solid #198754;
}

.verification-badge.failed {
    background-color: #f8d7da;
    color: #842029;
    border: 2px solid #dc3545;
}
</style>

<script>
let currentData = null;
let errorModal = null;

const dz = document.getElementById('uploader');
const fileInput = document.getElementById('file');
const runBtn = document.getElementById('run');
const fileInfo = document.getElementById('fileInfo');
const fileName = document.getElementById('fileName');
const fileSize = document.getElementById('fileSize');

// Initialize error modal on page load
document.addEventListener('DOMContentLoaded', () => {
    errorModal = new bootstrap.Modal(document.getElementById('errorModal'));
});

// Helper function to show errors in modal
function showError(message, showRetry = false) {
    document.getElementById('errorModalBody').textContent = message;
    const retryBtn = document.getElementById('retryButton');
    retryBtn.style.display = showRetry ? 'inline-block' : 'none';
    if (errorModal) {
        errorModal.show();
    }
}

// Retry button handler
document.getElementById('retryButton').onclick = () => {
    if (errorModal) {
        errorModal.hide();
    }
    document.getElementById('run').click();
};

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

// Progress tracking
let progressInterval = null;

function startProgressSimulation() {
    // Reset all stages
    const stages = ['ocr', 'extraction', 'summary', 'verification'];
    stages.forEach(stage => {
        const el = document.getElementById(`stage-${stage}`);
        el.classList.remove('active', 'completed', 'error');
        el.querySelector('.progress-bar').style.width = '0%';
        el.querySelector('.stage-status').innerHTML = '<i class="fas fa-clock text-muted"></i>';
    });
    
    // Start timing-based progression
    const startTime = Date.now();
    const stageDurations = [
        { name: 'ocr', start: 0, duration: 8000 },           // 0-8s: OCR
        { name: 'extraction', start: 8000, duration: 20000 }, // 8-28s: Extraction
        { name: 'summary', start: 28000, duration: 15000 },   // 28-43s: Summary
        { name: 'verification', start: 43000, duration: 12000 } // 43-55s: Verification
    ];
    
    progressInterval = setInterval(() => {
        const elapsed = Date.now() - startTime;
        
        stageDurations.forEach((stage, index) => {
            const stageEl = document.getElementById(`stage-${stage.name}`);
            const progressBar = stageEl.querySelector('.progress-bar');
            const statusEl = stageEl.querySelector('.stage-status');
            
            if (elapsed < stage.start) {
                // Not started yet
                return;
            } else if (elapsed >= stage.start && elapsed < stage.start + stage.duration) {
                // Currently processing this stage
                const progress = ((elapsed - stage.start) / stage.duration) * 100;
                progressBar.style.width = `${Math.min(progress, 100)}%`;
                
                // Mark as active
                stageEl.classList.remove('completed');
                stageEl.classList.add('active');
                statusEl.innerHTML = '<div class="spinner-border spinner-border-sm text-primary"><span class="visually-hidden">Processing...</span></div>';
                
                // Mark previous stages as completed
                for (let i = 0; i < index; i++) {
                    const prevStage = document.getElementById(`stage-${stageDurations[i].name}`);
                    prevStage.classList.remove('active');
                    prevStage.classList.add('completed');
                    prevStage.querySelector('.stage-status').innerHTML = '<i class="fas fa-check-circle text-success"></i>';
                }
            } else if (elapsed >= stage.start + stage.duration) {
                // Completed
                progressBar.style.width = '100%';
                stageEl.classList.remove('active');
                stageEl.classList.add('completed');
                statusEl.innerHTML = '<i class="fas fa-check-circle text-success"></i>';
            }
        });
    }, 100); // Update every 100ms
}

function stopProgressSimulation(success = true) {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }
    
    // Mark all stages as completed or error
    const stages = ['ocr', 'extraction', 'summary', 'verification'];
    stages.forEach(stage => {
        const el = document.getElementById(`stage-${stage}`);
        el.querySelector('.progress-bar').style.width = '100%';
        
        if (success) {
            el.classList.remove('active');
            el.classList.add('completed');
            el.querySelector('.stage-status').innerHTML = '<i class="fas fa-check-circle text-success"></i>';
        } else {
            el.classList.remove('active');
            el.classList.add('error');
            el.querySelector('.stage-status').innerHTML = '<i class="fas fa-times-circle text-danger"></i>';
        }
    });
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

    // Start progress simulation
    startProgressSimulation();

    const body = new FormData();
    body.append('file', f);
    body.append('extra', document.getElementById('extra').value || '');

    try {
        const r = await fetch('/court-beta/ajax/upload_and_summarize.cfm?bypass=1', { method: 'POST', body });
        const data = await r.json();

        // Stop progress simulation
        stopProgressSimulation(true);

        console.log('Response data:', data);
        console.log('doc_uid:', data.doc_uid);
        console.log('db_error:', data.db_error);

        if (data.error) {
            throw new Error(data.error);
        }

        currentData = data;

        // Small delay to show completion state
        await new Promise(resolve => setTimeout(resolve, 800));

        // Hide processing, show results
        document.getElementById('processingStatus').classList.add('d-none');
        document.getElementById('result').classList.remove('d-none');

        // Check for errors array from Python processing
        if (data.errors && data.errors.length > 0) {
            const summaryEl = document.getElementById('summary');
            summaryEl.innerHTML = `
                <div class="alert alert-warning">
                    <h6 class="alert-heading"><i class="fas fa-exclamation-triangle me-2"></i>Processing Errors</h6>
                    <ul class="mb-0">
                        ${data.errors.map(err => `<li>${escapeHtml(err)}</li>`).join('')}
                    </ul>
                    <hr class="my-2">
                    <p class="mb-0 small"><strong>Note:</strong> Partial results may still be available below. This is typically a Python-side issue with AI response parsing.</p>
                </div>
            `;
        } else {
            // Build summary from structured fields instead of using summary_html
            buildSummaryFromFields(data);
        }

        // Populate OCR text
        document.getElementById('ocr').textContent = data.ocr_text || 'No OCR text available';

        // Populate structured details (human-readable)
        buildStructuredDetails(data);
        
        // Populate verification info
        buildVerificationInfo(data);
        
        // Populate metadata
        buildMetadataInfo(data);
        
        // Populate raw JSON (for debugging)
        document.getElementById('json').textContent = JSON.stringify(data, null, 2);

        // Reset QC form
        document.getElementById('success').checked = false;
        document.getElementById('notes').value = '';
        document.getElementById('qcStatus').classList.add('d-none');

    } catch (err) {
        // Stop progress with error state
        stopProgressSimulation(false);
        
        // Small delay to show error state
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        document.getElementById('processingStatus').classList.add('d-none');
        alert('Error processing document: ' + err.message);
        runBtn.disabled = false;
    }
};

function buildSummaryFromFields(data) {
    const summaryEl = document.getElementById('summary');
    const fields = data.fields || {};
    
    let html = '';
    
    // Event Summary Section
    if (fields.filing_action_summary) {
        html += '<div class="summary-section">';
        html += '<h5 class="summary-heading">Event Summary</h5>';
        html += `<p>${escapeHtml(fields.filing_action_summary)}</p>`;
        html += '</div>';
    }
    
    // Newsworthiness Section
    if (fields.newsworthiness) {
        html += '<div class="summary-section">';
        html += '<h5 class="summary-heading">Newsworthiness</h5>';
        const newsValue = fields.newsworthiness === 'yes' ? 'Yes' : 
                         fields.newsworthiness === 'no' ? 'No' : 'Unknown';
        html += `<p><strong>${newsValue}</strong>`;
        if (fields.newsworthiness_reason) {
            html += ` - ${escapeHtml(fields.newsworthiness_reason)}`;
        }
        html += '</p></div>';
    }
    
    // Story Section (if newsworthy)
    if (fields.newsworthiness === 'yes') {
        html += '<div class="summary-section">';
        html += '<h5 class="summary-heading">Story</h5>';
        html += '<ul class="summary-list">';
        if (fields.headline) {
            html += `<li><strong>Headline:</strong> ${escapeHtml(fields.headline)}</li>`;
        }
        if (fields.subhead) {
            html += `<li><strong>Subhead:</strong> ${escapeHtml(fields.subhead)}</li>`;
        }
        if (fields.body) {
            html += `<li><strong>Body:</strong> ${escapeHtml(fields.body)}</li>`;
        }
        html += '</ul></div>';
    }
    
    // Key Details Section
    html += '<div class="summary-section">';
    html += '<h5 class="summary-heading">Key Details</h5>';
    html += '<ul class="summary-list">';
    
    // Parties
    if (fields.parties) {
        if (fields.parties.plaintiff) {
            html += `<li><strong>Plaintiff:</strong> ${escapeHtml(fields.parties.plaintiff)}</li>`;
        }
        if (fields.parties.defendant) {
            html += `<li><strong>Defendant:</strong> ${escapeHtml(fields.parties.defendant)}</li>`;
        }
        if (fields.parties.others && fields.parties.others.length > 0) {
            html += `<li><strong>Other Parties:</strong> ${escapeHtml(fields.parties.others.join(', '))}</li>`;
        }
    }
    
    // Document type and filing date
    if (fields.doc_type) {
        html += `<li><strong>Document Type:</strong> ${escapeHtml(fields.doc_type)}</li>`;
    }
    if (fields.filing_date_iso) {
        html += `<li><strong>Filing Date:</strong> ${escapeHtml(fields.filing_date_iso)}</li>`;
    }
    
    // Court status
    if (fields.court_status) {
        html += `<li><strong>Court Status:</strong> ${escapeHtml(fields.court_status)}</li>`;
    }
    
    html += '</ul></div>';
    
    // Orders Section
    if (fields.orders && fields.orders.length > 0) {
        html += '<div class="summary-section">';
        html += '<h5 class="summary-heading">Orders</h5>';
        html += '<ul class="summary-list">';
        fields.orders.forEach(order => {
            html += `<li>${escapeHtml(order)}</li>`;
        });
        html += '</ul></div>';
    }
    
    // Next Actions Section
    if (fields.next_actions && fields.next_actions.length > 0) {
        html += '<div class="summary-section">';
        html += '<h5 class="summary-heading">What\'s Next</h5>';
        html += '<ul class="summary-list">';
        fields.next_actions.forEach(action => {
            html += `<li>${escapeHtml(action)}</li>`;
        });
        html += '</ul></div>';
    }
    
    // Financial Terms Section
    if (fields.financial_terms && fields.financial_terms.length > 0) {
        html += '<div class="summary-section">';
        html += '<h5 class="summary-heading">Financial Terms</h5>';
        html += '<ul class="summary-list">';
        fields.financial_terms.forEach(term => {
            html += `<li>${escapeHtml(term)}</li>`;
        });
        html += '</ul></div>';
    }
    
    // Sentencing (if applicable)
    if (fields.sentence && (fields.sentence.imprisonment_months > 0 || 
        fields.sentence.fine_usd > 0 || 
        fields.sentence.restitution_usd > 0 || 
        fields.sentence.supervised_release_years > 0)) {
        html += '<div class="summary-section">';
        html += '<h5 class="summary-heading">Sentencing</h5>';
        html += '<ul class="summary-list">';
        if (fields.sentence.imprisonment_months > 0) {
            html += `<li><strong>Imprisonment:</strong> ${fields.sentence.imprisonment_months} months</li>`;
        }
        if (fields.sentence.supervised_release_years > 0) {
            html += `<li><strong>Supervised Release:</strong> ${fields.sentence.supervised_release_years} years</li>`;
        }
        if (fields.sentence.fine_usd > 0) {
            html += `<li><strong>Fine:</strong> $${fields.sentence.fine_usd.toLocaleString()}</li>`;
        }
        if (fields.sentence.restitution_usd > 0) {
            html += `<li><strong>Restitution:</strong> $${fields.sentence.restitution_usd.toLocaleString()}</li>`;
        }
        html += '</ul></div>';
    }
    
    // Fallback if no fields available
    if (html === '') {
        html = '<p class="text-muted">No structured summary data available.</p>';
        // Fall back to raw summary_html if present
        if (data.summary_html) {
            html = data.summary_html;
        }
    }
    
    summaryEl.innerHTML = html;
}

function buildStructuredDetails(data) {
    const container = document.getElementById('structuredDetails');
    const fields = data.fields || {};
    let html = '';
    let sectionCount = 0;
    
    // Helper function to add a section
    function addSection(title, icon, content) {
        if (content) {
            sectionCount++;
            html += `<div class="detail-section">`;
            html += `<h6><i class="fas fa-${icon} me-2"></i>${title}</h6>`;
            html += content;
            html += '</div>';
        }
    }
    
    // Helper function to add a row
    function addRow(label, value) {
        if (value !== null && value !== undefined && value !== '') {
            return `<div class="detail-row"><div class="detail-label">${label}:</div><div class="detail-value">${escapeHtml(String(value))}</div></div>`;
        }
        return '';
    }
    
    // Helper function to add a list
    function addList(items) {
        if (items && Array.isArray(items) && items.length > 0) {
            let listHtml = '<ul class="detail-list">';
            items.forEach(item => {
                listHtml += `<li>${escapeHtml(String(item))}</li>`;
            });
            listHtml += '</ul>';
            return listHtml;
        }
        return '';
    }
    
    // 1. Filing Action Summary
    let filingContent = '';
    if (fields.filing_action_summary) {
        filingContent += `<div class="detail-value mb-2"><strong>${escapeHtml(fields.filing_action_summary)}</strong></div>`;
    }
    filingContent += addRow('Document Type', fields.doc_type);
    filingContent += addRow('Filing Date', fields.filing_date_iso);
    filingContent += addRow('Case Number', fields.case_number);
    filingContent += addRow('Court', fields.court);
    filingContent += addRow('Jurisdiction', fields.jurisdiction);
    filingContent += addRow('Status', fields.court_status);
    filingContent += addRow('Adjudication Mode', fields.adjudication_mode);
    filingContent += addRow('Docket Number', fields.docket_number);
    addSection('Filing Information', 'file-alt', filingContent);
    
    // 2. Newsworthiness
    let newsContent = '';
    if (fields.newsworthiness) {
        const newsClass = fields.newsworthiness === 'HIGH' ? 'text-danger fw-bold' : 
                         fields.newsworthiness === 'MEDIUM' ? 'text-warning fw-bold' : 'text-muted';
        newsContent += `<div class="detail-row"><div class="detail-label">Rating:</div><div class="detail-value"><span class="${newsClass}">${escapeHtml(fields.newsworthiness)}</span></div></div>`;
    }
    if (fields.newsworthiness_reason) {
        newsContent += `<div class="detail-value mt-2">${escapeHtml(fields.newsworthiness_reason)}</div>`;
    }
    addSection('Newsworthiness', 'star', newsContent);
    
    // 3. Parties
    let partiesContent = '';
    if (fields.parties) {
        partiesContent += addRow('Plaintiff', fields.parties.plaintiff);
        partiesContent += addRow('Defendant', fields.parties.defendant);
        partiesContent += addRow('Petitioner', fields.parties.petitioner);
        partiesContent += addRow('Respondent', fields.parties.respondent);
        partiesContent += addRow('Appellant', fields.parties.appellant);
        partiesContent += addRow('Appellee', fields.parties.appellee);
        if (fields.parties.others && fields.parties.others.length > 0) {
            partiesContent += `<div class="detail-row"><div class="detail-label">Other Parties:</div><div class="detail-value">${escapeHtml(fields.parties.others.join(', '))}</div></div>`;
        }
    }
    addSection('Parties', 'users', partiesContent);
    
    // 4. Attorneys & Counsel
    let attorneyContent = '';
    if (fields.attorneys) {
        if (fields.attorneys.plaintiff && Array.isArray(fields.attorneys.plaintiff) && fields.attorneys.plaintiff.length > 0) {
            attorneyContent += '<div class="detail-row"><div class="detail-label">Plaintiff Counsel:</div><div class="detail-value">';
            attorneyContent += escapeHtml(fields.attorneys.plaintiff.join('; '));
            attorneyContent += '</div></div>';
        }
        if (fields.attorneys.defendant && Array.isArray(fields.attorneys.defendant) && fields.attorneys.defendant.length > 0) {
            attorneyContent += '<div class="detail-row"><div class="detail-label">Defendant Counsel:</div><div class="detail-value">';
            attorneyContent += escapeHtml(fields.attorneys.defendant.join('; '));
            attorneyContent += '</div></div>';
        }
    }
    if (fields.attorney_names && Array.isArray(fields.attorney_names) && fields.attorney_names.length > 0) {
        attorneyContent += '<div class="detail-row"><div class="detail-label">Attorneys:</div><div class="detail-value">';
        attorneyContent += escapeHtml(fields.attorney_names.join(', '));
        attorneyContent += '</div></div>';
    }
    addSection('Attorneys & Counsel', 'briefcase', attorneyContent);
    
    // 5. Judges & Court Officials
    let judgeContent = '';
    judgeContent += addRow('Judge', fields.judge);
    judgeContent += addRow('Judge Assigned', fields.judge_assigned);
    judgeContent += addRow('Magistrate Judge', fields.magistrate_judge);
    if (fields.judicial_officers && Array.isArray(fields.judicial_officers) && fields.judicial_officers.length > 0) {
        judgeContent += `<div class="detail-row"><div class="detail-label">Judicial Officers:</div><div class="detail-value">${escapeHtml(fields.judicial_officers.join(', '))}</div></div>`;
    }
    addSection('Judges & Court Officials', 'user-tie', judgeContent);
    
    // 6. Counts/Charges/Allegations
    let countsContent = '';
    if (fields.counts_alleged && fields.counts_alleged.length > 0) {
        countsContent += '<div class="mb-2"><strong>Counts Alleged:</strong></div>';
        countsContent += addList(fields.counts_alleged);
    }
    if (fields.charges && fields.charges.length > 0) {
        countsContent += '<div class="mb-2 mt-2"><strong>Charges:</strong></div>';
        countsContent += addList(fields.charges);
    }
    if (fields.allegations && fields.allegations.length > 0) {
        countsContent += '<div class="mb-2 mt-2"><strong>Allegations:</strong></div>';
        countsContent += addList(fields.allegations);
    }
    if (fields.claims && fields.claims.length > 0) {
        countsContent += '<div class="mb-2 mt-2"><strong>Claims:</strong></div>';
        countsContent += addList(fields.claims);
    }
    addSection('Counts & Allegations', 'list-ol', countsContent);
    
    // 7. Court Orders & Rulings
    let ordersContent = '';
    if (fields.orders && fields.orders.length > 0) {
        ordersContent += addList(fields.orders);
    }
    if (fields.rulings && fields.rulings.length > 0) {
        ordersContent += '<div class="mb-2 mt-2"><strong>Rulings:</strong></div>';
        ordersContent += addList(fields.rulings);
    }
    if (fields.holdings && fields.holdings.length > 0) {
        ordersContent += '<div class="mb-2 mt-2"><strong>Holdings:</strong></div>';
        ordersContent += addList(fields.holdings);
    }
    addSection('Court Orders & Rulings', 'gavel', ordersContent);
    
    // 8. Financial Terms
    let financialContent = '';
    if (fields.financial_terms && fields.financial_terms.length > 0) {
        financialContent += addList(fields.financial_terms);
    }
    financialContent += addRow('Amount in Controversy', fields.amount_in_controversy);
    financialContent += addRow('Damages Sought', fields.damages_sought);
    financialContent += addRow('Settlement Amount', fields.settlement_amount);
    financialContent += addRow('Judgment Amount', fields.judgment_amount);
    addSection('Financial Terms', 'dollar-sign', financialContent);
    
    // 9. Sentencing (if applicable)
    let sentenceContent = '';
    if (fields.sentence && typeof fields.sentence === 'object') {
        if (fields.sentence.imprisonment_months > 0) {
            sentenceContent += addRow('Imprisonment', `${fields.sentence.imprisonment_months} months`);
        }
        if (fields.sentence.supervised_release_years > 0) {
            sentenceContent += addRow('Supervised Release', `${fields.sentence.supervised_release_years} years`);
        }
        if (fields.sentence.probation_years > 0) {
            sentenceContent += addRow('Probation', `${fields.sentence.probation_years} years`);
        }
        if (fields.sentence.fine_usd > 0) {
            sentenceContent += addRow('Fine', `$${fields.sentence.fine_usd.toLocaleString()}`);
        }
        if (fields.sentence.restitution_usd > 0) {
            sentenceContent += addRow('Restitution', `$${fields.sentence.restitution_usd.toLocaleString()}`);
        }
        if (fields.sentence.community_service_hours > 0) {
            sentenceContent += addRow('Community Service', `${fields.sentence.community_service_hours} hours`);
        }
    }
    addSection('Sentencing', 'balance-scale', sentenceContent);
    
    // 10. Relief Sought
    let reliefContent = '';
    if (fields.relief_sought && fields.relief_sought.length > 0) {
        reliefContent += addList(fields.relief_sought);
    }
    if (fields.remedies && fields.remedies.length > 0) {
        reliefContent += '<div class="mb-2 mt-2"><strong>Remedies:</strong></div>';
        reliefContent += addList(fields.remedies);
    }
    addSection('Relief Sought', 'hands-helping', reliefContent);
    
    // 11. Deadlines & Important Dates
    let datesContent = '';
    datesContent += addRow('Trial Date', fields.trial_date);
    datesContent += addRow('Hearing Date', fields.hearing_date);
    datesContent += addRow('Response Due Date', fields.response_due_date);
    datesContent += addRow('Motion Deadline', fields.motion_deadline);
    datesContent += addRow('Discovery Deadline', fields.discovery_deadline);
    datesContent += addRow('Settlement Conference', fields.settlement_conference_date);
    if (fields.deadlines && fields.deadlines.length > 0) {
        datesContent += '<div class="mb-2 mt-2"><strong>Other Deadlines:</strong></div>';
        datesContent += addList(fields.deadlines);
    }
    addSection('Deadlines & Dates', 'calendar-alt', datesContent);
    
    // 12. Motions
    let motionsContent = '';
    if (fields.motions && fields.motions.length > 0) {
        motionsContent += addList(fields.motions);
    }
    motionsContent += addRow('Motion Type', fields.motion_type);
    motionsContent += addRow('Motion Status', fields.motion_status);
    addSection('Motions', 'file-contract', motionsContent);
    
    // 13. Evidence & Exhibits
    let evidenceContent = '';
    if (fields.exhibits && fields.exhibits.length > 0) {
        evidenceContent += '<div class="mb-2"><strong>Exhibits:</strong></div>';
        evidenceContent += addList(fields.exhibits);
    }
    if (fields.evidence && fields.evidence.length > 0) {
        evidenceContent += '<div class="mb-2 mt-2"><strong>Evidence:</strong></div>';
        evidenceContent += addList(fields.evidence);
    }
    evidenceContent += addRow('Number of Exhibits', fields.exhibit_count);
    addSection('Evidence & Exhibits', 'folder-open', evidenceContent);
    
    // 14. Procedural History
    let procedureContent = '';
    if (fields.procedural_history && fields.procedural_history.length > 0) {
        procedureContent += addList(fields.procedural_history);
    }
    procedureContent += addRow('Prior Case Number', fields.prior_case_number);
    procedureContent += addRow('Appeal Status', fields.appeal_status);
    procedureContent += addRow('Case Stage', fields.case_stage);
    addSection('Procedural History', 'history', procedureContent);
    
    // 15. Next Actions & Developments
    let actionsContent = '';
    if (fields.next_actions && fields.next_actions.length > 0) {
        actionsContent += addList(fields.next_actions);
    }
    if (fields.pending_matters && fields.pending_matters.length > 0) {
        actionsContent += '<div class="mb-2 mt-2"><strong>Pending Matters:</strong></div>';
        actionsContent += addList(fields.pending_matters);
    }
    addSection('Next Actions', 'arrow-right', actionsContent);
    
    // 16. Legal Issues & Citations
    let legalContent = '';
    if (fields.legal_issues && fields.legal_issues.length > 0) {
        legalContent += '<div class="mb-2"><strong>Legal Issues:</strong></div>';
        legalContent += addList(fields.legal_issues);
    }
    if (fields.statutes_cited && fields.statutes_cited.length > 0) {
        legalContent += '<div class="mb-2 mt-2"><strong>Statutes Cited:</strong></div>';
        legalContent += addList(fields.statutes_cited);
    }
    if (fields.case_citations && fields.case_citations.length > 0) {
        legalContent += '<div class="mb-2 mt-2"><strong>Case Citations:</strong></div>';
        legalContent += addList(fields.case_citations);
    }
    addSection('Legal Issues & Citations', 'book', legalContent);
    
    // 17. Additional Notes
    let notesContent = '';
    notesContent += addRow('Case Summary', fields.case_summary);
    notesContent += addRow('Key Facts', fields.key_facts);
    notesContent += addRow('Notable', fields.notable);
    notesContent += addRow('Public Interest', fields.public_interest);
    if (fields.notes && Array.isArray(fields.notes) && fields.notes.length > 0) {
        notesContent += '<div class="mb-2 mt-2"><strong>Notes:</strong></div>';
        notesContent += addList(fields.notes);
    }
    addSection('Additional Information', 'info-circle', notesContent);
    
    // If no sections were added, show a message
    if (sectionCount === 0) {
        html = '<p class="text-muted">No structured data available.</p>';
    }
    
    container.innerHTML = html;
}

function buildVerificationInfo(data) {
    const container = document.getElementById('verificationInfo');
    let html = '';
    
    if (data.verifier_result) {
        const passed = data.verifier_result === 'PASSED';
        html += `<div class="verification-badge ${passed ? 'passed' : 'failed'}">`;
        html += `<i class="fas fa-${passed ? 'check-circle' : 'exclamation-triangle'} me-2"></i>`;
        html += `FACT_GUARD Verification: ${data.verifier_result}`;
        html += '</div>';
        
        if (data.verifier_notes) {
            html += '<div class="alert alert-warning mb-0">';
            html += '<strong>Verification Notes:</strong><br>';
            html += escapeHtml(data.verifier_notes);
            html += '</div>';
        }
    }
    
    container.innerHTML = html;
}

function buildMetadataInfo(data) {
    const container = document.getElementById('metadataInfo');
    let html = '<div class="d-flex flex-wrap gap-2">';
    
    if (data.model_name) {
        html += `<span class="badge bg-primary">Model: ${escapeHtml(data.model_name)}</span>`;
    }
    if (data.processing_ms) {
        html += `<span class="badge bg-info">Processing: ${data.processing_ms}ms</span>`;
    }
    if (data.uploaded_filename) {
        html += `<span class="badge bg-secondary">File: ${escapeHtml(data.uploaded_filename)}</span>`;
    }
    if (data.upload_sha256) {
        html += `<span class="badge bg-dark">SHA-256: ${data.upload_sha256.substring(0, 16)}...</span>`;
    }
    if (data.doc_uid) {
        html += `<span class="badge bg-success">Doc ID: ${data.doc_uid}</span>`;
    }
    
    html += '</div>';
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
