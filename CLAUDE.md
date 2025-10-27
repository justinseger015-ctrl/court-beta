# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DocketWatch is a court case monitoring and AI-powered legal document summarization system built for TMZ. It tracks celebrity-related legal cases, monitors PACER RSS feeds, and generates newsworthy summaries of legal documents using AI.

**Technology Stack:**
- **Backend:** ColdFusion (CFML) on Windows Server
- **Database:** Microsoft SQL Server (datasource: "Reach", database: "docketwatch")
- **Frontend:** Bootstrap 5, jQuery, DataTables
- **Python:** 3.12+ for PDF processing, OCR, and AI summarization
- **AI:** Google Gemini API (gemini-2.5-flash, gemini-2.5-pro)

## Development Commands

### ColdFusion Development
- **No build process required** - CFML is interpreted at runtime
- **Test changes:** Save `.cfm` files and refresh browser (restart CF application if needed)
- **View logs:** Check ColdFusion Administrator logs and custom logs (written via `cflog`)

### Python Scripts
```bash
# Test PDF processing
python U:\docketwatch\python\combined_pacer_pdf_processor.py <url> <output_path>

# Test AI summarization (ad-hoc upload tool)
python U:\docketwatch\python\summarize_upload_cli.py --in "path/to/document.pdf" --extra "optional instructions"

# Common Python location
"C:\Program Files\Python312\python.exe"
```

### Database Queries
- **Connection:** Use datasource="Reach" in all `cfquery` tags
- **Schema:** Always fully qualify tables as `docketwatch.dbo.table_name`
- **SQL Scripts:** Located in `/sql/` directory
- **Run SQL:** Via SQL Server Management Studio or `cfquery`

### Testing Specific Features
```cfm
<!-- Test RSS monitoring -->
setup_rss_test.bat

<!-- Delete unfiled PDFs -->
run_deletion.bat

<!-- Fix Python syntax (utility scripts) -->
fix_python_complete.ps1
```

## Architecture

### Core Components

#### 1. Case Management System
- **Entry Point:** `/index.cfm` - Main dashboard for case tracking
- **Case Details:** `/case_details.cfm?id={case_id}` - Full case view with events, documents, hearings
- **Case Events:** `/case_events.cfm` - Alert dashboard showing new court events requiring acknowledgment

**Key Database Tables:**
- `docketwatch.dbo.cases` - Court cases being tracked
- `docketwatch.dbo.case_events` - Individual docket entries/events per case
- `docketwatch.dbo.documents` - PDFs and documents with OCR text and AI summaries
- `docketwatch.dbo.case_celebrity_matches` - Links between cases and celebrities

#### 2. Celebrity Matching System
- **Process:** Automatically matches case parties against celebrity database
- **Files:** `/includes/functions.cfm` contains matching algorithms (`fncNormalizeCaseName`, `fncIsMatch`)
- **Manual Tools:** Celebrity lookup modals, gallery views at `/celebrity_gallery.cfm`

#### 3. AI Summarization Pipeline

**Two-Step FACT_GUARD Verification:**
1. **Extract:** Structured field extraction from OCR text (parties, dates, charges, dispositions)
2. **Verify:** Generate summary from extracted facts, validate against facts to prevent hallucinations

**Frontend:** `/tools/summarize/index.cfm` - Drag-and-drop PDF upload interface
**Backend:** `/ajax/upload_and_summarize.cfm` - Handles uploads, calls Python worker
**Python Worker:** `U:\docketwatch\python\summarize_upload_cli.py` (CLI interface)

**Key Features:**
- OCR extraction with preprocessing (300 DPI, grayscale, denoise, deskew)
- Structured field extraction (JSON schema)
- Newsroom-safe summary generation
- FACT_GUARD verification to prevent hallucinations
- QC feedback system (`docketwatch.dbo.summary_qc_feedback`)

**Database Integration:**
- Documents stored in `docketwatch.dbo.documents` table
- Ad-hoc uploads linked to placeholder case: `ADHOC-UPLOADS-2025`
- Placeholder event ID: Use `EXEC dbo.sp_get_adhoc_upload_event_id`
- Gemini API calls logged in `docketwatch.dbo.gemini_api_log`

#### 4. AJAX Endpoints (`/ajax/` directory)
- `upload_and_summarize.cfm` - PDF upload + AI summarization
- `save_qc_feedback.cfm` - Save quality control feedback
- `ajax_generateSummary.cfm` - Generate summary for existing document
- `ajax_getPacerDoc.cfm` - Download document from PACER
- `ajax_acknowledgeEvent.cfm` - Mark event as acknowledged

#### 5. Authentication & Session Management
- **File:** `Application.cfc`
- **Auth Method:** Windows NT Authentication (`cfnTAuthenticate` with "tmz" domain)
- **Login:** `/dwloginform.cfm`
- **Logout:** `/logout.cfm`
- **Session Storage:** Session-scoped, 4-hour timeout
- **Bypass:** Set `Bypass` variable or use `?bypass=1` in URL (for AJAX requests)

### File Organization

```
/                       Root - Main CFML pages (index.cfm, case_details.cfm, etc.)
/ajax/                  AJAX endpoints for async operations
/includes/              Shared utilities and functions
/sql/                   Database scripts and stored procedures
/python/                Python workers for PDF/OCR/AI processing
/tools/                 Specialized tools (summarize, etc.)
/css/                   Stylesheets
/docs/                  Document storage (PDFs organized by case)
/uploads/               Temporary upload directory for ad-hoc files
```

## Common Development Patterns

### Database Queries
Always use parameterized queries with `cfqueryparam`:

```cfm
<cfquery name="result" datasource="Reach">
    SELECT * FROM docketwatch.dbo.cases
    WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>
```

### Error Handling
```cfm
<cftry>
    <!-- Your code here -->
    <cfcatch type="any">
        <cflog file="error_log" type="error" text="#cfcatch.message# - #cfcatch.detail#">
        <cfheader statuscode="500">
        <cfoutput>{"error": "#cfcatch.message#"}</cfoutput>
    </cfcatch>
</cftry>
```

### Logging
```cfm
<!-- Log to custom log file -->
<cflog file="summarize_upload" type="information" text="Processing doc #docId#">

<!-- Available log types: information, warning, error -->
```

### Calling Python from CFML
```cfm
<cfset pythonExe = "C:\Program Files\Python312\python.exe">
<cfset scriptPath = "U:\docketwatch\python\script.py">

<cfexecute name="#pythonExe#"
           arguments="#[scriptPath, '--arg1', 'value1']#"
           timeout="300"
           variable="output"
           errorVariable="errors">
</cfexecute>

<!-- Parse JSON output -->
<cfset result = deserializeJSON(output)>
```

### JSON API Responses
```cfm
<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<cfset response = {
    "status": "success",
    "data": dataStruct
}>

<cfoutput>#serializeJSON(response)#</cfoutput>
```

## AI Summarization Workflow

### Standard Event Summarization
1. New court event detected via RSS feed or manual upload
2. PDF downloaded and stored in `docs/cases/{case_id}/E{doc_id}.pdf`
3. Python script extracts OCR text
4. Two-step Gemini API call:
   - **Step 1:** Extract structured fields (JSON schema)
   - **Step 2:** Generate human-readable summary citing only extracted fields
5. FACT_GUARD verification validates summary against facts
6. Results stored in `documents` table (columns: `ocr_text`, `summary_ai`, `summary_ai_html`, `summary_ai_extraction_json`)
7. Email notifications sent to case subscribers

### Ad-Hoc Upload Tool
- **URL:** `/tools/summarize/index.cfm`
- Documents uploaded to `U:\docketwatch\uploads\`
- Linked to placeholder case event (UUID: `E906C250-7BBB-4D8E-BB1B-C5E1AB10BCE6`)
- QC feedback stored in `docketwatch.dbo.summary_qc_feedback`

### Gemini API Usage
```python
# Model selection (typical)
EXTRACT_MODEL = "gemini-2.5-flash"    # For field extraction
SUMMARY_MODEL = "gemini-2.5-flash"    # For summary generation
VERIFY_MODEL = "gemini-2.5-flash"     # For FACT_GUARD verification

# All API calls logged to docketwatch.dbo.gemini_api_log with:
# - script_name, model_name
# - input_tokens, output_tokens
# - success (bit), error_message
# - processing_time_ms, cost_estimate
```

## Important Database Tables

### Cases & Events
- `cases` - Court cases (columns: case_number, case_name, court_code, status, owner, etc.)
- `case_events` - Docket entries (columns: event_date, event_description, isDoc, acknowledged, processing)
- `documents` - PDFs with AI data (columns: doc_uid, rel_path, ocr_text, summary_ai, summary_ai_html)

### Celebrity Tracking
- `celebrities` - Celebrity database (columns: name, tmz_celeb_id)
- `case_celebrity_matches` - Links cases to celebrities (columns: fk_case, fk_celebrity, match_status)

### Reference Data
- `courts` - Courthouses (columns: court_code, court_name, address, fk_county)
- `counties` - Counties (columns: id, name, state_code)
- `states` - States (columns: state_code, state_name)

### Monitoring & QC
- `gemini_api_log` - AI API call telemetry
- `summary_qc_feedback` - Quality control feedback for AI summaries
- `scheduled_task_log` - Scheduled task execution history

### Users & Permissions
- `users` - User accounts (columns: username, firstname, lastname, email, userRole)
- `case_email_recipients` - Per-case notification subscriptions

## Security Considerations

1. **File Uploads:**
   - Validate PDF magic bytes (`%PDF`)
   - 25 MB file size limit
   - Store uploads outside webroot when possible
   - Use `nameConflict="makeunique"` to prevent overwrites

2. **SQL Injection:**
   - ALWAYS use `cfqueryparam` for user input in queries
   - Never concatenate user input directly into SQL

3. **Authentication:**
   - Most pages require authentication (handled in `Application.cfc`)
   - AJAX endpoints bypass auth checks - validate permissions manually if needed
   - Use `getAuthUser()` to get current username

4. **Sensitive Data:**
   - API keys stored in `docketwatch.dbo.utilities` table
   - Never commit credentials to version control
   - Log files may contain sensitive info - be careful with error messages

## Testing & Debugging

### Local Testing
- **ColdFusion Admin:** Check server logs, datasource connections
- **Browser DevTools:** Monitor AJAX calls, console errors
- **SQL Profiler:** Debug database queries
- **Python CLI:** Test scripts independently before CFML integration

### Common Issues

**"Failed to parse Python output"**
- Check Python stderr in logs
- Verify Python dependencies installed
- Test Python script directly from command line
- Check for non-JSON output (HTML errors, print statements)

**"Database query failed"**
- Verify datasource="Reach" is correct
- Check table names include schema: `docketwatch.dbo.table_name`
- Validate SQL Server connection in CF Admin
- Check for SQL syntax errors in logs

**"Authentication required"**
- Ensure user is logged in (check session)
- For AJAX: add `?bypass=1` parameter or handle in `Application.cfc`
- Verify NT Authentication is working

## Environment Configuration

### Application Variables (set in `Application.cfc`)
- `application.serverDomain` - Server domain (e.g., "docketwatch.tmz.tv")
- `application.fileSharePath` - Network path for shared files
- `application.appType` - "docketwatch" or "tmztools"
- `application.siteTitle` - Display title
- `application.webRoot` - Relative web path

### File Paths
- **Upload Directory:** `U:\docketwatch\uploads\`
- **Document Storage:** `U:\docketwatch\docs\cases\{case_id}\`
- **Python Scripts:** `U:\docketwatch\python\`
- **Python Executable:** `C:\Program Files\Python312\python.exe`

### Database Connection
- **Datasource Name:** "Reach"
- **Database:** "docketwatch"
- **Schema:** "dbo"
- **Server:** Configured in ColdFusion Administrator

## Additional Notes

- **Session Timeout:** 4 hours (configurable in `Application.cfc`)
- **DataTables:** Used extensively for case grids - server-side processing enabled
- **Date Handling:** SQL Server uses `DATETIME2(7)`, ColdFusion uses `now()` for current timestamp
- **OCR Preprocessing:** 300 DPI, grayscale, denoise, Otsu thresholding, deskew for best accuracy
- **Model Naming:** Recent commits updated model names to new conventions (e.g., gemini-2.5-flash)
