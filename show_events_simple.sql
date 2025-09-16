-- Simple command-line friendly version
-- Run: sqlcmd -S localhost -E -d docketwatch -Q "EXEC show_test_events"

CREATE OR ALTER PROCEDURE show_test_events
AS
BEGIN
    SET NOCOUNT OFF;
    
    PRINT '=== Recent Events with RSS Entries (Good for Testing) ===';
    
    SELECT TOP 10
        ROW_NUMBER() OVER (ORDER BY e.created_at DESC) as row_num,
        CAST(e.id AS VARCHAR(50)) as event_guid,
        e.event_no,
        LEFT(e.event_description, 40) as description,
        CONVERT(VARCHAR, e.created_at, 120) as created,
        LEFT(c.case_name, 25) as case_name,
        c.pacer_id,
        'YES' as has_rss
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    INNER JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
    WHERE e.created_at >= DATEADD(hour, -72, GETDATE())
        AND c.status = 'Tracked'
        AND c.pacer_id IS NOT NULL
    ORDER BY e.created_at DESC;
    
    PRINT '';
    PRINT '=== Ready-to-Run Delete Commands ===';
    
    SELECT TOP 5
        ROW_NUMBER() OVER (ORDER BY e.created_at DESC) as cmd_num,
        'EXEC delete_event_for_test ''' + CAST(e.id AS VARCHAR(50)) + ''';' as command_to_copy
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    INNER JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
    WHERE e.created_at >= DATEADD(hour, -72, GETDATE())
        AND c.status = 'Tracked'
        AND c.pacer_id IS NOT NULL
    ORDER BY e.created_at DESC;
END;
GO

-- Run the procedure immediately to show results
EXEC show_test_events;

PRINT '';
PRINT '=== Usage Instructions ===';
PRINT '1. Copy one of the commands from "command_to_copy" column above';
PRINT '2. First run: sqlcmd -S localhost -E -d docketwatch -i delete_event_procedures.sql';
PRINT '3. Then run your copied command';
PRINT '4. Finally test: http://your-server/docketwatch_rss_trigger_plus.cfm?bypass=1';
