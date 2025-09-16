-- DocketWatch Simple Event Deletion for RSS Testing
-- Run this to create the procedure, then use the commands from find_test_events.sql

CREATE OR ALTER PROCEDURE delete_event_for_test
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
        PRINT 'ERROR: Event not found: ' + CAST(@event_id AS VARCHAR(50));
        RETURN;
    END

    PRINT '=== Deleting Test Event ===';
    PRINT 'Event ID: ' + CAST(@event_id AS VARCHAR(50));
    PRINT 'Case: ' + @target_case_name;
    PRINT 'Event: ' + LEFT(@target_event_desc, 100);
    PRINT 'PACER ID: ' + CAST(ISNULL(@target_pacer_id, 0) AS VARCHAR(10));
    PRINT 'Event No: ' + CAST(ISNULL(@target_event_no, 0) AS VARCHAR(10));
    PRINT 'RSS GUID: ' + ISNULL(@target_guid, 'NO RSS ENTRY');

    -- Safety check for RSS entry
    IF @target_guid IS NULL
    BEGIN
        PRINT 'WARNING: No RSS entry found. This event may not reappear in RSS feed.';
        PRINT 'Stopping deletion. Choose an event with RSS entry instead.';
        RETURN;
    END

    -- Create timestamped backup tables
    DECLARE @timestamp VARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @backup_event_table VARCHAR(100) = 'backup_event_' + @timestamp;
    DECLARE @backup_rss_table VARCHAR(100) = 'backup_rss_' + @timestamp;
    DECLARE @backup_docs_table VARCHAR(100) = 'backup_docs_' + @timestamp;

    PRINT '';
    PRINT '=== Creating Backups ===';
    
    -- Backup event
    EXEC('SELECT * INTO docketwatch.dbo.' + @backup_event_table + ' FROM docketwatch.dbo.case_events WHERE id = ''' + @event_id + '''');
    PRINT 'Event backed up to: ' + @backup_event_table;

    -- Backup RSS entry
    EXEC('SELECT * INTO docketwatch.dbo.' + @backup_rss_table + ' FROM docketwatch.dbo.rss_feed_entries WHERE pacer_id = ' + @target_pacer_id + ' AND event_no = ' + @target_event_no);
    PRINT 'RSS entry backed up to: ' + @backup_rss_table;

    -- Backup documents
    EXEC('SELECT * INTO docketwatch.dbo.' + @backup_docs_table + ' FROM docketwatch.dbo.documents WHERE fk_case_event = ''' + @event_id + '''');
    PRINT 'Documents backed up to: ' + @backup_docs_table;

    PRINT '';
    PRINT '=== Performing Deletion ===';

    -- Delete in proper order (children first)
    DELETE FROM docketwatch.dbo.documents WHERE fk_case_event = @event_id;
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' document records';

    DELETE FROM docketwatch.dbo.rss_feed_entries WHERE pacer_id = @target_pacer_id AND event_no = @target_event_no;
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' RSS entries';

    DELETE FROM docketwatch.dbo.case_events WHERE id = @event_id;
    PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' case event record';

    PRINT '';
    PRINT '=== SUCCESS! Event Deleted for Testing ===';
    PRINT 'RSS should now see this as a "new" event when you trigger the pipeline.';
    PRINT '';
    PRINT '=== Next Steps ===';
    PRINT '1. Trigger RSS: http://your-server/docketwatch_rss_trigger_plus.cfm?bypass=1';
    PRINT '2. Monitor: EXEC check_rss_test_results;';
    PRINT '';
    PRINT '=== Restore Commands (if needed) ===';
    PRINT 'INSERT INTO docketwatch.dbo.case_events SELECT * FROM docketwatch.dbo.' + @backup_event_table + ';';
    PRINT 'INSERT INTO docketwatch.dbo.rss_feed_entries SELECT * FROM docketwatch.dbo.' + @backup_rss_table + ';';
    PRINT 'INSERT INTO docketwatch.dbo.documents SELECT * FROM docketwatch.dbo.' + @backup_docs_table + ';';
    PRINT '';
    PRINT '=== Cleanup (after successful test) ===';
    PRINT 'DROP TABLE docketwatch.dbo.' + @backup_event_table + ';';
    PRINT 'DROP TABLE docketwatch.dbo.' + @backup_rss_table + ';';
    PRINT 'DROP TABLE docketwatch.dbo.' + @backup_docs_table + ';';
END;
GO

-- Create monitoring procedure
CREATE OR ALTER PROCEDURE check_rss_test_results
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== Events Created in Last 30 Minutes ===';
    SELECT TOP 10
        CAST(e.id AS VARCHAR(36)) as event_guid,
        e.event_no,
        LEFT(e.event_description, 50) as description,
        e.status,
        CONVERT(VARCHAR, e.created_at, 120) as created_at,
        LEFT(c.case_name, 30) as case_name,
        c.pacer_id,
        CASE WHEN r.guid IS NOT NULL THEN 'YES' ELSE 'NO' END as has_rss
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    LEFT JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
    WHERE e.created_at >= DATEADD(minute, -30, GETDATE())
    ORDER BY e.created_at DESC;

    PRINT '';
    PRINT '=== RSS Entries Created in Last 30 Minutes ===';
    SELECT TOP 10
        LEFT(guid, 50) as rss_guid,
        pacer_id,
        event_no,
        LEFT(case_name, 30) as case_name,
        processed,
        CONVERT(VARCHAR, first_seen, 120) as first_seen
    FROM docketwatch.dbo.rss_feed_entries
    WHERE first_seen >= DATEADD(minute, -30, GETDATE())
    ORDER BY first_seen DESC;

    PRINT '';
    PRINT '=== Documents Created in Last 30 Minutes ===';
    SELECT TOP 10
        CAST(fk_case_event AS VARCHAR(36)) as event_guid,
        fk_case,
        LEFT(file_name, 40) as file_name,
        status,
        file_size,
        CONVERT(VARCHAR, created_at, 120) as created_at
    FROM docketwatch.dbo.documents
    WHERE created_at >= DATEADD(minute, -30, GETDATE())
    ORDER BY created_at DESC;
END;
GO

PRINT '=== Procedures Created Successfully ===';
PRINT '1. Run find_test_events.sql to see available events';
PRINT '2. Copy/paste one of the delete commands';
PRINT '3. Trigger RSS pipeline';
PRINT '4. Run EXEC check_rss_test_results; to monitor';
