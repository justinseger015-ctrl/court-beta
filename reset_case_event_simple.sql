-- DocketWatch Simple Case Event Reset for RSS Testing
-- STEP 1: Run this to see recent events with GUIDs
PRINT '=== Recent Case Events (Last 24 Hours) ===';
SELECT TOP 10 
    CAST(e.id AS VARCHAR(50)) as event_id_guid,
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
PRINT '=== COPY AND PASTE ONE OF THESE COMMANDS ===';
PRINT 'Copy a command below, replace the GUID with one from above that has "HAS RSS ENTRY":';
PRINT '';

-- Generate sample DELETE commands for easy copy/paste
SELECT TOP 5 
    'EXEC delete_test_event ''' + CAST(e.id AS VARCHAR(50)) + '''; -- ' + LEFT(c.case_name, 30) + ' - Event ' + CAST(e.event_no AS VARCHAR(10)) as copy_paste_command
FROM docketwatch.dbo.case_events e
INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
LEFT JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
WHERE e.created_at >= DATEADD(hour, -24, GETDATE())
    AND c.status = 'Tracked'
    AND c.pacer_id IS NOT NULL
    AND r.guid IS NOT NULL  -- Only show events with RSS entries
ORDER BY e.created_at DESC;

PRINT '';
PRINT '=== OR USE THIS STORED PROCEDURE ===';
GO

-- Create a simple stored procedure for easy testing
CREATE OR ALTER PROCEDURE delete_test_event
    @event_id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @target_guid NVARCHAR(255);
    DECLARE @target_case_id INT;
    DECLARE @target_case_name NVARCHAR(500);
    DECLARE @target_event_desc NVARCHAR(1000);
    DECLARE @target_pacer_id INT;
    DECLARE @target_event_no INT;

    -- Get event details
    SELECT 
        @target_case_id = e.fk_cases,
        @target_case_name = c.case_name,
        @target_event_desc = e.event_description,
        @target_pacer_id = c.pacer_id,
        @target_event_no = e.event_no
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    WHERE e.id = @event_id;

    -- Get the RSS GUID
    SELECT @target_guid = guid 
    FROM docketwatch.dbo.rss_feed_entries 
    WHERE pacer_id = @target_pacer_id AND event_no = @target_event_no;

    -- Verify we found the event
    IF @target_case_id IS NULL
    BEGIN
        PRINT 'ERROR: Event ID not found: ' + CAST(@event_id AS VARCHAR(50));
        RETURN;
    END

    PRINT '=== Target Event Details ===';
    PRINT 'Event ID: ' + CAST(@event_id AS VARCHAR(50));
    PRINT 'Case ID: ' + CAST(@target_case_id AS VARCHAR(10));
    PRINT 'PACER ID: ' + CAST(ISNULL(@target_pacer_id, 0) AS VARCHAR(10));
    PRINT 'Event No: ' + CAST(ISNULL(@target_event_no, 0) AS VARCHAR(10));
    PRINT 'Case Name: ' + @target_case_name;
    PRINT 'Event Description: ' + LEFT(@target_event_desc, 100);
    PRINT 'RSS GUID: ' + ISNULL(@target_guid, 'NO GUID FOUND');

    -- Safety check for GUID
    IF @target_guid IS NULL
    BEGIN
        PRINT 'WARNING: This event has no RSS entry. It may not reappear in RSS feed.';
        RETURN;
    END

    -- Create backup with timestamp
    DECLARE @backup_suffix VARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @backup_events_table VARCHAR(100) = 'case_events_backup_' + @backup_suffix;
    DECLARE @backup_rss_table VARCHAR(100) = 'rss_feed_entries_backup_' + @backup_suffix;
    DECLARE @backup_docs_table VARCHAR(100) = 'documents_backup_' + @backup_suffix;

    PRINT '';
    PRINT '=== Creating Backups ===';
    
    -- Backup case event
    DECLARE @sql_backup_event NVARCHAR(MAX) = 
        'SELECT * INTO docketwatch.dbo.' + @backup_events_table + 
        ' FROM docketwatch.dbo.case_events WHERE id = ''' + CAST(@event_id AS VARCHAR(50)) + '''';
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
        ' FROM docketwatch.dbo.documents WHERE fk_case_event = ''' + CAST(@event_id AS VARCHAR(50)) + '''';
    EXEC sp_executesql @sql_backup_docs;

    PRINT 'Backups created successfully.';

    -- Delete in correct order
    PRINT '';
    PRINT '=== Deleting Records for Testing ===';

    -- Delete documents first
    DELETE FROM docketwatch.dbo.documents WHERE fk_case_event = @event_id;
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' document records';

    -- Delete RSS entry
    DELETE FROM docketwatch.dbo.rss_feed_entries WHERE pacer_id = @target_pacer_id AND event_no = @target_event_no;
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' RSS feed entry';

    -- Delete case event
    DELETE FROM docketwatch.dbo.case_events WHERE id = @event_id;
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' case event record';

    -- Verification
    PRINT '';
    PRINT '=== Verification ===';
    IF NOT EXISTS(SELECT 1 FROM docketwatch.dbo.case_events WHERE id = @event_id)
        PRINT '✓ Case event successfully deleted';
    ELSE
        PRINT '✗ ERROR: Case event still exists';

    IF NOT EXISTS(SELECT 1 FROM docketwatch.dbo.rss_feed_entries WHERE pacer_id = @target_pacer_id AND event_no = @target_event_no)
        PRINT '✓ RSS entry successfully deleted';
    ELSE
        PRINT '✗ ERROR: RSS entry still exists';

    PRINT '';
    PRINT '=== Next Steps ===';
    PRINT '1. Go to: http://your-server/docketwatch_rss_trigger_plus.cfm?bypass=1';
    PRINT '2. Monitor with: EXEC monitor_rss_test;';
    PRINT '';
    PRINT '=== Restore Commands (if needed) ===';
    PRINT 'INSERT INTO docketwatch.dbo.case_events SELECT * FROM docketwatch.dbo.' + @backup_events_table + ';';
    PRINT 'INSERT INTO docketwatch.dbo.rss_feed_entries SELECT * FROM docketwatch.dbo.' + @backup_rss_table + ';';
    PRINT 'INSERT INTO docketwatch.dbo.documents SELECT * FROM docketwatch.dbo.' + @backup_docs_table + ';';
    PRINT '';
    PRINT '=== Cleanup Commands ===';
    PRINT 'DROP TABLE docketwatch.dbo.' + @backup_events_table + ';';
    PRINT 'DROP TABLE docketwatch.dbo.' + @backup_rss_table + ';';
    PRINT 'DROP TABLE docketwatch.dbo.' + @backup_docs_table + ';';
END;
GO

-- Create monitoring procedure
CREATE OR ALTER PROCEDURE monitor_rss_test
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== Events Created in Last 30 Minutes ===';
    SELECT TOP 10
        CAST(e.id AS VARCHAR(50)) as event_id,
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
    PRINT '=== RSS Entries Created in Last 30 Minutes ===';
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
END;
GO

PRINT '';
PRINT '=== USAGE SUMMARY ===';
PRINT '1. Run this script to see recent events';
PRINT '2. Copy/paste one of the delete commands above';
PRINT '3. Trigger RSS: http://your-server/docketwatch_rss_trigger_plus.cfm?bypass=1';
PRINT '4. Monitor with: EXEC monitor_rss_test;';
