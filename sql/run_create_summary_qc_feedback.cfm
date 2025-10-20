<cfsetting enablecfoutputonly="true">
<!DOCTYPE html>
<html>
<head>
    <title>Create Summary QC Feedback Table</title>
</head>
<body>
    <h1>Creating summary_qc_feedback Table</h1>
    
    <cfquery datasource="Reach" result="result1">
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
    </cfquery>
    
    <cfoutput>
        <p><strong>Step 1:</strong> #result1.ExecutionTime#ms - Table creation checked</p>
    </cfoutput>
    
    <cfquery datasource="Reach" result="result2">
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_summary_qc_feedback_doc_uid' AND object_id = OBJECT_ID('docketwatch.dbo.summary_qc_feedback'))
        BEGIN
            CREATE INDEX IX_summary_qc_feedback_doc_uid ON docketwatch.dbo.summary_qc_feedback(doc_uid);
        END
    </cfquery>
    
    <cfoutput>
        <p><strong>Step 2:</strong> #result2.ExecutionTime#ms - Index on doc_uid created</p>
    </cfoutput>
    
    <cfquery datasource="Reach" result="result3">
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_summary_qc_feedback_sha256' AND object_id = OBJECT_ID('docketwatch.dbo.summary_qc_feedback'))
        BEGIN
            CREATE INDEX IX_summary_qc_feedback_sha256 ON docketwatch.dbo.summary_qc_feedback(upload_sha256);
        END
    </cfquery>
    
    <cfoutput>
        <p><strong>Step 3:</strong> #result3.ExecutionTime#ms - Index on upload_sha256 created</p>
    </cfoutput>
    
    <cfquery datasource="Reach" result="result4">
        IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_summary_qc_feedback_created_at' AND object_id = OBJECT_ID('docketwatch.dbo.summary_qc_feedback'))
        BEGIN
            CREATE INDEX IX_summary_qc_feedback_created_at ON docketwatch.dbo.summary_qc_feedback(created_at DESC);
        END
    </cfquery>
    
    <cfoutput>
        <p><strong>Step 4:</strong> #result4.ExecutionTime#ms - Index on created_at created</p>
    </cfoutput>
    
    <h2 style="color: green;">✓ Database setup complete!</h2>
    <p><a href="../tools/summarize_upload.cfm">Go to AI Summary Upload Tool</a></p>
    
</body>
</html>
