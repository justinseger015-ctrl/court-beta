USE [docketwatch]
GO

-- ================================================================
-- Cleanup old ad-hoc placeholder event with string event_no
-- Run this before re-running adhoc_upload_setup.sql
-- ================================================================

DECLARE @placeholder_case_id INT;
SELECT @placeholder_case_id = id FROM [dbo].[cases] WHERE case_number = 'ADHOC-UPLOADS-2025';

-- Delete any documents linked to the old placeholder event
DELETE d
FROM [dbo].[documents] d
INNER JOIN [dbo].[case_events] ce ON d.fk_case_event = ce.id
WHERE ce.fk_cases = @placeholder_case_id;

PRINT 'Deleted documents linked to old placeholder event.';

-- Delete the old placeholder event (with string event_no)
DELETE FROM [dbo].[case_events]
WHERE fk_cases = @placeholder_case_id;

PRINT 'Deleted old placeholder event.';

-- Optionally delete the placeholder case if you want a clean slate
-- DELETE FROM [dbo].[cases] WHERE case_number = 'ADHOC-UPLOADS-2025';
-- PRINT 'Deleted placeholder case.';

GO

PRINT 'Cleanup complete! Now run adhoc_upload_setup.sql';
GO
