-- Add acknowledgment columns to case_events table
-- Run this SQL script to add the new columns needed for the alert system

USE docketwatch;

-- Add acknowledged flag column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.case_events') AND name = 'acknowledged')
BEGIN
    ALTER TABLE dbo.case_events 
    ADD acknowledged bit DEFAULT 0;
END

-- Add acknowledged timestamp column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.case_events') AND name = 'acknowledged_at')
BEGIN
    ALTER TABLE dbo.case_events 
    ADD acknowledged_at datetime2;
END

-- Add acknowledged by user column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.case_events') AND name = 'acknowledged_by')
BEGIN
    ALTER TABLE dbo.case_events 
    ADD acknowledged_by varchar(100);
END

-- Set all existing events as unacknowledged by default
UPDATE dbo.case_events 
SET acknowledged = 0 
WHERE acknowledged IS NULL;

PRINT 'Acknowledgment columns added successfully to case_events table';
