# AI Summarize Upload Tool - Enhancement Plan
## Interactive Q&A and UI Redesign

**Date:** 2025-01-28
**Status:** Planning Phase
**Goal:** Add interactive document Q&A using extracted JSON facts and redesign UI for better UX

---

## Table of Contents
1. [Overview](#overview)
2. [Current Implementation Analysis](#current-implementation-analysis)
3. [Proposed Enhancements](#proposed-enhancements)
4. [Database Schema Changes](#database-schema-changes)
5. [UI/UX Redesign](#uiux-redesign)
6. [Backend Architecture](#backend-architecture)
7. [Python Implementation](#python-implementation)
8. [Security Considerations](#security-considerations)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Testing Strategy](#testing-strategy)

---

## Overview

### Current Pain Points
- Users cannot ask follow-up questions about summarized documents
- Results page is cramped with limited space for summary display
- No conversation history or iterative exploration
- Extracted JSON data is underutilized after initial summarization

### Proposed Solution
Transform the summarize tool into a **two-phase interactive system**:

1. **Phase 1: Upload & Process** (Existing workflow enhanced)
   - Clean left-aligned upload interface
   - Modal-based progress tracking
   - Redirect to results page on completion

2. **Phase 2: Results & Q&A** (New capability)
   - Spacious summary display with tabs (Summary/JSON/OCR)
   - Interactive prompt interface for document questions
   - Gemini AI answers questions based on extracted JSON facts
   - Conversation history with feedback collection
   - FACT_GUARD verification for all responses

---

## Current Implementation Analysis

### Existing Components

#### Frontend
**File:** `/tools/summarize/index.cfm`
**Features:**
- Drag-and-drop PDF upload (max 25 MB)
- Optional instruction textarea
- Four-stage progress indicators (OCR → Extract → Summarize → Verify)
- Results display with collapsible sections
- QC feedback form

#### Backend (ColdFusion)
**File:** `/ajax/upload_and_summarize.cfm`
**Process:**
1. Accepts PDF upload
2. Validates PDF magic bytes (`%PDF`)
3. Computes SHA-256 hash for de-duplication
4. Calls batch file wrapper for Python script
5. Parses JSON response from Python
6. Inserts document record into `docketwatch.dbo.documents`
7. Returns JSON to frontend

#### Python Processing
**File:** `/python/summarize_upload_cli.py`
**Pipeline (FACT_GUARD):**
1. **OCR Extraction** - `pdf_to_text()` with fallback to Tesseract
2. **OCR Refinement** - AI cleanup for poor quality text
3. **Fact Extraction** - `extract_facts()` returns structured JSON
4. **Summary Rendering** - `render_summary()` creates human-readable text
5. **Verification** - `verify_summary()` checks for hallucinations

**Key Functions:**
- `extract_facts(text, case_overview, event_desc, event_date)` - Structured extraction
- `render_summary(extraction)` - Converts JSON to summary
- `verify_summary(extraction, summary)` - FACT_GUARD validation

#### Database Tables

**documents table** (existing):
```sql
doc_uid                        UNIQUEIDENTIFIER PRIMARY KEY
doc_id                         VARCHAR(100)
fk_case_event                  UNIQUEIDENTIFIER
fk_tool                        INT
pdf_title                      VARCHAR(500)
rel_path                       VARCHAR(500)
ocr_text                       TEXT
summary_ai                     TEXT
summary_ai_html                TEXT
summary_ai_extraction_json     TEXT (stores extracted fields)
date_downloaded                DATETIME2(7)
ai_processed_at                DATETIME2(7)
file_size                      INT
```

**summary_qc_feedback table** (existing):
```sql
id            INT IDENTITY PRIMARY KEY
doc_uid       UNIQUEIDENTIFIER
upload_sha256 CHAR(64)
user_name     NVARCHAR(100)
success       BIT
notes         NVARCHAR(MAX)
model_name    NVARCHAR(50)
created_at    DATETIME2(7)
```

---

## Proposed Enhancements

### 1. Interactive Document Q&A

**Concept:** Users can ask natural language questions about the document, and Gemini AI answers using **only** the extracted JSON facts (not the raw OCR text). This ensures:
- ✅ Answers are grounded in verified facts
- ✅ No hallucinations (FACT_GUARD principle)
- ✅ Consistent with initial extraction
- ✅ Fast responses (no re-OCR needed)

**Example Workflow:**
```
User uploads PDF → System extracts facts → User asks "What was the settlement amount?"
→ AI searches JSON facts → Finds "settlement_amount: $50,000" → Returns answer with citation
```

### 2. UI Redesign

**Before (Current):**
```
┌────────────────────────────────────────────────────────┐
│  Upload Panel (Left)  │  Results Panel (Right)         │
│  - Upload zone        │  - Processing (inline)         │
│  - Instructions       │  - Summary (cramped)           │
│  - Process button     │  - OCR, JSON (collapsed)       │
│                       │  - QC feedback                 │
└────────────────────────────────────────────────────────┘
```

**After (Proposed):**
```
┌─────────────────────────────────────────────────────────┐
│                  PHASE 1: Upload Page                   │
│                  (index.cfm)                            │
│                                                         │
│  ┌───────────────────────────────────────────┐         │
│  │  LEFT COLUMN (Centered)                   │         │
│  │  ┌─────────────────────────────────────┐  │         │
│  │  │  📄 Drag PDF Here                   │  │         │
│  │  │     (25 MB max)                     │  │         │
│  │  └─────────────────────────────────────┘  │         │
│  │                                            │         │
│  │  Optional Instructions:                   │         │
│  │  ┌─────────────────────────────────────┐  │         │
│  │  │  [Text area for extra context]     │  │         │
│  │  └─────────────────────────────────────┘  │         │
│  │                                            │         │
│  │  [🧠 Generate AI Summary]                 │         │
│  └───────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────┘

                    ↓ (On click)

┌─────────────────────────────────────────────────────────┐
│           MODAL: Processing Status                      │
│  ┌──────────────────────────────────────────┐           │
│  │  ⚙️  Processing Document                 │           │
│  │  ────────────────────────────────────────│           │
│  │  ✅ OCR Extraction       [████████] 100% │           │
│  │  ⏳ Fact Extraction      [████░░░░]  50% │           │
│  │  ⏳ Summary Generation   [░░░░░░░░]   0% │           │
│  │  ⏳ Verification         [░░░░░░░░]   0% │           │
│  │                                          │           │
│  │  Estimated: 30-60 seconds                │           │
│  └──────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────┘

                    ↓ (On complete)

┌─────────────────────────────────────────────────────────┐
│              PHASE 2: Results & Q&A Page                │
│              (view.cfm?doc_uid=...)                     │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  📊 SUMMARY (Full Width - More Real Estate)      │ │
│  │  ───────────────────────────────────────────────  │ │
│  │                                                   │ │
│  │  Event Summary:                                   │ │
│  │  Plaintiff John Doe filed a motion for summary   │ │
│  │  judgment seeking $50,000 in damages...          │ │
│  │                                                   │ │
│  │  Newsworthiness: HIGH                             │ │
│  │  - Celebrity defendant with prior convictions    │ │
│  │                                                   │ │
│  │  Key Details:                                     │ │
│  │  • Plaintiff: John Doe                            │ │
│  │  • Defendant: Jane Celebrity                      │ │
│  │  • Filing Date: 2025-01-15                        │ │
│  │  ...                                              │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  📁 TABS                                          │ │
│  │  [Summary] [Extracted JSON] [OCR Text]           │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  💬 ASK QUESTIONS ABOUT THIS DOCUMENT            │ │
│  │  ───────────────────────────────────────────────  │ │
│  │                                                   │ │
│  │  [What was the settlement amount?           ]    │ │
│  │  [Ask]                                            │ │
│  │                                                   │ │
│  │  📜 Conversation History (Scrollable):            │ │
│  │  ─────────────────────────────────────────────    │ │
│  │                                                   │ │
│  │  🧑 You: What was the settlement amount?          │ │
│  │  🤖 AI: Based on the extracted facts, the        │ │
│  │      settlement amount was $50,000 USD.           │ │
│  │      (Cited from: fields.settlement_amount)       │ │
│  │      👍 👎 [Feedback]                             │ │
│  │                                                   │ │
│  │  🧑 You: Who filed this motion?                   │ │
│  │  🤖 AI: The plaintiff John Doe filed the         │ │
│  │      motion on January 15, 2025.                  │ │
│  │      (Cited from: fields.parties.plaintiff,       │ │
│  │                   fields.filing_date_iso)         │ │
│  │      👍 👎 [Feedback]                             │ │
│  │                                                   │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  ✅ QUALITY CONTROL FEEDBACK                      │ │
│  │  [✓] Summary is correct and complete              │ │
│  │  Notes: [Text area...]                            │ │
│  │  [Save QC Feedback]                               │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Database Schema Changes

### New Table: `document_prompts`

Stores all interactive Q&A requests and responses for audit and feedback.

```sql
CREATE TABLE docketwatch.dbo.document_prompts (
    id                    BIGINT IDENTITY(1,1) PRIMARY KEY,
    fk_doc_uid            UNIQUEIDENTIFIER NOT NULL,
    user_name             NVARCHAR(100) NOT NULL,
    prompt_text           NVARCHAR(MAX) NOT NULL,
    prompt_response       NVARCHAR(MAX) NULL,
    model_name            NVARCHAR(50) NULL,
    tokens_input          INT NULL,
    tokens_output         INT NULL,
    processing_ms         INT NULL,
    cited_fields          NVARCHAR(MAX) NULL,  -- JSON array of field paths cited
    created_at            DATETIME2(7) DEFAULT SYSUTCDATETIME(),

    -- Optional feedback from user
    feedback_rating       TINYINT NULL,        -- 1-5 stars or NULL
    feedback_comment      NVARCHAR(MAX) NULL,
    feedback_submitted_at DATETIME2(7) NULL,

    -- Tracking
    session_id            NVARCHAR(100) NULL,  -- Group prompts by session
    prompt_sequence       INT NULL,            -- Order within session

    CONSTRAINT FK_document_prompts_doc FOREIGN KEY (fk_doc_uid)
        REFERENCES docketwatch.dbo.documents(doc_uid) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IX_document_prompts_doc_uid ON docketwatch.dbo.document_prompts(fk_doc_uid);
CREATE INDEX IX_document_prompts_user ON docketwatch.dbo.document_prompts(user_name);
CREATE INDEX IX_document_prompts_created ON docketwatch.dbo.document_prompts(created_at DESC);
CREATE INDEX IX_document_prompts_session ON docketwatch.dbo.document_prompts(session_id, prompt_sequence);
```

**Rationale:**
- `fk_doc_uid` - Links to specific document
- `prompt_text` - User's question
- `prompt_response` - AI's answer
- `cited_fields` - JSON array tracking which facts were used (e.g., `["fields.parties.plaintiff", "fields.filing_date_iso"]`)
- `feedback_rating` - User thumbs up/down or star rating
- `session_id` - Groups related prompts (e.g., UUID generated on page load)
- `prompt_sequence` - Maintains order of conversation

---

## UI/UX Redesign

### Page 1: Upload Interface (`/tools/summarize/index.cfm`)

**Design Goals:**
- Clean, uncluttered left-aligned vertical layout
- Larger upload dropzone for better visibility
- Clear call-to-action button
- Remove right-side results panel (moves to new page)

**Changes:**
```diff
- Two-column layout (upload left, results right)
+ Single-column centered layout (max-width: 600px)

- Inline processing indicators
+ Modal-based processing overlay

- Results shown on same page
+ Redirect to dedicated results page
```

**New Elements:**
```html
<div class="container" style="max-width: 600px; margin-top: 5rem;">
    <h1 class="text-center mb-4">AI Document Summarizer</h1>

    <!-- Upload Card -->
    <div class="card shadow-lg">
        <div class="card-body p-5">
            <!-- Large dropzone -->
            <div id="uploader" class="upload-zone">
                <i class="fas fa-cloud-upload-alt fa-5x mb-3"></i>
                <h4>Drag PDF here or click to select</h4>
                <p class="text-muted">Maximum file size: 25 MB</p>
            </div>

            <!-- Optional instructions -->
            <div class="mt-4">
                <label>Optional Instructions</label>
                <textarea id="extra" class="form-control" rows="3"
                    placeholder="Focus on sentencing details, highlight financial terms, etc.">
                </textarea>
            </div>

            <!-- CTA Button -->
            <button id="run" class="btn btn-primary btn-lg w-100 mt-4" disabled>
                <i class="fas fa-brain me-2"></i>Generate AI Summary
            </button>
        </div>
    </div>
</div>
```

### Modal: Processing Status

**Triggered on:** Button click
**Features:**
- Animated progress bars for each stage
- Real-time status updates (via polling or websockets)
- Estimated time remaining
- Cannot be dismissed (processing is server-side)

**Implementation:**
```javascript
// Show modal
const processingModal = new bootstrap.Modal(document.getElementById('processingModal'), {
    backdrop: 'static',
    keyboard: false
});
processingModal.show();

// Poll for status updates (every 2 seconds)
const statusInterval = setInterval(async () => {
    const status = await fetch(`/ajax/get_processing_status.cfm?session_id=${sessionId}`);
    const data = await status.json();

    updateProgressBar('ocr', data.ocr_progress);
    updateProgressBar('extraction', data.extraction_progress);
    updateProgressBar('summary', data.summary_progress);
    updateProgressBar('verification', data.verification_progress);

    if (data.completed) {
        clearInterval(statusInterval);
        processingModal.hide();
        window.location.href = `/tools/summarize/view.cfm?doc_uid=${data.doc_uid}`;
    }
}, 2000);
```

### Page 2: Results & Q&A (`/tools/summarize/view.cfm`)

**URL Structure:**
```
/tools/summarize/view.cfm?doc_uid={uuid}
```

**Layout:**
```html
<div class="container-fluid mt-4">
    <div class="row">
        <!-- Summary Section (Full Width) -->
        <div class="col-12">
            <div class="card shadow mb-4">
                <div class="card-header bg-success text-white">
                    <h4><i class="fas fa-check-circle"></i> AI Summary</h4>
                </div>
                <div class="card-body p-4">
                    <!-- Summary content with more space -->
                    <div id="summary" class="summary-content"></div>
                </div>
            </div>
        </div>

        <!-- Tabbed Data Views -->
        <div class="col-12">
            <ul class="nav nav-tabs" role="tablist">
                <li class="nav-item">
                    <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tab-summary">
                        Summary
                    </button>
                </li>
                <li class="nav-item">
                    <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-json">
                        Extracted JSON
                    </button>
                </li>
                <li class="nav-item">
                    <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-ocr">
                        OCR Text
                    </button>
                </li>
            </ul>
            <div class="tab-content p-4 bg-white border border-top-0">
                <div class="tab-pane active" id="tab-summary"><!-- Summary HTML --></div>
                <div class="tab-pane" id="tab-json"><!-- Pretty JSON --></div>
                <div class="tab-pane" id="tab-ocr"><!-- OCR text --></div>
            </div>
        </div>

        <!-- Q&A Section -->
        <div class="col-12">
            <div class="card shadow mb-4">
                <div class="card-header bg-primary text-white">
                    <h5><i class="fas fa-comments"></i> Ask Questions About This Document</h5>
                </div>
                <div class="card-body">
                    <!-- Conversation History (Scrollable) -->
                    <div id="conversationHistory" class="conversation-history mb-3">
                        <!-- Dynamically populated with Q&A pairs -->
                    </div>

                    <!-- Input Area -->
                    <div class="input-group">
                        <input type="text" id="promptInput" class="form-control"
                            placeholder="Ask a question about this document...">
                        <button id="askButton" class="btn btn-primary">
                            <i class="fas fa-paper-plane"></i> Ask
                        </button>
                    </div>

                    <small class="text-muted mt-2 d-block">
                        <i class="fas fa-info-circle"></i>
                        Questions are answered using the extracted facts above, ensuring accuracy.
                    </small>
                </div>
            </div>
        </div>

        <!-- QC Feedback Section -->
        <div class="col-12">
            <!-- Existing QC form -->
        </div>
    </div>
</div>
```

**Conversation History Design:**
```html
<div class="message user-message">
    <div class="message-meta">
        <i class="fas fa-user-circle"></i> You
        <span class="text-muted">2:45 PM</span>
    </div>
    <div class="message-content">
        What was the settlement amount?
    </div>
</div>

<div class="message ai-message">
    <div class="message-meta">
        <i class="fas fa-robot"></i> AI Assistant
        <span class="text-muted">2:45 PM</span>
        <span class="badge bg-secondary">gemini-2.5-flash</span>
    </div>
    <div class="message-content">
        Based on the extracted facts, the settlement amount was <strong>$50,000 USD</strong>.
        <div class="citations mt-2">
            <small class="text-muted">
                <i class="fas fa-quote-left"></i>
                Cited from: <code>fields.settlement_amount</code>
            </small>
        </div>
    </div>
    <div class="message-feedback">
        <button class="btn btn-sm btn-outline-success" onclick="rateFeedback(1, 5)">
            <i class="fas fa-thumbs-up"></i>
        </button>
        <button class="btn btn-sm btn-outline-danger" onclick="rateFeedback(1, 1)">
            <i class="fas fa-thumbs-down"></i>
        </button>
    </div>
</div>
```

---

## Backend Architecture

### New ColdFusion Endpoints

#### 1. `/ajax/get_processing_status.cfm`
**Purpose:** Poll for processing progress during upload
**Method:** GET
**Parameters:**
- `session_id` (string) - Unique session identifier

**Response:**
```json
{
    "session_id": "abc-123",
    "status": "processing",
    "ocr_progress": 100,
    "extraction_progress": 75,
    "summary_progress": 0,
    "verification_progress": 0,
    "completed": false,
    "doc_uid": null,
    "error": null
}
```

**Implementation Notes:**
- Store progress in session scope or database table (`processing_sessions`)
- Python script updates progress via database or file writes
- Clean up session data after completion

#### 2. `/ajax/ask_document_question.cfm`
**Purpose:** Process user question and return AI answer based on JSON
**Method:** POST
**Parameters:**
```json
{
    "doc_uid": "uuid-here",
    "prompt_text": "What was the settlement amount?",
    "session_id": "conversation-session-id"
}
```

**Response:**
```json
{
    "ok": true,
    "prompt_id": 12345,
    "response_text": "Based on the extracted facts, the settlement amount was $50,000 USD.",
    "cited_fields": ["fields.settlement_amount"],
    "model_name": "gemini-2.5-flash",
    "processing_ms": 1200,
    "tokens_input": 450,
    "tokens_output": 85
}
```

**Process Flow:**
```
1. Load document from database by doc_uid
2. Extract JSON fields from summary_ai_extraction_json column
3. Call Python script: python answer_from_json.py --doc_uid=X --prompt="..."
4. Python queries Gemini with:
   - Prompt: "Answer this question using ONLY the provided JSON facts"
   - Context: Serialized extraction JSON
   - Question: User's prompt
5. Parse Python response
6. Insert record into document_prompts table
7. Return response to frontend
```

**Implementation:**
```cfm
<cftry>
    <!--- Get document and extraction JSON --->
    <cfquery name="getDoc" datasource="Reach">
        SELECT doc_uid, summary_ai_extraction_json
        FROM docketwatch.dbo.documents
        WHERE doc_uid = <cfqueryparam value="#form.doc_uid#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfif getDoc.recordCount EQ 0>
        <cfthrow message="Document not found">
    </cfif>

    <!--- Call Python Q&A script --->
    <cfset pythonScript = "U:\docketwatch\python\answer_from_json.py">
    <cfset pythonExe = "C:\Program Files\Python312\python.exe">

    <cfexecute name="#pythonExe#"
               arguments="#[pythonScript, '--doc_uid', form.doc_uid, '--prompt', form.prompt_text]#"
               timeout="60"
               variable="pyOutput"
               errorVariable="pyError">
    </cfexecute>

    <!--- Parse response --->
    <cfset response = deserializeJSON(pyOutput)>

    <!--- Log to database --->
    <cfquery name="insertPrompt" datasource="Reach">
        INSERT INTO docketwatch.dbo.document_prompts (
            fk_doc_uid, user_name, prompt_text, prompt_response,
            model_name, tokens_input, tokens_output, processing_ms,
            cited_fields, session_id, prompt_sequence, created_at
        )
        VALUES (
            <cfqueryparam value="#form.doc_uid#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#getAuthUser()#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.prompt_text#" cfsqltype="cf_sql_longvarchar">,
            <cfqueryparam value="#response.response_text#" cfsqltype="cf_sql_longvarchar">,
            <cfqueryparam value="#response.model_name#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#response.tokens_input#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#response.tokens_output#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#response.processing_ms#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#serializeJSON(response.cited_fields)#" cfsqltype="cf_sql_longvarchar">,
            <cfqueryparam value="#form.session_id#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#getNextSequence(form.session_id)#" cfsqltype="cf_sql_integer">,
            SYSUTCDATETIME()
        );
        SELECT SCOPE_IDENTITY() AS prompt_id;
    </cfquery>

    <cfset response.prompt_id = insertPrompt.prompt_id>
    <cfset response.ok = true>

    <cfoutput>#serializeJSON(response)#</cfoutput>

    <cfcatch type="any">
        <cfheader statuscode="500">
        <cfoutput>#serializeJSON({"ok": false, "error": cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
```

#### 3. `/ajax/save_prompt_feedback.cfm`
**Purpose:** Save user feedback on AI responses
**Method:** POST
**Parameters:**
```json
{
    "prompt_id": 12345,
    "rating": 5,
    "comment": "Accurate and helpful!"
}
```

**Response:**
```json
{
    "ok": true
}
```

#### 4. `/ajax/load_conversation_history.cfm`
**Purpose:** Load previous Q&A for a document
**Method:** GET
**Parameters:**
- `doc_uid` (string) - Document UUID

**Response:**
```json
{
    "ok": true,
    "prompts": [
        {
            "id": 123,
            "prompt_text": "What was the settlement amount?",
            "response_text": "Based on...",
            "created_at": "2025-01-28T14:45:00Z",
            "cited_fields": ["fields.settlement_amount"],
            "feedback_rating": 5
        },
        ...
    ]
}
```

---

## Python Implementation

### New Script: `/python/answer_from_json.py`

**Purpose:** Answer user questions using extracted JSON facts only

**Command-Line Interface:**
```bash
python answer_from_json.py --doc_uid=UUID --prompt="User question here"
```

**Output:** JSON to stdout
```json
{
    "response_text": "Based on the extracted facts...",
    "cited_fields": ["fields.settlement_amount"],
    "model_name": "gemini-2.5-flash",
    "processing_ms": 1200,
    "tokens_input": 450,
    "tokens_output": 85,
    "error": null
}
```

**Implementation:**

```python
"""
Answer user questions about documents using extracted JSON facts.
Ensures FACT_GUARD compliance by answering only from verified extraction.
"""

import os
import sys
import json
import time
import argparse
import google.generativeai as genai

# Fix encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

# Redirect print to stderr
original_stdout = sys.stdout
sys.stdout = sys.stderr

def load_document_json(doc_uid: str) -> dict:
    """
    Load extracted JSON facts from database for given document.

    Args:
        doc_uid: Document UUID

    Returns:
        Dictionary with extracted fields
    """
    import pyodbc

    conn_str = (
        "DRIVER={SQL Server};"
        "SERVER=your-server;"
        "DATABASE=docketwatch;"
        "Trusted_Connection=yes;"
    )

    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT summary_ai_extraction_json
        FROM docketwatch.dbo.documents
        WHERE doc_uid = ?
    """, (doc_uid,))

    row = cursor.fetchone()
    conn.close()

    if not row or not row[0]:
        raise ValueError(f"No extraction JSON found for doc_uid: {doc_uid}")

    return json.loads(row[0])


def answer_from_facts(extraction: dict, user_question: str) -> dict:
    """
    Use Gemini to answer question based ONLY on extracted facts.

    Args:
        extraction: Dictionary of extracted fields
        user_question: User's natural language question

    Returns:
        Response with answer and citations
    """
    t_start = time.time()

    # Configure Gemini with service account (no API key needed)
    model = genai.GenerativeModel("gemini-2.5-flash")

    # Build prompt that enforces FACT_GUARD principle
    system_prompt = """You are a legal document assistant. Answer the user's question using ONLY the provided extracted facts from the document.

CRITICAL RULES:
1. Answer ONLY from the provided JSON facts - do NOT invent information
2. If the facts don't contain the answer, say "This information is not available in the extracted facts"
3. Cite which field(s) you used (e.g., "According to fields.settlement_amount...")
4. Keep answers concise and factual
5. Never speculate or make assumptions

Extracted Facts (JSON):
```json
{facts_json}
```

User Question: {question}

Provide your answer and list the JSON field paths you cited."""

    prompt = system_prompt.format(
        facts_json=json.dumps(extraction, indent=2),
        question=user_question
    )

    # Call Gemini
    response = model.generate_content(prompt)
    response_text = response.text

    # Extract cited fields from response (simple heuristic)
    cited_fields = extract_citations(response_text, extraction)

    processing_ms = int((time.time() - t_start) * 1000)

    # Get token counts if available
    try:
        tokens_input = response.usage_metadata.prompt_token_count
        tokens_output = response.usage_metadata.candidates_token_count
    except:
        tokens_input = 0
        tokens_output = 0

    return {
        "response_text": response_text,
        "cited_fields": cited_fields,
        "model_name": "gemini-2.5-flash",
        "processing_ms": processing_ms,
        "tokens_input": tokens_input,
        "tokens_output": tokens_output,
        "error": None
    }


def extract_citations(response_text: str, extraction: dict) -> list:
    """
    Extract field paths that were likely used from the response.

    This is a heuristic - looks for mentions of field names in the response.

    Args:
        response_text: AI's response text
        extraction: The extraction dict

    Returns:
        List of field paths (e.g., ["fields.settlement_amount"])
    """
    cited = []

    def check_field(path: str, value: any):
        """Recursively check if field value appears in response."""
        if isinstance(value, str) and len(value) > 3:
            if value.lower() in response_text.lower():
                cited.append(path)
        elif isinstance(value, (int, float)):
            if str(value) in response_text:
                cited.append(path)
        elif isinstance(value, dict):
            for k, v in value.items():
                check_field(f"{path}.{k}", v)
        elif isinstance(value, list):
            for item in value:
                if isinstance(item, str) and len(item) > 3:
                    if item.lower() in response_text.lower():
                        cited.append(path)
                        break

    # Check all top-level fields
    for key, val in extraction.items():
        check_field(f"fields.{key}", val)

    return list(set(cited))  # Remove duplicates


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Answer questions about documents using extracted JSON facts"
    )
    parser.add_argument("--doc_uid", required=True, help="Document UUID")
    parser.add_argument("--prompt", required=True, help="User's question")

    args = parser.parse_args()

    try:
        # Load extraction JSON from database
        print(f"Loading extraction for doc_uid: {args.doc_uid}", file=sys.stderr)
        extraction = load_document_json(args.doc_uid)

        # Answer question
        print(f"Processing question: {args.prompt[:100]}...", file=sys.stderr)
        result = answer_from_facts(extraction, args.prompt)

        # Output JSON to stdout
        sys.stdout = original_stdout
        print(json.dumps(result, ensure_ascii=False, indent=2))

    except Exception as e:
        import traceback
        tb = traceback.format_exc()

        error_result = {
            "response_text": "",
            "cited_fields": [],
            "model_name": "gemini-2.5-flash",
            "processing_ms": 0,
            "tokens_input": 0,
            "tokens_output": 0,
            "error": f"{type(e).__name__}: {str(e)}"
        }

        print(tb, file=sys.stderr)
        sys.stdout = original_stdout
        print(json.dumps(error_result, ensure_ascii=False, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
```

### Integration with Existing `summarize_upload_cli.py`

**Option 1:** Keep separate scripts (recommended for modularity)
- `summarize_upload_cli.py` - Initial processing
- `answer_from_json.py` - Q&A functionality

**Option 2:** Add Q&A as subcommand to existing script
```python
# In summarize_upload_cli.py
parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(dest='command')

# Existing command
process_parser = subparsers.add_parser('process')
process_parser.add_argument('--in', ...)

# New command
qa_parser = subparsers.add_parser('qa')
qa_parser.add_argument('--doc_uid', ...)
qa_parser.add_argument('--prompt', ...)
```

---

## Security Considerations

### 1. Input Validation
- **Prompt Injection:** Sanitize user prompts to prevent malicious instructions
  ```python
  # Example: Limit prompt length
  if len(user_prompt) > 500:
      return {"error": "Prompt too long (max 500 characters)"}

  # Check for injection patterns
  forbidden_patterns = ["ignore previous", "disregard instructions", "new task"]
  if any(p in user_prompt.lower() for p in forbidden_patterns):
      return {"error": "Invalid prompt detected"}
  ```

- **SQL Injection:** Use `cfqueryparam` in all database queries
- **XSS:** Escape all user input before displaying in HTML

### 2. Rate Limiting
- Limit prompts per user per document (e.g., 50 per hour)
- Track in `document_prompts` table with timestamp checks

```cfm
<cfquery name="checkRate" datasource="Reach">
    SELECT COUNT(*) as prompt_count
    FROM docketwatch.dbo.document_prompts
    WHERE user_name = <cfqueryparam value="#getAuthUser()#" cfsqltype="cf_sql_varchar">
    AND created_at > DATEADD(hour, -1, SYSUTCDATETIME())
</cfquery>

<cfif checkRate.prompt_count GTE 50>
    <cfthrow message="Rate limit exceeded. Maximum 50 prompts per hour.">
</cfif>
```

### 3. Access Control
- Verify user has permission to access document before answering prompts
- Check if document is ad-hoc upload (owned by uploader) or case-related (check case permissions)

```cfm
<cfquery name="checkAccess" datasource="Reach">
    SELECT d.doc_uid
    FROM docketwatch.dbo.documents d
    LEFT JOIN docketwatch.dbo.case_events ce ON ce.event_uid = d.fk_case_event
    LEFT JOIN docketwatch.dbo.cases c ON c.id = ce.fk_case
    WHERE d.doc_uid = <cfqueryparam value="#form.doc_uid#" cfsqltype="cf_sql_varchar">
    AND (
        c.owner = <cfqueryparam value="#getAuthUser()#" cfsqltype="cf_sql_varchar">
        OR d.fk_case_event = '00000000-0000-0000-0000-000000000000'  -- Ad-hoc upload
    )
</cfquery>

<cfif checkAccess.recordCount EQ 0>
    <cfthrow message="Access denied">
</cfif>
```

### 4. Data Privacy
- Log all prompts for audit trail
- Implement data retention policy (delete prompts older than 2 years?)
- Ensure prompts don't leak sensitive information in logs

---

## Implementation Roadmap

### Phase 1: Database & Infrastructure (Week 1)
- [ ] Create `document_prompts` table (SQL script)
- [ ] Add indexes for performance
- [ ] Update `documents` table if needed (add columns for prompt count, last prompted, etc.)
- [ ] Test database connectivity from Python
- [ ] Set up session tracking for conversations

### Phase 2: Python Q&A Script (Week 1-2)
- [ ] Create `answer_from_json.py` script
- [ ] Implement `load_document_json()` function
- [ ] Implement `answer_from_facts()` with Gemini API
- [ ] Add citation extraction logic
- [ ] Write unit tests for Q&A logic
- [ ] Test with sample documents and questions
- [ ] Handle edge cases (no facts, malformed JSON, API errors)

### Phase 3: Backend CFML Endpoints (Week 2)
- [ ] Create `/ajax/ask_document_question.cfm`
- [ ] Create `/ajax/save_prompt_feedback.cfm`
- [ ] Create `/ajax/load_conversation_history.cfm`
- [ ] Add rate limiting middleware
- [ ] Add access control checks
- [ ] Log Gemini API calls to `gemini_api_log` table
- [ ] Test all endpoints with Postman/curl

### Phase 4: Frontend - Upload Page Redesign (Week 3)
- [ ] Redesign `/tools/summarize/index.cfm` with left-aligned layout
- [ ] Create processing modal component
- [ ] Implement progress polling (optional: websockets for real-time updates)
- [ ] Update JavaScript to redirect to results page on completion
- [ ] Test upload flow end-to-end

### Phase 5: Frontend - Results & Q&A Page (Week 3-4)
- [ ] Create new `/tools/summarize/view.cfm` page
- [ ] Implement tabbed interface (Summary/JSON/OCR)
- [ ] Build conversation history component
- [ ] Add prompt input and "Ask" button
- [ ] Implement real-time Q&A (AJAX call → display response)
- [ ] Add feedback buttons (thumbs up/down)
- [ ] Style conversation bubbles (user vs. AI)
- [ ] Add loading indicators for async operations

### Phase 6: Integration & Testing (Week 4)
- [ ] End-to-end testing: Upload → Process → View → Prompt
- [ ] Test with various document types (complaints, motions, orders, etc.)
- [ ] Test edge cases:
  - Document with no extractable facts
  - Questions outside scope of facts
  - Malformed prompts
  - Multiple rapid prompts
- [ ] Performance testing (response times, database load)
- [ ] User acceptance testing with TMZ team

### Phase 7: Polish & Deployment (Week 5)
- [ ] Add keyboard shortcuts (Enter to submit prompt)
- [ ] Implement conversation export (PDF, CSV)
- [ ] Add "Clear conversation" button
- [ ] Create user documentation
- [ ] Deploy to staging environment
- [ ] Final QA and bug fixes
- [ ] Deploy to production

### Phase 8: Analytics & Monitoring (Week 6)
- [ ] Add usage dashboards (prompt counts, popular questions)
- [ ] Monitor API costs (Gemini token usage)
- [ ] Track feedback ratings to improve prompts
- [ ] Set up alerts for errors or high latency

---

## Testing Strategy

### Unit Tests

#### Python Tests (`test_answer_from_json.py`)
```python
def test_load_document_json():
    """Test loading extraction JSON from database."""
    extraction = load_document_json("test-uuid")
    assert "filing_action_summary" in extraction

def test_answer_simple_question():
    """Test answering question with clear fact."""
    extraction = {"settlement_amount": "$50,000"}
    result = answer_from_facts(extraction, "What was the settlement amount?")
    assert "$50,000" in result["response_text"]
    assert "fields.settlement_amount" in result["cited_fields"]

def test_answer_unavailable_fact():
    """Test handling question with no matching fact."""
    extraction = {"plaintiff": "John Doe"}
    result = answer_from_facts(extraction, "What was the settlement amount?")
    assert "not available" in result["response_text"].lower()
```

#### ColdFusion Tests (Manual or CFUnit)
- Test endpoint with valid/invalid doc_uid
- Test rate limiting enforcement
- Test access control (user can only access own documents)
- Test prompt logging to database

### Integration Tests
1. **Full Upload Flow:**
   - Upload PDF → Process → Redirect → Load results → Prompt → Display answer

2. **Conversation Flow:**
   - Ask multiple questions in sequence
   - Verify conversation history persists
   - Test feedback submission

3. **Error Handling:**
   - Invalid doc_uid → Show friendly error
   - Python script timeout → Return timeout message
   - Database connection failure → Graceful degradation

### Performance Tests
- Upload 100 documents and measure average processing time
- Submit 50 prompts concurrently and check response times
- Monitor database query performance (add indexes if needed)
- Check Gemini API rate limits and quotas

### User Acceptance Tests
- TMZ staff upload real documents and ask realistic questions
- Gather feedback on:
  - Accuracy of answers
  - Ease of use
  - UI/UX clarity
  - Missing features

---

## Success Metrics

### Quantitative
- **Usage:** % of documents that receive follow-up prompts
- **Engagement:** Average prompts per document
- **Accuracy:** % of prompts with positive feedback (thumbs up)
- **Performance:** 95th percentile response time < 3 seconds
- **Reliability:** < 1% error rate on prompts

### Qualitative
- User satisfaction survey (1-5 stars)
- Feature adoption (are users actually using Q&A?)
- Feedback comments (what improvements do users suggest?)

---

## Future Enhancements

### V2 Features (Post-Launch)
1. **Multi-Document Q&A:** Compare facts across multiple documents
2. **Conversation Export:** Download Q&A history as PDF or Word doc
3. **Suggested Questions:** AI proposes relevant questions based on extraction
4. **Voice Input:** Use speech-to-text for prompts
5. **Smart Summaries:** Generate summaries of entire conversations
6. **Collaboration:** Share documents and conversations with team members
7. **Advanced Search:** Search across all prompts and responses
8. **Custom Extraction Templates:** Users define custom fields to extract

### Technical Improvements
- WebSocket support for real-time progress updates (instead of polling)
- Redis caching for frequently accessed documents
- Elasticsearch for full-text search across prompts
- GraphQL API for more flexible data queries

---

## Appendix

### A. Database Connection String (Python)
```python
import pyodbc

conn_str = (
    "DRIVER={SQL Server};"
    "SERVER=your-sql-server-hostname;"
    "DATABASE=docketwatch;"
    "Trusted_Connection=yes;"
)

conn = pyodbc.connect(conn_str)
cursor = conn.cursor()
```

### B. Gemini API Configuration (Python)
```python
import google.generativeai as genai
import os

# Option 1: Service Account (recommended)
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/path/to/service-account.json"
genai.configure()

# Option 2: API Key (from database)
api_key = get_util("GeminiApiKey")
genai.configure(api_key=api_key)
```

### C. Sample Extraction JSON
```json
{
    "filing_action_summary": "Plaintiff filed motion for summary judgment",
    "doc_type": "Motion",
    "filing_date_iso": "2025-01-15",
    "parties": {
        "plaintiff": "John Doe",
        "defendant": "Jane Celebrity"
    },
    "settlement_amount": "$50,000",
    "newsworthiness": "HIGH",
    "newsworthiness_reason": "Celebrity defendant with prior convictions",
    "financial_terms": [
        "Settlement of $50,000",
        "Payment due within 30 days"
    ]
}
```

### D. Sample Prompts & Expected Responses

| User Prompt | Expected Answer | Cited Fields |
|-------------|----------------|--------------|
| "What was the settlement amount?" | "The settlement amount was $50,000." | `fields.settlement_amount` |
| "Who is the plaintiff?" | "The plaintiff is John Doe." | `fields.parties.plaintiff` |
| "When was this filed?" | "This was filed on January 15, 2025." | `fields.filing_date_iso` |
| "Is this newsworthy?" | "Yes, this is rated as HIGH newsworthiness due to celebrity defendant with prior convictions." | `fields.newsworthiness`, `fields.newsworthiness_reason` |
| "What was the weather on that day?" | "This information is not available in the extracted facts." | (none) |

---

**End of Plan**

Last Updated: 2025-01-28
Next Review: After Phase 1 completion
