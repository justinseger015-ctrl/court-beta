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
        
        /* Ensure white background for the entire page */
        body {
            background-color: #ffffff !important;
        }
        
        /* Main content area specific to case events - white background */
        .content-main {
            background-color: #ffffff !important;
        }
        
        /* Ensure navbar keeps its black background and proper styling */
        nav.navbar.navbar-dark.bg-dark {
            background-color: #000000 !important;
        }
        
        nav.navbar.navbar-dark .navbar-nav .nav-link {
            color: #ffffff !important;
        }
        
        nav.navbar.navbar-dark .navbar-brand {
            color: #9d3433 !important;
        }
        
        /* Alert Card Styling - White background for events */
        .event-alert {
            background: white;
            border: 1px solid #dee2e6;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
            border-radius: 8px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }
        .event-alert.unacknowledged {
            animation: pulse-glow 2s infinite;
        }
        .event-alert.acknowledged {
            opacity: 0.8;
        }
        @keyframes pulse-glow {
            0% { transform: scale(1); }
            50% { transform: scale(1.01); }
            100% { transform: scale(1); }
        }
        .event-alert:hover {
            transform: translateY(-2px);
        }
        
        .event-alert.unacknowledged:hover {
            transform: translateY(-3px);
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
            border: 2px solid #666666;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .case-avatar:hover {
            transform: scale(1.02);
            box-shadow: 0 12px 35px rgba(0, 0, 0, 0.3);
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
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
        }
        
        /* Inline Case Avatar Styles */
        .case-avatar-inline {
            height: 80px;
            width: 100px;
            border-radius: 8px;
            object-fit: cover;
            border: 2px solid #666666;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        .case-avatar-placeholder-inline {
            height: 80px;
            width: 100px;
            border-radius: 8px;
            background: linear-gradient(135deg, var(--tmz-red) 0%, #8b2635 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.5rem;
            font-weight: bold;
            border: 2px solid #666666;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
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
        }
        .status-acknowledged {
            background: linear-gradient(45deg, #00d2d3, #54a0ff);
            color: white;
        }
        /* Action Buttons CSS */
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
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
        }
        .event-meta {
            font-size: 0.875rem;
            color: #6c757d;
        }
        .case-info {
            background: linear-gradient(135deg, #f8f9fa 100%, #e9ecef 0%);
            border-radius: 10px;
            padding: 1rem;
            margin-bottom: 1rem;
        }
        
        /* Case Wrapper - Default (no priority or unknown) */
        .case-wrapper {
            background: #f8f9fa;
            border-radius: 12px;
            border: 1px solid #dee2e6;
            padding: 1.5rem;
            margin-bottom: 2rem;
        }
        
        /* Critical Priority - Red */
        .case-wrapper.priority-critical {
            background: #fee2e2;
            border: 1px solid #dc2626;
        }
        
        /* High Priority - Orange */
        .case-wrapper.priority-high {
            background: #ffedd5;
            border: 1px solid #ea580c;
        }
        
        /* Medium Priority - Yellow */
        .case-wrapper.priority-medium {
            background: #fef3c7;
            border: 1px solid #d97706;
        }
        
        /* Low Priority - Green */
        .case-wrapper.priority-low {
            background: #dcfce7;
            border: 1px solid #16a34a;
        }
        
        /* Unknown Priority - Gray */
        .case-wrapper.priority-unknown {
            background: #f3f4f6;
            border: 1px solid #6b7280;
        }
        
        /* Case Header Styles - White background */
        .case-header {
            margin-bottom: 1.5rem;
        }
        
        .case-header .card {
            background: white;
            border-radius: 8px;
            border: none;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        }
        
        .case-header .card-body {
            border: none;
        }
        
        .case-header .card-footer {
            border: none;
        }
        
        .case-header h4 {
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: #212529;
        }
        
        .case-header .case-meta {
            font-size: 0.9rem;
            color: #6c757d;
        }
        
        .case-header .case-avatar-header {
            width: 80px;
            height: 60px;
            object-fit: cover;
            border-radius: 8px;
            border: 2px solid #dee2e6;
        }
        
        .case-header .case-avatar-placeholder-header {
            width: 80px;
            height: 60px;
            background: linear-gradient(135deg, #6c757d, #495057);
            color: white;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 1.2rem;
            border: 2px solid #dee2e6;
        }
        
        /* Event Panel Indentation - Now inside case card */
        .event-panel-container {
            margin-left: 0;
            margin-bottom: 1rem;
            position: relative;
        }
        
        /* Last event panel has no bottom margin */
        .event-panel-container:last-child {
            margin-bottom: 0;
        }
        
        /* Discovery Time Display */
        .discovery-time {
            color: white;
            padding: 1rem;
            border-radius: 8px 0 0 0;
            text-align: center;
            display: flex;
            flex-direction: column;
            justify-content: center;
            min-height: 80px;
            transition: background 0.3s ease;
        }
        
        /* Unacknowledged - Red background */
        .event-alert.unacknowledged .discovery-time {
            background: linear-gradient(135deg, var(--tmz-red), #c41e3a);
        }
        
        /* Acknowledged - Light Grey background */
        .event-alert.acknowledged .discovery-time {
            background: linear-gradient(135deg, #e9ecef, #dee2e6);
            color: #495057;
        }
        
        .discovery-time .time {
            font-size: 1.5rem;
            font-weight: bold;
            line-height: 1;
            margin-bottom: 0.25rem;
        }
        
        .discovery-time .label {
            font-size: 0.75rem;
            opacity: 0.9;
            text-transform: uppercase;
            letter-spacing: 0.5px;
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
        
        /* Priority Badge Styles */
        .priority-badge {
            font-size: 0.75rem;
            padding: 0.25rem 0.5rem;
            border-radius: 0.375rem;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .priority-critical { 
            background-color: #dc2626; 
            color: white; 
            font-weight: 700; 
        }
        .priority-high { 
            background-color: #ea580c; 
            color: white; 
            font-weight: 600; 
        }
        .priority-medium { 
            background-color: #d97706; 
            color: white; 
            font-weight: 500; 
        }
        .priority-low { 
            background-color: #16a34a; 
            color: white; 
            font-weight: 400; 
        }
        .priority-unknown { 
            background-color: #6b7280; 
            color: white; 
            font-weight: 400; 
        }
        .filter-controls {
            background: white;
            border-radius: 10px;
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        /* Owner filter button group styling */
        #ownerFilterGroup {
            gap: 0.5rem;
        }
        
        #ownerFilterGroup .btn {
            border-radius: 0.375rem;
            transition: all 0.2s ease;
        }
        
        #ownerFilterGroup .btn-check:checked + .btn {
            background-color: #0ea5e9;
            border-color: #0ea5e9;
            color: white;
        }
        
        #ownerFilterGroup .btn:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
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
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
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
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
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
            /* .action-buttons { justify-content: center; } - COMMENTED OUT */
            .avatar-placeholder, .celebrity-avatar { width: 60px; height: 60px; }
            .case-avatar { width: 150px; height: 120px; }
            .case-avatar-placeholder { width: 150px; height: 120px; font-size: 2rem; }
            .case-avatar-inline { width: 80px; height: 60px; }
            .case-avatar-placeholder-inline { width: 80px; height: 60px; font-size: 1rem; }
            .case-info { flex-direction: column !important; align-items: flex-start !important; }
            .case-image-container { margin-bottom: 1rem !important; margin-right: 0 !important; }
            .event-status { position: static; margin-bottom: 0.5rem; }
            
            /* Case header mobile styles */
            .case-header {
                padding: 1rem;
                margin-bottom: 1rem;
            }
            .case-header .d-flex {
                flex-direction: column !important;
                align-items: flex-start !important;
            }
            .case-header .me-3 {
                margin-bottom: 1rem !important;
                margin-right: 0 !important;
            }
            .case-avatar-header,
            .case-avatar-placeholder-header {
                width: 60px;
                height: 45px;
                font-size: 1rem;
            }
            
            /* Event panel mobile indentation */
            .event-panel-container {
                margin-left: 2rem;
                padding-left: 0.75rem;
            }
            
            /* Discovery time mobile styles */
            .discovery-time {
                border-radius: 8px 8px 0 0;
                border-right: none;
                border-bottom: 3px solid rgba(255,255,255,0.3);
                min-height: 60px;
                padding: 0.75rem;
            }
            .discovery-time .time {
                font-size: 1.25rem;
            }
        }
        
        /* Override Bootstrap's cyan info colors with dark blue */
        .btn-info {
            --bs-btn-color: #fff;
            --bs-btn-bg: #1e3a8a;
            --bs-btn-border-color: #1e3a8a;
            --bs-btn-hover-color: #fff;
            --bs-btn-hover-bg: #1e40af;
            --bs-btn-hover-border-color: #1e40af;
            --bs-btn-focus-shadow-rgb: 30, 58, 138;
            --bs-btn-active-color: #fff;
            --bs-btn-active-bg: #1d4ed8;
            --bs-btn-active-border-color: #1d4ed8;
            --bs-btn-active-shadow: inset 0 3px 5px rgba(0, 0, 0, 0.125);
            --bs-btn-disabled-color: #fff;
            --bs-btn-disabled-bg: #1e3a8a;
            --bs-btn-disabled-border-color: #1e3a8a;
        }
        
        .btn-outline-info {
            --bs-btn-color: #1e3a8a;
            --bs-btn-border-color: #1e3a8a;
            --bs-btn-hover-color: #fff;
            --bs-btn-hover-bg: #1e3a8a;
            --bs-btn-hover-border-color: #1e3a8a;
            --bs-btn-focus-shadow-rgb: 30, 58, 138;
            --bs-btn-active-color: #fff;
            --bs-btn-active-bg: #1e3a8a;
            --bs-btn-active-border-color: #1e3a8a;
            --bs-btn-active-shadow: inset 0 3px 5px rgba(0, 0, 0, 0.125);
            --bs-btn-disabled-color: #1e3a8a;
            --bs-btn-disabled-bg: transparent;
            --bs-btn-disabled-border-color: #1e3a8a;
        }

        /* Square button styles */
        .btn-square {
            border-radius: 0.375rem !important;
            width: 45px;
            height: 45px;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .btn-square i {
            font-size: 1.1rem;
        }

        /* Action buttons container */
        .action-buttons {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
            align-items: center;
        }
    </style>

</head>
<body>

<cfinclude template="navbar.cfm">

<!--- Get current authenticated user --->
<cfset currentuser = getAuthUser()>

<!--- Query to get list of users for ownership filter --->
<cfquery name="owners" datasource="Reach">
    SELECT 
        username AS value,
        firstname + ' ' + lastname AS display
    FROM docketwatch.dbo.users
    WHERE userRole = 'User'
    ORDER BY 
        CASE WHEN username = <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar"> THEN 0 ELSE 1 END,
        firstname, lastname
</cfquery>

<!-- Params and sanitization -->
<cfparam name="url.case_id" default="all">
<cfparam name="url.acknowledged" default="all">
<cfparam name="url.days" default="1">
<cfparam name="url.owner" default="">
<!--- Pagination removed since we're only showing current day events --->
<!--- <cfparam name="url.page" default="1"> --->
<!--- <cfparam name="url.pageSize" default="20"> --->

<!--- Validate days parameter --->
<cfset url.days = val(url.days)>
<cfif url.days LT 1 OR url.days GT 30><cfset url.days = 1></cfif>

<!--- Calculate date range based on days parameter --->
<cfset startDate = dateAdd("d", -(url.days - 1), now())>
<cfset endDate = now()>
<!--- Get cases that have events in the selected date range for filter dropdown --->
<cfquery name="casesWithEvents" datasource="Reach">
    SELECT DISTINCT c.id, c.case_name, c.case_number, t.tool_name, COUNT(e.id) as event_count
    FROM docketwatch.dbo.cases c
    INNER JOIN docketwatch.dbo.case_events e ON c.id = e.fk_cases
    LEFT JOIN docketwatch.dbo.tools t ON t.id = c.fk_tool
    WHERE c.status = 'Tracked'
      AND c.case_number <> 'Unfiled'
      AND e.created_at >= <cfqueryparam value="#dateFormat(startDate, 'yyyy-mm-dd')# 00:00:00" cfsqltype="cf_sql_timestamp">
      AND e.created_at <= <cfqueryparam value="#dateFormat(endDate, 'yyyy-mm-dd')# 23:59:59" cfsqltype="cf_sql_timestamp">
      <cfif len(trim(url.owner))>
        <!--- Handle multiple owners (comma-separated) --->
        <cfset ownerList = listToArray(url.owner, ",")>
        <cfif arrayLen(ownerList) GT 0>
            AND (
                <cfloop array="#ownerList#" index="i" item="ownerValue">
                    t.owners LIKE <cfqueryparam value="%#trim(ownerValue)#%" cfsqltype="cf_sql_varchar">
                    <cfif i NEQ arrayLen(ownerList)>OR</cfif>
                </cfloop>
            )
        </cfif>
      </cfif>
    GROUP BY c.id, c.case_name, c.case_number, t.tool_name
    ORDER BY c.case_name
</cfquery>

<cfset allowedAck = "all,0,1">
<cfif listFindNoCase(allowedAck, url.acknowledged) EQ 0><cfset url.acknowledged = "all"></cfif>

<!--- Pagination variables removed --->
<!--- <cfset page = val(url.page)> --->
<!--- <cfif page LT 1><cfset page = 1></cfif> --->

<!--- <cfset pageSize = val(url.pageSize)> --->
<!--- <cfif pageSize LT 5 OR pageSize GT 100><cfset pageSize = 20></cfif> --->

<!--- <cfset offsetRows = (page - 1) * pageSize> --->

<!-- Events query (grouped by case, sorted by latest event) -->
<cfquery name="events" datasource="Reach">
    WITH celeb AS (
        SELECT 
            m.fk_case,
            c.name AS celebrity_name,
            c.image_url AS celebrity_image,
            m.probability_score AS match_probability,
            ROW_NUMBER() OVER (PARTITION BY m.fk_case ORDER BY m.ranking_score DESC) AS rn
        FROM docketwatch.dbo.case_celebrity_matches m
        INNER JOIN docketwatch.dbo.celebrities c ON c.id = m.fk_celebrity
        WHERE m.match_status <> 'Removed'
    ),
    LatestPerCase AS (
        SELECT
            e.fk_cases,
            MAX(e.created_at) AS latest_event_created_at
        FROM docketwatch.dbo.case_events e
        INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
        WHERE c.status = 'Tracked'
          AND c.case_number <> 'Unfiled'
          AND e.created_at >= <cfqueryparam value="#dateFormat(startDate, 'yyyy-mm-dd')# 00:00:00" cfsqltype="cf_sql_timestamp">
          AND e.created_at <= <cfqueryparam value="#dateFormat(endDate, 'yyyy-mm-dd')# 23:59:59" cfsqltype="cf_sql_timestamp">
        GROUP BY e.fk_cases
    ),
    DocumentCounts AS (
        SELECT 
            ce.id as event_id,
            COUNT(d.doc_uid) as doc_count
        FROM docketwatch.dbo.case_events ce
        LEFT JOIN docketwatch.dbo.documents d ON ce.id = d.fk_case_event
        WHERE ce.created_at >= <cfqueryparam value="#dateFormat(startDate, 'yyyy-mm-dd')# 00:00:00" cfsqltype="cf_sql_timestamp">
          AND ce.created_at <= <cfqueryparam value="#dateFormat(endDate, 'yyyy-mm-dd')# 23:59:59" cfsqltype="cf_sql_timestamp">
        GROUP BY ce.id
    ),
    DocOne AS (
        SELECT 
            d.fk_case_event,
            MAX(d.doc_uid) AS doc_uid
        FROM docketwatch.dbo.documents d
        WHERE (d.pdf_type IS NULL OR d.pdf_type <> 'Attachment')
        GROUP BY d.fk_case_event
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
        c.summarize_html,
        c.status AS case_status,

        d.pdf_title,
        d.summary_ai,
        d.summary_ai_html,
        d.event_summary,
        CASE 
            WHEN d.rel_path IS NOT NULL AND d.rel_path <> '' 
                THEN '/docs/' + REPLACE(d.rel_path,'\','/')
            WHEN d.doc_id IS NOT NULL 
                THEN REPLACE('/docs/cases/' + CAST(e.fk_cases AS varchar(20)) + '/E' + CAST(d.doc_id AS varchar(20)) + '.pdf', '\', '/')
            ELSE NULL
        END AS pdf_path,

        celeb.celebrity_name,
        celeb.celebrity_image,
        cp.name as priority,
        celeb.match_probability,
        lpc.latest_event_created_at,
        t.tool_name as source_tool,
        ISNULL(dc.doc_count, 0) as document_count
    FROM LatestPerCase lpc
    INNER JOIN docketwatch.dbo.cases c ON c.id = lpc.fk_cases
    INNER JOIN docketwatch.dbo.case_events e ON e.fk_cases = lpc.fk_cases
    LEFT JOIN DocOne do ON do.fk_case_event = e.id
    LEFT JOIN docketwatch.dbo.documents d ON d.doc_uid = do.doc_uid
    LEFT JOIN celeb ON celeb.fk_case = e.fk_cases AND celeb.rn = 1
    LEFT JOIN docketwatch.dbo.case_priority cp ON cp.id = c.fk_priority
    LEFT JOIN docketwatch.dbo.tools t ON t.id = c.fk_tool
    LEFT JOIN DocumentCounts dc ON dc.event_id = e.id
    WHERE 1=1
      AND e.created_at >= <cfqueryparam value="#dateFormat(startDate, 'yyyy-mm-dd')# 00:00:00" cfsqltype="cf_sql_timestamp">
      AND e.created_at <= <cfqueryparam value="#dateFormat(endDate, 'yyyy-mm-dd')# 23:59:59" cfsqltype="cf_sql_timestamp">
      AND e.event_date >= <cfqueryparam value="#dateFormat(dateAdd('d', -7, now()), 'yyyy-mm-dd')#" cfsqltype="cf_sql_date">
      <cfif len(trim(url.owner))>
        <!--- Handle multiple owners (comma-separated) --->
        <cfset ownerList = listToArray(url.owner, ",")>
        <cfif arrayLen(ownerList) GT 0>
            AND (
                <cfloop array="#ownerList#" index="i" item="ownerValue">
                    t.owners LIKE <cfqueryparam value="%#trim(ownerValue)#%" cfsqltype="cf_sql_varchar">
                    <cfif i NEQ arrayLen(ownerList)>OR</cfif>
                </cfloop>
            )
        </cfif>
      </cfif>
      <cfif url.case_id NEQ "all">
        AND e.fk_cases = <cfqueryparam value="#url.case_id#" cfsqltype="cf_sql_integer">
      </cfif>
      <cfif url.acknowledged NEQ "all">
        AND ISNULL(e.acknowledged, 0) = <cfqueryparam value="#url.acknowledged#" cfsqltype="cf_sql_bit">
      </cfif>
    ORDER BY lpc.latest_event_created_at DESC, e.created_at DESC
</cfquery>

<!-- Statistics (Tracked only) -->
<cfquery name="stats" datasource="Reach">
    SELECT 
        COUNT(DISTINCT e.fk_cases) as active_cases,
        COUNT(*) as total_events,
        SUM(CASE WHEN ISNULL(acknowledged, 0) = 0 THEN 1 ELSE 0 END) as unacknowledged,
        SUM(CASE WHEN ISNULL(acknowledged, 0) = 1 THEN 1 ELSE 0 END) as acknowledged
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    LEFT JOIN docketwatch.dbo.tools t ON t.id = c.fk_tool
    WHERE c.status = 'Tracked'
      AND c.case_number <> 'Unfiled'
      AND e.created_at >= <cfqueryparam value="#dateFormat(startDate, 'yyyy-mm-dd')# 00:00:00" cfsqltype="cf_sql_timestamp">
      AND e.created_at <= <cfqueryparam value="#dateFormat(endDate, 'yyyy-mm-dd')# 23:59:59" cfsqltype="cf_sql_timestamp">
      AND e.event_date >= <cfqueryparam value="#dateFormat(dateAdd('d', -7, now()), 'yyyy-mm-dd')#" cfsqltype="cf_sql_date">
      <cfif len(trim(url.owner))>
        <!--- Handle multiple owners (comma-separated) --->
        <cfset ownerList = listToArray(url.owner, ",")>
        <cfif arrayLen(ownerList) GT 0>
            AND (
                <cfloop array="#ownerList#" index="i" item="ownerValue">
                    t.owners LIKE <cfqueryparam value="%#trim(ownerValue)#%" cfsqltype="cf_sql_varchar">
                    <cfif i NEQ arrayLen(ownerList)>OR</cfif>
                </cfloop>
            )
        </cfif>
      </cfif>
      <cfif url.case_id NEQ "all">
        AND e.fk_cases = <cfqueryparam value="#url.case_id#" cfsqltype="cf_sql_integer">
      </cfif>
      <cfif url.acknowledged NEQ "all">
        AND ISNULL(e.acknowledged, 0) = <cfqueryparam value="#url.acknowledged#" cfsqltype="cf_sql_bit">
      </cfif>
</cfquery>

<div class="container-fluid content-main mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="mb-0">
                <i class="fas fa-bell me-2 text-primary"></i>
                Case Events Alert Dashboard
            </h2>
            <cfoutput>
            <p class="text-muted mb-0">
                <cfif url.days EQ 1>
                    Monitor and manage case events from today
                <cfelse>
                    Monitor and manage case events from the last #url.days# days
                </cfif>
                <span class="small">
                    (#dateFormat(startDate, "mmm d")# 
                    <cfif url.days GT 1>- #dateFormat(endDate, "mmm d")#</cfif>)
                </span>
            </p>
            </cfoutput>
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
            <div class="stat-number">#stats.active_cases#</div>
            <div class="stat-label">Total Active Cases</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">#stats.total_events#</div>
            <div class="stat-label">Total Case Events Today</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">#stats.unacknowledged#</div>
            <div class="stat-label">Needs Attention</div>
        </div>
        <div class="stat-card">
            <div class="stat-number">#stats.acknowledged#</div>
            <div class="stat-label">Acknowledged</div>
        </div>
        </cfoutput>
    </div>

    <div class="filter-controls">
        <div class="row align-items-center">
            <div class="col-md-12 mb-3">
                <label class="form-label small text-muted mb-2">Case Owners (select one or more)</label>
                <div id="ownerFilterGroup" class="btn-group btn-group-sm flex-wrap" role="group" aria-label="Filter by case owners">
                    <cfoutput query="owners">
                        <input type="checkbox" class="btn-check owner-filter-btn" id="owner_#value#" value="#value#" autocomplete="off">
                        <label class="btn btn-outline-primary" for="owner_#value#">
                            <i class="fas fa-user me-1"></i>#display#
                        </label>
                    </cfoutput>
                </div>
            </div>
            <div class="col-md-3">
                <label for="caseFilter" class="form-label">
                    <i class="fas fa-filter me-1"></i>
                    Filter by Case
                </label>
                <select id="caseFilter" class="form-select" onchange="updateFilters()">
                    <option value="all" <cfif url.case_id eq "all">selected</cfif>>All Cases</option>
                    <cfoutput query="casesWithEvents">
                        <option value="#id#" <cfif url.case_id eq id>selected</cfif>>#htmlEditFormat(case_name)# (#event_count# events)</option>
                    </cfoutput>
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
            <div class="col-md-2">
                <label for="daysFilter" class="form-label">
                    <i class="fas fa-calendar me-1"></i>
                    Date Range
                </label>
                <select id="daysFilter" class="form-select" onchange="updateFilters()">
                    <option value="1" <cfif url.days eq 1>selected</cfif>>Today Only</option>
                    <option value="2" <cfif url.days eq 2>selected</cfif>>Last 2 Days</option>
                    <option value="3" <cfif url.days eq 3>selected</cfif>>Last 3 Days</option>
                    <option value="7" <cfif url.days eq 7>selected</cfif>>Last 7 Days</option>
                    <option value="14" <cfif url.days eq 14>selected</cfif>>Last 14 Days</option>
                    <option value="30" <cfif url.days eq 30>selected</cfif>>Last 30 Days</option>
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
            <!--- Page Size selector removed since we're showing all current day events --->
            <!--- <div class="col-md-2">
                <label class="form-label">Page Size</label>
                <select id="pageSize" class="form-select form-select-sm" onchange="changePageSize()">
                    <option value="20"  <cfif pageSize EQ 20>selected</cfif>>20</option>
                    <option value="50"  <cfif pageSize EQ 50>selected</cfif>>50</option>
                    <option value="100" <cfif pageSize EQ 100>selected</cfif>>100</option>
                </select>
            </div> --->
        </div>
    </div>
<CFoutput>
    <!--- Pagination navigation removed since we're showing all current day events --->
    <!--- <div class="d-flex align-items-center justify-content-end mb-3 gap-2">
        <div class="btn-group">
            <a class="btn btn-outline-secondary btn-sm" href="#buildPageUrl(page-1)#" <cfif page EQ 1>style="pointer-events:none;opacity:.5"</cfif>>&laquo; Prev</a>
            <span class="btn btn-outline-secondary btn-sm disabled">Page #page#</span>
            <a class="btn btn-outline-secondary btn-sm" href="#buildPageUrl(page+1)#">Next &raquo;</a>
        </div>
    </div> --->
</CFoutput>
    <!-- Events List Grouped by Case -->
    <div class="row">
        <cfif events.recordcount EQ 0>
            <div class="col-12">
                <div class="text-center py-5">
                    <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                    <h4 class="text-muted">No Events Found</h4>
                    <p class="text-muted">No case events match your current filters.</p>
                </div>
            </div>
        <cfelse>
            <div class="col-12">
                <!-- Group events by case -->
                <cfoutput query="events" group="fk_cases">
                    <!--- Determine priority class for case wrapper --->
                    <cfset priorityClass = "">
                    <cfswitch expression="#lcase(trim(priority))#">
                        <cfcase value="critical"><cfset priorityClass = "priority-critical"></cfcase>
                        <cfcase value="high"><cfset priorityClass = "priority-high"></cfcase>
                        <cfcase value="medium"><cfset priorityClass = "priority-medium"></cfcase>
                        <cfcase value="low"><cfset priorityClass = "priority-low"></cfcase>
                        <cfdefaultcase><cfset priorityClass = "priority-unknown"></cfdefaultcase>
                    </cfswitch>
                    
                    <!-- COLOR-CODED WRAPPER CONTAINER -->
                    <div class="case-wrapper #priorityClass#">
                        <!-- CASE HEADER -->
                        <div class="case-header" role="heading" aria-level="3">
                            <div class="card">
                                <!-- Case Header Section -->
                                <div class="card-body">
                                <div class="d-flex align-items-center">
                                    <!-- Case Image/Avatar -->
                                    <div class="me-3">
                                        <cfif len(case_image_url)>
                                            <img src="#case_image_url#" loading="lazy" decoding="async" alt="#htmlEditFormat(case_name)#" class="case-avatar-header" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                            <div class="case-avatar-placeholder-header" style="display:none;">
                                                <i class="fas fa-balance-scale"></i>
                                            </div>
                                        <cfelseif len(celebrity_name) AND len(celebrity_image)>
                                            <img src="#celebrity_image#" loading="lazy" decoding="async" alt="#htmlEditFormat(celebrity_name)#" class="case-avatar-header" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                            <div class="case-avatar-placeholder-header" style="display:none;">#left(celebrity_name, 2)#</div>
                                        <cfelseif len(celebrity_name)>
                                            <div class="case-avatar-placeholder-header">#left(celebrity_name, 2)#</div>
                                        <cfelse>
                                            <div class="case-avatar-placeholder-header"><i class="fas fa-gavel"></i></div>
                                        </cfif>
                                    </div>
                                    
                                    <!-- Case Content -->
                                    <div class="flex-grow-1">
                                        <h4 class="mb-2">#htmlEditFormat(case_name)#</h4>
                                        <div class="row case-meta">
                                            <div class="col-md-6">
                                                <div class="d-flex align-items-center gap-2">
                                                    <span><strong>Case No.:</strong> #htmlEditFormat(case_number)#</span>
                                                    <cfif len(source_tool)>
                                                        <span class="badge bg-secondary">
                                                            <i class="fas fa-cog me-1"></i>#htmlEditFormat(source_tool)#
                                                        </span>
                                                    </cfif>
                                                    <cfif len(celebrity_name)>
                                                        <span class="badge bg-info">
                                                            <i class="fas fa-star me-1"></i>#htmlEditFormat(celebrity_name)#
                                                        </span>
                                                    </cfif>
                                                </div>
                                            </div>
                                            <div class="col-md-6 d-flex align-items-center justify-content-end">
                                                <span class="priority-badge #priorityClass#">#htmlEditFormat(priority)#</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Case Action Buttons -->
                            <div class="card-footer bg-light">
                                <div class="btn-group" role="group">
                                    <a href="case_details.cfm?id=#fk_cases#" class="btn btn-outline-primary btn-sm">
                                        <i class="fa-solid fa-file-lines me-1"></i>View Case Details
                                    </a>
                                    <cfif len(case_url)>
                                        <a href="#case_url#" target="_blank" class="btn btn-outline-secondary btn-sm">
                                            <i class="fa-solid fa-up-right-from-square me-1"></i>Open Court Page
                                        </a>
                                    </cfif>
                                    <button type="button" class="btn btn-outline-info btn-sm" data-bs-toggle="modal" data-bs-target="##caseSummaryModal#fk_cases#">
                                        <i class="fas fa-file-text me-1"></i>Case Summary
                                    </button>
                                </div>
                            </div>
                        </div>
                        </div>
                        
                        <!-- EVENTS FOR THIS CASE - OUTSIDE CASE CARD BUT INSIDE WRAPPER -->
                        <cfoutput>
                                    <div class="event-panel-container mb-3">
                                        <div class="card event-alert #iif(acknowledged, de('acknowledged'), de('unacknowledged'))#" 
                                             id="event-#id#" 
                                             <cfif NOT acknowledged>
                                             data-event-id="#id#" 
                                             style="cursor: pointer;" 
                                             title="Click to acknowledge this event"
                                             </cfif>>

                                <!--- Event Status Badge 
                                <div class="event-status">
                                    <span class="badge #iif(acknowledged, de('status-acknowledged'), de('status-new'))#">
                                        #iif(acknowledged, de('ACKNOWLEDGED'), de('NEW'))#
                                    </span>
                                </div> --->

                                <!-- Acknowledge Button Removed - Using color coding and acknowledge date instead -->

                                <div class="card-body p-0">
                                    <div class="row g-0">
                                        <!-- Event Date Column -->
                                        <div class="col-md-2">
                                            <div class="discovery-time">
                                                <div class="time">#dateFormat(event_date, "mm/dd")#</div>
                                                <div class="label">Event Date</div>
                                                <div class="discovered-time" style="font-size: 0.7rem; margin-top: 0.5rem; opacity: 0.8;">
                                                    Discovered: #timeFormat(created_at, "h:mm tt")#
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <!-- Main Content Column -->
                                        <div class="col-md-8">
                                            <div class="p-3">
                                                <div class="event-description">
                                                    <strong><cfif len(event_no) AND event_no NEQ 0>No. #event_no# - </cfif>#htmlEditFormat(event_description)#</strong>
                                                </div>
                                                
                                                <cfif len(trim(event_summary))>
                                                    <div class="event-summary mt-2" style="font-size: 1.1rem; color: ##2d3748; line-height: 1.4;">
                                                        #htmlEditFormat(event_summary)#
                                                    </div>
                                                </cfif>

                                                <div class="event-meta mt-3">
                                                    <div class="d-flex flex-wrap gap-3 align-items-center">
                                                        <span style="color: white;">#id#</span>
                                                        <small style="color: white;">
                                                            Event #event_no# - isDoc:#isDoc# url:#len(event_url)# summary:#len(summary_ai_html)# docs:#document_count# source:#source_tool#
                                                        </small>
                                                        
                                                        <!--- Status Badge - Commented Out
                                                        <cfset statusClass = "">
                                                        <cfset statusText = "">
                                                        <cfswitch expression="#lcase(trim(status))#">
                                                            <cfcase value="new"><cfset statusClass = "status-new"><cfset statusText = "New"></cfcase>
                                                            <cfcase value="rss"><cfset statusClass = "status-rss"><cfset statusText = "RSS"></cfcase>
                                                            <cfcase value="rss pending"><cfset statusClass = "status-rss-pending"><cfset statusText = "RSS Pending"></cfcase>
                                                            <cfdefaultcase><cfset statusClass = "status-null"><cfset statusText = "Unknown"></cfdefaultcase>
                                                        </cfswitch>
                                                        <span class="status-badge #statusClass#"><i class="fas fa-info-circle me-1"></i>#statusText#</span>
                                                        --->
                                                        <!--- Acknowledged Date - Commented Out
                                                        <cfif acknowledged>
                                                            <div class="text-success"><i class="fas fa-check-circle me-1"></i>Acknowledged #dateFormat(acknowledged_at, "mm/dd/yyyy")#</div>
                                                        </cfif>
                                                        --->
                                                    </div>
                                                </div>

                                            </div>
                                        </div>
                                        
                                        <!-- Action Buttons Column -->
                                        <div class="col-md-2 d-flex align-items-center justify-content-center">
                                            <div class="action-buttons d-flex flex-column gap-2 align-items-center">
                                                <cfif document_count GT 0>
                                                    <button class="btn btn-success btn-sm btn-square" 
                                                            data-bs-toggle="modal" 
                                                            data-bs-target="##documentModal#id#"
                                                            title="View #document_count# document<cfif document_count GT 1>s</cfif>">
                                                        <i class="fas fa-file-pdf"></i>
                                                    </button>
                                                <!--- PDF Download button commented out - auto-downloading now
                                                <cfelseif source_tool EQ "Pacer" AND document_count EQ 0>
                                                    <button class="btn btn-danger btn-sm btn-square get-pdf-btn" data-event-id="#id#" data-event-url="#event_url#" data-case-id="#fk_cases#">
                                                        <i class="fas fa-download"></i>
                                                    </button>
                                                --->
                                                </cfif>
                                                <cfif len(summary_ai_html)>
                                                    <button class="btn btn-info btn-sm btn-square" data-bs-toggle="modal" data-bs-target="##summaryModal#id#">
                                                        <i class="fas fa-brain"></i>
                                                    </button>
                                                <!--- Generate Summary button commented out - auto-summarizing now
                                                <cfelse>
                                                    <button class="btn btn-outline-info btn-sm btn-square generate-summary-btn" data-event-id="#id#">
                                                        <i class="fas fa-robot"></i>
                                                    </button>
                                                --->
                                                </cfif>
                                                <!--- Generate Article button commented out for now
                                                <cfif isDoc>
                                                    <button class="btn btn-outline-danger btn-sm btn-square generate-article-btn" data-event-id="#id#">
                                                        <i class="fas fa-newspaper"></i>
                                                    </button>
                                                </cfif>
                                                --->
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                        </div>
                                    </div>
                                </cfoutput>
                    </div>
                    <!-- Close case-wrapper -->

                    <!-- Generate Case Summary Modal for this case -->
                    <div class="modal fade" id="caseSummaryModal#fk_cases#" tabindex="-1" aria-hidden="true">
                        <div class="modal-dialog modal-lg modal-dialog-scrollable">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title"><i class="fas fa-file-text me-2"></i>Case Summary</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <div class="mb-3">
                                        <strong>Case:</strong> #htmlEditFormat(case_name)# (#htmlEditFormat(case_number)#)
                                    </div>
                                    <hr>
                                    <cfif len(trim(summarize_html))>
                                        <div class="summary-content">#REReplace(summarize_html, "(\r\n|\n|\r)", "<br>", "all")#</div>
                                    <cfelse>
                                        <div class="text-center text-muted py-4">
                                            <i class="fas fa-file-text fa-3x mb-3" style="opacity: 0.3;"></i>
                                            <p class="mb-0">No case summary available.</p>
                                            <small class="text-muted">Summary can be generated from the case details page.</small>
                                        </div>
                                    </cfif>
                                </div>
                                <div class="modal-footer">
                                    <a href="case_details.cfm?id=#fk_cases#" class="btn btn-primary">
                                        <i class="fas fa-external-link-alt me-1"></i>View Full Case Details
                                    </a>
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </cfoutput>

            </div>
        </cfif>
    </div>
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

<!-- Document Modals -->
<cfoutput query="events">
    <cfif document_count GT 0>
        <!--- Query for documents related to this event --->
        <cfquery name="eventDocuments" datasource="Reach">
            SELECT 
                d.doc_uid,
                d.pdf_title,
                d.summary_ai,
                d.summary_ai_html,
                d.event_summary,
                d.pdf_type,
                d.rel_path,
                d.doc_id,
                CASE 
                    WHEN d.rel_path IS NOT NULL AND d.rel_path <> '' 
                        THEN '/docs/' + REPLACE(d.rel_path,'\','/')
                    WHEN d.doc_id IS NOT NULL 
                        THEN REPLACE('/docs/cases/' + CAST(#fk_cases# AS varchar(20)) + '/E' + CAST(d.doc_id AS varchar(20)) + '.pdf', '\', '/')
                    ELSE NULL
                END AS pdf_path,
                CASE 
                    WHEN d.rel_path IS NOT NULL AND d.rel_path <> '' 
                        THEN 1
                    ELSE 0
                END AS has_pdf
            FROM docketwatch.dbo.documents d
            WHERE d.fk_case_event = <cfqueryparam value="#id#" cfsqltype="cf_sql_varchar">
            ORDER BY 
                CASE WHEN d.pdf_type IS NULL OR d.pdf_type <> 'Attachment' THEN 0 ELSE 1 END,
                d.pdf_title
        </cfquery>
        
        <div class="modal fade" id="documentModal#id#" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-xl modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-file-pdf me-2"></i>
                            Documents for Event <cfif len(event_no) AND event_no NEQ 0>#event_no#</cfif>
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <strong>Case:</strong> #htmlEditFormat(case_name)# (#htmlEditFormat(case_number)#)<br>
                            <strong>Event:</strong> <cfif len(event_no) AND event_no NEQ 0>No. #event_no# - </cfif>#htmlEditFormat(event_description)#
                        </div>
                        <hr>
                        
                        <cfif eventDocuments.recordCount GT 0>
                            <div class="row">
                                <cfloop query="eventDocuments">
                                    <div class="col-md-6 mb-3">
                                        <div class="card h-100">
                                            <div class="card-header d-flex justify-content-between align-items-center">
                                                <h6 class="mb-0">
                                                    <i class="fas fa-file-pdf me-1 text-danger"></i>
                                                    #htmlEditFormat(pdf_title)#
                                                </h6>
                                                <cfif len(pdf_type)>
                                                    <span class="badge bg-secondary">#htmlEditFormat(pdf_type)#</span>
                                                </cfif>
                                            </div>
                                            <div class="card-body">
                                                <cfif len(event_summary)>
                                                    <div class="event-summary-content mb-3">
                                                        <strong>Event Summary:</strong><br>
                                                        #htmlEditFormat(event_summary)#
                                                    </div>
                                                    <cfif len(summary_ai_html) OR len(summary_ai)>
                                                        <button type="button" class="btn btn-outline-info btn-sm" 
                                                                data-bs-toggle="modal" 
                                                                data-bs-target="##summaryModal#doc_uid#">
                                                            <i class="fas fa-eye me-1"></i>View Full Summary
                                                        </button>
                                                    </cfif>
                                                <cfelseif len(summary_ai_html)>
                                                    <div class="summary-content mb-3">
                                                        #summary_ai_html#
                                                    </div>
                                                <cfelseif len(summary_ai)>
                                                    <div class="summary-content mb-3">
                                                        #htmlEditFormat(summary_ai)#
                                                    </div>
                                                <cfelse>
                                                    <p class="text-muted">No summary available</p>
                                                </cfif>
                                            </div>
                                            <div class="card-footer">
                                                <cfif has_pdf AND len(pdf_path)>
                                                    <!--- Check if file exists before showing download button --->
                                                    <cfset pdfNetworkPath = application.fileSharePath & replace(pdf_path, "/", "\", "all")>
                                                    <cfif fileExists(pdfNetworkPath)>
                                                        <a href="#pdf_path#" target="_blank" class="btn btn-primary btn-sm">
                                                            <i class="fas fa-external-link-alt me-1"></i>Open PDF
                                                        </a>
                                                    <cfelse>
                                                        <button class="btn btn-outline-danger btn-sm" disabled>
                                                            <i class="fas fa-exclamation-triangle me-1"></i>PDF Missing
                                                        </button>
                                                    </cfif>
                                                <cfelse>
                                                    <button class="btn btn-outline-secondary btn-sm" disabled>
                                                        <i class="fas fa-file me-1"></i>No PDF Available
                                                    </button>
                                                </cfif>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <!--- Full Summary Modal for this document --->
                                    <div class="modal fade" id="summaryModal#doc_uid#" tabindex="-1" aria-hidden="true">
                                        <div class="modal-dialog modal-lg modal-dialog-scrollable">
                                            <div class="modal-content">
                                                <div class="modal-header">
                                                    <h5 class="modal-title">
                                                        <i class="fas fa-file-text me-2"></i>
                                                        Full Summary - #htmlEditFormat(pdf_title)#
                                                    </h5>
                                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                                </div>
                                                <div class="modal-body">
                                                    <cfif len(summary_ai_html)>
                                                        <div class="summary-content">
                                                            #summary_ai_html#
                                                        </div>
                                                    <cfelseif len(summary_ai)>
                                                        <div class="summary-content">
                                                            #htmlEditFormat(summary_ai)#
                                                        </div>
                                                    <cfelse>
                                                        <p class="text-muted">No full summary available</p>
                                                    </cfif>
                                                </div>
                                                <div class="modal-footer">
                                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </cfloop>
                            </div>
                        <cfelse>
                            <div class="text-center text-muted py-4">
                                <i class="fas fa-file-alt fa-3x mb-3"></i>
                                <h5>No Documents Found</h5>
                                <p>This event has no associated documents.</p>
                            </div>
                        </cfif>
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
// Helper function to get selected owners as comma-separated string
function getSelectedOwners() {
    const selected = [];
    $('.owner-filter-btn:checked').each(function() {
        selected.push($(this).val());
    });
    return selected.join(',');
}

// Centralized localStorage management for filter persistence
const LocalStorageManager = {
    keys: {
        owner: 'case_events_owner'
    },
    
    set(key, value) {
        if (this.keys[key]) {
            localStorage.setItem(this.keys[key], value);
        }
    },
    
    get(key) {
        return this.keys[key] ? localStorage.getItem(this.keys[key]) : null;
    },
    
    clearAll() {
        Object.values(this.keys).forEach(key => localStorage.removeItem(key));
    }
};

$(document).ready(function() {
    // Restore owner selections from localStorage on page load
    const savedOwners = LocalStorageManager.get('owner');
    if (savedOwners) {
        const ownerArray = savedOwners.split(',');
        ownerArray.forEach(function(owner) {
            $('#owner_' + owner).prop('checked', true);
        });
    }
    
    // Setup owner filter button change handler
    $('.owner-filter-btn').on('change', function() {
        const selectedOwners = getSelectedOwners();
        LocalStorageManager.set('owner', selectedOwners);
        updateFilters();
    });
    
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
            url: 'ajax_getPacerDoc.cfm?bypass=1',
            method: 'POST',
            data: { docID: eventId, eventURL: eventUrl, caseID: caseId },
            dataType: 'json',
            timeout: 60000, // 60 second timeout for PDF downloads
            success: function(response) {
                if (response.STATUS === 'SUCCESS') {
                    button.replaceWith('<a href="' + response.FILEPATH + '" target="_blank" class="btn btn-success btn-action"><i class="fas fa-file-pdf me-1"></i>View PDF</a>');
                    showNotification('success', 'PDF downloaded successfully!');
                    
                    // Update the document count badge if visible
                    var eventCard = $('#event-' + eventId);
                    var pdfButton = eventCard.find('.btn[data-bs-target*="documentModal"]');
                    if (pdfButton.length > 0) {
                        // Refresh the page to show updated document count
                        setTimeout(function() {
                            showNotification('info', 'Refreshing page to show updated document...');
                            window.location.reload();
                        }, 2000);
                    }
                } else {
                    showNotification('error', 'Failed to download PDF: ' + (response.MESSAGE || 'Unknown error'));
                    button.prop('disabled', false).html('<i class="fas fa-download me-1"></i>Get PDF');
                }
            },
            error: function(xhr, status, error) {
                console.error('PDF Download Error:', {xhr: xhr, status: status, error: error});
                var errorMessage = 'Network error occurred';
                if (xhr.responseText) {
                    try {
                        var errorResponse = JSON.parse(xhr.responseText);
                        errorMessage = errorResponse.MESSAGE || errorMessage;
                    } catch (e) {
                        errorMessage = xhr.responseText.substring(0, 100);
                    }
                }
                showNotification('error', errorMessage);
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
            url: 'ajax_generateSummary.cfm?bypass=1',
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
    console.log('Acknowledging event:', eventId);
    
    // Show loading state
    const eventCard = $('#event-' + eventId);
    if (eventCard.length === 0) {
        console.error('Event card not found for ID:', eventId);
        showNotification('error', 'Event card not found');
        return;
    }
    
    eventCard.css('opacity', '0.7');
    
    $.ajax({
        url: 'ajax_acknowledgeEvent.cfm?bypass=1',
        method: 'POST',
        data: { eventId: eventId },
        dataType: 'json',
        timeout: 10000,
        success: function(response) {
            console.log('AJAX Response:', response);
            
            try {
                if (response && response.success) {
                    // Update visual state
                    eventCard.removeClass('unacknowledged').addClass('acknowledged');
                    
                    // Remove clickable behavior
                    eventCard.removeAttr('data-event-id style title').css('cursor', 'default');
                    
                    <!--- Update status badge --->
                    <!--- const statusBadge = eventCard.find('.event-status .badge');
                    if (statusBadge.length > 0) {
                        statusBadge.removeClass('status-new').addClass('status-acknowledged').text('ACKNOWLEDGED');
                    } --->
                    
                    // Update discovery time background (red to grey)
                    const discoveryTime = eventCard.find('.discovery-time');
                    if (discoveryTime.length > 0) {
                        discoveryTime.css('background', 'linear-gradient(135deg, #e9ecef, #dee2e6)');
                    }
                    
                    <!--- Update right-side acknowledge area --->
                    <!--- const acknowledgeArea = eventCard.find('.col-md-2').last();
                    if (acknowledgeArea.length > 0) {
                        acknowledgeArea.html('<div class="text-success text-center"><i class="fas fa-check-circle fa-2x mb-1"></i><br><small>Acknowledged</small></div>');
                    } --->
                    
                    // Add acknowledged timestamp to meta section
                    const now = new Date();
                    const timeString = now.toLocaleDateString();
                    const existingMeta = eventCard.find('.event-meta .d-flex');
                    if (existingMeta.length > 0 && existingMeta.find('.text-success').length === 0) {
                        existingMeta.append(
                            '<div class="text-success"><i class="fas fa-check-circle me-1"></i>Acknowledged ' + timeString + '</div>'
                        );
                    }
                    
                    // Restore opacity with animation
                    eventCard.animate({'opacity': '0.8'}, 500);
                    
                    showNotification('success', 'Event acknowledged!');
                    updateEventCounts();
                } else {
                    eventCard.css('opacity', '1');
                    const errorMsg = response && response.message ? response.message : 'Unknown error occurred';
                    showNotification('error', 'Failed to acknowledge event: ' + errorMsg);
                }
            } catch (e) {
                console.error('Error updating UI:', e);
                eventCard.css('opacity', '1');
                showNotification('error', 'Error updating interface: ' + e.message);
            }
        },
        error: function(xhr, status, error) {
            console.error('AJAX Error:', {xhr: xhr, status: status, error: error});
            eventCard.css('opacity', '1');
            
            let errorMessage = 'Network error occurred';
            if (xhr.responseText) {
                try {
                    const errorResponse = JSON.parse(xhr.responseText);
                    errorMessage = errorResponse.message || errorMessage;
                } catch (e) {
                    errorMessage = xhr.responseText.substring(0, 100);
                }
            }
            
            showNotification('error', errorMessage);
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
    const case_id = $('#caseFilter').val();
    const acknowledged = $('#ackFilter').val();
    const days = $('#daysFilter').val();
    const owner = getSelectedOwners();
    let url = window.location.pathname + '?';
    const params = [];
    if (case_id !== 'all') params.push('case_id=' + encodeURIComponent(case_id));
    if (acknowledged !== 'all') params.push('acknowledged=' + encodeURIComponent(acknowledged));
    if (days !== '1') params.push('days=' + encodeURIComponent(days));
    if (owner !== '') params.push('owner=' + encodeURIComponent(owner));
    window.location.href = url + params.join('&');
}

function doExport(){
  const case_id = $('#caseFilter').val();
  const acknowledged = $('#ackFilter').val();
  const days = $('#daysFilter').val();
  const owner = getSelectedOwners();
  let url = 'export_events.cfm?case_id=' + encodeURIComponent(case_id) + '&acknowledged=' + encodeURIComponent(acknowledged);
  if (days !== '1') url += '&days=' + encodeURIComponent(days);
  if (owner !== '') url += '&owner=' + encodeURIComponent(owner);
  window.location = url;
}

// Change page size function - COMMENTED OUT since pagination removed
/*
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
*/

// Stats refresh
function updateEventCounts() {
    const case_id = $('#caseFilter').val();
    const acknowledged = $('#ackFilter').val();
    const days = $('#daysFilter').val();
    const owner = getSelectedOwners();
    $.ajax({
        url: 'ajax_getEventCounts.cfm?bypass=1',
        method: 'GET',
        data: { case_id: case_id, acknowledged: acknowledged, days: days, owner: owner },
        dataType: 'json',
        success: function(data) {
            $('.stat-card:nth-child(1) .stat-number').text(data.activeCases);
            $('.stat-card:nth-child(2) .stat-number').text(data.total);
            $('.stat-card:nth-child(3) .stat-number').text(data.unacknowledged);
            $('.stat-card:nth-child(4) .stat-number').text(data.acknowledged);
            
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


<!-- Bootstrap 5 JS (with Popper included) -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" 
        integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" 
        crossorigin="anonymous"></script>


</body>
</html>
