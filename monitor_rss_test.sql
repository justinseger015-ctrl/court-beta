-- DocketWatch RSS Pipeline Test Monitoring Script
-- Run this script after triggering the RSS test to monitor pipeline progress

-- STEP 1: Monitor for event recreation (run every few minutes)
PRINT '=== Checking for Event Recreation ===';
PRINT 'Looking for events created in the last 30 minutes...';

SELECT TOP 10
    e.id as event_id,
    e.fk_cases,
    e.event_no,
    LEFT(e.event_description, 60) as event_description,
    e.status,
    e.created_at,
    LEFT(c.case_name, 40) as case_name,
    c.pacer_id,
    r.guid,
    DATEDIFF(minute, e.created_at, GETDATE()) as minutes_ago
FROM docketwatch.dbo.case_events e
INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
LEFT JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
WHERE e.created_at >= DATEADD(minute, -30, GETDATE())
ORDER BY e.created_at DESC;

PRINT '';

-- STEP 2: Check RSS entries
PRINT '=== Recent RSS Feed Entries ===';
SELECT TOP 10
    guid,
    pacer_id,
    event_no,
    LEFT(case_name, 40) as case_name,
    LEFT(event_description, 60) as event_desc,
    processed,
    first_seen,
    DATEDIFF(minute, first_seen, GETDATE()) as minutes_ago
FROM docketwatch.dbo.rss_feed_entries
WHERE first_seen >= DATEADD(minute, -30, GETDATE())
ORDER BY first_seen DESC;

PRINT '';

-- STEP 3: Check document pipeline progress
PRINT '=== Document Pipeline Status ===';
SELECT 
    d.id,
    d.fk_case_event,
    d.fk_case,
    d.doc_id,
    LEFT(d.file_name, 40) as file_name,
    d.status,
    d.file_size,
    CASE WHEN LEN(d.ocr_text) > 0 THEN 'OCR Complete' ELSE 'OCR Pending' END as ocr_status,
    d.created_at,
    DATEDIFF(minute, d.created_at, GETDATE()) as minutes_ago
FROM docketwatch.dbo.documents d
WHERE d.created_at >= DATEADD(minute, -30, GETDATE())
ORDER BY d.created_at DESC;

PRINT '';

-- STEP 4: Check scheduled task runs
PRINT '=== Recent Task Executions ===';
SELECT TOP 10
    task_name,
    start_time,
    end_time,
    status,
    LEFT(error_message, 60) as error_message,
    DATEDIFF(minute, start_time, GETDATE()) as minutes_ago
FROM docketwatch.dbo.scheduled_task_runs
WHERE start_time >= DATEADD(minute, -30, GETDATE())
ORDER BY start_time DESC;

PRINT '';

-- STEP 5: Pipeline success indicators
PRINT '=== Pipeline Success Indicators ===';

-- Count new events
DECLARE @new_events INT = (
    SELECT COUNT(*) FROM docketwatch.dbo.case_events 
    WHERE created_at >= DATEADD(minute, -30, GETDATE())
);

-- Count new documents
DECLARE @new_documents INT = (
    SELECT COUNT(*) FROM docketwatch.dbo.documents 
    WHERE created_at >= DATEADD(minute, -30, GETDATE())
);

-- Count completed OCR
DECLARE @completed_ocr INT = (
    SELECT COUNT(*) FROM docketwatch.dbo.documents 
    WHERE created_at >= DATEADD(minute, -30, GETDATE())
    AND LEN(ocr_text) > 0
);

PRINT 'New Events Created: ' + CAST(@new_events AS VARCHAR(10));
PRINT 'New Documents Found: ' + CAST(@new_documents AS VARCHAR(10));
PRINT 'OCR Completed: ' + CAST(@completed_ocr AS VARCHAR(10));

IF @new_events > 0 AND @new_documents > 0
    PRINT '✓ RSS Pipeline appears to be working - events and documents detected';
ELSE IF @new_events > 0
    PRINT '⚠ Events created but no documents yet - pipeline may still be running';
ELSE
    PRINT '✗ No new events detected - check RSS trigger and logs';

PRINT '';
PRINT '=== Log File Locations to Check ===';
PRINT 'RSS Trigger: \\10.146.176.84\general\docketwatch\python\logs\docketwatch_rss_trigger_plus.log';
PRINT 'Scraper: \\10.146.176.84\general\docketwatch\python\logs\docketwatch_scraper.log';
PRINT 'PDF Finder: \\10.146.176.84\general\docketwatch\python\logs\final_pdfs_finder.log';
PRINT 'Summarizer: \\10.146.176.84\general\docketwatch\python\logs\pacer_case_summarizer.log';
PRINT 'Errors: \\10.146.176.84\general\docketwatch\python\logs\error_notifications.log';
