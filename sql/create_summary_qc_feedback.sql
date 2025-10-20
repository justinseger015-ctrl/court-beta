<!--- Create table for QC feedback on AI summaries from upload tool --->
<!--- Part of the summarize_upload.cfm workflow --->

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'summary_qc_feedback' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE docketwatch.dbo.summary_qc_feedback (
        id            INT IDENTITY(1,1) PRIMARY KEY,
        doc_uid       UNIQUEIDENTIFIER NULL,
        upload_sha256 CHAR(64) NULL,
        user_name     NVARCHAR(100) NULL,
        success       BIT NOT NULL,
        notes         NVARCHAR(MAX) NULL,
        model_name    NVARCHAR(50) NULL,
        created_at    DATETIME2(7) DEFAULT SYSUTCDATETIME()
    );
    
    PRINT 'Table docketwatch.dbo.summary_qc_feedback created successfully';
END
ELSE
BEGIN
    PRINT 'Table docketwatch.dbo.summary_qc_feedback already exists';
END
GO

<!--- Create index on doc_uid for faster lookups --->
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_summary_qc_feedback_doc_uid' AND object_id = OBJECT_ID('docketwatch.dbo.summary_qc_feedback'))
BEGIN
    CREATE INDEX IX_summary_qc_feedback_doc_uid ON docketwatch.dbo.summary_qc_feedback(doc_uid);
    PRINT 'Index IX_summary_qc_feedback_doc_uid created successfully';
END
GO

<!--- Create index on upload_sha256 for de-duplication --->
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_summary_qc_feedback_sha256' AND object_id = OBJECT_ID('docketwatch.dbo.summary_qc_feedback'))
BEGIN
    CREATE INDEX IX_summary_qc_feedback_sha256 ON docketwatch.dbo.summary_qc_feedback(upload_sha256);
    PRINT 'Index IX_summary_qc_feedback_sha256 created successfully';
END
GO

<!--- Create index on created_at for reporting --->
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_summary_qc_feedback_created_at' AND object_id = OBJECT_ID('docketwatch.dbo.summary_qc_feedback'))
BEGIN
    CREATE INDEX IX_summary_qc_feedback_created_at ON docketwatch.dbo.summary_qc_feedback(created_at DESC);
    PRINT 'Index IX_summary_qc_feedback_created_at created successfully';
END
GO
