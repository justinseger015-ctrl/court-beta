-- Reset all case events back to not acknowledged
-- Use this for testing purposes to reset acknowledgement status

-- Query 1: Reset all acknowledgement fields to NULL/0
UPDATE docketwatch.dbo.case_events 
SET 
    acknowledged = 0,
    acknowledged_at = NULL,
    acknowledged_by = NULL
WHERE acknowledged = 1;

-- Query 2: Check how many records will be affected (run this first to see count)
SELECT 
    COUNT(*) as total_acknowledged_records
FROM docketwatch.dbo.case_events 
WHERE acknowledged = 1;

-- Query 3: Verify the reset worked (should return 0 if successful)
SELECT 
    COUNT(*) as remaining_acknowledged_records
FROM docketwatch.dbo.case_events 
WHERE acknowledged = 1;

-- Query 4: Get a summary of all records after reset
SELECT 
    COUNT(*) as total_events,
    SUM(CASE WHEN ISNULL(acknowledged, 0) = 0 THEN 1 ELSE 0 END) as unacknowledged,
    SUM(CASE WHEN ISNULL(acknowledged, 0) = 1 THEN 1 ELSE 0 END) as acknowledged
FROM docketwatch.dbo.case_events;
