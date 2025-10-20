-- Optional helper function to check whether a case has an article for today
-- Generated on 2025-10-16
GO
CREATE OR ALTER FUNCTION dbo.ufn_HasTodaysArticle
(
    @CaseId INT,
    @Today DATE = NULL
)
RETURNS BIT
AS
BEGIN
    IF @Today IS NULL
    BEGIN
        SET @Today = CAST(GETDATE() AS DATE);
    END

    RETURN (
        SELECT CASE WHEN EXISTS (
            SELECT 1
            FROM docketwatch.dbo.articles WITH (NOLOCK)
            WHERE fk_case = @CaseId
              AND article_date = @Today
              AND generated_by = 'summary_parser'
              AND story_headline <> 'No Story Necessary.'
        ) THEN 1 ELSE 0 END
    );
END
GO
