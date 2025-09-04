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
<body>

<cfinclude template="navbar.cfm">

<div class="container-fluid mt-4">
    <!-- Minimal header section matching search form style -->
    <div class="container">
        <div class="card shadow-sm mb-4 filter-card">
            <div class="card-header">
                <h6 class="mb-0 d-flex align-items-center">
                    <i class="fas fa-gavel me-2"></i>Case Details - <cfoutput>#case_details.case_name#</cfoutput>
                    <div class="ms-auto d-flex gap-2">
                        <a href="case_update.cfm?id=<cfoutput>#case_details.id#</cfoutput>" 
                           class="btn btn-primary btn-sm" 
                           role="button"
                           aria-label="Update case details">
                            <i class="fas fa-edit me-1" aria-hidden="true"></i>
                            Update
                        </a>
                        <button onclick="history.back()" 
                                class="btn btn-outline-secondary btn-sm"
                                aria-label="Go back to previous page">
                            <i class="fas fa-arrow-left me-1" aria-hidden="true"></i>
                            Back
                        </button>
                    </div>
                </h6>

            </div>
        </div>
    </div>

    <div class="container">
        <div class="row gx-4">
        <!--- Case Detail Section --->
        <div class="col-12 col-xl-6">
            <div class="card shadow-sm mb-4 filter-card">
                <div class="card-header">
                    <h6 class="mb-0 d-flex align-items-center">
                        <i class="fas fa-file-alt me-2"></i>Case Information
                        <cfoutput>
                        <cfif len(trim(case_details.case_url))>
                        <a href="#case_details.case_url#" 
                           target="_blank" 
                           class="ms-auto btn btn-primary btn-sm" 
                           role="button"
                           aria-label="View full case in external site">
                            <i class="fas fa-external-link-alt me-1" aria-hidden="true"></i>
                            External Link
                        </a>
                        </cfif>
                        </cfoutput>
                    </h6>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <strong>Case Number:</strong> <cfoutput>#case_details.case_number#</cfoutput><br>
                        <strong>Case Name:</strong> <cfoutput>#case_details.case_name#</cfoutput>
                    </div>

                    <dl class="row mb-3">
                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-flag me-1 text-muted" aria-hidden="true"></i>
                            Status
                        </dt>
                        <dd class="col-sm-8 mb-2">
                            <cfoutput>
                            <span id="currentStatus" class="status-badge status-#lcase(case_details.status)#">
                                <cfif case_details.status EQ "Review">
                                    <i class="fas fa-search" aria-hidden="true"></i>
                                <cfelseif case_details.status EQ "Tracked">
                                    <i class="fas fa-eye" aria-hidden="true"></i>
                                <cfelseif case_details.status EQ "Removed">
                                    <i class="fas fa-times" aria-hidden="true"></i>
                                </cfif>
                                #case_details.status#
                            </span>
                            </cfoutput>

                            <div class="btn-group ms-2" role="group" aria-label="Status change actions">
                                <cfoutput>
                                <cfif case_details.status EQ "Review">
                                    <button class="btn btn-sm btn-outline-danger" 
                                            onclick="updateCaseStatus(#case_details.id#, 'Removed')"
                                            aria-label="Remove case from tracking">
                                        <i class="fas fa-trash me-1" aria-hidden="true"></i>
                                        Remove
                                    </button>
                                    <button class="btn btn-sm btn-outline-success" 
                                            onclick="updateCaseStatus(#case_details.id#, 'Tracked')"
                                            aria-label="Start tracking case">
                                        <i class="fas fa-eye me-1" aria-hidden="true"></i>
                                        Track
                                    </button>
                                <cfelseif case_details.status EQ "Tracked">
                                    <button class="btn btn-sm btn-outline-secondary" 
                                            onclick="updateCaseStatus(#case_details.id#, 'Review')"
                                            aria-label="Set case to review status">
                                        <i class="fas fa-search me-1" aria-hidden="true"></i>
                                        Review
                                    </button>
                                    <button class="btn btn-sm btn-outline-danger" 
                                            onclick="updateCaseStatus(#case_details.id#, 'Removed')"
                                            aria-label="Remove case from tracking">
                                        <i class="fas fa-trash me-1" aria-hidden="true"></i>
                                        Remove
                                    </button>
                                <cfelseif case_details.status EQ "Removed">
                                    <button class="btn btn-sm btn-outline-secondary" 
                                            onclick="updateCaseStatus(#case_details.id#, 'Review')"
                                            aria-label="Set case to review status">
                                        <i class="fas fa-search me-1" aria-hidden="true"></i>
                                        Review
                                    </button>
                                    <button class="btn btn-sm btn-outline-success" 
                                            onclick="updateCaseStatus(#case_details.id#, 'Tracked')"
                                            aria-label="Start tracking case">
                                        <i class="fas fa-eye me-1" aria-hidden="true"></i>
                                        Track
                                    </button>
                                </cfif>
                                </cfoutput>
                            </div>
                        </dd>

                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-folder-open me-1 text-muted" aria-hidden="true"></i>
                            Case Type
                        </dt>
                        <dd class="col-sm-8 mb-2">
                            <cfoutput>#case_details.case_type#</cfoutput>
                        </dd>

                        <cfoutput>
                        <cfif len(trim(case_details.tool_name))>
                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-tools me-1 text-muted" aria-hidden="true"></i>
                            Tool
                        </dt>
                        <dd class="col-sm-8 mb-2">
                            <div class="d-flex align-items-center">
                                <div class="flex-grow-1">
                                    <cfif len(trim(case_details.case_url))>
                                        <a href="#case_details.case_url#" target="_blank" class="text-decoration-none">
                                            #case_details.tool_name#
                                            <i class="fas fa-external-link-alt ms-1 text-muted" aria-hidden="true"></i>
                                        </a>
                                    <cfelse>
                                        #case_details.tool_name#
                                    </cfif>
                                </div>
                                <cfif len(trim(case_details.username)) OR len(trim(case_details.pass))>
                                    <button type="button" 
                                            class="btn btn-sm btn-outline-secondary ms-2" 
                                            data-bs-toggle="modal" 
                                            data-bs-target="##toolCredentialsModal"
                                            title="View login credentials"
                                            aria-label="View tool login credentials">
                                        <i class="fas fa-key" aria-hidden="true"></i>
                                    </button>
                                </cfif>
                            </div>
                        </dd>
                        </cfif>
                        </cfoutput>

                        <cfoutput>
                        <cfif len(trim(case_details.details))>
                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-tag me-1 text-muted" aria-hidden="true"></i>
                            Category
                        </dt>
                        <dd class="col-sm-8 mb-0">
                            #htmlEditFormat(case_details.details)#
                        </dd>
                        </cfif>
                        </cfoutput>
                    </dl>
                    
                    <!--- Timestamp info --->
                    <div class="mt-3 pt-3 border-top">
                        <small class="text-muted">
                            <i class="fas fa-calendar-plus me-1" aria-hidden="true"></i>
                            Created: <cfoutput>#dateFormat(case_details.created_at, "mm/dd/yyyy")#</cfoutput>
                            &nbsp;&nbsp;&nbsp;
                            <i class="fas fa-clock me-1" aria-hidden="true"></i>
                            Last Updated: <cfoutput>#dateFormat(case_details.last_updated, "mm/dd/yyyy")# at #timeFormat(case_details.last_updated, "h:mm tt")#</cfoutput>
                        </small>
                    </div>
                </div>
            </div>
        </div>

        <!--- Courthouse Info Section --->
        <div class="col-12 col-xl-6">
            <div class="card shadow-sm mb-4 filter-card">
                <div class="card-header">
                    <h6 class="mb-0 d-flex align-items-center">
                        <i class="fas fa-university me-2"></i>Courthouse Information
                        <cfoutput>
                        <cfif len(trim(courthouse.court_url))>
                            <a href="#courthouse.court_url#" 
                               target="_blank" 
                               class="ms-auto btn btn-primary btn-sm" 
                               role="button"
                               aria-label="View courthouse information in external site">
                                <i class="fas fa-external-link-alt me-1" aria-hidden="true"></i>
                                External Link
                            </a>
                        </cfif>
                        </cfoutput>
                    </h6>
                </div>
                <div class="card-body">

                    <cfoutput>
                    <cfif case_details.court_name_pacer neq "">
                        <div class="alert alert-info d-flex align-items-center">
                            <i class="fas fa-info-circle me-2" aria-hidden="true"></i>
                            <strong>#case_details.court_name_pacer#</strong>
                        </div>
                    <cfelse>
                        <div class="d-flex align-items-center mb-3">
                            <img src="#courthouse.image_url#" 
                                 alt="Courthouse" 
                                 class="courthouse-image rounded-circle me-3">
                            <div>
                                <h6 class="mb-1 ">#courthouse.court_name#</h6>
                                <p class="mb-0 text-muted">
                                    <i class="fas fa-map-marker-alt me-1" aria-hidden="true"></i>
                                    #courthouse.address#<br>
                                    #courthouse.city#, #courthouse.state# #courthouse.zip#
                                </p>
                            </div>
                        </div>

                        <dl class="row mb-0">
                            <dt class="col-sm-4 mb-2">
                                <i class="fas fa-map me-1 text-muted" aria-hidden="true"></i>
                                County
                            </dt>
                            <dd class="col-sm-8 mb-2">#courthouse.county_name#</dd>

                            <dt class="col-sm-4 mb-0">
                                <i class="fas fa-id-card me-1 text-muted" aria-hidden="true"></i>
                                Court ID
                            </dt>
                            <dd class="col-sm-8 mb-0">#courthouse.court_code#</dd>
                        </dl>
                    </cfif>
                    </cfoutput>
                </div>
            </div>
        </div>

    </div> <!-- /.row -->
