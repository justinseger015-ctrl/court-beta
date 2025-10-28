<!---
================================================================================
DocketWatch - Main Cases Dashboard (index.cfm)
================================================================================

PURPOSE:
--------
Main interface for managing and monitoring court cases. Provides comprehensive
filtering, bulk operations, and real-time data updates for case tracking.

KEY FEATURES:
-------------
1. CASE VIEWING & FILTERING
   - View cases by status: Review (new), Tracked (monitored), Removed (archived)
   - Filter by: Tool/Source, Owner, State, County, Courthouse, Celebrity
   - Full-text search across document OCR content
   - User-specific filter persistence via localStorage

2. BULK OPERATIONS
   - Track Cases: Move cases from Review to Tracked status
   - Remove Cases: Archive unwanted cases
   - Set to Review: Return tracked cases to review queue

3. COLUMN CUSTOMIZATION
   - User-specific column visibility preferences
   - Saved per status (Review/Tracked/Removed)
   - Persisted in database: docketwatch.dbo.column_visibility_defaults

4. CASE MANAGEMENT
   - Add new cases manually via modal form
   - Quick access to case details, external court pages, PDFs
   - Celebrity matching indicators
   - Case priority visualization
   - "Case not found" warnings for stale cases

ARCHITECTURE:
-------------
┌─────────────────────────────────────────────────────────────────────┐
│                         index.cfm (THIS FILE)                        │
├─────────────────────────────────────────────────────────────────────┤
│  1. Server-Side (ColdFusion)                                        │
│     - User authentication (getAuthUser)                             │
│     - Load column visibility preferences from DB                    │
│     - Query filter options (owners, celebrities, tools, etc.)      │
│                                                                     │
│  2. Client-Side (JavaScript/jQuery)                                │
│     - DataTables grid with AJAX loading                            │
│     - Filter state management (localStorage)                       │
│     - Bulk action handlers                                         │
│     - Column visibility modal                                      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ AJAX Calls
                                    ▼
         ┌──────────────────────────────────────────────┐
         │          AJAX Endpoints Used                 │
         ├──────────────────────────────────────────────┤
         │ cases_ajax.cfm          - Load case data    │
         │ get_tools.cfm           - Filter options    │
         │ get_states.cfm          - Filter options    │
         │ get_counties.cfm        - Filter options    │
         │ get_courthouses.cfm     - Filter options    │
         │ get_celebrities.cfm     - Filter options    │
         │ update_case_status_list.cfm - Bulk updates  │
         │ insert_new_case.cfm     - Add new case      │
         │ save_column_visibility.cfm - Save prefs     │
         └──────────────────────────────────────────────┘

DATABASE TABLES:
----------------
PRIMARY TABLES:
  - docketwatch.dbo.cases                    Case records
  - docketwatch.dbo.case_events              Docket entries/events
  - docketwatch.dbo.documents                PDF documents with OCR
  - docketwatch.dbo.case_celebrity_matches   Celebrity linkages

REFERENCE TABLES:
  - docketwatch.dbo.celebrities              Celebrity database
  - docketwatch.dbo.tools                    Data source tools (PACER, UniCourt, etc.)
  - docketwatch.dbo.courts                   Courthouses
  - docketwatch.dbo.counties                 Counties
  - docketwatch.dbo.states                   States

USER TABLES:
  - docketwatch.dbo.users                    User accounts
  - docketwatch.dbo.column_visibility_defaults - Column prefs
  - docketwatch.dbo.UserActivity             Activity logging

JAVASCRIPT MODULES:
-------------------
1. LocalStorageManager (lines 520-543)
   - Manages filter persistence across sessions
   - Keys: tool, owner, courthouse, county, state, celebrity

2. ColumnRenderers (lines 590-659)
   - Custom rendering functions for DataTables columns
   - Handles: dates, priorities, statuses, links, celebrity lists

3. DataTable Configuration (lines 661-779)
   - Server-side data loading from cases_ajax.cfm
   - Column definitions with visibility defaults
   - Sorting, paging, searching configuration

4. Filter Management (lines 786-930)
   - Cascading filter dropdowns (state → county → courthouse)
   - Owner toggle buttons with multi-select
   - Document OCR full-text search with debouncing

5. Bulk Actions (lines 932-1001)
   - SweetAlert2 confirmations
   - Status updates via fetch API
   - Table refresh after operations

6. Column Visibility Modal (lines 1089-1153)
   - Dynamic checkbox generation
   - Per-status preference saving
   - Database persistence

URL PARAMETERS:
---------------
?status=[Review|Tracked|Removed]  - Initial status filter (default: Review)
?id=[case_id]                     - Specific case (unused on this page)

SESSION VARIABLES:
------------------
session.userActivityLogged        - Prevents duplicate activity logging

AUTHENTICATION:
---------------
Requires authenticated user via Application.cfc
Uses getAuthUser() to retrieve current username

PERFORMANCE CONSIDERATIONS:
---------------------------
- DataTables uses client-side processing (serverSide: false)
- Filter dropdowns reload asynchronously via AJAX
- Debounced search input (300ms) prevents excessive queries
- Column visibility stored in DB, loaded once per page load

RELATED FILES:
--------------
Frontend:
  - navbar.cfm                    Navigation bar
  - head.cfm                      Common HTML head (CSS, meta)
  - footer_script.cfm             Common scripts (jQuery, Bootstrap)

Backend:
  - Application.cfc               Authentication, session management
  - includes/functions.cfm        Shared utility functions
  - case_details.cfm              Individual case view
  - add_blank_case.cfm            Manual case addition form

MAINTENANCE NOTES:
------------------
- Column keys in JavaScript must match database column_key values
- Tool IDs are hardcoded in updateFieldRequirements() (lines 1026-1032)
- Priority colors defined in CSS (lines 182-186)
- Status badge colors in ColumnRenderers.status (lines 627-635)

TESTING:
--------
- Test with different user roles (userRole='User' required for filter)
- Verify filter persistence across browser sessions
- Check bulk operations with large selections (100+ cases)
- Validate column visibility saves per status correctly

LAST UPDATED: 2025 (see Git history for recent changes)
================================================================================
--->

<!--- Get current authenticated user --->
<cfset currentuser = getAuthUser()>

<!--- JavaScript configuration for DataTables column definitions --->
<script>
const allColumnKeys = [
    { key: "tool_name", label: "Source" },
    { key: "case_number", label: "Case Number" },
    { key: "case_name", label: "Case Name" },
    { key: "court_name", label: "Courthouse" },
    { key: "priority", label: "Priority" },
    { key: "notes", label: "Details" },
    { key: "sortable_created_at", label: "Discovered" },
    { key: "sortable_last_updated", label: "Last Tracked" },
    { key: "possible_celebs", label: "Possible Celebs" },
    { key: "county", label: "County" },
    { key: "status", label: "Status" },
    { key: "case_url", label: "Case Link" }
];
</script>

<!--- Set case status from URL parameter --->
<cfset caseStatus = url.status ?: "Review">

<!--- Query to get user's column visibility preferences --->
<cfquery name="columnDefaults" datasource="Reach">
    SELECT column_key, is_visible
    FROM docketwatch.dbo.column_visibility_defaults
    WHERE (username = <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar"> OR username IS NULL)
    AND status = <cfqueryparam value="#caseStatus#" cfsqltype="cf_sql_varchar">
</cfquery>

<!--- Build visibility map for JavaScript consumption --->
<cfset visibilityMap = {}>
<cfloop query="columnDefaults">
    <cfset visibilityMap[column_key] = is_visible>
</cfloop>

<!--- URL parameter defaults --->
<cfparam name="url.status" default="Review">
<cfparam name="idlist" default="">

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

<!--- Query to get celebrities that have case matches --->
<cfquery name="celebrities" datasource="Reach">
    SELECT DISTINCT ce.id, ce.name as celebrity_name
    FROM docketwatch.dbo.celebrities ce
    WHERE ce.id IN (
        SELECT DISTINCT cm.fk_celebrity
        FROM docketwatch.dbo.case_celebrity_matches cm
        WHERE cm.match_status <> 'Removed'
    )
    ORDER BY ce.name
</cfquery>

<!--- Query to get tools that have associated cases --->
<cfquery name="tools" datasource="Reach">
    SELECT id, tool_name
    FROM docketwatch.dbo.tools
    WHERE id IN (
        SELECT DISTINCT fk_tool 
        FROM docketwatch.dbo.cases 
        WHERE fk_tool IS NOT NULL
    )
    ORDER BY tool_name
</cfquery>

<!--- Query to get all states --->
<cfquery name="states" datasource="Reach">
    SELECT state_code, state_name
    FROM docketwatch.dbo.states
    ORDER BY state_name
</cfquery>

<!--- Query to get courts with associated county and state information --->
<cfquery name="courts" datasource="Reach">
    SELECT c.court_code, c.court_name, c.fk_county, o.state_code
    FROM docketwatch.dbo.courts c
    INNER JOIN docketwatch.dbo.counties o ON o.id = c.fk_county
    ORDER BY c.court_name
</cfquery>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>#application.siteTitle#</cfoutput></title>
    <cfinclude template="head.cfm">
    
    <style>
        /* Professional improvements for DocketWatch interface */
        .page-title {
            font-weight: 600;
            color: #1e293b;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 0.5rem;
            margin-bottom: 1.5rem;
        }
        
        .filter-card .card-header {
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
            border-bottom: 1px solid #cbd5e1;
            font-weight: 500;
            color: #475569;
        }
        
        .cases-table-wrapper {
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        }
        
        #casesTable tbody tr:hover {
            background-color: #f1f5f9 !important;
            transition: background-color 0.2s ease;
        }
        
        .btn-group-actions .btn {
            margin-right: 0.5rem;
            margin-bottom: 0.25rem;
        }
        
        .status-badge {
            font-size: 0.75rem;
            padding: 0.25rem 0.5rem;
            border-radius: 0.375rem;
            font-weight: 500;
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
        
        .priority-critical { color: #dc2626; font-weight: 700; }  /* Red - Critical */
        .priority-high { color: #ea580c; font-weight: 600; }      /* Orange - High */
        .priority-medium { color: #d97706; font-weight: 500; }    /* Amber/Yellow - Medium */
        .priority-low { color: #16a34a; font-weight: 400; }       /* Green - Low */
        .priority-unknown { color: #6b7280; font-weight: 400; }   /* Gray - Unknown */
        
        @media (max-width: 768px) {
            .filter-row > div {
                margin-bottom: 0.5rem;
            }
            .btn-group-actions .btn {
                width: 100%;
                margin-bottom: 0.5rem;
            }
        }
    </style>
</head>
<body>

<cfinclude template="navbar.cfm">

<div class="container mt-4">
    <!--- Page header with title and status filter --->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0 page-title">Cases</h2>
        <select id="statusFilter" class="form-select form-select-sm w-auto">
            <option value="Review" <cfif url.status EQ "Review">selected</cfif>>For Review</option>
            <option value="Tracked" <cfif url.status EQ "Tracked">selected</cfif>>Tracked</option>
            <option value="Removed" <cfif url.status EQ "Removed">selected</cfif>>Removed</option>
        </select>
    </div>

    <!--- Filter Panel --->
    <div class="card mb-3 filter-card">
        <div class="card-header">
            <h6 class="mb-0">
                <i class="fa-solid fa-filter me-2"></i>Search Filters
            </h6>
        </div>
        <div class="card-body">
            <div class="row g-3 align-items-end filter-row">
                
                <!--- Owner Filter - Toggle Buttons --->
                <div class="col-12">
                    <label class="form-label small text-muted mb-2">Case Owners (select one or more)</label>
                    <div id="ownerFilterGroup" class="btn-group btn-group-sm flex-wrap" role="group" aria-label="Filter by case owners">
                        <cfoutput query="owners">
                            <input type="checkbox" class="btn-check owner-filter-btn" id="owner_#value#" value="#value#" autocomplete="off" <cfif value EQ currentUser>checked</cfif>>
                            <label class="btn btn-outline-primary" for="owner_#value#">
                                <i class="fas fa-user me-1"></i>#display#
                            </label>
                        </cfoutput>
                    </div>
                </div>

                <!--- Tool Filter --->
                <div class="col-auto">
                    <label for="toolFilter" class="form-label small text-muted mb-1">Source Tool</label>
                    <select id="toolFilter" name="toolFilter" class="form-select form-select-sm case-filter" aria-label="Filter by source tool">
                        <option value="">All Tools</option>
                    </select>
                </div>

                <!--- State Filter --->
                <div class="col-auto">
                    <label for="stateFilter" class="form-label small text-muted mb-1">State</label>
                    <select id="stateFilter" name="stateFilter" class="form-select form-select-sm case-filter" aria-label="Filter by state">
                        <option value="">All States</option>
                    </select>
                </div>

                <!--- County Filter --->
                <div class="col-auto">
                    <label for="county_id" class="form-label small text-muted mb-1">County</label>
                    <select id="county_id" name="county_id" class="form-select form-select-sm case-filter" aria-label="Filter by county">
                        <option value="">All Counties</option>
                    </select>
                </div>

                <!--- Courthouse Filter --->
                <div class="col-auto">
                    <label for="courthouseFilter" class="form-label small text-muted mb-1">Courthouse</label>
                    <select id="courthouseFilter" name="courthouseFilter" class="form-select form-select-sm case-filter" aria-label="Filter by courthouse">
                        <option value="">All Courthouses</option>
                    </select>
                </div>

                <!--- Celebrity Filter --->
                <div class="col-auto">
                    <label for="celebrityFilter" class="form-label small text-muted mb-1">Celebrity</label>
                    <select id="celebrityFilter" name="celebrityFilter" class="form-select form-select-sm case-filter" aria-label="Filter by celebrity">
                        <option value="">All Celebrities</option>
                    </select>
                </div>
                
                <!--- Clear Filters Button --->
                <div class="col-auto">
                    <button id="clearFilters" class="btn btn-outline-secondary btn-sm" title="Clear all filters">
                        <i class="fa-solid fa-times me-1"></i>Clear
                    </button>
                </div>

            </div>
        </div>
    </div>

    <!--- Document OCR Search Panel --->
    <div class="card mb-3">
        <div class="card-body">
            <div class="row align-items-center">
                <div class="col">
                    <div class="input-group">
                        <span class="input-group-text">
                            <i class="fa-solid fa-search text-muted"></i>
                        </span>
                        <input type="text" class="form-control" id="documentSearch" 
                               placeholder="Search document OCR text (e.g., contract terms, defendant names)..." 
                               autocomplete="off"
                               aria-label="Search document OCR text">
                        <button class="btn btn-outline-secondary" type="button" id="clearSearch" title="Clear search">
                            <i class="fa-solid fa-times"></i>
                        </button>
                    </div>
                    <small class="text-muted">
                        <i class="fa-solid fa-info-circle me-1"></i>
                        Search across scanned document content and case descriptions
                    </small>
                </div>
            </div>
        </div>
    </div>

    <!--- Action Panel --->
    <div class="card mb-3">
        <div class="card-body">
            <div class="d-flex flex-wrap align-items-center justify-content-between">
                <div class="btn-group-actions">
                    <cfoutput>
                        <button id="removeCases" class="btn btn-danger btn-sm" aria-label="Remove selected cases">
                            <i class="fa-solid fa-trash me-1"></i>Remove Cases
                        </button>
                        <button id="trackCases" class="btn btn-success btn-sm" aria-label="Track selected cases">
                            <i class="fa-solid fa-eye me-1"></i>Track Cases
                        </button>
                        <button id="ReviewCases" class="btn btn-warning btn-sm" aria-label="Set selected cases to review">
                            <i class="fa-solid fa-undo me-1"></i>Set to Review
                        </button>
                        <a href="add_blank_case.cfm" class="btn btn-primary btn-sm">
                            <i class="fa-solid fa-plus me-1"></i>Track New Case
                        </a>
                    </cfoutput>
                </div>
                <div class="btn-group-settings">
                    <button class="btn btn-outline-secondary btn-sm" data-bs-toggle="modal" data-bs-target="#columnVisibilityModal">
                        <i class="fa-solid fa-columns me-1"></i>Columns
                    </button>
                    <button id="refreshFilters" class="btn btn-outline-secondary btn-sm">
                        <i class="fa-solid fa-sync me-1"></i>Refresh
                    </button>
                </div>
            </div>
        </div>
    </div>


    <!--- Main Cases DataTable --->
    <div class="cases-table-wrapper">
        <div id="tableLoadingOverlay" class="d-none position-absolute w-100 h-100 d-flex align-items-center justify-content-center" 
             style="background: rgba(255,255,255,0.8); z-index: 10;">
            <div class="text-center">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Loading cases...</span>
                </div>
                <div class="mt-2 text-muted">Loading cases...</div>
            </div>
        </div>
        
        <table id="casesTable" class="table w-100 table-striped table-hover">
            <thead class="table-dark">
                <tr>
                    <th style="width: 40px;">
                        <input type="checkbox" id="select-all" aria-label="Select all cases">
                    </th>
                    <th>Source</th>
                    <th style="display:none;" class="noVis">ID</th> <!--- Hidden ID column for internal use --->
                    <th>Case Number</th>
                    <th>Case Name</th>
                    <th>Courthouse</th>
                    <th>Priority</th>
                    <th>Details</th>
                    <th>Discovered</th>
                    <th>Last Tracked</th>
                    <th nowrap>Possible Celebs</th>
                    <th>County</th>
                    <th>Status</th>
                    <th>Link</th>
                </tr>
            </thead>
            <tbody></tbody>
        </table>
    </div>
</div>

<cfinclude template="footer_script.cfm">

<!--- User Activity Logging (only log once per session) --->
<cfif NOT isDefined("session.userActivityLogged") OR session.userActivityLogged NEQ true>
    <cftry>
        <cfset login_name = getAuthUser()>
        <cfif NOT isDefined("login_name") OR len(trim(login_name)) EQ 0>
            <cfset login_name = "user">
        </cfif>
        
        <cfquery datasource="reach">
            INSERT INTO docketwatch.dbo.UserActivity (UserName, PageName, CGI_IP, CGI_UserAgent)
            VALUES (
                <cfqueryparam value="#login_name#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#CGI.SCRIPT_NAME#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#CGI.IP_ADDRESS#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#CGI.HTTP_USER_AGENT#" cfsqltype="cf_sql_varchar">
            );
        </cfquery>
        <cfset session.userActivityLogged = true>
        <cfcatch type="any">
            <!--- Log error silently without affecting page load --->
        </cfcatch>
    </cftry>
</cfif>

<!--- Column Visibility Modal --->
<div class="modal fade" id="columnVisibilityModal" tabindex="-1" aria-labelledby="columnVisibilityLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Customize Column Visibility</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <select id="statusSelector" class="form-select mb-3">
                    <option value="Review">Review</option>
                    <option value="Tracked">Tracked</option>
                </select>
                <div id="columnOptionsContainer" class="row g-2">
                    <!--- Checkboxes populated dynamically by JavaScript --->
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-primary" onclick="saveColumnVisibility()">Save</button>
            </div>
        </div>
    </div>
</div>

<!--- Track New Case Modal --->
<div class="modal fade" id="trackCaseModal" tabindex="-1" aria-labelledby="trackCaseModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="trackCaseModalLabel">Track New Case</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <form id="trackCaseForm">
                    <cfoutput>
                        <input type="hidden" id="currentuser" name="currentuser" value="#currentuser#">
                    </cfoutput>
                    
                    <div class="mb-3">
                        <label for="toolSelect" class="form-label">Tool <span class="text-danger">*</span></label>
                        <select class="form-select" id="toolSelect" required onchange="updateFieldRequirements()">
                            <option value="">Select Tool</option>
                            <cfquery name="getUserTools" datasource="Reach">
                                SELECT id as fk_tool, tool_name
                                FROM docketwatch.dbo.tools
                                WHERE owners LIKE <cfqueryparam value="%#currentUser#%" cfsqltype="cf_sql_varchar">
                                AND addNew = 1
                                ORDER BY tool_name
                            </cfquery>
                            <cfoutput query="getUserTools">
                                <option value="#fk_tool#">#tool_name#</option>
                            </cfoutput>
                        </select>
                    </div>

                    <!--- Case URL Field (shown for specific tools) --->
                    <div class="mb-3" id="caseUrlGroup" style="display: none;">
                        <label for="caseUrl" class="form-label">Case URL <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="caseUrl">
                    </div>

                    <!--- Case Number Field (shown for specific tools) --->
                    <div class="mb-3" id="caseNumberGroup" style="display: none;">
                        <label for="caseNumber" class="form-label">Case Number <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="caseNumber">
                    </div>

                    <!--- Case Name Field (optional) --->
                    <div class="mb-3" id="caseNameGroup" style="display: none;">
                        <label for="caseName" class="form-label">Case Name</label>
                        <input type="text" class="form-control" id="caseName">
                    </div>

                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" onclick="submitNewCase()">Submit</button>
            </div>
        </div>
    </div>
</div>


 
<script>
/**
 * Configuration and Utility Functions
 * ==================================
 */

// Column visibility defaults from server-side ColdFusion
const columnVisibilityDefaults = <cfoutput>#serializeJSON(visibilityMap)#</cfoutput>;

/**
 * Debounces a function call to prevent excessive API calls during rapid user input.
 *
 * @param {Function} func - The function to debounce
 * @param {number} wait - Milliseconds to wait before executing (default: 300ms for search)
 * @returns {Function} Debounced function that delays execution
 *
 * @example
 * // Search input with 300ms debounce
 * $('#documentSearch').on('input', debounce(function() {
 *     $('#casesTable').DataTable().ajax.reload();
 * }, 300));
 */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

/**
 * Centralized localStorage management for filter persistence across sessions.
 *
 * Stores user filter selections so they persist when the user returns to the page.
 * Each filter (tool, owner, courthouse, etc.) is saved under a unique key.
 *
 * @property {Object} keys - Mapping of filter names to localStorage key names
 * @property {Function} set - Save a filter value to localStorage
 * @property {Function} get - Retrieve a filter value from localStorage
 * @property {Function} clearAll - Remove all saved filter values
 *
 * @example
 * // Save a filter selection
 * LocalStorageManager.set('tool', '13'); // Save tool ID 13
 *
 * // Retrieve saved filter
 * const savedTool = LocalStorageManager.get('tool'); // Returns '13'
 *
 * // Clear all filters
 * LocalStorageManager.clearAll();
 */
const LocalStorageManager = {
    keys: {
        tool: 'selectedTool',
        owner: 'docketwatch_owner',
        courthouse: 'selectedCourthouse',
        county: 'selectedCounty',
        state: 'selectedState',
        celebrity: 'selectedCelebrity'
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
</script>


<script>
/**
 * Gets all selected case owners from the owner filter toggle buttons.
 *
 * Scans all checked owner filter buttons and returns their values as a
 * comma-separated string for passing to AJAX endpoints.
 *
 * @returns {string} Comma-separated list of owner usernames (e.g., "jsmith,bjones")
 *
 * @example
 * // If "John Smith" and "Jane Doe" are selected
 * getSelectedOwners(); // Returns "jsmith,jdoe"
 */
function getSelectedOwners() {
    const selected = [];
    $('.owner-filter-btn:checked').each(function() {
        selected.push($(this).val());
    });
    return selected.join(',');
}

/**
 * Reloads all filter dropdown options asynchronously based on current filter state.
 *
 * This function implements cascading filters where each dropdown's options depend
 * on selections in other filters (e.g., counties depend on selected state).
 * All dropdowns reload in parallel for optimal performance.
 *
 * Restores previously selected values from localStorage after reloading.
 *
 * @returns {Promise} Promise that resolves when all dropdowns are loaded
 *
 * @example
 * // Reload all filters after user changes state selection
 * reloadDropdownsAsync().then(function() {
 *     $('#casesTable').DataTable().ajax.reload();
 * });
 *
 * @see LocalStorageManager For filter persistence mechanism
 */
function reloadDropdownsAsync() {
    var filters = {
        status: $('#statusFilter').val(),
        tool: $('#toolFilter').val(),
        owner: getSelectedOwners(),
        state: $('#stateFilter').val(),
        county: $('#county_id').val(),
        courthouse: $('#courthouseFilter').val(),
        fk_celebrity: $('#celebrityFilter').val()
    };

    const loaders = [
        { url: 'get_tools.cfm', target: '#toolFilter', selected: LocalStorageManager.get('tool') },
        { url: 'get_states.cfm', target: '#stateFilter', selected: LocalStorageManager.get('state') },
        { url: 'get_counties.cfm', target: '#county_id', selected: LocalStorageManager.get('county') },
        { url: 'get_courthouses.cfm', target: '#courthouseFilter', selected: LocalStorageManager.get('courthouse') },
        { url: 'get_celebrities.cfm', target: '#celebrityFilter', selected: LocalStorageManager.get('celebrity') }
    ];

    return Promise.all(loaders.map(item =>
        new Promise(resolve => {
            $.get(item.url, filters, function(data) {
                $(item.target).html(data);
                if (item.selected && $(item.target + ' option[value="' + item.selected + '"]').length) {
                    $(item.target).val(item.selected);
                }
                resolve();
            });
        })
    ));
}

/**
 * Column rendering utilities for DataTables custom cell display.
 *
 * Each method transforms raw data into formatted HTML for display in the DataTables grid.
 * These renderers handle special formatting for dates, priorities, statuses, links, etc.
 *
 * @namespace ColumnRenderers
 *
 * @property {Function} defaultOrFallback - Returns data or fallback text if empty
 * @property {Function} caseNumber - Renders case number with action buttons (view, external link, PDF)
 * @property {Function} priority - Renders priority with color coding (high=red, medium=yellow, low=green)
 * @property {Function} status - Renders status as colored badge (Review=warning, Tracked=success, Removed=secondary)
 * @property {Function} dateFormat - Formats sortable date to human-readable display
 * @property {Function} lastUpdated - Formats last updated date with "not found" warnings
 * @property {Function} celebrities - Formats celebrity list with line breaks
 *
 * @example
 * // Used in DataTables column definition
 * {
 *     data: "priority",
 *     render: ColumnRenderers.priority
 * }
 */
const ColumnRenderers = {
    defaultOrFallback: (data, fallback = "(None)") => data || fallback,
    
    caseNumber: function(data, type, row) {
        let html = '<div class="d-flex align-items-center">';
        html += '<span class="me-2 fw-medium">' + data + '</span>';
        
        html += '<div class="btn-group btn-group-sm" role="group">';
        html += '<a href="' + row.internal_case_url + '" title="View Case Details" class="btn btn-outline-primary btn-sm">';
        html += '<i class="fa-solid fa-file-lines"></i></a>';
        
        if (row.external_case_url) {
            html += '<a href="' + row.external_case_url + '" target="_blank" title="Open Official Court Page" class="btn btn-outline-secondary btn-sm">';
            html += '<i class="fa-solid fa-up-right-from-square"></i></a>';
        }
        
        if (row.pdf_link && row.pdf_link.trim() !== "") {
            html += '<a href="' + row.pdf_link + '" target="_blank" title="View PDF Document" class="btn btn-outline-danger btn-sm">';
            html += '<i class="fa-solid fa-file-pdf"></i></a>';
        }
        html += '</div></div>';
        
        return html;
    },
    
    priority: function(data) {
        if (!data || data === "(None)") return '<span class="text-muted">—</span>';
        
        const priorityClass = data.toLowerCase().includes('high') ? 'priority-high' :
                             data.toLowerCase().includes('medium') ? 'priority-medium' : 'priority-low';
        
        return '<span class="' + priorityClass + '">' + data + '</span>';
    },
    
    status: function(data) {
        if (!data) return '<span class="text-muted">—</span>';
        
        const statusMap = {
            'Review': 'warning',
            'Tracked': 'success', 
            'Removed': 'secondary',
            'Active': 'primary'
        };
        
        const badgeClass = statusMap[data] || 'secondary';
        return '<span class="badge bg-' + badgeClass + ' status-badge">' + data + '</span>';
    },
    
    dateFormat: function(data, type, row, formattedField) {
        return type === 'display' ? (row[formattedField] || "(No Date)") : data;
    },
    
    lastUpdated: function(data, type, row) {
        if (type === 'display') {
            let text = row.formatted_last_updated || "(No Date)";
            if (row.not_found_count && row.not_found_count > 0) {
                const plural = row.not_found_count > 1 ? 's' : '';
                return `<a href="not_found.cfm#case${row.id}" style="color: #b91c1c; font-weight: bold; text-decoration:underline;">
                        ${text} 
                        <i class="fa fa-exclamation-triangle" title="Case not found ${row.not_found_count} time${plural}"></i>
                        <span style="font-size:90%;font-weight:normal;">(${row.not_found_count})</span>
                    </a>`;
            }
            return text;
        }
        return data;
    },
    
    celebrities: (data) => data ? data.replace(/, /g, "<br>") : "(None)"
};

/**
 * Initializes the main DataTables instance for the cases grid.
 *
 * Configures the DataTables library with AJAX data loading, custom column rendering,
 * sorting, paging, and column visibility based on user preferences.
 *
 * Data is loaded from cases_ajax.cfm with current filter parameters.
 * Column visibility defaults are loaded from server-side (columnVisibilityDefaults).
 *
 * @returns {void}
 *
 * @fires ajax.reload - When filters change
 *
 * @see ColumnRenderers For custom column display logic
 * @see cases_ajax.cfm For data source endpoint
 *
 * @example
 * // Initialize table on page load
 * initializeCasesTable();
 *
 * // Reload data after filter change
 * $('#casesTable').DataTable().ajax.reload();
 */
function initializeCasesTable() {
    window.table = $('#casesTable').DataTable({
        dom: '<"dt-toolbar d-flex justify-content-between align-items-center mb-2"lfB>rt<"bottom"ip><"clear">',
        buttons: [
            {
                extend: 'colvis',
                columns: ':not(.noVis)', // Exclude critical columns like checkboxes or IDs
                text: 'Choose Columns',
                titleAttr: 'Select visible columns'
            }
        ],
        columnDefs: [
            {
                targets: [0, 2], // Prevent visibility toggle for checkbox and ID
                className: 'noVis'
            }
        ],
        ajax: {
            url: "cases_ajax.cfm",
            data: function (d) {
                d.status     = $('#statusFilter').val();
                d.county     = $('#county_id').val();
                d.tool       = $('#toolFilter').val();
                d.owner      = getSelectedOwners();
                d.state      = $('#stateFilter').val();
                d.courthouse = $('#courthouseFilter').val();
                d.celebrity  = $('#celebrityFilter').val();
                d.docsearch  = $('#documentSearch').val();
            },
            beforeSend: function() {
                $('#tableLoadingOverlay').removeClass('d-none');
            },
            complete: function() {
                $('#tableLoadingOverlay').addClass('d-none');
            },
            dataSrc: function (json) {
                console.log("AJAX Response Data:", json);
                return Array.isArray(json) ? json : [];
            },
            error: function (xhr, error, thrown) {
                console.error("AJAX Error:", error, thrown);
                $('#tableLoadingOverlay').addClass('d-none');
            }
        },
columns: [
    {
        data: null,
        orderable: false,
        className: "select-checkbox noVis",
        render: function (data, type, row) {
            return '<input type="checkbox" class="row-checkbox" value="' + row.id + '">';
        }
    },
    { data: "tool_name", visible: columnVisibilityDefaults["tool_name"] === 1, title: "Source", defaultContent: "(None)" },
    { data: "id", visible: false, className: "noVis" },
    {
        data: "case_number",
        className: "nowrap",
        visible: true,
        render: ColumnRenderers.caseNumber
    },
    {
        data: "case_name",
        visible: columnVisibilityDefaults["case_name"] === 1,
        defaultContent: "(None)",
        render: function(data) { return ColumnRenderers.defaultOrFallback(data); }
    },
    { data: "court_name", visible: columnVisibilityDefaults["court_name"] === 1, defaultContent: "(Unknown)" },
    { 
        data: "priority", 
        visible: columnVisibilityDefaults["priority"] === 1, 
        defaultContent: "(None)",
        render: ColumnRenderers.priority
    },
    {
        data: "notes",
        visible: columnVisibilityDefaults["notes"] === 1,
        defaultContent: "(No Details)",
        render: function(data) { return ColumnRenderers.defaultOrFallback(data, "(No Details)"); }
    },
    {
        data: "sortable_created_at",
        visible: columnVisibilityDefaults["sortable_created_at"] === 1,
        className: "nowrap",
        render: function(data, type, row) { return ColumnRenderers.dateFormat(data, type, row, 'formatted_created_at'); }
    },
    {
        data: "sortable_last_updated",
        visible: columnVisibilityDefaults["sortable_last_updated"] === 1,
        className: "nowrap",
        render: ColumnRenderers.lastUpdated
    },
    {
        data: "possible_celebs",
        visible: columnVisibilityDefaults["possible_celebs"] === 1,
        defaultContent: "(None)",
        render: function(data) { return ColumnRenderers.celebrities(data); }
    },
    { data: "county", visible: columnVisibilityDefaults["county"] === 1, defaultContent: "(None)" },
    { 
        data: "status", 
        visible: columnVisibilityDefaults["status"] === 1, 
        defaultContent: "(None)",
        render: ColumnRenderers.status
    },
    { data: "case_url", visible: columnVisibilityDefaults["case_url"] === 1, defaultContent: "(None)" }
],

        paging: true,
        searching: true,
        ordering: true,
        info: true,
        order: [[8, "desc"]],
        pageLength: 10,
        lengthMenu: [[10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]],
        processing: true,
        serverSide: false
    });
}


/**
 * Main Application Initialization
 * ===============================
 */
$(document).ready(function () {
    // Restore owner selections from localStorage on page load
    const savedOwners = LocalStorageManager.get('owner');
    if (savedOwners) {
        const ownerArray = savedOwners.split(',');
        ownerArray.forEach(function(owner) {
            $('#owner_' + owner).prop('checked', true);
        });
    }
    
    // Initialize page: Load all dropdown filters and set up table
    reloadDropdownsAsync().then(function() {
        // Initialize DataTable after filters are loaded
        initializeCasesTable();

        // Setup owner filter button change handler
        $('.owner-filter-btn').on('change', function() {
            const selectedOwners = getSelectedOwners();
            LocalStorageManager.set('owner', selectedOwners);
            
            // Reload dependent dropdowns and refresh table
            reloadDropdownsAsync().then(function() {
                $('#casesTable').DataTable().ajax.reload();
            });
        });

        // Setup unified filter change handlers for all dropdowns
        $('#toolFilter, #county_id, #courthouseFilter, #celebrityFilter, #stateFilter, #statusFilter').on('change', function () {
            const id = $(this).attr('id');
            const val = $(this).val();
            
            // Map filter IDs to localStorage keys
            const storageMap = {
                'toolFilter': 'tool',
                'courthouseFilter': 'courthouse',
                'county_id': 'county',
                'stateFilter': 'state',
                'celebrityFilter': 'celebrity'
            };
            
            // Save filter state to localStorage
            if (storageMap[id]) {
                LocalStorageManager.set(storageMap[id], val);
            }

            // Reload dependent dropdowns and refresh table
            reloadDropdownsAsync().then(function() {
                $('#casesTable').DataTable().ajax.reload();
            });

            // Update page title based on status filter
            if (id === 'statusFilter') {
                const statusText = {
                    "Review": "New Cases Review",
                    "Tracked": "Tracked Cases",
                    "Removed": "Removed Cases"
                }[val] || "Cases";
                $('.page-title').text(statusText);
            }
        });

        // Setup document search with debouncing
        $('#documentSearch').on('input', debounce(function() {
            $('#casesTable').DataTable().ajax.reload();
        }, 300));
        
        // Clear search functionality
        $('#clearSearch').on('click', function() {
            $('#documentSearch').val('');
            $('#casesTable').DataTable().ajax.reload();
        });
        
        // Clear all filters functionality
        $('#clearFilters').on('click', function() {
            LocalStorageManager.clearAll();
            $('#toolFilter, #stateFilter, #county_id, #courthouseFilter, #celebrityFilter').val('');
            $('.owner-filter-btn').prop('checked', false);
            $('#documentSearch').val('');
            reloadDropdownsAsync().then(function() {
                $('#casesTable').DataTable().ajax.reload();
            });
        });

        // Configure action button visibility based on status and selection
        const actionButtons = {
            '#removeCases': { hideOnLoad: true, showWhen: (status, hasChecked) => status === 'Review' && hasChecked },
            '#trackCases': { hideOnLoad: true, showWhen: (status, hasChecked) => status === 'Review' && hasChecked },
            '#trackCaseModalBtn': { hideOnLoad: true, showWhen: (status, hasChecked) => status === 'Review' && hasChecked },
            '#ReviewCases': { hideOnLoad: true, showWhen: (status, hasChecked) => status === 'Tracked' && hasChecked },
            '#trackAdd': { hideOnLoad: true, showWhen: (status, hasChecked) => status === 'Tracked' },
            '#refreshFilters': { hideOnLoad: true, showWhen: (status, hasChecked, hasFilters) => hasFilters }
        };

        // Hide action buttons initially
        Object.keys(actionButtons).forEach(selector => {
            if (actionButtons[selector].hideOnLoad) {
                $(selector).hide();
            }
        });

        // Function to update action button visibility
        function updateActionButtons() {
            const status = $('#statusFilter').val();
            const anyChecked = $('.row-checkbox:checked').length > 0;
            const filters = ['#toolFilter','#ownerFilter','#stateFilter','#county_id','#courthouseFilter','#celebrityFilter'];
            const anyFilterSet = filters.some(sel => $(sel).val()?.length > 0);
            
            Object.entries(actionButtons).forEach(([selector, config]) => {
                const shouldShow = config.showWhen(status, anyChecked, anyFilterSet);
                $(selector).toggle(shouldShow);
            });
        }

        // Bind action button update events
        $(document).on('change', '.row-checkbox', updateActionButtons);
        $('#statusFilter, #toolFilter, #stateFilter, #county_id, #courthouseFilter, #celebrityFilter, .owner-filter-btn')
            .on('change', updateActionButtons);
        $('#casesTable').on('draw.dt', updateActionButtons);

        // Setup select-all checkbox functionality
        $('#select-all').on('click', function() {
            var isChecked = this.checked;
            $('.row-checkbox').prop('checked', isChecked).trigger('change');
        });

        // Allow clicking on checkbox cell to toggle checkbox
        $('#casesTable tbody').on('click', 'td.select-checkbox', function(event) {
            if (!$(event.target).is('input')) {
                var checkbox = $(this).find('input.row-checkbox');
                checkbox.prop('checked', !checkbox.prop('checked')).trigger('change');
            }
        });

        // Setup refresh button to clear all filters
        $('#refreshFilters').on('click', function () {
            LocalStorageManager.clearAll();
            $('#statusFilter').val('Review');
            $('#toolFilter, #ownerFilter, #stateFilter, #county_id, #courthouseFilter, #celebrityFilter').val('');
            reloadDropdownsAsync().then(function() {
                $('#casesTable').DataTable().ajax.reload();
            });
            $('.page-title').text('New Cases Review');
        });
    });
});

/**
 * Case Status Management Functions
 * ===============================
 */

/**
 * Updates the status of one or more cases with user confirmation.
 *
 * Displays a SweetAlert2 confirmation dialog before sending the status update
 * to the server via update_case_status_list.cfm.
 *
 * Valid status values: 'Review', 'Tracked', 'Removed'
 *
 * @param {string} caseId - Comma-separated list of case IDs (e.g., "123,456,789")
 * @param {string} newStatus - New status to set ('Review', 'Tracked', or 'Removed')
 * @returns {void}
 *
 * @fires table.ajax.reload - Refreshes DataTable after successful update
 *
 * @example
 * // Update multiple cases to "Tracked" status
 * updateCaseStatus("123,456,789", "Tracked");
 *
 * @see update_case_status_list.cfm Backend endpoint for status updates
 */
function updateCaseStatus(caseId, newStatus) {
    Swal.fire({
        title: 'Are you sure?',
        text: 'Set selected cases to ' + newStatus + '?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#3085d6',
        cancelButtonColor: '#aaa',
        confirmButtonText: 'Yes, set it!'
    }).then((result) => {
        if (result.isConfirmed) {
            fetch('update_case_status_list.cfm', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ idlist: caseId, status: newStatus })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    Swal.fire({
                        title: 'Updated!',
                        text: 'Status updated successfully.',
                        icon: 'success'
                    }).then(() => {
                        table.ajax.reload(null, false);
                        $('.row-checkbox').prop('checked', false);
                        updateActionButtons();
                    });
                } else {
                    Swal.fire('Error', 'Error updating status: ' + data.message, 'error');
                }
            })
            .catch(error => Swal.fire('Error', 'An error occurred: ' + error, 'error'));
        }
    });
}

// Button event handlers for case status changes
$('#removeCases').on('click', function () {
    const selected = getSelectedCaseIds();
    if (selected.length === 0) return alert("No cases selected.");
    updateCaseStatus(selected.join(','), 'Removed');
});

$('#trackCases').on('click', function () {
    const selected = getSelectedCaseIds();
    if (selected.length === 0) return alert("No cases selected.");
    updateCaseStatus(selected.join(','), 'Tracked');
});

$('#ReviewCases').on('click', function () {
    const selected = getSelectedCaseIds();
    if (selected.length === 0) return alert("No cases selected.");
    updateCaseStatus(selected.join(','), 'Review');
});

/**
 * Retrieves the IDs of all currently selected cases from checkboxes.
 *
 * Scans all checked row checkboxes in the DataTable and returns their values.
 * Used for bulk operations (track, remove, set to review).
 *
 * @returns {Array<string>} Array of case ID strings
 *
 * @example
 * // Get selected case IDs
 * const selected = getSelectedCaseIds(); // Returns ["123", "456", "789"]
 *
 * // Use for bulk status update
 * if (selected.length > 0) {
 *     updateCaseStatus(selected.join(','), 'Tracked');
 * }
 */
function getSelectedCaseIds() {
    const ids = [];
    $('.row-checkbox:checked').each(function () {
        ids.push($(this).val());
    });
    return ids;
}

/**
 * New Case Modal Functions
 * =======================
 */

/**
 * Updates the new case form field visibility and requirements based on selected tool.
 *
 * Different tools require different input fields:
 * - Tool 2 (UniCourt): Requires case URL
 * - Tools 13, 25 (PACER, Broward): Require case number
 * - Other tools: May show case name field
 *
 * Fields are shown/hidden dynamically and required attributes are updated.
 *
 * @returns {void}
 *
 * @example
 * // Called automatically when tool dropdown changes
 * document.getElementById('toolSelect').addEventListener('change', updateFieldRequirements);
 *
 * @see submitNewCase For form submission logic
 */
function updateFieldRequirements() {
    const tool = document.getElementById('toolSelect').value;
    const caseUrlGroup = document.getElementById('caseUrlGroup');
    const caseNumberGroup = document.getElementById('caseNumberGroup');
    const caseNameGroup = document.getElementById('caseNameGroup');
    const caseUrl = document.getElementById('caseUrl');
    const caseNumber = document.getElementById('caseNumber');
    const caseName = document.getElementById('caseName');

    // Hide all fields by default
    caseUrlGroup.style.display = 'none';
    caseNumberGroup.style.display = 'none';
    caseNameGroup.style.display = 'none';
    caseUrl.required = false;
    caseNumber.required = false;

    // Show relevant fields based on tool selection
    if (tool === "2") { // UniCourt
        caseUrlGroup.style.display = 'block';
        caseUrl.required = true;
    } else if (tool === "13" || tool === "25") { // PACER, Broward, etc.
        caseNumberGroup.style.display = 'block';
        caseNumber.required = true;
    }
}

// Initialize field requirements when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
    const toolSelect = document.getElementById('toolSelect');
    if (toolSelect) {
        toolSelect.addEventListener('change', updateFieldRequirements);
        updateFieldRequirements(); // Run on load in case tool is preselected
    }
});

/**
 * Submits the new case tracking form to the server.
 *
 * Validates required fields based on selected tool, displays loading indicator,
 * and submits case data to insert_new_case.cfm. On success, redirects to the
 * new case's detail page.
 *
 * @returns {void}
 *
 * @fires insert_new_case.cfm - Backend endpoint for case insertion
 * @fires window.location.href - Redirects to case_details.cfm?id={case_id} on success
 *
 * @example
 * // Called when "Submit" button is clicked in track case modal
 * <button onclick="submitNewCase()">Submit</button>
 *
 * @see updateFieldRequirements For field visibility logic
 * @see insert_new_case.cfm Backend endpoint
 */
function submitNewCase() {
    const tool = document.getElementById('toolSelect').value;
    const caseUrlEl = document.getElementById('caseUrl');
    const caseNumberEl = document.getElementById('caseNumber');
    const caseNameEl = document.getElementById('caseName');
    const currentuser = document.getElementById('currentuser').value.trim();

    // Only collect values from visible fields
    const caseUrl = caseUrlEl.offsetParent !== null ? caseUrlEl.value.trim() : '';
    const caseNumber = caseNumberEl.offsetParent !== null ? caseNumberEl.value.trim() : '';
    const caseName = caseNameEl.offsetParent !== null ? caseNameEl.value.trim() : '';

    if (!tool) {
        Swal.fire('Validation Error', 'Please select a tool.', 'warning');
        return;
    }

    // Show loading indicator
    Swal.fire({
        title: 'Tracking Case...',
        html: 'Please wait while the case is processed.',
        allowOutsideClick: false,
        didOpen: () => { Swal.showLoading(); }
    });

    // Submit case data
    fetch('insert_new_case.cfm?bypass=1', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool, caseUrl, caseNumber, caseName, currentuser })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success && data.inserted_case_id) {
            Swal.fire('Success', 'Case added successfully.', 'success')
                .then(() => window.location.href = `case_details.cfm?id=${data.inserted_case_id}`);
        } else {
            Swal.fire('Error', data.message || 'Unknown error', 'error');
        }
    })
    .catch(err => Swal.fire('Error', err.message || err, 'error'));
}
</script>

<script>
/**
 * Column Visibility Modal Functions
 * =================================
 */
document.addEventListener('DOMContentLoaded', function () {
    // Setup column visibility modal - populate checkboxes when modal opens
    $('#columnVisibilityModal').on('show.bs.modal', function () {
        const status = $('#statusSelector').val();
        const container = $('#columnOptionsContainer');
        container.empty();

        // Create checkbox for each column
        allColumnKeys.forEach(col => {
            const checked = columnVisibilityDefaults[col.key] === 1;
            const checkbox = `
                <div class="col-md-4">
                    <div class="form-check">
                        <input class="form-check-input col-check" type="checkbox" 
                            data-col="${col.key}" id="col-${col.key}" ${checked ? 'checked' : ''}>
                        <label class="form-check-label" for="col-${col.key}">
                            ${col.label}
                        </label>
                    </div>
                </div>`;
            container.append(checkbox);
        });
    });

    // Refresh modal when status selector changes
    $('#statusSelector').on('change', function () {
        $('#columnVisibilityModal').modal('show'); // Force re-trigger modal setup
    });
});

/**
 * Saves user column visibility preferences to the database.
 *
 * Collects all checkbox states from the column visibility modal and sends them
 * to save_column_visibility.cfm for persistence. Preferences are saved per status
 * (Review/Tracked/Removed) and per user.
 *
 * On success, reloads the page to apply the new column visibility settings.
 *
 * @returns {void}
 *
 * @fires save_column_visibility.cfm - Backend endpoint for saving preferences
 * @fires location.reload - Refreshes page after successful save
 *
 * @example
 * // Called when "Save" button is clicked in column visibility modal
 * <button onclick="saveColumnVisibility()">Save</button>
 *
 * @see docketwatch.dbo.column_visibility_defaults Database table for preferences
 */
function saveColumnVisibility() {
    const status = $('#statusSelector').val();
    const updates = [];

    // Collect all checkbox states
    $('.col-check').each(function () {
        const col = $(this).data('col');
        const isVisible = $(this).is(':checked') ? 1 : 0;
        updates.push({ column_key: col, is_visible: isVisible });
    });

    // Send updates to server
    fetch('save_column_visibility.cfm', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, updates })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            Swal.fire("Saved", "Column visibility saved successfully.", "success")
                .then(() => location.reload()); // Refresh page to apply changes
        } else {
            Swal.fire("Error", data.message || "Failed to save settings.", "error");
        }
    })
    .catch(err => Swal.fire("Error", err.message, "error"));
}
</script>


</body>
</html>
</html>
