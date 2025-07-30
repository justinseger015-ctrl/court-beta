<cfparam name="url.case_id" default="">
<cfset caseId = val(url.case_id)>

<cftry>
    <!--- Validate input --->
    <cfif caseId EQ 0>
        <cfoutput>
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle me-2"></i>
                Invalid case ID provided.
            </div>
        </cfoutput>
        <cfabort>
    </cfif>
    
    <!--- Get case details and summary --->
    <cfquery name="case_info" datasource="Reach">
        SELECT 
            c.[id],
            c.[case_number],
            c.[case_name],
            c.[status],
            c.[summarize_html],
            c.[notes],
            c.[created_at],
            c.[last_updated],
            c.[case_type],
            
            -- Tool information
            t.[tool_name],
            t.[username] as tool_username,
            
            -- Court information
            ct.[court_name],
            ct.[address] as court_address,
            ct.[city] as court_city,
            ct.[state] as court_state
            
        FROM [docketwatch].[dbo].[cases] c
        LEFT JOIN [docketwatch].[dbo].[tools] t ON t.id = c.fk_tool
        LEFT JOIN [docketwatch].[dbo].[courts] ct ON ct.court_code = c.fk_court
        WHERE c.id = <cfqueryparam value="#caseId#" cfsqltype="cf_sql_integer">
    </cfquery>
    
    <!--- Check if case exists --->
    <cfif case_info.recordCount EQ 0>
        <cfoutput>
            <div class="alert alert-warning">
                <i class="fas fa-search me-2"></i>
                Case not found.
            </div>
        </cfoutput>
        <cfabort>
    </cfif>
    
    <!--- Get recent events for this case --->
    <cfquery name="recent_events" datasource="Reach">
        SELECT TOP 10
            e.[id],
            e.[event_date],
            e.[event_description],
            e.[event_result],
            e.[additional_information],
            e.[created_at],
            e.[summarize],
            e.[tmz_summarize],
            
            -- PDF information
            p.[pdf_title],
            p.[local_pdf_filename],
            p.[isDownloaded]
            
        FROM [docketwatch].[dbo].[case_events] e
        LEFT JOIN [docketwatch].[dbo].[case_events_pdf] p ON p.fk_case_event = e.id AND p.pdf_type = 'Docket'
        WHERE e.fk_cases = <cfqueryparam value="#caseId#" cfsqltype="cf_sql_integer">
        ORDER BY e.created_at DESC
    </cfquery>
    
    <!--- Get celebrity matches --->
    <cfquery name="celebrity_info" datasource="Reach">
        SELECT 
            c.name as celebrity_name,
            c.id as celebrity_id,
            '' as avatar_url,
            ccm.probability_score,
            ccm.priority_score,
            ccm.match_status,
            cn.name as legal_name
        FROM [docketwatch].[dbo].[case_celebrity_matches] ccm
        INNER JOIN [docketwatch].[dbo].[celebrities] c ON c.id = ccm.fk_celebrity
        LEFT JOIN [docketwatch].[dbo].[celebrity_names] cn ON cn.fk_celebrity = c.id AND cn.type = 'Legal'
        WHERE ccm.fk_case = <cfqueryparam value="#caseId#" cfsqltype="cf_sql_integer">
        AND ccm.match_status <> 'Removed'
        ORDER BY ccm.probability_score DESC
    </cfquery>

    <!--- Output the summary content --->
    <cfoutput>
        <div class="case-summary-content">
            
            <!-- Case Header -->
            <div class="summary-header mb-4">
                <h4 class="text-light mb-2">
                    <i class="fas fa-gavel me-2" style="color: var(--tmz-red);"></i>
                    #case_info.case_number#
                </h4>
                <h5 class="text-muted mb-3">#case_info.case_name#</h5>
                
                <div class="row">
                    <div class="col-md-6">
                        <small class="text-muted">
                            <i class="fas fa-calendar me-1"></i>
                            Filed: #dateFormat(case_info.created_at, "mm/dd/yyyy")#
                        </small>
                    </div>
                    <div class="col-md-6">
                        <small class="text-muted">
                            <i class="fas fa-clock me-1"></i>
                            Updated: #dateFormat(case_info.last_updated, "mm/dd/yyyy")#
                        </small>
                    </div>
                </div>
                
                <cfif len(trim(case_info.tool_name))>
                    <div class="mt-2">
                        <span class="badge" style="background: var(--tmz-red);">
                            <i class="fas fa-tools me-1"></i>
                            #case_info.tool_name#
                        </span>
                    </div>
                </cfif>
            </div>
            
            <!-- Celebrity Information (if any) -->
            <cfif celebrity_info.recordCount GT 0>
                <div class="celebrity-section mb-4">
                    <h6 class="section-title">
                        <i class="fas fa-star me-2" style="color: var(--tmz-red);"></i>
                        Celebrity Connections
                    </h6>
                    <cfloop query="celebrity_info">
                        <div class="celeb-match-item d-flex align-items-center mb-2 p-2" style="background: rgba(214, 0, 0, 0.1); border-radius: 8px; border: 1px solid rgba(214, 0, 0, 0.3);">
                            <cfif len(trim(celebrity_info.avatar_url))>
                                <img src="#celebrity_info.avatar_url#" alt="#celebrity_info.celebrity_name#" 
                                     style="width: 40px; height: 40px; border-radius: 50%; object-fit: cover; border: 2px solid var(--tmz-red);" class="me-3">
                            <cfelse>
                                <div style="width: 40px; height: 40px; border-radius: 50%; background: var(--tmz-red); display: flex; align-items: center; justify-content: center;" class="me-3">
                                    <i class="fas fa-user text-white"></i>
                                </div>
                            </cfif>
                            <div class="flex-grow-1">
                                <div class="fw-bold" style="color: var(--tmz-red);">
                                    #celebrity_info.celebrity_name#
                                </div>
                                <small class="text-muted">
                                    #numberFormat(celebrity_info.probability_score * 100, "0")#% confidence
                                    <cfif len(trim(celebrity_info.legal_name))>
                                        • Legal Name: #celebrity_info.legal_name#
                                    </cfif>
                                </small>
                            </div>
                        </div>
                    </cfloop>
                </div>
            </cfif>
            
            <!-- AI Summary -->
            <cfif len(trim(case_info.summarize_html))>
                <div class="ai-summary-section mb-4">
                    <h6 class="section-title">
                        <i class="fas fa-robot me-2" style="color: var(--tmz-red);"></i>
                        AI Generated Summary
                    </h6>
                    <div class="summary-content p-3" style="background: ##1e1e1e; border-radius: 8px; border-left: 4px solid var(--tmz-red);">
                        #case_info.summarize_html#
                    </div>
                </div>
            <cfelse>
                <div class="ai-summary-section mb-4">
                    <h6 class="section-title">
                        <i class="fas fa-robot me-2" style="color: var(--tmz-red);"></i>
                        AI Generated Summary
                    </h6>
                    <div class="summary-content p-3" style="background: #1e1e1e; border-radius: 8px; border-left: 4px solid #555;">
                        <p class="text-muted mb-0">
                            <i class="fas fa-info-circle me-2"></i>
                            No AI summary has been generated for this case yet.
                        </p>
                    </div>
                </div>
            </cfif>
            
            <!-- Recent Activity -->
            <cfif recent_events.recordCount GT 0>
                <div class="recent-activity-section mb-4">
                    <h6 class="section-title">
                        <i class="fas fa-history me-2" style="color: var(--tmz-red);"></i>
                        Recent Activity
                    </h6>
                    <div class="activity-timeline">
                        <cfloop query="recent_events">
                            <div class="activity-item d-flex mb-3 p-2" style="background: #1e1e1e; border-radius: 8px;">
                                <div class="activity-date me-3 text-center" style="min-width: 80px;">
                                    <div class="date-day" style="color: var(--tmz-red); font-weight: bold;">
                                        #dateFormat(recent_events.event_date, "dd")#
                                    </div>
                                    <div class="date-month text-muted" style="font-size: 0.8rem;">
                                        #dateFormat(recent_events.event_date, "mmm")#
                                    </div>
                                </div>
                                <div class="activity-content flex-grow-1">
                                    <div class="activity-description text-light">
                                        #recent_events.event_description#
                                    </div>
                                    <cfif len(trim(recent_events.additional_information))>
                                        <div class="activity-details text-muted mt-1" style="font-size: 0.9rem;">
                                            #recent_events.additional_information#
                                        </div>
                                    </cfif>
                                    <cfif len(trim(recent_events.local_pdf_filename)) AND recent_events.isDownloaded EQ 1>
                                        <div class="activity-pdf mt-2">
                                            <a href="/mediaroot/pacer_pdfs/#recent_events.local_pdf_filename#" 
                                               target="_blank" 
                                               class="btn btn-sm" 
                                               style="background: var(--tmz-red); color: white;">
                                                <i class="fas fa-file-pdf me-1"></i>
                                                View PDF
                                            </a>
                                        </div>
                                    </cfif>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </div>
            </cfif>
            
            <!-- Case Details -->
            <div class="case-details-section">
                <h6 class="section-title">
                    <i class="fas fa-info-circle me-2" style="color: var(--tmz-red);"></i>
                    Case Details
                </h6>
                <div class="details-grid row">
                    <div class="col-md-6">
                        <div class="detail-item mb-2">
                            <strong class="text-muted">Status:</strong>
                            <span class="ms-2 badge" style="background: 
                                <cfif case_info.status EQ 'Tracked'>var(--priority-normal)<cfelseif case_info.status EQ 'Review'>var(--priority-urgent)<cfelse>#666</cfif>;">
                                #case_info.status#
                            </span>
                        </div>
                        <cfif len(trim(case_info.case_type))>
                            <div class="detail-item mb-2">
                                <strong class="text-muted">Type:</strong>
                                <span class="ms-2 text-light">#case_info.case_type#</span>
                            </div>
                        </cfif>
                    </div>
                    <div class="col-md-6">
                        <cfif len(trim(case_info.court_name))>
                            <div class="detail-item mb-2">
                                <strong class="text-muted">Court:</strong>
                                <span class="ms-2 text-light">#case_info.court_name#</span>
                            </div>
                        </cfif>
                        <cfif len(trim(case_info.court_city))>
                            <div class="detail-item mb-2">
                                <strong class="text-muted">Location:</strong>
                                <span class="ms-2 text-light">#case_info.court_city#, #case_info.court_state#</span>
                            </div>
                        </cfif>
                    </div>
                </div>
                
                <cfif len(trim(case_info.notes))>
                    <div class="case-notes mt-3 p-3" style="background: #1e1e1e; border-radius: 8px;">
                        <strong class="text-muted">Notes:</strong>
                        <div class="mt-2 text-light">#case_info.notes#</div>
                    </div>
                </cfif>
            </div>
            
        </div>
        
        <style>
            .section-title {
                color: #ffffff;
                font-weight: 600;
                margin-bottom: 1rem;
                padding-bottom: 0.5rem;
                border-bottom: 1px solid #444;
            }
            
            .activity-timeline {
                max-height: 400px;
                overflow-y: auto;
            }
            
            .activity-timeline::-webkit-scrollbar {
                width: 6px;
            }
            
            .activity-timeline::-webkit-scrollbar-track {
                background: #1e1e1e;
                border-radius: 3px;
            }
            
            .activity-timeline::-webkit-scrollbar-thumb {
                background: var(--tmz-red);
                border-radius: 3px;
            }
            
            .summary-content h3, .summary-content h4, .summary-content h5 {
                color: var(--tmz-red) !important;
                margin-top: 1rem;
                margin-bottom: 0.5rem;
            }
            
            .summary-content p {
                margin-bottom: 1rem;
                line-height: 1.6;
            }
            
            .summary-content ul, .summary-content ol {
                margin-left: 1.5rem;
                margin-bottom: 1rem;
            }
            
            .summary-content li {
                margin-bottom: 0.5rem;
            }
        </style>
    </cfoutput>

<cfcatch type="any">
    <cfoutput>
        <div class="alert alert-danger">
            <i class="fas fa-exclamation-triangle me-2"></i>
            <strong>Error Loading Summary:</strong><br>
            #cfcatch.message#
        </div>
    </cfoutput>
</cfcatch>
</cftry>
