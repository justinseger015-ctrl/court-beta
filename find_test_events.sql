-- DocketWatch Case Event Finder - Shows Recent Events for RSS Testing
-- This script will definitely show you the events to choose from

SET NOCOUNT OFF;  -- Force row display
GO

PRINT '=== RECENT CASE EVENTS (Last 48 Hours) ===';
PRINT 'Looking for events with RSS entries...';
PRINT '';

-- Find recent case events with RSS entries
SELECT TOP 10 
    CAST(e.id AS VARCHAR(50)) as event_id_guid,
    e.fk_cases,
    e.event_no,
    LEFT(e.event_description, 50) as event_description,
    e.status,
    CONVERT(VARCHAR, e.created_at, 120) as created_at,
    LEFT(c.case_name, 30) as case_name,
    c.case_number,
    c.pacer_id,
    CASE WHEN r.guid IS NOT NULL THEN 'YES' ELSE 'NO' END as has_rss_entry,
    LEFT(r.guid, 30) as rss_guid_partial
FROM docketwatch.dbo.case_events e
INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
LEFT JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
WHERE e.created_at >= DATEADD(hour, -48, GETDATE())  -- Extended to 48 hours for more options
    AND c.status = 'Tracked'  -- Only tracked cases
    AND c.pacer_id IS NOT NULL  -- Only cases with PACER IDs
ORDER BY e.created_at DESC;

PRINT '';
PRINT '=== COPY THESE COMMANDS (Events with RSS entries only) ===';
PRINT '';

-- Show only events that HAVE RSS entries (these are good for testing)
SELECT TOP 5
    'EXEC delete_event_for_test ''' + CAST(e.id AS VARCHAR(50)) + ''';' as copy_this_command,
    LEFT(c.case_name, 40) as case_name,
    e.event_no,
    LEFT(e.event_description, 50) as description
FROM docketwatch.dbo.case_events e
INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
LEFT JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no
WHERE e.created_at >= DATEADD(hour, -48, GETDATE())
    AND c.status = 'Tracked'
    AND c.pacer_id IS NOT NULL
    AND r.guid IS NOT NULL  -- Only events with RSS entries
ORDER BY e.created_at DESC;
