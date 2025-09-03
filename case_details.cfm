<cfset fk_user = getauthuser()>
<cfset subscribers_tab_status = "">

<cfquery name="case_details" datasource="Reach">
    SELECT c.fk_tool,
        c.[id],
        c.[case_number],
        c.[case_name],
        c.[notes] AS details,
        c.[last_updated],
        c.[owner],
        c.[created_at],
        c.[status],
        ISNULL(c.[case_type], 'Unknown') AS case_type,
        c.[case_url],
        c.fk_court AS court_code,
        c.court_name_pacer,
        c.[summarize_html],
        t.[id] AS tool_id,
        t.[tool_name] AS tool_name,
        t.[username],
        t.[pass],
        t.[search_url] as tool_url,
        t.[login_url] as tool_login_url
    FROM [docketwatch].[dbo].[cases] c
    LEFT JOIN [docketwatch].[dbo].[tools] t ON t.id = c.fk_tool
    WHERE c.id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<cfquery name="subscribers" datasource="Reach">
SELECT r.id,
u.firstname + ' ' + u.lastname as fullname,
u.firstname,
u.lastname,
u.email,
u.userRole
  FROM [docketwatch].[dbo].[case_email_recipients] r
  inner join [docketwatch].[dbo].[users] u on u.username = r.fk_username
    WHERE r.fk_case = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer"> and r.notify = 1
    ORDER BY u.lastname, u.firstname
</cfquery>

<cfquery name="eligible_users" datasource="Reach">
    SELECT 
        u.username AS id,
        u.firstname + ' ' + u.lastname AS display
    FROM docketwatch.dbo.users u
    WHERE u.username NOT IN (
        SELECT r.fk_username
        FROM docketwatch.dbo.case_email_recipients r
        WHERE r.fk_case = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer">
    )
    ORDER BY u.lastname, u.firstname
</cfquery>

<cfquery name="courthouse" datasource="Reach">
    SELECT c.[court_code],
           c.[court_name],
           c.[address],
           c.[city],
           c.[state],
           c.[zip],
           ISNULL(c.[image_location], '../services/courthouse.png') AS image_url,
           o.[name] AS county_name,
           c.[court_id],
           c.[court_url],
           c.[last_scraped]
    FROM [docketwatch].[dbo].[courts] c
    INNER JOIN [docketwatch].[dbo].[counties] o ON c.fk_county = o.id
    WHERE c.court_code = <cfqueryparam value="#case_details.court_code#" cfsqltype="cf_sql_varchar">
</cfquery>

<cfquery name="dockets" datasource="Reach">
SELECT 
    e.[event_no],
    e.[id],
    e.[event_date],
    e.[event_description],
    e.[additional_information],
    e.[created_at],
    e.[status],
    e.[event_result],
    e.[party_type],
    e.[party_number],
    e.[amount],
    e.[fk_cases],
    e.[fk_task_run_log],
    e.[emailed],
    e.[summarize],
    e.[tmz_summarize],
    e.[event_url],
    e.[isDoc],
    d.[pdf_title],
    d.[summary_ai],
    d.[summary_ai_html],
    d.[search_text],
    '/docs/cases/' + cast(e.fk_cases as varchar) + '/E' + cast(d.doc_id as varchar) + '.pdf' as pdf_path,
    'tbd' AS attachment_links
FROM docketwatch.dbo.case_events e
LEFT JOIN docketwatch.dbo.documents d 
    ON e.id = d.fk_case_event 
    AND (d.pdf_type IS NULL OR d.pdf_type != 'Attachment')
WHERE e.fk_cases = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer">
ORDER BY e.created_at DESC
</cfquery>

<cfquery name="attachments" datasource="Reach">
SELECT 
    d.[doc_uid],
    d.[fk_case_event],
    d.[pdf_title],
    d.[doc_id],
    '/docs/cases/' + cast(d.fk_case as varchar) + '/E' + cast(d.doc_id as varchar) + '.pdf' as pdf_path,
    d.[pdf_type]
FROM docketwatch.dbo.documents d
WHERE d.fk_case = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer">
AND d.pdf_type = 'Attachment'
ORDER BY d.pdf_title
</cfquery>

<cfquery name="hearings" datasource="Reach">
    SELECT h.[ID],
           h.[fk_case],
           d.[name] AS department,
           h.[hearing_type] AS type,
           h.[case_utype_description] AS description,
           h.[hearing_datetime] AS date,
           h.[hearing_datetime] AS time
    FROM [docketwatch].[dbo].[hearings] h
    LEFT JOIN [docketwatch].[dbo].[departments] d ON d.id = h.fk_department
    WHERE h.fk_case = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer">
    ORDER BY h.[hearing_datetime] DESC
</cfquery>

<cfquery name="logs" datasource="Reach">
SELECT  
    COUNT(*) as cnt,
    r.timestamp_started, 
    r.timestamp_ended,
    r.status,
    r.summary,
    r.created_at,
    s.task_name,
    DATEDIFF(MINUTE, r.timestamp_started, r.timestamp_ended) AS duration_minutes,
    DATEDIFF(SECOND, r.timestamp_started, r.timestamp_ended) AS duration_seconds,
    RIGHT('0' + CAST(DATEDIFF(MINUTE, r.timestamp_started, r.timestamp_ended) AS VARCHAR), 2) + ':' +
    RIGHT('0' + CAST(DATEDIFF(SECOND, r.timestamp_started, r.timestamp_ended) % 60 AS VARCHAR), 2) AS duration_mmss
FROM docketwatch.dbo.task_runs_log l
INNER JOIN docketwatch.dbo.task_runs r ON r.id = l.fk_task_run
INNER JOIN docketwatch.dbo.cases c ON c.id = l.fk_case
INNER JOIN docketwatch.dbo.scheduled_task s ON s.id = r.fk_scheduled_task
WHERE c.id = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer">
GROUP BY  
    r.timestamp_started, 
    r.timestamp_ended,
    r.status,
    r.summary,
    s.task_name,
    r.created_at
ORDER BY r.created_at DESC
</cfquery>

<cfquery name="celebrities" datasource="Reach">
    SELECT 
        m.[id],
        c.id as celebrity_id,
        c.name AS celebrity_name,
        a.name AS legal_name,
        m.[probability_score],
        m.[priority_score],
        m.[ranking_score],
        m.match_status
    FROM [docketwatch].[dbo].[case_celebrity_matches] m
    INNER JOIN [docketwatch].[dbo].[celebrities] c ON c.id = m.fk_celebrity
    LEFT JOIN [docketwatch].[dbo].[celebrity_names] a 
        ON a.fk_celebrity = c.id AND a.type = 'Legal'
    WHERE m.fk_case = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer">
    AND m.match_status <> <cfqueryparam value="Removed" cfsqltype="cf_sql_varchar">
</cfquery>

<cfquery name="links" datasource="reach">
    SELECT 
        id,
        fk_case,
        case_url,
        title,
        category,
        created_at,
        fk_user,
        isActive
    FROM docketwatch.dbo.case_links
    WHERE fk_case = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer"> 
      and isactive = 1
</cfquery>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>Case Details - #case_details.case_number#</cfoutput></title>
    <cfinclude template="head.cfm">

</head>
