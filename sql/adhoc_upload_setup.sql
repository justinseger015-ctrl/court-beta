USE [docketwatch]
GO

-- ================================================================
-- Ad-Hoc Document Upload Infrastructure Setup
-- 
-- Creates placeholder case and event for documents uploaded via
-- the AI Summary Upload Tool. These documents are stored in the
-- documents table but don't appear in normal case tracking.
-- 
-- Run this once to set up the infrastructure.
-- ================================================================

-- Step 1: Insert placeholder case
IF NOT EXISTS (SELECT 1 FROM [dbo].[cases] WHERE case_number = 'ADHOC-UPLOADS-2025')
BEGIN
    INSERT INTO [dbo].[cases]
        ([case_number]
        ,[case_name]
        ,[notes]
        ,[created_at]
        ,[last_updated]
        ,[status]
        ,[case_parties_checked]
        ,[celebrity_checked]
        ,[critical_case]
        ,[not_found_flag]
        ,[not_found_count])
    VALUES
        ('ADHOC-UPLOADS-2025'
        ,'Ad-Hoc Document Upload Placeholder'
        ,'Placeholder case for documents uploaded via the AI Summary Upload Tool. These documents are not part of tracked cases.'
        ,GETDATE()
        ,GETDATE()
        ,'placeholder'
        ,1  -- Mark as checked to avoid processing
        ,1  -- Mark as checked to avoid processing
        ,0  -- Not critical
        ,0  -- Not not-found
        ,0);
    
    PRINT 'Placeholder case created successfully.';
END
ELSE
BEGIN
    PRINT 'Placeholder case already exists.';
END
GO

-- Step 2: Insert placeholder event
DECLARE @placeholder_case_id INT;
SELECT @placeholder_case_id = id FROM [dbo].[cases] WHERE case_number = 'ADHOC-UPLOADS-2025';

IF NOT EXISTS (SELECT 1 FROM [dbo].[case_events] WHERE fk_cases = @placeholder_case_id AND event_no = 0)
BEGIN
    INSERT INTO [dbo].[case_events]
        ([id]
        ,[event_date]
        ,[event_description]
        ,[event_result]
        ,[fk_cases]
        ,[created_at]
        ,[status]
        ,[event_no]
        ,[isDoc]
        ,[emailed]
        ,[acknowledged]
        ,[processing]
        ,[event_type])
    VALUES
        (NEWID()
        ,CAST(GETDATE() AS DATE)
        ,'Ad-Hoc Document Upload'
        ,'Document uploaded for standalone AI summarization'
        ,@placeholder_case_id
        ,GETDATE()
        ,'placeholder'
        ,0
        ,1  -- Mark as document event
        ,1  -- Mark as emailed to avoid notifications
        ,1  -- Mark as acknowledged to avoid processing
        ,0  -- Not processing
        ,'Document Upload');
    
    PRINT 'Placeholder event created successfully.';
END
ELSE
BEGIN
    PRINT 'Placeholder event already exists.';
END
GO

-- Step 3: Display the IDs for reference
SELECT 
    c.id AS case_id,
    c.case_number,
    ce.id AS event_id,
    ce.event_description,
    '*** Use this event_id in your Python script configuration ***' AS note
FROM [dbo].[cases] c
JOIN [dbo].[case_events] ce ON ce.fk_cases = c.id
WHERE c.case_number = 'ADHOC-UPLOADS-2025';
GO

-- Step 4: Create utility stored procedure to get the placeholder event ID
IF OBJECT_ID('dbo.sp_get_adhoc_upload_event_id', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_get_adhoc_upload_event_id;
GO

CREATE PROCEDURE dbo.sp_get_adhoc_upload_event_id
AS
BEGIN
    SET NOCOUNT ON;
    
        SELECT ce.id AS event_id
        FROM [dbo].[cases] c
        JOIN [dbo].[case_events] ce ON ce.fk_cases = c.id
        WHERE c.case_number = 'ADHOC-UPLOADS-2025'
            AND ce.event_no = 0;
END
GO

PRINT 'Setup complete! You can now call: EXEC dbo.sp_get_adhoc_upload_event_id';
GO
