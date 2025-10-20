-- Stored procedure to retrieve today's article for a given case
-- Generated on 2025-10-16
GO
CREATE OR ALTER PROCEDURE dbo.usp_GetTodaysArticleForCase
    @CaseId INT,
    @Today DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Today IS NULL
    BEGIN
        SET @Today = CAST(GETDATE() AS DATE);
    END

    SELECT TOP 1
        id,
        fk_case,
        article_date,
        articleStatus,
        version,
        story_headline,
        story_sub_head,
        story_body,
        image_url,
        ai_model,
        ai_tokens_input,
        ai_tokens_output,
        ai_cost,
        generated_by,
        is_published,
        published_at,
        notes,
        created_at,
        updated_at
    FROM docketwatch.dbo.articles WITH (NOLOCK)
    WHERE fk_case = @CaseId
      AND article_date = @Today
      AND generated_by = 'summary_parser'
      AND story_headline <> 'No Story Necessary.'
    ORDER BY updated_at DESC, created_at DESC;
END
GO
