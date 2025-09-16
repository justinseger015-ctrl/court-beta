-- DocketWatch Case Event Reset Script for RSS Testing
-- This script helps you safely delete a recent case event for pipeline testing

-- STEP 1: Find recent case events (run this first to pick your target)
PRINT '=== Recent Case Events (Last 24 Hours) ===';
SELECT TOP 10 
    e.id as event_id,
    e.fk_cases,
    e.event_no,
    LEFT(e.event_description, 60) as event_description,
    e.status,
    e.created_at,
    LEFT(c.case_name, 40) as case_name,
    c.case_number,
    c.pacer_id,
    r.guid as rss_guid,
    r.event_no as rss_event_no,
    CASE WHEN r.guid IS NOT NULL THEN 'HAS RSS ENTRY' ELSE 'NO RSS ENTRY' END as rss_status
FROM docketwatch.dbo.case_events e
INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
LEFT JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
WHERE e.created_at >= DATEADD(hour, -24, GETDATE())
    AND c.status = 'Tracked'  -- Only tracked cases
    AND c.pacer_id IS NOT NULL  -- Only cases with PACER IDs
ORDER BY e.created_at DESC;

PRINT '';
PRINT '=== Instructions ===';
PRINT '1. Pick an event_id (GUID) from above that has RSS_STATUS = "HAS RSS ENTRY"';
PRINT '2. Copy the full GUID (including dashes) from the event_id column';
PRINT '3. Update the @target_event_id variable below with your chosen GUID';
PRINT '4. Example: SET @target_event_id = ''12345678-1234-1234-1234-123456789ABC'';';
PRINT '5. Run the backup and deletion section';
PRINT '';

-- STEP 2: Set your target event ID here
DECLARE @target_event_id UNIQUEIDENTIFIER = NULL;  -- *** CHANGE THIS TO YOUR TARGET EVENT ID (as GUID) ***

-- Safety check
IF @target_event_id IS NULL
BEGIN
    PRINT 'ERROR: Please set @target_event_id to a valid event GUID from the list above';
    PRINT 'Example: SET @target_event_id = ''12345678-1234-1234-1234-123456789ABC'';';
    RETURN;
END

-- Get event details
DECLARE @target_guid NVARCHAR(255);
DECLARE @target_case_id INT;
DECLARE @target_case_name NVARCHAR(500);
DECLARE @target_event_desc NVARCHAR(1000);
DECLARE @target_pacer_id INT;
DECLARE @target_event_no INT;

SELECT 
    @target_case_id = e.fk_cases,
    @target_case_name = c.case_name,
    @target_event_desc = e.event_description,
    @target_pacer_id = c.pacer_id,
    @target_event_no = e.event_no
FROM docketwatch.dbo.case_events e
INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
WHERE e.id = @target_event_id;

-- Get the RSS GUID separately
SELECT @target_guid = guid 
FROM docketwatch.dbo.rss_feed_entries 
WHERE pacer_id = @target_pacer_id AND event_no = @target_event_no;

-- Verify we found the event
IF @target_case_id IS NULL
BEGIN
    PRINT 'ERROR: Event ID ' + CAST(@target_event_id AS VARCHAR(50)) + ' not found';
    RETURN;
END

PRINT '=== Target Event Details ===';
PRINT 'Event ID: ' + CAST(@target_event_id AS VARCHAR(50));
PRINT 'Case ID: ' + CAST(@target_case_id AS VARCHAR(10));
PRINT 'PACER ID: ' + CAST(ISNULL(@target_pacer_id, 0) AS VARCHAR(10));
PRINT 'Event No: ' + CAST(ISNULL(@target_event_no, 0) AS VARCHAR(10));
PRINT 'Case Name: ' + @target_case_name;
PRINT 'Event Description: ' + LEFT(@target_event_desc, 100);
PRINT 'RSS GUID: ' + ISNULL(@target_guid, 'NO GUID FOUND');
PRINT '';

-- Safety check for GUID
IF @target_guid IS NULL
BEGIN
    PRINT 'WARNING: This event has no RSS entry. It may not reappear in RSS feed.';
    PRINT 'Consider choosing a different event with RSS_STATUS = "HAS RSS ENTRY"';
    RETURN;
END

-- STEP 3: Create backup tables with timestamp
DECLARE @backup_suffix VARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
DECLARE @backup_events_table VARCHAR(100) = 'case_events_backup_' + @backup_suffix;
DECLARE @backup_rss_table VARCHAR(100) = 'rss_feed_entries_backup_' + @backup_suffix;
DECLARE @backup_docs_table VARCHAR(100) = 'documents_backup_' + @backup_suffix;

PRINT '=== Creating Backups ===';
PRINT 'Event backup table: ' + @backup_events_table;
PRINT 'RSS backup table: ' + @backup_rss_table;
PRINT 'Documents backup table: ' + @backup_docs_table;

-- Backup case event
DECLARE @sql_backup_event NVARCHAR(MAX) = 
    'SELECT * INTO docketwatch.dbo.' + @backup_events_table + 
    ' FROM docketwatch.dbo.case_events WHERE id = ''' + CAST(@target_event_id AS VARCHAR(50)) + '''';
EXEC sp_executesql @sql_backup_event;

-- Backup RSS entry
DECLARE @sql_backup_rss NVARCHAR(MAX) = 
    'SELECT * INTO docketwatch.dbo.' + @backup_rss_table + 
    ' FROM docketwatch.dbo.rss_feed_entries WHERE pacer_id = ' + CAST(@target_pacer_id AS VARCHAR(10)) + 
    ' AND event_no = ' + CAST(@target_event_no AS VARCHAR(10));
EXEC sp_executesql @sql_backup_rss;

-- Backup related documents
DECLARE @sql_backup_docs NVARCHAR(MAX) = 
    'SELECT * INTO docketwatch.dbo.' + @backup_docs_table + 
    ' FROM docketwatch.dbo.documents WHERE fk_case_event = ''' + CAST(@target_event_id AS VARCHAR(50)) + '''';
EXEC sp_executesql @sql_backup_docs;

PRINT 'Backups created successfully.';
PRINT '';

-- STEP 4: Delete in correct order (foreign key dependencies)
PRINT '=== Deleting Records for Testing ===';

-- Delete documents first (child table)
DELETE FROM docketwatch.dbo.documents WHERE fk_case_event = @target_event_id;
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' document records';

-- Delete RSS entry
DELETE FROM docketwatch.dbo.rss_feed_entries WHERE pacer_id = @target_pacer_id AND event_no = @target_event_no;
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' RSS feed entry';

-- Delete case event
DELETE FROM docketwatch.dbo.case_events WHERE id = @target_event_id;
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' case event record';

PRINT '';
PRINT '=== Verification ===';

-- Verify deletion
IF NOT EXISTS(SELECT 1 FROM docketwatch.dbo.case_events WHERE id = @target_event_id)
    PRINT '✓ Case event successfully deleted (ID: ' + CAST(@target_event_id AS VARCHAR(50)) + ')';
ELSE
    PRINT '✗ ERROR: Case event still exists';

IF NOT EXISTS(SELECT 1 FROM docketwatch.dbo.rss_feed_entries WHERE pacer_id = @target_pacer_id AND event_no = @target_event_no)
    PRINT '✓ RSS entry successfully deleted (PACER ID: ' + CAST(@target_pacer_id AS VARCHAR(10)) + ', Event No: ' + CAST(@target_event_no AS VARCHAR(10)) + ')';
ELSE
    PRINT '✗ ERROR: RSS entry still exists';

PRINT '';
PRINT '=== Next Steps for Testing ===';
PRINT '1. Go to: http://your-server/docketwatch_rss_trigger_plus.cfm?bypass=1';
PRINT '2. The RSS feed should now detect this as a "new" event';
PRINT '3. Monitor logs at: \\10.146.176.84\general\docketwatch\python\logs\';
PRINT '4. Check if event gets re-inserted with PACER ID: ' + CAST(@target_pacer_id AS VARCHAR(10)) + ', Event No: ' + CAST(@target_event_no AS VARCHAR(10)) + ', GUID: ' + ISNULL(@target_guid, 'N/A');
PRINT '';
PRINT '=== Restore Commands (if needed) ===';
PRINT 'To restore the deleted records if something goes wrong:';
PRINT '';
PRINT '-- Restore case event:';
PRINT 'INSERT INTO docketwatch.dbo.case_events SELECT * FROM docketwatch.dbo.' + @backup_events_table + ';';
PRINT '';
PRINT '-- Restore RSS entry:';
PRINT 'INSERT INTO docketwatch.dbo.rss_feed_entries SELECT * FROM docketwatch.dbo.' + @backup_rss_table + ';';
PRINT '';
PRINT '-- Restore documents:';
PRINT 'INSERT INTO docketwatch.dbo.documents SELECT * FROM docketwatch.dbo.' + @backup_docs_table + ';';
PRINT '';
PRINT '=== Cleanup Backup Tables (after successful testing) ===';
PRINT 'DROP TABLE docketwatch.dbo.' + @backup_events_table + ';';
PRINT 'DROP TABLE docketwatch.dbo.' + @backup_rss_table + ';';
PRINT 'DROP TABLE docketwatch.dbo.' + @backup_docs_table + ';';
