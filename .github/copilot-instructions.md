# GitHub Copilot Instructions for DocketWatch

## Project Overview

DocketWatch is a court case monitoring and AI-powered legal document summarization system built for TMZ. It tracks celebrity-related legal cases, monitors PACER RSS feeds, and generates newsworthy summaries of legal documents using AI.

**Technology Stack:**
- **Backend:** ColdFusion (CFML) on Windows Server
- **Database:** Microsoft SQL Server (datasource: "Reach", database: "docketwatch")
- **Frontend:** Bootstrap 5, jQuery, DataTables
- **Python:** 3.12+ for PDF processing, OCR, and AI summarization
- **AI:** Google Gemini API (gemini-2.5-flash, gemini-2.5-pro)

## Code Style Guidelines

### ColdFusion (CFML)
- Always use `cfqueryparam` for SQL parameters
- Fully qualify database objects: `docketwatch.dbo.table_name`
- Use datasource="Reach" for all queries
- Prefer `<cfscript>` blocks for logic when possible
- Use `cflog` for logging with appropriate log types (information, warning, error)
- Handle errors with `<cftry>/<cfcatch>` blocks

### Database Queries
```cfm
<cfquery name="result" datasource="Reach">
    SELECT * FROM docketwatch.dbo.cases
    WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>
```

### JSON API Responses
```cfm
<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">
<cfoutput>#serializeJSON(response)#</cfoutput>
```

### Python Integration
```cfm
<cfset pythonExe = "C:\Program Files\Python312\python.exe">
<cfexecute name="#pythonExe#" arguments="#[scriptPath, arg1, arg2]#" timeout="300" variable="output" errorVariable="errors"></cfexecute>
<cfset result = deserializeJSON(output)>
```

## Key Architecture Patterns

### File Organization
- `/` - Main CFML pages
- `/ajax/` - AJAX endpoints
- `/includes/` - Shared utilities
- `/sql/` - Database scripts
- `/python/` - Python workers
- `/tools/` - Specialized tools

### Authentication
- Handled in `Application.cfc`
- Windows NT Authentication with "tmz" domain
- Use `getAuthUser()` to get current username
- AJAX endpoints can bypass with `?bypass=1`

### AI Summarization
- Two-step FACT_GUARD process (extract → verify)
- Models: gemini-2.5-flash (standard), gemini-2.5-pro (complex)
- All API calls logged to `docketwatch.dbo.gemini_api_log`
- QC feedback stored in `docketwatch.dbo.summary_qc_feedback`

## Security Best Practices
1. Always use `cfqueryparam` for user input in SQL
2. Validate PDF magic bytes (`%PDF`) for uploads
3. Use 25 MB file size limit
4. Never expose API keys in code
5. Log sensitive operations for audit trail

## Important Database Tables
- `cases` - Court cases being tracked
- `case_events` - Docket entries/events
- `documents` - PDFs with OCR text and AI summaries
- `celebrities` - Celebrity database
- `case_celebrity_matches` - Case-celebrity links
- `gemini_api_log` - AI API telemetry

## Common File Paths
- Upload Directory: `U:\docketwatch\uploads\`
- Document Storage: `U:\docketwatch\docs\cases\{case_id}\`
- Python Scripts: `U:\docketwatch\python\`
- Python Executable: `C:\Program Files\Python312\python.exe`

## When Writing Code
1. Always include error handling (`<cftry>/<cfcatch>`)
2. Log important operations with `cflog`
3. Use parameterized queries exclusively
4. Follow existing naming conventions (snake_case for DB, camelCase for variables)
5. Include comments for complex logic
6. Test database connections before deployment
7. Validate file uploads before processing
8. Use meaningful log file names and error messages
