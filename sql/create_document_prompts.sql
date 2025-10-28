/*
================================================================================
Create table for Interactive Document Q&A Prompts
================================================================================

PURPOSE:
--------
Stores all user questions and AI responses for documents processed through the
summarize upload tool. Enables conversation history, feedback collection, and
audit trails for the interactive Q&A feature.

RELATED FILES:
--------------
- /tools/summarize/view.cfm - Results page with Q&A interface
- /ajax/ask_document_question.cfm - Backend endpoint
- /python/answer_from_json.py - Python Q&A script

USAGE:
------
Run this script once to create the table and indexes.
*/

USE [docketwatch];
GO

-- Create table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'document_prompts' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE docketwatch.dbo.document_prompts (
        -- Primary key
        id                    BIGINT IDENTITY(1,1) PRIMARY KEY,

        -- Document reference
        fk_doc_uid            UNIQUEIDENTIFIER NOT NULL,

        -- User who asked the question
        user_name             NVARCHAR(100) NOT NULL,

        -- Prompt and response
        prompt_text           NVARCHAR(MAX) NOT NULL,
        prompt_response       NVARCHAR(MAX) NULL,

        -- AI metadata
        model_name            NVARCHAR(50) NULL,
        tokens_input          INT NULL,
        tokens_output         INT NULL,
        processing_ms         INT NULL,

        -- Citations (JSON array of field paths)
        cited_fields          NVARCHAR(MAX) NULL,

        -- Timestamps
        created_at            DATETIME2(7) DEFAULT SYSUTCDATETIME(),

        -- User feedback
        feedback_rating       TINYINT NULL CHECK (feedback_rating BETWEEN 1 AND 5),
        feedback_comment      NVARCHAR(MAX) NULL,
        feedback_submitted_at DATETIME2(7) NULL,

        -- Session tracking for conversation grouping
        session_id            NVARCHAR(100) NULL,
        prompt_sequence       INT NULL,

        -- Foreign key constraint
        CONSTRAINT FK_document_prompts_doc FOREIGN KEY (fk_doc_uid)
            REFERENCES docketwatch.dbo.documents(doc_uid) ON DELETE CASCADE
    );

    PRINT 'Table docketwatch.dbo.document_prompts created successfully';
END
ELSE
BEGIN
    PRINT 'Table docketwatch.dbo.document_prompts already exists';
END
GO

-- Index on doc_uid (most common query pattern)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_document_prompts_doc_uid' AND object_id = OBJECT_ID('docketwatch.dbo.document_prompts'))
BEGIN
    CREATE INDEX IX_document_prompts_doc_uid
    ON docketwatch.dbo.document_prompts(fk_doc_uid)
    INCLUDE (created_at, prompt_sequence);

    PRINT 'Index IX_document_prompts_doc_uid created successfully';
END
GO

-- Index on user_name (for user activity tracking)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_document_prompts_user' AND object_id = OBJECT_ID('docketwatch.dbo.document_prompts'))
BEGIN
    CREATE INDEX IX_document_prompts_user
    ON docketwatch.dbo.document_prompts(user_name)
    INCLUDE (created_at);

    PRINT 'Index IX_document_prompts_user created successfully';
END
GO

-- Index on created_at (for time-based queries and rate limiting)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_document_prompts_created' AND object_id = OBJECT_ID('docketwatch.dbo.document_prompts'))
BEGIN
    CREATE INDEX IX_document_prompts_created
    ON docketwatch.dbo.document_prompts(created_at DESC);

    PRINT 'Index IX_document_prompts_created created successfully';
END
GO

-- Index on session_id and prompt_sequence (for conversation history)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_document_prompts_session' AND object_id = OBJECT_ID('docketwatch.dbo.document_prompts'))
BEGIN
    CREATE INDEX IX_document_prompts_session
    ON docketwatch.dbo.document_prompts(session_id, prompt_sequence)
    WHERE session_id IS NOT NULL;

    PRINT 'Index IX_document_prompts_session created successfully';
END
GO

-- Index on feedback_rating (for analytics)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_document_prompts_feedback' AND object_id = OBJECT_ID('docketwatch.dbo.document_prompts'))
BEGIN
    CREATE INDEX IX_document_prompts_feedback
    ON docketwatch.dbo.document_prompts(feedback_rating)
    WHERE feedback_rating IS NOT NULL;

    PRINT 'Index IX_document_prompts_feedback created successfully';
END
GO

/*
================================================================================
SAMPLE QUERIES
================================================================================

-- Get all prompts for a specific document (with conversation history)
SELECT
    id, prompt_text, prompt_response, created_at,
    feedback_rating, prompt_sequence
FROM docketwatch.dbo.document_prompts
WHERE fk_doc_uid = 'YOUR-DOC-UUID-HERE'
ORDER BY prompt_sequence, created_at;

-- Get recent prompts by user (for rate limiting check)
SELECT COUNT(*) as recent_prompt_count
FROM docketwatch.dbo.document_prompts
WHERE user_name = 'jsmith'
AND created_at > DATEADD(hour, -1, SYSUTCDATETIME());

-- Get prompts with negative feedback (for quality analysis)
SELECT
    dp.prompt_text, dp.prompt_response, dp.feedback_rating,
    dp.feedback_comment, d.pdf_title
FROM docketwatch.dbo.document_prompts dp
INNER JOIN docketwatch.dbo.documents d ON d.doc_uid = dp.fk_doc_uid
WHERE dp.feedback_rating <= 2
ORDER BY dp.created_at DESC;

-- Get usage statistics by model
SELECT
    model_name,
    COUNT(*) as prompt_count,
    AVG(tokens_input) as avg_input_tokens,
    AVG(tokens_output) as avg_output_tokens,
    AVG(processing_ms) as avg_processing_ms
FROM docketwatch.dbo.document_prompts
WHERE created_at > DATEADD(day, -30, SYSUTCDATETIME())
GROUP BY model_name;

-- Get most active users
SELECT
    user_name,
    COUNT(*) as prompt_count,
    AVG(CAST(feedback_rating AS FLOAT)) as avg_rating
FROM docketwatch.dbo.document_prompts
WHERE created_at > DATEADD(day, -7, SYSUTCDATETIME())
GROUP BY user_name
ORDER BY prompt_count DESC;

-- Get conversation session details
SELECT
    prompt_sequence, prompt_text, prompt_response,
    created_at, feedback_rating
FROM docketwatch.dbo.document_prompts
WHERE session_id = 'YOUR-SESSION-ID'
ORDER BY prompt_sequence;

-- Data retention cleanup (delete prompts older than 2 years)
DELETE FROM docketwatch.dbo.document_prompts
WHERE created_at < DATEADD(year, -2, SYSUTCDATETIME());

*/
