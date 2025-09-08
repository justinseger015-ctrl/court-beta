<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Case Events - Alert Dashboard</title>
    <cfinclude template="head.cfm">
    <style>
          :root {
            --tmz-red: #9d3433;
            --tmz-dark-gray: #2b2b2b;
        }
        /* Alert Card Styling */
        .event-alert {
            border-left: 5px solid var(--tmz-red);
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        .event-alert.unacknowledged {
            border-left-color: var(--tmz-red);
            box-shadow: 0 0 20px rgba(157, 52, 51, 0.3);
            animation: pulse-glow 2s infinite;
            border-top: 2px solid var(--tmz-red);
        }
        .event-alert.acknowledged {
            border-left-color: #28a745;
            opacity: 0.8;
            border-top: 2px solid #28a745;
        }
        @keyframes pulse-glow {
            0% { box-shadow: 0 0 5px rgba(157, 52, 51, 0.2); }
            50% { box-shadow: 0 0 25px rgba(157, 52, 51, 0.5); }
            100% { box-shadow: 0 0 5px rgba(157, 52, 51, 0.2); }
        }
        .event-alert:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        
        .event-alert.unacknowledged:hover {
            transform: translateY(-3px);
            box-shadow: 0 6px 20px rgba(157, 52, 51, 0.4);
            border-left-color: #ff4444;
        }
        
        .event-alert.unacknowledged:hover::after {
            content: "Click to acknowledge";
            position: absolute;
            top: 10px;
            right: 100px;
            background: rgba(157, 52, 51, 0.9);
            color: white;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 0.8rem;
            z-index: 5;
        }
        .avatar-placeholder {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--tmz-dark-gray) 0%, #1a1a1a 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.5rem;
            font-weight: bold;
            border: 2px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }
        .celebrity-avatar {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
        }
        .case-avatar {
            width: 200px;
            height: 160px;
            border-radius: 12px;
            object-fit: cover;
            border: 4px solid var(--tmz-red);
            box-shadow: 0 8px 25px rgba(157, 52, 51, 0.3);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .case-avatar:hover {
            transform: scale(1.02);
            box-shadow: 0 12px 35px rgba(157, 52, 51, 0.4);
        }
        .case-avatar-placeholder {
            width: 200px;
            height: 160px;
            border-radius: 12px;
            background: linear-gradient(135deg, var(--tmz-red) 0%, #8b2635 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 2.5rem;
            font-weight: bold;
            border: 4px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 6px 20px rgba(157, 52, 51, 0.3);
        }
        .event-status {
            position: absolute;
            top: 15px;
            right: 15px;
            z-index: 10;
        }
        .status-new {
            background: linear-gradient(45deg, #ff6b6b, #ee5a24);
            color: white;
            animation: bounce 1s infinite;
        }
        .status-acknowledged {
            background: linear-gradient(45deg, #00d2d3, #54a0ff);
            color: white;
        }
        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }
        .action-buttons {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }
        .action-buttons .btn-group-vertical {
            border-radius: 0.375rem;
            overflow: hidden;
        }
        .action-buttons .btn-group-vertical .btn {
            border-radius: 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        .action-buttons .btn-group-vertical .btn:first-child {
            border-top-left-radius: 0.375rem;
            border-top-right-radius: 0.375rem;
        }
        .action-buttons .btn-group-vertical .btn:last-child {
            border-bottom-left-radius: 0.375rem;
            border-bottom-right-radius: 0.375rem;
            border-bottom: none;
        }
        .event-number-badge {
            display: inline-flex;
            align-items: center;
            font-weight: 500;
        }
        .btn-action {
            padding: 0.5rem 1rem;
            font-size: 0.875rem;
            border-radius: 0.375rem;
            transition: all 0.3s ease;
        }
        .btn-action:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(157, 52, 51, 0.3);
        }
        .event-meta {
            font-size: 0.875rem;
            color: #6c757d;
        }
        .case-info {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-radius: 10px;
            padding: 1rem;
            margin-bottom: 1rem;
        }
        .event-description {
            font-size: 1.1rem;
            line-height: 1.5;
            margin: 0.5rem 0;
        }
        .timestamp-badge {
            background: var(--tmz-dark-gray);
            color: white;
            padding: 0.25rem 0.75rem;
            border-radius: 15px;
            font-size: 0.8rem;
            font-weight: 500;
        }
        .status-badge {
            padding: 0.25rem 0.75rem;
            border-radius: 15px;
            font-size: 0.8rem;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .status-rss {
            background: linear-gradient(45deg, #ffa726, #ff9800);
            color: white;
        }
        .status-rss-pending {
            background: linear-gradient(45deg, #ffeb3b, #ffc107);
            color: #333;
        }
        .status-null {
            background: linear-gradient(45deg, #9e9e9e, #757575);
            color: white;
        }
        .acknowledge-btn {
            position: absolute;
            top: 15px;
            left: 15px;
            z-index: 10;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            border: none;
            background: rgba(157, 52, 51, 0.9);
            color: white;
            transition: all 0.3s ease;
        }
        .acknowledge-btn:hover {
            background: rgba(157, 52, 51, 1);
            transform: scale(1.1);
        }
        .acknowledge-btn.acknowledged {
            background: rgba(40, 167, 69, 0.9);
        }
        .filter-controls {
            background: white;
            border-radius: 10px;
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .stats-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        .stat-card {
            background: white;
            border-radius: 10px;
            padding: 1.5rem;
            text-align: center;
            box-shadow: 0 2px 10px rgba(157, 52, 51, 0.2);
            border-top: 4px solid var(--tmz-red);
        }
        .stat-number {
            font-size: 2rem;
            font-weight: bold;
            color: var(--tmz-red);
        }
        .stat-label {
            color: #6c757d;
            font-size: 0.9rem;
        }
        
        /* Floating Acknowledge Button */
        .floating-ack-btn {
            position: fixed;
            bottom: 30px;
            right: 30px;
            z-index: 1000;
            animation: pulse 2s infinite;
        }
        
        .floating-ack-btn .btn {
            width: 70px;
            height: 70px;
            box-shadow: 0 4px 20px rgba(157, 52, 51, 0.4);
            position: relative;
        }
        
        .floating-ack-btn .badge {
            position: absolute;
            top: -5px;
            right: -5px;
            background: white !important;
            color: var(--tmz-red) !important;
            font-weight: bold;
            border: 2px solid var(--tmz-red);
        }
        
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
        /* Mobile responsiveness */
        @media (max-width: 768px) {
            .action-buttons { justify-content: center; }
            .avatar-placeholder, .celebrity-avatar { width: 60px; height: 60px; }
            .case-avatar { width: 150px; height: 120px; }
            .case-avatar-placeholder { width: 150px; height: 120px; font-size: 2rem; }
            .event-status { position: static; margin-bottom: 0.5rem; }
            .acknowledge-btn { position: static; margin-bottom: 0.5rem; }
        }
    </style>

</head>
<body>

<cfinclude template="navbar.cfm">

<!-- Params and sanitization -->
<cfparam name="url.status" default="all">
<cfparam name="url.acknowledged" default="all">
<cfparam name="url.page" default="1">
<cfparam name="url.pageSize" default="20">

<cfset allowedStatus = "all,Active,Processed">
<cfif listFindNoCase(allowedStatus, url.status) EQ 0><cfset url.status = "all"></cfif>

<cfset allowedAck = "all,0,1">
<cfif listFindNoCase(allowedAck, url.acknowledged) EQ 0><cfset url.acknowledged = "all"></cfif>

<cfset page = val(url.page)>
<cfif page LT 1><cfset page = 1></cfif>

<cfset pageSize = val(url.pageSize)>
<cfif pageSize LT 5 OR pageSize GT 100><cfset pageSize = 20></cfif>

<cfset offsetRows = (page - 1) * pageSize>

<!-- Events query (paged, Tracked only) -->
<cfquery name="events" datasource="Reach">
    WITH celeb AS (
        SELECT 
            m.fk_case,
            cel.name AS celebrity_name,
            cel.image_url AS celebrity_image,
            m.probability_score AS match_probability,
            ROW_NUMBER() OVER (PARTITION BY m.fk_case ORDER BY m.ranking_score DESC) AS rn
        FROM docketwatch.dbo.case_celebrity_matches m
        INNER JOIN docketwatch.dbo.celebrities cel ON cel.id = m.fk_celebrity
        WHERE m.match_status <> 'Removed'
    )
    SELECT 
        e.id,
        e.event_no,
        e.event_date,
        e.event_description,
        e.additional_information,
        e.created_at,
        e.status,
        e.event_result,
        e.fk_cases,
        e.event_url,
        e.isDoc,
        e.summarize,
        e.tmz_summarize,
        ISNULL(e.acknowledged, 0) AS acknowledged,
        e.acknowledged_at,
        e.acknowledged_by,

        c.case_number,
        c.case_name,
        c.case_url,
        c.case_image_url,
        c.status AS case_status,

        d.pdf_title,
        d.summary_ai,
        d.summary_ai_html,
        CASE 
            WHEN d.rel_path IS NOT NULL AND d.rel_path <> '' 
                THEN '/pdf/' + d.rel_path
            WHEN d.doc_id IS NOT NULL 
                THEN '/docs/cases/' + CAST(e.fk_cases AS varchar(20)) + '/E' + CAST(d.doc_id AS varchar(20)) + '.pdf'
            ELSE NULL
        END AS pdf_path,

        celeb.celebrity_name,
        celeb.celebrity_image,
        celeb.match_probability
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    LEFT JOIN docketwatch.dbo.documents d 
        ON e.id = d.fk_case_event 
       AND (d.pdf_type IS NULL OR d.pdf_type <> 'Attachment')
    LEFT JOIN celeb ON celeb.fk_case = e.fk_cases AND celeb.rn = 1
    WHERE 1=1
      AND c.status = 'Tracked'
      AND c.case_number <> 'Unfiled'
      <cfif url.status NEQ "all">
        AND e.status = <cfqueryparam value="#url.status#" cfsqltype="cf_sql_varchar">
      </cfif>
      <cfif url.acknowledged NEQ "all">
        AND ISNULL(e.acknowledged, 0) = <cfqueryparam value="#url.acknowledged#" cfsqltype="cf_sql_bit">
      </cfif>
    ORDER BY e.created_at DESC, e.acknowledged ASC
    OFFSET <cfqueryparam value="#offsetRows#" cfsqltype="cf_sql_integer"> ROWS
    FETCH NEXT <cfqueryparam value="#pageSize#" cfsqltype="cf_sql_integer"> ROWS ONLY;
</cfquery>

<!-- Statistics (Tracked only) -->
<cfquery name="stats" datasource="Reach">
    SELECT 
        COUNT(*) as total_events,
        SUM(CASE WHEN ISNULL(acknowledged, 0) = 0 THEN 1 ELSE 0 END) as unacknowledged,
        SUM(CASE WHEN ISNULL(acknowledged, 0) = 1 THEN 1 ELSE 0 END) as acknowledged,
        SUM(CASE WHEN isDoc = 1 THEN 1 ELSE 0 END) as with_documents
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    WHERE c.status = 'Tracked'
      AND c.case_number <> 'Unfiled'
</cfquery>

<div class="container-fluid mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-0">
                <i class="fas fa-bell me-2 text-primary"></i>
                Case Events Alert Dashboard
            </h2>
            <p class="text-muted mb-0">Monitor and manage case events in real-time</p>
        </div>
        <div>
            <button class="btn btn-outline-secondary" onclick="window.location.reload()">
                <i class="fas fa-sync-alt me-1"></i>
                Refresh
            </button>
        </div>
    </div>

    <div class="stats-cards">
        <cfoutput>
        <div class="stat-card">
            <div class="stat-number">#stats.total_events#</div>
            <div class="stat-label">Total Events</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">#stats.unacknowledged#</div>
            <div class="stat-label">Needs Attention</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">#stats.acknowledged#</div>
            <div class="stat-label">Acknowledged</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">#stats.with_documents#</div>
            <div class="stat-label">With Documents</div>
        </div>
        </cfoutput>
    </div>

    <div class="filter-controls">
        <div class="row align-items-center">
            <div class="col-md-3">
                <label for="statusFilter" class="form-label">
                    <i class="fas fa-filter me-1"></i>
                    Filter by Status
                </label>
                <select id="statusFilter" class="form-select" onchange="updateFilters()">
                    <option value="all" <cfif url.status eq "all">selected</cfif>>All Status</option>
                    <option value="Active" <cfif url.status eq "Active">selected</cfif>>Active</option>
                    <option value="Processed" <cfif url.status eq "Processed">selected</cfif>>Processed</option>
                </select>
            </div>
            <div class="col-md-3">
                <label for="ackFilter" class="form-label">
                    <i class="fas fa-check-circle me-1"></i>
                    Acknowledgment
                </label>
                <select id="ackFilter" class="form-select" onchange="updateFilters()">
                    <option value="all" <cfif url.acknowledged eq "all">selected</cfif>>All Events</option>
                    <option value="0" <cfif url.acknowledged eq "0">selected</cfif>>Needs Attention</option>
                    <option value="1" <cfif url.acknowledged eq "1">selected</cfif>>Acknowledged</option>
                </select>
            </div>
            <div class="col-md-4">
                <label class="form-label">Quick Actions</label>
                <div class="d-flex gap-2">
                    <button class="btn btn-primary btn-sm" onclick="acknowledgeAll()">
                        <i class="fas fa-check-double me-1"></i>
                        Acknowledge All Visible
                    </button>
                    <button class="btn btn-outline-secondary btn-sm" onclick="doExport()">
                        <i class="fas fa-download me-1"></i>
                        Export Events
                    </button>
                </div>
            </div>
            <div class="col-md-2">
                <label class="form-label">Page Size</label>
                <select id="pageSize" class="form-select form-select-sm" onchange="changePageSize()">
                    <option value="20"  <cfif pageSize EQ 20>selected</cfif>>20</option>
                    <option value="50"  <cfif pageSize EQ 50>selected</cfif>>50</option>
                    <option value="100" <cfif pageSize EQ 100>selected</cfif>>100</option>
                </select>
            </div>
        </div>
    </div>
<CFoutput>
    <div class="d-flex align-items-center justify-content-end mb-3 gap-2">
        <div class="btn-group">
            <a class="btn btn-outline-secondary btn-sm" href="#buildPageUrl(page-1)#" <cfif page EQ 1>style="pointer-events:none;opacity:.5"</cfif>>&laquo; Prev</a>
            <span class="btn btn-outline-secondary btn-sm disabled">Page #page#</span>
            <a class="btn btn-outline-secondary btn-sm" href="#buildPageUrl(page+1)#">Next &raquo;</a>
        </div>
    </div>
</CFoutput>
    <!-- Events List -->
    <div class="row">
     <!---   <cfif events.recordcount EQ 0>
            <div class="col-12">
                <div class="text-center py-5">
                    <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                    <h4 class="text-muted">No Events Found</h4>
                    <p class="text-muted">No case events match your current filters.</p>
                </div>
            </div>
        <cfelse> --->
            <cfoutput query="events">
                <div class="col-12 mb-4">
                    <div class="card event-alert #iif(acknowledged, de('acknowledged'), de('unacknowledged'))#" 
                         id="event-#id#" 
                         <cfif NOT acknowledged>
                         data-event-id="#id#" 
                         style="cursor: pointer;" 
                         title="Click to acknowledge this event"
                         </cfif>>

                    <!-- Acknowledge Button -->
                    <cfif NOT acknowledged>
                        <button class="acknowledge-btn" onclick="acknowledgeEvent(#id#); event.stopPropagation();" title="Mark as acknowledged">
                            <i class="fas fa-exclamation"></i>
                        </button>
                    <cfelse>
                        <button class="acknowledge-btn acknowledged" title="Already acknowledged">
                            <i class="fas fa-check"></i>
                        </button>
                    </cfif>

                    <!-- Status Badge -->
        <div class="event-status">
            <span class="badge #iif(acknowledged, de('status-acknowledged'), de('status-new'))#">
                #iif(acknowledged, de('ACKNOWLEDGED'), de('NEW'))#
            </span>
        </div>


                    <div class="card-body">
                        <div class="row">
                            <!-- Avatar Column -->
                            <div class="col-md-2 text-center mb-3">
                                <cfif len(case_image_url)>
                                    <img src="#case_image_url#" loading="lazy" decoding="async" alt="#htmlEditFormat(case_name)#" class="case-avatar" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                    <div class="case-avatar-placeholder" style="display:none;">
                                        <i class="fas fa-balance-scale"></i>
                                    </div>
                                    <div class="mt-3">
                                        <strong class="text-primary">Case Image</strong>
                                    </div>
                                <cfelseif len(celebrity_name) AND len(celebrity_image)>
                                    <img src="#celebrity_image#" loading="lazy" decoding="async" alt="#htmlEditFormat(celebrity_name)#" class="celebrity-avatar" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                    <div class="avatar-placeholder" style="display:none;">#left(celebrity_name, 2)#</div>
                                    <div class="mt-2"><small class="text-muted">#celebrity_name#</small></div>
                                <cfelseif len(celebrity_name)>
                                    <div class="avatar-placeholder">#left(celebrity_name, 2)#</div>
                                    <div class="mt-2"><small class="text-muted">#celebrity_name#</small></div>
                                <cfelse>
                                    <div class="avatar-placeholder"><i class="fas fa-gavel"></i></div>
                                    <div class="mt-2"><small class="text-muted">Legal Case</small></div>
                                </cfif>
                            </div>

                            <!-- Main Content Column -->
                            <div class="col-md-7">
                                <div class="case-info">
                                    <h5 class="mb-2 text-dark fw-bold">#htmlEditFormat(case_name)#</h5>
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="d-flex align-items-center gap-2">
                                                <span><strong>Case No.:</strong> #htmlEditFormat(case_number)#</span>
                                                <div class="btn-group btn-group-sm" role="group">
                                                    <a href="case_details.cfm?id=#fk_cases#" title="View Case Details" class="btn btn-outline-primary btn-sm">
                                                        <i class="fa-solid fa-file-lines"></i>
                                                    </a>
                                                    <cfif len(case_url)>
                                                        <a href="#case_url#" target="_blank" title="Open Official Court Page" class="btn btn-outline-secondary btn-sm">
                                                            <i class="fa-solid fa-up-right-from-square"></i>
                                                        </a>
                                                    </cfif>
                                                </div>
                                            </div>
                                        </div>
                                     <div class="col-md-6">
                                            <strong>Event ##:</strong>
                                            <span class="event-number-badge">
                                                <cfif acknowledged>
                                                    <i class="fas fa-circle text-success me-1" style="font-size: 0.5rem;"></i>
                                                <cfelse>
                                                    <i class="fas fa-circle text-danger me-1" style="font-size: 0.5rem;"></i>
                                                </cfif>
                                                #event_no#
                                            </span>
                                        </div>
                                    </div>
                                </div>

                                <div class="event-description">
                                    <strong>#htmlEditFormat(event_description)#</strong>
                                    <cfif len(additional_information)>
                                        <div class="mt-2 text-muted">#htmlEditFormat(additional_information)#</div>
                                    </cfif>
                                </div>

                                <div class="event-meta mt-3">
                                    <div class="d-flex flex-wrap gap-3">
                                        <div>
                                            <cfset statusClass = "">
                                            <cfset statusText = "">
                                            <cfswitch expression="#lcase(trim(status))#">
                                                <cfcase value="new"><cfset statusClass = "status-new"><cfset statusText = "New"></cfcase>
                                                <cfcase value="rss"><cfset statusClass = "status-rss"><cfset statusText = "RSS"></cfcase>
                                                <cfcase value="rss pending"><cfset statusClass = "status-rss-pending"><cfset statusText = "RSS Pending"></cfcase>
                                                <cfdefaultcase><cfset statusClass = "status-null"><cfset statusText = "Unknown"></cfdefaultcase>
                                            </cfswitch>
                                            <span class="status-badge #statusClass#"><i class="fas fa-info-circle me-1"></i>#statusText#</span>
                                        </div>
                                        <div><i class="fas fa-calendar me-1"></i><strong>Event Date:</strong> #dateFormat(event_date, "mm/dd/yyyy")#</div>
                                        <div>
                                            <span class="timestamp-badge"><i class="fas fa-clock me-1"></i>#dateFormat(created_at, "mm/dd/yyyy")# at #timeFormat(created_at, "h:mm tt")#</span>
                                        </div>
                                        <cfif acknowledged>
                                            <div class="text-success"><i class="fas fa-check-circle me-1"></i>Acknowledged #dateFormat(acknowledged_at, "mm/dd/yyyy")#</div>
                                        </cfif>
                                    </div>
                                </div>
                            </div>

                            <!-- Actions Column -->
                            <div class="col-md-3">
                                <div class="action-buttons">
                                    <div class="btn-group-vertical w-100 mb-2" role="group" aria-label="Document Actions">
                                        <cfif len(pdf_path)>
                                            <a href="#pdf_path#" target="_blank" class="btn btn-success btn-action"><i class="fas fa-file-pdf me-1"></i>View PDF</a>
                                        <cfelseif isDoc AND len(event_url)>
                                            <button class="btn btn-primary btn-action get-pdf-btn" data-event-id="#id#" data-event-url="#event_url#" data-case-id="#fk_cases#">
                                                <i class="fas fa-download me-1"></i>Get PDF
                                            </button>
                                        </cfif>
                                        <cfif len(summary_ai_html)>
                                            <button class="btn btn-primary btn-action" data-bs-toggle="modal" data-bs-target="##summaryModal#id#">
                                                <i class="fas fa-brain me-1"></i>View Summary
                                            </button>
                                        <cfelse>
                                            <button class="btn btn-outline-primary btn-action generate-summary-btn" data-event-id="#id#">
                                                <i class="fas fa-magic me-1"></i>Generate Summary
                                            </button>
                                        </cfif>
                                    </div>
                                    <div class="btn-group-vertical w-100 mb-2" role="group" aria-label="Content Actions">
                                        <button class="btn btn-primary btn-action generate-tmz-btn" data-event-id="#id#" data-case-name="#htmlEditFormat(case_name)#">
                                            <i class="fas fa-newspaper me-1"></i>TMZ Article
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div> <!-- row -->
                    </div> <!-- card-body -->
                </div> <!-- card -->
            </div> <!-- col -->
            </cfoutput>
  
    </div> <!-- row -->
</div> <!-- container-fluid -->

<!-- Floating Acknowledge All Button -->
<div id="floatingAckBtn" class="floating-ack-btn" style="display: none;">
    <button class="btn btn-danger btn-lg rounded-circle" onclick="acknowledgeAll()" title="Acknowledge All Unacknowledged Events">
        <i class="fas fa-check-double"></i>
        <span class="badge badge-light" id="unackCount">0</span>
    </button>
</div>

<!-- Summary Modals -->
<cfoutput query="events">
    <cfif len(summary_ai_html)>
    <div class="modal fade" id="summaryModal#id#" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title"><i class="fas fa-brain me-2"></i>AI Summary - Event #event_no#</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <strong>Case:</strong> #htmlEditFormat(case_name)# (#htmlEditFormat(case_number)#)<br>
                        <strong>Event:</strong> #htmlEditFormat(event_description)#
                    </div>
                    <hr>
                    <div class="summary-content">#summary_ai_html#</div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>
    </cfif>
</cfoutput>
<cfscript>
/* Build page URL with preserved filters */
function buildPageUrl(newPage){
    var params = [];
    if (url.status NEQ "all") arrayAppend(params, "status=" & urlEncodedFormat(url.status));
    if (url.acknowledged NEQ "all") arrayAppend(params, "acknowledged=" & urlEncodedFormat(url.acknowledged));
    if (pageSize NEQ 20) arrayAppend(params, "pageSize=" & pageSize);
    if (newPage LT 1) newPage = 1;
    arrayAppend(params, "page=" & newPage);
    return getPageContext().getRequest().getRequestURI() & "?" & arrayToList(params, "&");
}
</cfscript>

<script>
$(document).ready(function() {
    // Initialize floating acknowledge button
    updateEventCounts();
    
    // Auto-refresh every 30 seconds
    setInterval(function() {
        if (document.visibilityState === 'visible') {
            updateEventCounts();
        }
    }, 30000);

    // Click on unacknowledged card to acknowledge
    $('body').on('click', '.event-alert.unacknowledged[data-event-id]', function(e) {
        // Don't trigger if clicking on buttons, links, or other interactive elements
        if ($(e.target).closest('button, a, .btn').length === 0) {
            const eventId = $(this).data('event-id');
            acknowledgeEvent(eventId);
        }
    });

    // Get PDF
    $('body').on('click', '.get-pdf-btn', function() {
        var button = $(this);
        var eventId = button.data('event-id');
        var eventUrl = button.data('event-url');
        var caseId = button.data('case-id');

        button.prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-1"></span>Getting PDF...');

        $.ajax({
            url: 'ajax_getPacerDoc.cfm',
            method: 'POST',
            data: { docID: eventId, eventURL: eventUrl, caseID: caseId },
            dataType: 'json',
            success: function(response) {
                if (response.STATUS === 'SUCCESS') {
                    button.replaceWith('<a href="' + response.FILEPATH + '" target="_blank" class="btn btn-success btn-action"><i class="fas fa-file-pdf me-1"></i>View PDF</a>');
                    showNotification('success', 'PDF downloaded successfully!');
                } else {
                    showNotification('error', 'Failed to download PDF: ' + (response.MESSAGE || 'Unknown error'));
                    button.prop('disabled', false).html('<i class="fas fa-download me-1"></i>Get PDF');
                }
            },
            error: function() {
                showNotification('error', 'Network error occurred');
                button.prop('disabled', false).html('<i class="fas fa-download me-1"></i>Get PDF');
            }
        });
    });

    // Generate Summary
    $('body').on('click', '.generate-summary-btn', function() {
        var button = $(this);
        var eventId = button.data('event-id');

        button.prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-1"></span>Generating...');

        $.ajax({
            url: 'ajax_generateSummary.cfm',
            method: 'POST',
            data: { eventId: eventId },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    button.replaceWith('<button class="btn btn-primary btn-action" data-bs-toggle="modal" data-bs-target="#summaryModal' + eventId + '"><i class="fas fa-brain me-1"></i>View Summary</button>');
                    $('body').append(response.modalHtml);
                    showNotification('success', 'Summary generated successfully!');
                } else {
                    showNotification('error', 'Failed to generate summary: ' + (response.message || 'Unknown error'));
                    button.prop('disabled', false).html('<i class="fas fa-magic me-1"></i>Generate Summary');
                }
            },
            error: function() {
                showNotification('error', 'Network error occurred');
                button.prop('disabled', false).html('<i class="fas fa-magic me-1"></i>Generate Summary');
            }
        });
    });

    // Generate TMZ Article (mock)
    $('body').on('click', '.generate-tmz-btn', function() {
        var button = $(this);
        var caseName = button.data('case-name');

        button.prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-1"></span>Writing...');

        setTimeout(function() {
            Swal.fire({
                title: 'TMZ Article Generated!',
                html: '<div class="text-left"><h6>BREAKING: ' + caseName + ' - New Court Filing!</h6><p class="small text-muted">[MOCK ARTICLE] In a shocking turn of events, new court documents have been filed in the ' + caseName + ' case. Sources close to the situation say this could be a game-changer. Stay tuned for more updates as this story develops...</p><div class="mt-3"><button class="btn btn-sm btn-primary me-2">Share on Social</button><button class="btn btn-sm btn-outline-secondary">Save Draft</button></div></div>',
                icon: 'success',
                width: 600,
                showConfirmButton: false,
                timer: 5000
            });
            button.prop('disabled', false).html('<i class="fas fa-newspaper me-1"></i>TMZ Article');
        }, 1500);
    });
});

// Acknowledge single event
function acknowledgeEvent(eventId) {
    // Show loading state
    const eventCard = $('#event-' + eventId);
    eventCard.css('opacity', '0.7').find('.acknowledge-btn').prop('disabled', true);
    
    $.ajax({
        url: 'ajax_acknowledgeEvent.cfm',
        method: 'POST',
        data: { eventId: eventId },
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                // Update visual state
                eventCard.removeClass('unacknowledged').addClass('acknowledged');
                
                // Remove clickable behavior
                eventCard.removeAttr('data-event-id style title').css('cursor', 'default');
                
                // Update acknowledge button
                const ackBtn = eventCard.find('.acknowledge-btn');
                ackBtn.addClass('acknowledged').html('<i class="fas fa-check"></i>').prop('onclick', null).prop('disabled', false);
                
                // Update status badge
                eventCard.find('.event-status .badge').removeClass('status-new').addClass('status-acknowledged').text('ACKNOWLEDGED');
                
                // Add acknowledged timestamp to meta section
                const now = new Date();
                const timeString = now.toLocaleDateString() + ' at ' + now.toLocaleTimeString();
                eventCard.find('.event-meta .d-flex').append(
                    '<div class="text-success"><i class="fas fa-check-circle me-1"></i>Acknowledged ' + timeString + '</div>'
                );
                
                // Restore opacity with animation
                eventCard.animate({'opacity': '0.8'}, 500);
                
                showNotification('success', 'Event acknowledged!');
                updateEventCounts();
            } else {
                showNotification('error', 'Failed to acknowledge event');
            }
        },
        error: function() {
            showNotification('error', 'Network error occurred');
        }
    });
}

// Acknowledge all visible
function acknowledgeAll() {
    const unacknowledged = $('.event-alert.unacknowledged');
    if (unacknowledged.length === 0) {
        showNotification('info', 'No events need acknowledgment');
        return;
    }
    Swal.fire({
        title: 'Acknowledge All Events?',
        text: 'This will acknowledge ' + unacknowledged.length + ' visible events.',
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes, acknowledge all',
        cancelButtonText: 'Cancel'
    }).then((result) => {
        if (result.isConfirmed) {
            unacknowledged.each(function() {
                const eventId = $(this).attr('id').replace('event-', '');
                acknowledgeEvent(eventId);
            });
        }
    });
}

// Filters and export
function updateFilters() {
    const status = $('#statusFilter').val();
    const acknowledged = $('#ackFilter').val();
    let url = window.location.pathname + '?';
    const params = [];
    if (status !== 'all') params.push('status=' + encodeURIComponent(status));
    if (acknowledged !== 'all') params.push('acknowledged=' + encodeURIComponent(acknowledged));
    const pageSize = $('#pageSize').val();
    if (pageSize) params.push('pageSize=' + encodeURIComponent(pageSize));
    params.push('page=1');
    window.location.href = url + params.join('&');
}

function doExport(){
  const status = $('#statusFilter').val();
  const acknowledged = $('#ackFilter').val();
  const url = 'export_events.cfm?status=' + encodeURIComponent(status) + '&acknowledged=' + encodeURIComponent(acknowledged);
  window.location = url;
}

function changePageSize() {
    const status = $('#statusFilter').val();
    const acknowledged = $('#ackFilter').val();
    const pageSize = $('#pageSize').val();
    let url = window.location.pathname + '?';
    const params = [];
    if (status !== 'all') params.push('status=' + encodeURIComponent(status));
    if (acknowledged !== 'all') params.push('acknowledged=' + encodeURIComponent(acknowledged));
    if (pageSize) params.push('pageSize=' + encodeURIComponent(pageSize));
    params.push('page=1');
    window.location.href = url + params.join('&');
}

// Stats refresh
function updateEventCounts() {
    const status = $('#statusFilter').val();
    const acknowledged = $('#ackFilter').val();
    $.ajax({
        url: 'ajax_getEventCounts.cfm',
        method: 'GET',
        data: { status: status, acknowledged: acknowledged },
        dataType: 'json',
        success: function(data) {
            $('.stat-card:nth-child(1) .stat-number').text(data.total);
            $('.stat-card:nth-child(2) .stat-number').text(data.unacknowledged);
            $('.stat-card:nth-child(3) .stat-number').text(data.acknowledged);
            $('.stat-card:nth-child(4) .stat-number').text(data.withDocs);
            
            // Update floating acknowledge button
            updateFloatingAckButton(data.unacknowledged);
        }
    });
}

// Update floating acknowledge button visibility and count
function updateFloatingAckButton(unackCount) {
    const floatingBtn = $('#floatingAckBtn');
    const countBadge = $('#unackCount');
    
    if (unackCount > 0) {
        countBadge.text(unackCount);
        floatingBtn.fadeIn(300);
    } else {
        floatingBtn.fadeOut(300);
    }
}

// Notifications
function showNotification(type, message) {
    if (typeof Swal !== 'undefined') {
        const icons = { success: 'success', error: 'error', info: 'info', question: 'question' };
        Swal.fire({
            icon: icons[type] || 'info',
            title: message,
            timer: 3000,
            showConfirmButton: false,
            toast: true,
            position: 'top-end'
        });
    } else {
        alert(message);
    }
}
</script>

</body>
</html>
