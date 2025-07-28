<cfset fk_user = getauthuser()>
<cfset subscribers_tab_status = "">

<cfquery name="case_details" datasource="Reach">
    SELECT [id],
           [case_number],
           [case_name],
           [notes] AS details,
           [last_updated],
           [owner],
           [created_at],
           [status],
           ISNULL([case_type], 'Unknown') AS case_type,
           [case_url],
           fk_court AS court_code,
           court_name_pacer,
           [summarize_html]
    FROM [docketwatch].[dbo].[cases]
    WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
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
    p.[pdf_title],
    e.[event_result],
    e.[party_type],
    e.[party_number],
    e.[amount],
    e.[fk_cases],
    e.[fk_task_run_log],
    e.[additional_information],
    e.[emailed],
    e.[summarize],
    e.[tmz_summarize],
    e.[event_url],
    e.[isDoc],
    p.[isDownloaded],
    p.[local_pdf_filename], -- main docket PDF

    -- HTML anchor tags for each attachment
    (
        SELECT STUFF((
            SELECT 
                ' <a href="/mediaroot/pacer_pdfs/' + ap.local_pdf_filename + '" target="_blank" class="btn btn-sm btn-outline-secondary" title="' + 
                ISNULL(REPLACE(ap.pdf_title, '"', ''), 'Exhibit') + 
                '"><i class=''fas fa-paperclip''></i></a>'
            FROM docketwatch.dbo.case_events_pdf ap
            WHERE ap.fk_case_event = e.id
              AND ap.pdf_type = 'Attachment'
              AND ap.isDownloaded = 1
              AND ap.local_pdf_filename IS NOT NULL order by ap.pdf_no 
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
    ) AS attachment_links

FROM docketwatch.dbo.case_events e

-- Main docket PDF (single)
LEFT JOIN docketwatch.dbo.case_events_pdf p 
    ON e.id = p.fk_case_event AND p.pdf_type = 'Docket'

WHERE e.fk_cases = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer">
ORDER BY e.created_at DESC



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
    WHERE fk_case = <cfqueryparam value="#case_details.id#" cfsqltype="cf_sql_integer"> and isactive = 1
</cfquery>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>Case Details - #case_details.case_number#</cfoutput></title>
    <cfinclude template="head.cfm"> <!--- Includes Bootstrap & DataTables CSS --->
    <style>
        /* Page-specific styling for case details */
        .case-actions {
            display: flex;
            gap: 0.5rem;
            flex-wrap: wrap;
        }
        
        .filter-card .card-header {
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
            border-bottom: 1px solid #cbd5e1;
            font-weight: 500;
            color: #475569;
        }
        
        .courthouse-image {
            width: 64px;
            height: 64px;
            object-fit: cover;
            border: 2px solid #e9ecef;
        }
        
        .pdf-actions {
            display: flex;
            gap: 0.25rem;
            align-items: center;
        }
        
        .btn-pdf {
            padding: 0.25rem 0.5rem;
            font-size: 0.875rem;
            border-radius: 0.375rem;
        }
        
        /* Responsive improvements */
        @media (max-width: 768px) {
            .case-header {
                padding: 1.5rem 0;
                margin-bottom: 1.5rem;
            }
            
            .case-actions {
                margin-top: 1rem;
            }
            
            .courthouse-image {
                width: 48px;
                height: 48px;
            }
            
            .pdf-actions {
                flex-direction: column;
                gap: 0.125rem;
            }
        }
        
        /* DataTable responsive improvements */
        @media (max-width: 992px) {
            .dataTables_wrapper .row {
                margin: 0;
            }
            
            .dataTables_wrapper .col-md-6 {
                padding: 0.5rem 0;
            }
        }
    </style>
</head>
<body>

<cfinclude template="navbar.cfm"> <!--- Navigation Bar --->

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
        <div class="row gx-4"> <!--- Bootstrap Row with horizontal gutter --->

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
                           class="ms-auto text-decoration-none btn btn-primary btn-sm" 
                           title="View full case"
                           aria-label="View full case in new window">
                            <i class="fas fa-external-link-alt" aria-hidden="true"></i>
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


                    <dl class="row mb-0">
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

                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-user me-1 text-muted" aria-hidden="true"></i>
                            Owner
                        </dt>
                        <dd class="col-sm-8 mb-2">
                            <cfoutput>#case_details.owner#</cfoutput>
                        </dd>

                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-calendar-plus me-1 text-muted" aria-hidden="true"></i>
                            Created
                        </dt>
                        <dd class="col-sm-8 mb-2">
                            <cfoutput>#dateFormat(case_details.created_at, "mm/dd/yyyy")#</cfoutput>
                        </dd>

                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-clock me-1 text-muted" aria-hidden="true"></i>
                            Last Updated
                        </dt>
                        <dd class="col-sm-8 mb-2">
                            <cfoutput>#dateFormat(case_details.last_updated, "mm/dd/yyyy")# at #timeformat(case_details.last_updated)#</cfoutput>
                        </dd>

                        <dt class="col-sm-4 mb-2">
                            <i class="fas fa-sticky-note me-1 text-muted" aria-hidden="true"></i>
                            Notes / Details
                        </dt>
                        <dd class="col-sm-8 mb-0">
                            <div class="bg-light p-3 rounded">
                                <pre class="mb-0" style="white-space: pre-wrap; font-family: inherit; font-size: inherit;">
                                    <cfoutput>#htmlEditFormat(case_details.details)#</cfoutput>
                                </pre>
                            </div>
                        </dd>
                    </dl>
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
                               class="ms-auto text-decoration-none btn btn-primary btn-sm" 
                               title="View Courthouse"
                               aria-label="View courthouse information in new window">
                                <i class="fas fa-external-link-alt" aria-hidden="true"></i>
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

    </div>
<!--- Set active tab variables --->
<cfset links_tab_status = "">
<cfset dockets_tab_status = "">
<cfset hearings_tab_status = "">
<cfset log_tab_status = "">
<cfset celebrities_tab_status = "">


<!--- Initialize all tab statuses --->
<cfset summary_tab_status = "">
<cfset links_tab_status = "">
<cfset dockets_tab_status = "">
<cfset hearings_tab_status = "">
<cfset log_tab_status = "">
<cfset celebrities_tab_status = "">
<cfset subscribers_tab_status = "">

<!--- Handle tab switching --->
<cfif structKeyExists(url, "tab")>
    <cfset tabName = lcase(trim(url.tab))>
    <cfif listFind("summary,links,dockets,hearings,log,celebrities,alerts", tabName)>
        <cfset "#tabName#_tab_status" = "active">
    <cfelse>
        <cfset summary_tab_status = "active"> <!--- fallback for invalid tab param --->
    </cfif>
<cfelse>
    <!--- Default to Summary tab for consistent behavior --->
    <cfset summary_tab_status = "active">
</cfif>


<!--- Enhanced Tabs Section --->
<div class="info-card shadow-sm mt-4">
    <div class="card-body p-0">

        <!--- Tab headings with enhanced styling --->
        <cfoutput>
        <ul class="nav nav-tabs" id="caseTabs" role="tablist">
            <li class="nav-item" role="presentation">
                <a class="nav-link #summary_tab_status#" 
                   id="summary-tab" 
                   data-bs-toggle="tab" 
                   href="##summary" 
                   role="tab"
                   aria-controls="summary"
                   aria-label="View case summary">
                    <i class="fas fa-file-text me-2" aria-hidden="true"></i>
                    Summary
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link #links_tab_status#" 
                   id="links-tab" 
                   data-bs-toggle="tab" 
                   href="##links" 
                   role="tab"
                   aria-controls="links"
                   aria-label="View case links">
                    <i class="fas fa-link me-2" aria-hidden="true"></i>
                    Links
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link #dockets_tab_status#" 
                   id="dockets-tab" 
                   data-bs-toggle="tab" 
                   href="##dockets" 
                   role="tab"
                   aria-controls="dockets"
                   aria-label="View case dockets">
                    <i class="fas fa-file-alt me-2" aria-hidden="true"></i>
                    Dockets
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link #hearings_tab_status#" 
                   id="hearings-tab" 
                   data-bs-toggle="tab" 
                   href="##hearings" 
                   role="tab"
                   aria-controls="hearings"
                   aria-label="View case hearings">
                    <i class="fas fa-gavel me-2" aria-hidden="true"></i>
                    Hearings
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link #log_tab_status#" 
                   id="log-tab" 
                   data-bs-toggle="tab" 
                   href="##log" 
                   role="tab"
                   aria-controls="log"
                   aria-label="View case activity log">
                    <i class="fas fa-history me-2" aria-hidden="true"></i>
                    Log
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link #celebrities_tab_status#" 
                   id="celebrities-tab" 
                   data-bs-toggle="tab" 
                   href="##celebrities" 
                   role="tab"
                   aria-controls="celebrities"
                   aria-label="View celebrity matches">
                    <i class="fas fa-star me-2" aria-hidden="true"></i>
                    Celebrities
                </a>
            </li>
            <li class="nav-item" role="presentation">
                <a class="nav-link #subscribers_tab_status#" 
                   id="alerts-tab" 
                   data-bs-toggle="tab" 
                   href="##alerts" 
                   role="tab"
                   aria-controls="alerts"
                   aria-label="View case subscribers">
                    <i class="fas fa-users me-2" aria-hidden="true"></i>
                    Subscribers
                </a>
            </li>
        </ul>
        </cfoutput>

        <!--- Tab content panes with enhanced styling --->
        <div class="tab-content mt-0" id="caseTabsContent">
            <cfoutput>
            <div class="tab-pane p-4 #summary_tab_status#" id="summary" role="tabpanel" aria-labelledby="summary-tab">
                <cfif len(trim(case_details.summarize_html))>
                    <div class="summary-content">
                        #REReplace(
                            case_details.summarize_html,
                            "<h3(.*?)>(.*?)</h3>",
                            "<h5\1>\2</h5>",
                            "all"
                        )#
                    </div>
                <cfelse>
                    <div class="empty-state">
                        <i class="fas fa-file-text" aria-hidden="true"></i>
                        <h5>No Summary Available</h5>
                        <p>No summary has been generated for this case yet.</p>
                    </div>
                </cfif>
            </div>

            <div class="tab-pane p-4 #links_tab_status#" id="links" role="tabpanel" aria-labelledby="links-tab">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h6 class="mb-0">
                        <i class="fas fa-link me-2 text-primary" aria-hidden="true"></i>
                        Case Links
                    </h6>
                    <button class="btn btn-primary" onclick="showAddLinkModal()" aria-label="Add new case link">
                        <i class="fas fa-plus me-2" aria-hidden="true"></i>
                        Add Link
                    </button>
                </div>

                <cfif links.recordcount GT 0>
                    <div class="data-table-wrapper">
                        <table id="linksTable" class="table table-striped table-hover mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th scope="col">
                                        <i class="fas fa-heading me-1" aria-hidden="true"></i>
                                        Title
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-tag me-1" aria-hidden="true"></i>
                                        Category
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-user me-1" aria-hidden="true"></i>
                                        Created By
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-calendar me-1" aria-hidden="true"></i>
                                        Date Added
                                    </th>
                                    <th scope="col" class="text-center">
                                        <i class="fas fa-cogs me-1" aria-hidden="true"></i>
                                        Actions
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="links">
                                <cfoutput>
                                    <tr>
                                        <td>
                                            <a href="#case_url#" target="_blank" class="text-decoration-none d-flex align-items-center">
                                                <i class="fas fa-external-link-alt me-2 text-muted" aria-hidden="true"></i>
                                                #title#
                                            </a>
                                        </td>
                                        <td>
                                            <span class="badge bg-secondary">#category#</span>
                                        </td>
                                        <td>#fk_user#</td>
                                        <td>#dateFormat(created_at, "mm/dd/yyyy")#</td>
                                        <td class="text-center">
                                            <button class="btn btn-sm btn-outline-danger" 
                                                    title="Delete link" 
                                                    onclick="deleteLink(#id#)"
                                                    aria-label="Delete link">
                                                <i class="fas fa-trash" aria-hidden="true"></i>
                                            </button>
                                        </td>
                                    </tr>
                                </cfoutput>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="empty-state">
                        <i class="fas fa-link" aria-hidden="true"></i>
                        <h5>No Links Found</h5>
                        <p>No links are associated with this case yet.</p>
                    </div>
                </cfif>
            </div>




            <!--- Dockets Tab --->
            <div class="tab-pane p-4 #dockets_tab_status#" id="dockets" role="tabpanel" aria-labelledby="dockets-tab">
                <div class="d-flex align-items-center mb-3">
                    <h6 class="mb-0">
                        <i class="fas fa-file-alt me-2 text-primary" aria-hidden="true"></i>
                        Docket Entries
                    </h6>
                </div>

                <cfif dockets.recordcount GT 0>
                    <div class="data-table-wrapper">
                        <table id="docketTable" class="table table-striped table-hover mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th scope="col">
                                        <i class="fas fa-hashtag me-1" aria-hidden="true"></i>
                                        Event No
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-calendar me-1" aria-hidden="true"></i>
                                        Date
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-file-text me-1" aria-hidden="true"></i>
                                        Description
                                    </th>
                                    <th scope="col" class="text-center">
                                        <i class="fas fa-download me-1" aria-hidden="true"></i>
                                        Actions
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="dockets">
                                <cfoutput>
                                    <tr>
                                        <td class="">#event_no#</td>
                                        <td data-order="#dateFormat(event_date, 'yyyy-mm-dd')#">
                                            #dateFormat(event_date, 'mm/dd/yyyy')#
                                        </td>
                                        <td>#event_description#</td>
                                        <td class="text-center">
                                            <div class="pdf-actions" id="button-container-#dockets.id#">
                                                <!--- View Docket PDF if downloaded --->
                                                <cfif dockets.isDownloaded EQ 1 AND len(dockets.local_pdf_filename)>
                                                    <a href="/mediaroot/pacer_pdfs/#dockets.local_pdf_filename#"
                                                       target="_blank"
                                                       class="btn btn-sm btn-success btn-pdf"
                                                       title="#dockets.pdf_title#"
                                                       aria-label="View PDF: #dockets.pdf_title#">
                                                        <i class="fas fa-file-pdf" aria-hidden="true"></i>
                                                    </a>
                                                <cfelseif dockets.isDoc EQ 1 AND len(dockets.event_url)>
                                                    <button class="btn btn-sm btn-primary btn-pdf get-pacer-pdf"
                                                            data-doc-id="#dockets.id#"
                                                            data-event-url="#dockets.event_url#"
                                                            data-case-id="#dockets.fk_cases#"
                                                            title="Download: #dockets.pdf_title#"
                                                            aria-label="Download PDF: #dockets.pdf_title#">
                                                        <i class="fas fa-download" aria-hidden="true"></i>
                                                    </button>
                                                </cfif>

                                                <!--- Attachment PDF icons (e.g., Exhibits) --->
                                                <cfif len(dockets.attachment_links)>
                                                    #dockets.attachment_links#
                                                </cfif>
                                            </div>
                                        </td>
                                    </tr>
                                </cfoutput>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="empty-state">
                        <i class="fas fa-file-alt" aria-hidden="true"></i>
                        <h5>No Dockets Found</h5>
                        <p>No docket entries are associated with this case yet.</p>
                    </div>
                </cfif>
            </div>
           

            <!--- Hearings Tab --->
            <div class="tab-pane p-4 #hearings_tab_status#" id="hearings" role="tabpanel" aria-labelledby="hearings-tab">
                <div class="d-flex align-items-center mb-3">
                    <h6 class="mb-0">
                        <i class="fas fa-gavel me-2 text-primary" aria-hidden="true"></i>
                        Scheduled Hearings
                    </h6>
                </div>

                <cfif hearings.recordcount GT 0>
                    <div class="data-table-wrapper">
                        <table id="hearingTable" class="table table-striped table-hover mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th scope="col">
                                        <i class="fas fa-calendar me-1" aria-hidden="true"></i>
                                        Date
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-clock me-1" aria-hidden="true"></i>
                                        Time
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-tag me-1" aria-hidden="true"></i>
                                        Type
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-file-text me-1" aria-hidden="true"></i>
                                        Description
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-building me-1" aria-hidden="true"></i>
                                        Department
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="hearings">
                                <cfoutput>
                                    <tr>
                                        <td>#dateFormat(date, "mm/dd/yyyy")#</td>
                                        <td>#timeFormat(time, "h:mm tt")#</td>
                                        <td>
                                            <span class="badge bg-info text-dark">#type#</span>
                                        </td>
                                        <td>#description#</td>
                                        <td>#department#</td>
                                    </tr>
                                </cfoutput>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="empty-state">
                        <i class="fas fa-gavel" aria-hidden="true"></i>
                        <h5>No Hearings Scheduled</h5>
                        <p>No hearings are scheduled for this case.</p>
                    </div>
                </cfif>
            </div>
   

            <!--- Log Tab --->
            <div class="tab-pane p-4 #log_tab_status#" id="log" role="tabpanel" aria-labelledby="log-tab">
                <div class="d-flex align-items-center mb-3">
                    <h6 class="mb-0">
                        <i class="fas fa-history me-2 text-primary" aria-hidden="true"></i>
                        Activity Log
                    </h6>
                </div>

                <cfif logs.recordcount GT 0>
                    <div class="data-table-wrapper">
                        <table id="logTable" class="table table-striped table-hover mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th scope="col">
                                        <i class="fas fa-check-circle me-1" aria-hidden="true"></i>
                                        Completed
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-tasks me-1" aria-hidden="true"></i>
                                        Task
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-info-circle me-1" aria-hidden="true"></i>
                                        Status
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-clock me-1" aria-hidden="true"></i>
                                        Duration
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-file-text me-1" aria-hidden="true"></i>
                                        Description
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="logs">
                                <cfoutput>
                                    <tr>
                                        <td>
                                            <div class="d-flex flex-column">
                                                <span class="">#dateFormat(timestamp_ended, "mm/dd/yyyy")#</span>
                                                <small class="text-muted">#timeFormat(timestamp_ended, "hh:mm tt")#</small>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="badge bg-primary">#task_name#</span>
                                        </td>
                                        <td>
                                            <cfif status EQ "Success">
                                                <span class="badge bg-success">#status#</span>
                                            <cfelseif status EQ "Failed">
                                                <span class="badge bg-danger">#status#</span>
                                            <cfelse>
                                                <span class="badge bg-secondary">#status#</span>
                                            </cfif>
                                        </td>
                                        <td>
                                            <span class="badge bg-info text-dark">#duration_mmss#</span>
                                        </td>
                                        <td>
                                            <div class="text-truncate" style="max-width: 300px;" title="#HTMLEditFormat(summary)#">
                                                #HTMLEditFormat(summary)#
                                            </div>
                                        </td>
                                    </tr>
                                </cfoutput>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="empty-state">
                        <i class="fas fa-history" aria-hidden="true"></i>
                        <h5>No Activity Log</h5>
                        <p>No activity has been logged for this case yet.</p>
                    </div>
                </cfif>
            </div>

            <!--- Subscribers Tab --->
            <div class="tab-pane p-4 #subscribers_tab_status#" id="alerts" role="tabpanel" aria-labelledby="alerts-tab">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h6 class="mb-0">
                        <i class="fas fa-users me-2 text-primary" aria-hidden="true"></i>
                        Case Subscribers
                    </h6>
                </div>

                <div class="subscriber-controls">
                    <div class="row align-items-center">
                        <div class="col-md-8">
                            <label for="addUserSelect" class="form-label mb-2">
                                <i class="fas fa-user-plus me-1" aria-hidden="true"></i>
                                <strong>Add User:</strong>
                            </label>
                            <select id="addUserSelect" class="form-select" aria-label="Select user to add as subscriber">
                                <option value="">Choose a user to add...</option>
                                <cfloop query="eligible_users">
                                <cfoutput>
                                    <option value="#id#">#display#</option>
                                </cfoutput>
                                </cfloop>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <button class="btn btn-primary w-100 mt-4" 
                                    id="addSubscriberBtn"
                                    aria-label="Add selected user as subscriber">
                                <i class="fas fa-plus me-2" aria-hidden="true"></i>
                                Add Subscriber
                            </button>
                        </div>
                    </div>
                </div>

                <cfif subscribers.recordcount GT 0>
                    <div class="data-table-wrapper">
                        <table id="alertsTable" class="table table-striped table-hover mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th scope="col">
                                        <i class="fas fa-user me-1" aria-hidden="true"></i>
                                        Full Name
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-envelope me-1" aria-hidden="true"></i>
                                        Email
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-shield-alt me-1" aria-hidden="true"></i>
                                        User Role
                                    </th>
                                    <th scope="col" class="text-center">
                                        <i class="fas fa-cogs me-1" aria-hidden="true"></i>
                                        Actions
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="subscribers">
                                <cfoutput>
                                    <tr id="subscriberRow_#subscribers.id#">
                                        <td>
                                            <div class="d-flex align-items-center">
                                                <i class="fas fa-user-circle me-2 text-muted" aria-hidden="true"></i>
                                                #fullname#
                                            </div>
                                        </td>
                                        <td>
                                            <a href="mailto:#email#" class="text-decoration-none">
                                                #email#
                                            </a>
                                        </td>
                                        <td>
                                            <span class="badge bg-secondary">#userRole#</span>
                                        </td>
                                        <td class="text-center">
                                            <button class="btn btn-sm btn-outline-danger" 
                                                    onclick="removeSubscriber(#id#)"
                                                    title="Remove subscriber"
                                                    aria-label="Remove #fullname# from subscribers">
                                                <i class="fas fa-trash" aria-hidden="true"></i>
                                            </button>
                                        </td>
                                    </tr>
                                </cfoutput>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="empty-state">
                        <i class="fas fa-users" aria-hidden="true"></i>
                        <h5>No Subscribers</h5>
                        <p>No users are subscribed to receive notifications for this case.</p>
                    </div>
                </cfif>
            </div>


            <!--- Celebrities Tab --->
            <div class="tab-pane p-4 #celebrities_tab_status#" id="celebrities" role="tabpanel" aria-labelledby="celebrities-tab">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h6 class="mb-0">
                        <i class="fas fa-star me-2 text-primary" aria-hidden="true"></i>
                        Celebrity Matches
                    </h6>
                </div>

                <div class="celebrity-search-container">
                    <div class="row align-items-end">
                        <div class="col-md-8">
                            <label for="celebritySearch" class="form-label mb-2">
                                <i class="fas fa-search me-1" aria-hidden="true"></i>
                                <strong>Find Celebrity:</strong>
                            </label>
                            <select id="celebritySearch" class="form-select" aria-label="Search for celebrity to add">
                                <option value="">Start typing to search celebrities...</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <button id="submitCelebrityBtn" 
                                    class="btn btn-primary w-100" 
                                    style="display: none;"
                                    aria-label="Add selected celebrity to case">
                                <i class="fas fa-star me-2" aria-hidden="true"></i>
                                Add Celebrity
                            </button>
                        </div>
                    </div>

                    <input type="hidden" id="celebrityId">
                    
                    <div id="celebrityWarnings" class="mt-3" style="display: none;">
                        <div id="primaryNotice" class="alert alert-info" style="display: none;"></div>
                        <div id="verifyWarning" class="alert alert-warning" style="display: none;"></div>
                    </div>
                </div>

                <!--- Celebrity matches table --->
                <div id="celebrityTableWrapper" <cfif celebrities.recordcount EQ 0>style="display:none;"</cfif>>
                    <div class="data-table-wrapper">
                        <table id="celebTable" class="table table-striped table-hover mb-0">
                            <thead class="table-dark">
                                <tr>
                                    <th scope="col">
                                        <i class="fas fa-star me-1" aria-hidden="true"></i>
                                        Celebrity
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-check-circle me-1" aria-hidden="true"></i>
                                        Status
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-percent me-1" aria-hidden="true"></i>
                                        Probability
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-exclamation me-1" aria-hidden="true"></i>
                                        Priority
                                    </th>
                                    <th scope="col">
                                        <i class="fas fa-sort-numeric-up me-1" aria-hidden="true"></i>
                                        Ranking
                                    </th>
                                    <th scope="col" class="text-center">
                                        <i class="fas fa-cogs me-1" aria-hidden="true"></i>
                                        Actions
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="celebrities">
                                <cfoutput>
                                    <tr>
                                        <td>
                                            <div class="d-flex align-items-center">
                                                <i class="fas fa-star me-2 text-warning" aria-hidden="true"></i>
                                                #celebrity_name#
                                                <a href="celebrity_details.cfm?id=#celebrities.celebrity_id#" 
                                                   target="_blank" 
                                                   class="ms-2 text-decoration-none btn btn-sm btn-outline-primary"
                                                   title="View celebrity details"
                                                   aria-label="View details for #celebrity_name#">
                                                    <i class="fas fa-external-link-alt" aria-hidden="true"></i>
                                                </a>
                                            </div>
                                        </td>
                                        <td>
                                            <cfif Match_status EQ "Verified">
                                                <span class="badge bg-success">#Match_status#</span>
                                            <cfelseif Match_status EQ "Pending">
                                                <span class="badge bg-warning text-dark">#Match_status#</span>
                                            <cfelse>
                                                <span class="badge bg-secondary">#Match_status#</span>
                                            </cfif>
                                        </td>
                                        <td>
                                            <div class="progress" style="height: 20px;">
                                                <div class="progress-bar" 
                                                     role="progressbar" 
                                                     style="width: #numberFormat(probability_score, '0.00')#%"
                                                     aria-valuenow="#numberFormat(probability_score, '0.00')#" 
                                                     aria-valuemin="0" 
                                                     aria-valuemax="100">
                                                    #numberFormat(probability_score, "0.00")#%
                                                </div>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="badge bg-info text-dark">#numberFormat(priority_score, "0.00")#</span>
                                        </td>
                                        <td>
                                            <span class="badge bg-dark">#numberFormat(ranking_score, "0.00")#</span>
                                        </td>
                                        <td class="text-center">
                                            <button class="btn btn-sm btn-outline-danger" 
                                                    title="Remove celebrity match" 
                                                    onclick="deleteCelebrityMatch('#celebrities.id#')"
                                                    aria-label="Remove #celebrity_name# from matches">
                                                <i class="fas fa-trash" aria-hidden="true"></i>
                                            </button>
                                        </td>
                                    </tr>
                                </cfoutput>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                </div>

                <cfif celebrities.recordcount EQ 0>
                    <div class="empty-state">
                        <i class="fas fa-star" aria-hidden="true"></i>
                        <h5>No Celebrity Matches</h5>
                        <p>No celebrities have been matched to this case yet.</p>
                    </div>
                </cfif>
            </div>

        </div>
        </cfoutput>
    </div>
</div>
// Enhanced DataTable initialization with loading states
$(document).ready(function() {
    // Show loading overlay for tables
    function showTableLoading(tableId) {
        const wrapper = $(`#${tableId}`).closest('.data-table-wrapper');
        if (wrapper.length && !wrapper.find('.loading-overlay').length) {
            wrapper.css('position', 'relative').append(
                '<div class="loading-overlay"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div></div>'
            );
        }
    }

    function hideTableLoading(tableId) {
        const wrapper = $(`#${tableId}`).closest('.data-table-wrapper');
        wrapper.find('.loading-overlay').remove();
    }

    // Initialize DataTables with enhanced styling
    if ($('#hearingTable').length) {
        showTableLoading('hearingTable');
        $('#hearingTable').DataTable({
            order: [[0, 'desc']],
            pageLength: 10,
            responsive: true,
            language: {
                emptyTable: "No hearings scheduled for this case"
            },
            initComplete: function() {
                hideTableLoading('hearingTable');
            }
        });
    }

    if ($('#docketTable').length) {
        showTableLoading('docketTable');
        $('#docketTable').DataTable({
            order: [[1, 'desc']],
            paging: false,
            info: false,
            lengthChange: false,
            searching: true,
            ordering: true,
            responsive: true,
            language: {
                emptyTable: "No docket entries found for this case"
            },
            initComplete: function() {
                hideTableLoading('docketTable');
            }
        });
    }

    if ($('#logTable').length) {
        showTableLoading('logTable');
        $('#logTable').DataTable({
            order: [[0, 'desc']],
            pageLength: 25,
            responsive: true,
            language: {
                emptyTable: "No activity logged for this case"
            },
            initComplete: function() {
                hideTableLoading('logTable');
            }
        });
    }

    if ($('#linksTable').length) {
        showTableLoading('linksTable');
        $('#linksTable').DataTable({
            order: [[3, 'desc']],
            pageLength: 10,
            responsive: true,
            language: {
                emptyTable: "No links added to this case"
            },
            initComplete: function() {
                hideTableLoading('linksTable');
            }
        });
    }

    if ($('#alertsTable').length) {
        showTableLoading('alertsTable');
        $('#alertsTable').DataTable({
            order: [[0, 'asc']],
            pageLength: 10,
            responsive: true,
            language: {
                emptyTable: "No subscribers for this case"
            },
            initComplete: function() {
                hideTableLoading('alertsTable');
            }
        });
    }

    if ($('#celebTable').length) {
        showTableLoading('celebTable');
        $('#celebTable').DataTable({
            order: [[4, 'desc']],
            pageLength: 10,
            responsive: true,
            language: {
                emptyTable: "No celebrity matches found"
            },
            initComplete: function() {
                hideTableLoading('celebTable');
            }
        });
    }

    // Enhanced PDF download functionality with better UX
    $('body').on('click', '.get-pacer-pdf', function() {
        var button = $(this);
        var docId = button.data('doc-id');
        var eventUrl = button.data('event-url');
        var caseId = button.data('case-id');
        var buttonContainer = $('#button-container-' + docId);

        // Enhanced loading state with better animation
        button.prop('disabled', true).html(`
            <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
            <span>Downloading...</span>
        `);

        $.ajax({
            url: 'ajax_getPacerDoc.cfm',
            method: 'POST',
            data: {
                docID: docId,
                eventURL: eventUrl,
                caseID: caseId
            },
            dataType: 'json',
            timeout: 60000, // 60 second timeout
            success: function(response) {
                if (response.STATUS === 'SUCCESS') {
                    // Success state with icon
                    var successButton = `
                        <a href="${response.FILEPATH}" 
                           target="_blank" 
                           class="btn btn-sm btn-success btn-pdf"
                           title="View downloaded PDF"
                           aria-label="View PDF document">
                            <i class="fas fa-file-pdf me-1" aria-hidden="true"></i>
                            View PDF
                        </a>
                    `;
                    buttonContainer.html(successButton);
                    
                    // Show success notification
                    if (typeof Swal !== 'undefined') {
                        Swal.fire({
                            icon: 'success',
                            title: 'PDF Downloaded',
                            text: 'Document is ready to view',
                            timer: 2000,
                            showConfirmButton: false
                        });
                    }
                } else {
                    // Error state
                    if (typeof Swal !== 'undefined') {
                        Swal.fire({
                            icon: 'error',
                            title: 'Download Failed',
                            text: response.MESSAGE || 'Unable to download PDF'
                        });
                    } else {
                        alert('Error: ' + (response.MESSAGE || 'Unable to download PDF'));
                    }
                    // Reset button
                    button.prop('disabled', false).html('<i class="fas fa-download" aria-hidden="true"></i>');
                }
            },
            error: function(xhr, status, error) {
                // Network error state
                if (typeof Swal !== 'undefined') {
                    Swal.fire({
                        icon: 'error',
                        title: 'Network Error',
                        text: 'Please check your connection and try again'
                    });
                } else {
                    alert('Network error occurred. Please try again.');
                }
                button.prop('disabled', false).html('<i class="fas fa-download" aria-hidden="true"></i>');
                console.error("AJAX Error:", status, error);
            }
        });
    });

    // Global function for modal handling
    window.showAddLinkModal = function () {
        $('#addLinkModal').modal('show');
    };

    // Enhanced form submission with better feedback
    if (document.getElementById("addLinkForm")) {
        document.getElementById("addLinkForm").addEventListener("submit", function (e) {
            e.preventDefault();
            
            const submitBtn = e.target.querySelector('button[type="submit"]');
            const originalText = submitBtn.innerHTML;
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Adding...';

            fetch("insert_case_link.cfm?bypass=1", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    fk_case: this.fk_case.value,
                    fk_user: this.fk_user.value,
                    case_url: this.case_url.value
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    if (typeof Swal !== 'undefined') {
                        Swal.fire("Success", "Link added successfully!", "success").then(() => {
                            window.location.href = window.location.pathname + "?id=" + encodeURIComponent(getUrlParam("id")) + "&tab=links";
                        });
                    } else {
                        alert("Link added successfully!");
                        window.location.reload();
                    }
                } else {
                    if (typeof Swal !== 'undefined') {
                        Swal.fire("Error", data.message || "Unable to add link", "error");
                    } else {
                        alert("Error: " + (data.message || "Unable to add link"));
                    }
                }
            })
            .catch(err => {
                if (typeof Swal !== 'undefined') {
                    Swal.fire("Error", "Network error occurred", "error");
                } else {
                    alert("Network error: " + err.message);
                }
            })
            .finally(() => {
                submitBtn.disabled = false;
                submitBtn.innerHTML = originalText;
            });
        });
    }

    // Celebrity Search Functionality
    const caseId = $('#case_details input[name="fk_case"]').val() || <cfoutput>#case_details.id#</cfoutput>;

    // Initialize Select2 for celebrity search
    $('#celebritySearch').select2({
        placeholder: 'Lookup a celebrity to add...',
        allowClear: true,
        width: '50%',
        minimumInputLength: 0,
        ajax: {
            url: 'lookup_celebrity_autocomplete.cfm',
            dataType: 'json',
            delay: 250,
            data: function (params) {
                return { term: params.term };
            },
            processResults: function (data) {
                return {
                    results: data.map(function (item) {
                        return {
                            id: item.celebrity_id,
                            text: item.display_name,
                            verified: item.verified,
                            celebrity_name: item.celebrity_name
                        };
                    })
                };
            }
        }
    });

    // Show dropdown on click
    $('#celebritySearch').on('focus', function () {
        $(this).select2('open');
    });

    // Celebrity selection handler
    $('#celebritySearch').on('select2:select', function (e) {
        const data = e.params.data;
        $('#celebrityId').val(data.id);
        $('#submitCelebrityBtn').show();
        $('#celebrityWarnings').show();

        if (data.text !== data.celebrity_name) {
            $('#primaryNotice').html(
                `You selected <strong>${data.text}</strong>. This will be linked to the public-facing name <strong>${data.celebrity_name}</strong>.`
            ).show();
        } else {
            $('#primaryNotice').hide();
        }

        if (data.verified !== 'Verified') {
            $('#verifyWarning').html(' This name has not been verified yet.').show();
        } else {
            $('#verifyWarning').hide();
        }
    });

    // Celebrity submission handler
    $('#submitCelebrityBtn').click(function () {
        const celebId = $('#celebrityId').val();
        const selectedData = $('#celebritySearch').select2('data')[0];
        const name = selectedData ? selectedData.text : '';

        if (!celebId) return;

        $.post("insert_case_celebrity.cfm", {
            fk_case: caseId,
            fk_celebrity: celebId
        }, function (response) {
            if (response.status === "success") {
                $('#celebrityId').val('');

                const newRow = `
                    <tr>
                        <td>
                            <div class="d-flex align-items-center">
                                <i class="fas fa-star me-2 text-warning" aria-hidden="true"></i>
                                ${response.celebrity_name}
                                <a href="celebrity_details.cfm?id=${response.celebrity_id}" 
                                   target="_blank" 
                                   class="ms-2 text-decoration-none btn btn-sm btn-outline-primary"
                                   title="View celebrity details">
                                    <i class="fas fa-external-link-alt" aria-hidden="true"></i>
                                </a>
                            </div>
                        </td>
                        <td>
                            <span class="badge bg-secondary">${response.match_status}</span>
                        </td>
                        <td>
                            <div class="progress" style="height: 20px;">
                                <div class="progress-bar" 
                                     role="progressbar" 
                                     style="width: ${response.probability_score || '0.00'}%">
                                    ${response.probability_score || '0.00'}%
                                </div>
                            </div>
                        </td>
                        <td>
                            <span class="badge bg-info text-dark">${response.priority_score || '0.00'}</span>
                        </td>
                        <td>
                            <span class="badge bg-dark">${response.ranking_score || '0.00'}</span>
                        </td>
                        <td class="text-center">
                            <button class="btn btn-sm btn-outline-danger" 
                                    title="Remove celebrity match" 
                                    onclick="deleteCelebrityMatch('${response.match_id}')">
                                <i class="fas fa-trash" aria-hidden="true"></i>
                            </button>
                        </td>
                    </tr>`;

                $('#celebrityTableWrapper').show();
                $('#celebTable tbody').append(newRow);

                $('#submitCelebrityBtn').hide();
                $('#celebrityWarnings, #primaryNotice, #verifyWarning').hide();
                $('#celebritySearch').val(null).trigger('change.select2');
            } else {
                if (typeof Swal !== 'undefined') {
                    Swal.fire("Error", "Insert failed: " + (response.error || "Unknown error"), "error");
                } else {
                    alert("Insert failed: " + (response.error || "Unknown error"));
                }
            }
        }, "json");
    });

    // Subscriber Management
    document.getElementById('addSubscriberBtn').addEventListener('click', function () {
        const caseId = <cfoutput>#case_details.id#</cfoutput>;
        const select = document.getElementById('addUserSelect');
        const username = select.value;

        if (!username) {
            if (typeof Swal !== 'undefined') {
                Swal.fire('Error', 'Please select a user to add.', 'warning');
            } else {
                alert('Please select a user to add.');
            }
            return;
        }

        fetch('insert_case_subscriber.cfm', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ fk_case: caseId, fk_username: username })
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                const tableBody = document.querySelector('#alertsTable tbody');
                const row = document.createElement('tr');
                row.id = 'subscriberRow_' + data.id;

                row.innerHTML = `
                    <td>
                        <div class="d-flex align-items-center">
                            <i class="fas fa-user-circle me-2 text-muted" aria-hidden="true"></i>
                            ${data.firstname} ${data.lastname}
                        </div>
                    </td>
                    <td>
                        <a href="mailto:${data.email}" class="text-decoration-none">
                            ${data.email}
                        </a>
                    </td>
                    <td>
                        <span class="badge bg-secondary">${data.userRole || 'user'}</span>
                    </td>
                    <td class="text-center">
                        <button class="btn btn-sm btn-outline-danger" 
                                onclick="removeSubscriber(${data.id})"
                                title="Remove subscriber"
                                aria-label="Remove ${data.firstname} ${data.lastname} from subscribers">
                            <i class="fas fa-trash" aria-hidden="true"></i>
                        </button>
                    </td>
                `;

                tableBody.appendChild(row);

                // Remove from dropdown
                select.querySelector(`option[value="${username}"]`)?.remove();
                select.selectedIndex = 0;
            } else {
                if (typeof Swal !== 'undefined') {
                    Swal.fire('Error', data.message || 'Insert failed.', 'error');
                } else {
                    alert('Error: ' + (data.message || 'Insert failed.'));
                }
            }
        })
        .catch(err => {
            console.error(err);
            if (typeof Swal !== 'undefined') {
                Swal.fire('Error', 'Network error occurred', 'error');
            } else {
                alert('Network error: ' + err.message);
            }
        });
    });
});

// Subscriber removal function
function removeSubscriber(id) {
    if (typeof Swal !== 'undefined') {
        Swal.fire({
            title: 'Remove Subscriber?',
            text: 'This will remove the user from case notifications.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: '<i class="fas fa-user-minus me-2"></i>Yes, remove',
            cancelButtonText: 'Cancel',
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d'
        }).then((result) => {
            if (result.isConfirmed) {
                fetch('delete_case_subscriber.cfm?id=' + id)
                    .then(res => res.json())
                    .then(data => {
                        if (data.success) {
                            // Remove the row from the table
                            const row = document.getElementById('subscriberRow_' + id);
                            if (row) {
                                // Get name and username before removing
                                const fullName = row.querySelector('td:nth-child(1)').textContent.trim();
                                const username = data.fk_username;
                                row.remove();

                                // Add user back to dropdown
                                const select = document.getElementById('addUserSelect');
                                const option = document.createElement('option');
                                option.value = username;
                                option.textContent = fullName;
                                select.appendChild(option);
                            }
                            Swal.fire('Removed!', 'Subscriber has been removed.', 'success');
                        } else {
                            Swal.fire('Error', data.message || 'Could not remove user.', 'error');
                        }
                    })
                    .catch(err => Swal.fire('Error', err.message, 'error'));
            }
        });
    } else {
        if (confirm('Remove this subscriber?')) {
            fetch('delete_case_subscriber.cfm?id=' + id)
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        const row = document.getElementById('subscriberRow_' + id);
                        if (row) {
                            const fullName = row.querySelector('td:nth-child(1)').textContent.trim();
                            const username = data.fk_username;
                            row.remove();

                            const select = document.getElementById('addUserSelect');
                            const option = document.createElement('option');
                            option.value = username;
                            option.textContent = fullName;
                            select.appendChild(option);
                        }
                        alert('Subscriber removed successfully!');
                    } else {
                        alert('Error: ' + (data.message || 'Could not remove user.'));
                    }
                })
                .catch(err => alert('Error: ' + err.message));
        }
    }
}

// Utility function for URL parameters
function getUrlParam(key) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(key);
}

// Modal functions for link management
function showAddLinkModal() {
    const modal = new bootstrap.Modal(document.getElementById('addLinkModal'));
    modal.show();
}

// Handle add link form submission
document.addEventListener('DOMContentLoaded', function() {
    const addLinkForm = document.getElementById('addLinkForm');
    if (addLinkForm) {
        addLinkForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(addLinkForm);
            const data = {
                fk_case: formData.get('fk_case'),
                fk_user: formData.get('fk_user'),
                case_url: formData.get('case_url'),
                title: formData.get('case_url'), // Use URL as title if no title field
                category: 'General'
            };
            
            fetch('insert_case_link.cfm', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    if (typeof Swal !== 'undefined') {
                        Swal.fire('Success!', 'Link added successfully', 'success')
                            .then(() => location.reload());
                    } else {
                        alert('Link added successfully!');
                        location.reload();
                    }
                } else {
                    if (typeof Swal !== 'undefined') {
                        Swal.fire('Error', data.message || 'Failed to add link', 'error');
                    } else {
                        alert('Error: ' + (data.message || 'Failed to add link'));
                    }
                }
            })
            .catch(error => {
                console.error('Error:', error);
                if (typeof Swal !== 'undefined') {
                    Swal.fire('Error', 'Network error occurred', 'error');
                } else {
                    alert('Network error occurred');
                }
            });
        });
    }
});
</script>

<script>
function deleteCelebrityMatch(matchId) {
  Swal.fire({
    title: 'Are you sure?',
    text: 'This will remove the celebrity match from view (soft delete).',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, delete it',
    cancelButtonText: 'Cancel',
    confirmButtonColor: '#d33',
    cancelButtonColor: '#aaa'
  }).then((result) => {
    if (result.isConfirmed) {
      fetch('delete_case_celebrity.cfm?bypass=1', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ id: matchId })
      })
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          Swal.fire('Deleted!', data.message || 'Celebrity match removed.', 'success')
            .then(() => {
              // Reload page and activate the Celebrities tab
              const caseId = new URLSearchParams(window.location.search).get("id");
              window.location.href = `${window.location.pathname}?id=${caseId}&tab=celebrities`;
            });
        } else {
          Swal.fire('Error', data.message || 'Could not delete match.', 'error');
        }
      })
      .catch(err => Swal.fire('Error', err.message, 'error'));
    }
  });
}
</script>



            




        </div> <!--- /.tab-content --->
    </div>
</div>

    </div> <!--- /.container --->
</div> <!--- /.container-fluid --->

<cfinclude template="footer_script.cfm"> <!--- Includes JS libraries --->


<script>
// Enhanced case status update with better UX
function updateCaseStatus(caseId, newStatus) {
    const statusIcons = {
        'Review': 'fas fa-search',
        'Tracked': 'fas fa-eye', 
        'Removed': 'fas fa-times'
    };
    
    const statusColors = {
        'Review': '#ffc107',
        'Tracked': '#17a2b8',
        'Removed': '#dc3545'
    };

    if (typeof Swal !== 'undefined') {
        Swal.fire({
            title: 'Confirm Status Change',
            html: `
                <div class="text-center">
                    <i class="${statusIcons[newStatus]} fa-3x mb-3" style="color: ${statusColors[newStatus]}"></i>
                    <p>Set this case status to <strong>${newStatus}</strong>?</p>
                </div>
            `,
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: statusColors[newStatus],
            cancelButtonColor: '#6c757d',
            confirmButtonText: `<i class="${statusIcons[newStatus]} me-2"></i>Yes, set to ${newStatus}`,
            cancelButtonText: 'Cancel'
        }).then((result) => {
            if (result.isConfirmed) {
                // Show loading state
                Swal.fire({
                    title: 'Updating Status...',
                    allowOutsideClick: false,
                    didOpen: () => {
                        Swal.showLoading();
                    }
                });

                fetch('update_case_status.cfm', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({id: caseId, status: newStatus})
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        Swal.fire({
                            title: 'Status Updated!',
                            html: `Case status successfully changed to <strong>${newStatus}</strong>`,
                            icon: 'success',
                            confirmButtonColor: '#28a745'
                        }).then(() => {
                            location.reload();
                        });
                    } else {
                        Swal.fire({
                            title: 'Update Failed',
                            text: 'Error updating status: ' + (data.message || 'Unknown error'),
                            icon: 'error',
                            confirmButtonColor: '#dc3545'
                        });
                    }
                })
                .catch(error => {
                    Swal.fire({
                        title: 'Network Error',
                        text: 'Unable to connect to server. Please try again.',
                        icon: 'error',
                        confirmButtonColor: '#dc3545'
                    });
                    console.error('Status update error:', error);
                });
            }
        });
    } else {
        // Fallback for no SweetAlert
        if (confirm(`Set this case status to ${newStatus}?`)) {
            fetch('update_case_status.cfm', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({id: caseId, status: newStatus})
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Status updated successfully!');
                    location.reload();
                } else {
                    alert('Error updating status: ' + (data.message || 'Unknown error'));
                }
            })
            .catch(error => {
                alert('Network error occurred. Please try again.');
                console.error('Status update error:', error);
            });
        }
    }
}
</script>



<script>
// Enhanced link deletion with better UX
function deleteLink(linkId) {
    if (typeof Swal !== 'undefined') {
        Swal.fire({
            title: 'Remove Link?',
            text: 'This will permanently remove the link from this case.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: '<i class="fas fa-trash me-2"></i>Yes, remove it',
            cancelButtonText: 'Cancel',
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d'
        }).then((result) => {
            if (result.isConfirmed) {
                // Show loading
                Swal.fire({
                    title: 'Removing Link...',
                    allowOutsideClick: false,
                    didOpen: () => { Swal.showLoading(); }
                });

                fetch('delete_case_link.cfm', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id: linkId })
                })
                .then(res => res.json())
                .then(data => {
                    if (data.success) {
                        Swal.fire({
                            title: 'Link Removed!',
                            text: 'The link has been successfully removed.',
                            icon: 'success',
                            confirmButtonColor: '#28a745'
                        }).then(() => location.reload());
                    } else {
                        Swal.fire({
                            title: 'Removal Failed',
                            text: data.message || 'Could not remove the link.',
                            icon: 'error',
                            confirmButtonColor: '#dc3545'
                        });
                    }
                })
                .catch(err => {
                    Swal.fire({
                        title: 'Network Error',
                        text: 'Unable to connect to server. Please try again.',
                        icon: 'error',
                        confirmButtonColor: '#dc3545'
                    });
                    console.error('Delete link error:', err);
                });
            }
        });
    } else {
        // Fallback for no SweetAlert
        if (confirm('Are you sure you want to remove this link?')) {
            fetch('delete_case_link.cfm', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: linkId })
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    alert('Link removed successfully!');
                    location.reload();
                } else {
                    alert('Error: ' + (data.message || 'Could not remove link'));
                }
            })
            .catch(err => {
                alert('Network error occurred. Please try again.');
                console.error('Delete link error:', err);
            });
        }
    }
}
</script>

<!--- Add Link Modal --->
<div class="modal " id="addLinkModal" tabindex="-1" aria-labelledby="addLinkModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <form id="addLinkForm">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="addLinkModalLabel">Add New Link</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" name="fk_case" value="<cfoutput>#case_details.id#</cfoutput>">
          <input type="hidden" name="fk_user" value="<cfoutput>#fk_user#</cfoutput>">

          <div class="mb-3">
            <label for="case_url" class="form-label">URL</label>
            <input type="url" class="form-control" id="case_url" name="case_url" required>
          </div>
        </div>
        <div class="modal-footer">
          <button type="submit" class="btn btn-primary">Add Link</button>
        </div>
      </div>
    </form>
  </div>
</div>

</body>
</html>