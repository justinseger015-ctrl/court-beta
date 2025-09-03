<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Case Events - Alert Dashboard</title>
    <cfinclude template="head.cfm">
    <style>
        /* Alert Card Styling */
        .event-alert {
            border-left: 5px solid #007bff;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .event-alert.unacknowledged {
            border-left-color: #dc3545;
            box-shadow: 0 0 20px rgba(220, 53, 69, 0.3);
            animation: pulse-glow 2s infinite;
        }
        
        .event-alert.acknowledged {
            border-left-color: #28a745;
            opacity: 0.8;
        }
        
        @keyframes pulse-glow {
            0% { box-shadow: 0 0 5px rgba(220, 53, 69, 0.2); }
            50% { box-shadow: 0 0 25px rgba(220, 53, 69, 0.5); }
            100% { box-shadow: 0 0 5px rgba(220, 53, 69, 0.2); }
        }
        
        .event-alert:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        
        .avatar-placeholder {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.5rem;
            font-weight: bold;
        }
        
        .celebrity-avatar {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid #fff;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
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
            gap: 0.5rem;
            flex-wrap: wrap;
        }
        
        .btn-action {
            padding: 0.5rem 1rem;
            font-size: 0.875rem;
            border-radius: 25px;
            transition: all 0.3s ease;
        }
        
        .btn-action:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
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
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            padding: 0.25rem 0.75rem;
            border-radius: 15px;
            font-size: 0.8rem;
            font-weight: 500;
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
            background: rgba(220, 53, 69, 0.9);
            color: white;
            transition: all 0.3s ease;
        }
        
        .acknowledge-btn:hover {
            background: rgba(220, 53, 69, 1);
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
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-top: 4px solid #007bff;
        }
        
        .stat-number {
            font-size: 2rem;
            font-weight: bold;
            color: #007bff;
        }
        
        .stat-label {
            color: #6c757d;
            font-size: 0.9rem;
        }
        
        /* Mobile responsiveness */
        @media (max-width: 768px) {
            .action-buttons {
                justify-content: center;
            }
            
            .avatar-placeholder,
            .celebrity-avatar {
                width: 60px;
                height: 60px;
            }
            
            .event-status {
                position: static;
                margin-bottom: 0.5rem;
            }
            
            .acknowledge-btn {
                position: static;
                margin-bottom: 0.5rem;
            }
        }
    </style>
</head>
<body>

<cfinclude template="navbar.cfm">

<cfparam name="url.status" default="all">
<cfparam name="url.acknowledged" default="all">

<!--- Query for case events with celebrity matches --->
<cfquery name="events" datasource="Reach">
    SELECT 
        e.[id],
        e.[event_no],
        e.[event_date],
        e.[event_description],
        e.[additional_information],
        e.[created_at],
        e.[status],
        e.[event_result],
        e.[fk_cases],
        e.[event_url],
        e.[isDoc],
        e.[summarize],
        e.[tmz_summarize],
        ISNULL(e.[acknowledged], 0) as acknowledged,
        e.[acknowledged_at],
        e.[acknowledged_by],
        
        -- Case information
        c.[case_number],
        c.[case_name],
        c.[case_url],
        c.[status] as case_status,
        
        -- Document information
        d.[pdf_title],
        d.[summary_ai],
        d.[summary_ai_html],
        '/docs/cases/' + cast(e.fk_cases as varchar) + '/E' + cast(d.doc_id as varchar) + '.pdf' as pdf_path,
        
        -- Celebrity information (get the highest ranking match)
        celeb.[celebrity_name],
        celeb.[celebrity_image],
        celeb.[match_probability]
        
    FROM docketwatch.dbo.case_events e
    
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    
    LEFT JOIN docketwatch.dbo.documents d 
        ON e.id = d.fk_case_event 
        AND (d.pdf_type IS NULL OR d.pdf_type != 'Attachment')
    
    LEFT JOIN (
        SELECT 
            m.fk_case,
            cel.name as celebrity_name,
            cel.image_url as celebrity_image,
            m.probability_score as match_probability,
            ROW_NUMBER() OVER (PARTITION BY m.fk_case ORDER BY m.ranking_score DESC) as rn
        FROM docketwatch.dbo.case_celebrity_matches m
        INNER JOIN docketwatch.dbo.celebrities cel ON cel.id = m.fk_celebrity
        WHERE m.match_status <> 'Removed'
    ) celeb ON celeb.fk_case = e.fk_cases AND celeb.rn = 1
    
    WHERE 1=1
    <cfif url.status neq "all">
        AND e.status = <cfqueryparam value="#url.status#" cfsqltype="cf_sql_varchar">
    </cfif>
    <cfif url.acknowledged neq "all">
        AND ISNULL(e.acknowledged, 0) = <cfqueryparam value="#url.acknowledged#" cfsqltype="cf_sql_bit">
    </cfif>
    
    ORDER BY e.created_at DESC, e.acknowledged ASC
</cfquery>

<!--- Statistics queries --->
<cfquery name="stats" datasource="Reach">
    SELECT 
        COUNT(*) as total_events,
        SUM(CASE WHEN ISNULL(acknowledged, 0) = 0 THEN 1 ELSE 0 END) as unacknowledged,
        SUM(CASE WHEN ISNULL(acknowledged, 0) = 1 THEN 1 ELSE 0 END) as acknowledged,
        SUM(CASE WHEN isDoc = 1 THEN 1 ELSE 0 END) as with_documents
    FROM docketwatch.dbo.case_events e
    INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
    WHERE c.status = 'Tracked'
</cfquery>

<div class="container-fluid mt-4">
    
    <!--- Header --->
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

    <!--- Statistics Cards --->
    <div class="stats-cards">
        <cfoutput>
        <div class="stat-card">
            <div class="stat-number">#stats.total_events#</div>
            <div class="stat-label">Total Events</div>
        </div>
        <div class="stat-card" style="border-top-color: ##dc3545;">
            <div class="stat-number" style="color: ##dc3545;">#stats.unacknowledged#</div>
            <div class="stat-label">Needs Attention</div>
        </div>
        <div class="stat-card" style="border-top-color: ##28a745;">
            <div class="stat-number" style="color: ##28a745;">#stats.acknowledged#</div>
            <div class="stat-label">Acknowledged</div>
        </div>
        <div class="stat-card" style="border-top-color: ##ffc107;">
            <div class="stat-number" style="color: ##ffc107;">#stats.with_documents#</div>
            <div class="stat-label">With Documents</div>
        </div>
        </cfoutput>
    </div>

    <!--- Filter Controls --->
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
            <div class="col-md-6">
                <label class="form-label">Quick Actions</label>
                <div class="d-flex gap-2">
                    <button class="btn btn-primary btn-sm" onclick="acknowledgeAll()">
                        <i class="fas fa-check-double me-1"></i>
                        Acknowledge All Visible
                    </button>
                    <button class="btn btn-outline-secondary btn-sm" onclick="exportEvents()">
                        <i class="fas fa-download me-1"></i>
                        Export Events
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!--- Events List --->
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
            <cfloop query="events">
            <div class="col-12 mb-4">
                <cfoutput>
                <div class="card event-alert #iif(acknowledged, de('acknowledged'), de('unacknowledged'))#" 
                     id="event-#events.id#">
                     
                    <!--- Acknowledge Button --->
                    <cfif NOT acknowledged>
                        <button class="acknowledge-btn" 
                                onclick="acknowledgeEvent(#events.id#)"
                                title="Mark as acknowledged">
                            <i class="fas fa-exclamation"></i>
                        </button>
                    <cfelse>
                        <button class="acknowledge-btn acknowledged" 
                                title="Already acknowledged">
                            <i class="fas fa-check"></i>
                        </button>
                    </cfif>

                    <!--- Status Badge --->
                    <div class="event-status">
                        <span class="badge #iif(acknowledged, de('status-acknowledged'), de('status-new'))#">
                            #iif(acknowledged, de('ACKNOWLEDGED'), de('NEW'))#
                        </span>
                    </div>

                    <div class="card-body">
                        <div class="row">
                            
                            <!--- Avatar Column --->
                            <div class="col-md-2 text-center mb-3">
                                <cfif len(celebrity_name) AND len(celebrity_image)>
                                    <img src="#celebrity_image#" 
                                         alt="#celebrity_name#" 
                                         class="celebrity-avatar"
                                         onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                    <div class="avatar-placeholder" style="display:none;">
                                        #left(celebrity_name, 2)#
                                    </div>
                                    <div class="mt-2">
                                        <small class="text-muted">#celebrity_name#</small>
                                    </div>
                                <cfelseif len(celebrity_name)>
                                    <div class="avatar-placeholder">
                                        #left(celebrity_name, 2)#
                                    </div>
                                    <div class="mt-2">
                                        <small class="text-muted">#celebrity_name#</small>
                                    </div>
                                <cfelse>
                                    <div class="avatar-placeholder">
                                        <i class="fas fa-gavel"></i>
                                    </div>
                                    <div class="mt-2">
                                        <small class="text-muted">Legal Case</small>
                                    </div>
                                </cfif>
                            </div>

                            <!--- Main Content Column --->
                            <div class="col-md-7">
                                <!--- Case Information --->
                                <div class="case-info">
                                    <div class="row">
                                        <div class="col-md-6">
                                            <strong>Case Number:</strong> #case_number#
                                        </div>
                                        <div class="col-md-6">
                                            <strong>Event ##:</strong> #event_no#
                                        </div>
                                    </div>
                                    <div class="mt-1">
                                        <strong>Case Name:</strong> #case_name#
                                    </div>
                                </div>

                                <!--- Event Description --->
                                <div class="event-description">
                                    <strong>#event_description#</strong>
                                    <cfif len(additional_information)>
                                        <div class="mt-2 text-muted">
                                            #additional_information#
                                        </div>
                                    </cfif>
                                </div>

                                <!--- Event Meta Information --->
                                <div class="event-meta mt-3">
                                    <div class="d-flex flex-wrap gap-3">
                                        <div>
                                            <i class="fas fa-calendar me-1"></i>
                                            <strong>Event Date:</strong> #dateFormat(event_date, "mm/dd/yyyy")#
                                        </div>
                                        <div>
                                            <span class="timestamp-badge">
                                                <i class="fas fa-clock me-1"></i>
                                                #dateFormat(created_at, "mm/dd/yyyy")# at #timeFormat(created_at, "h:mm tt")#
                                            </span>
                                        </div>
                                        <cfif acknowledged>
                                            <div class="text-success">
                                                <i class="fas fa-check-circle me-1"></i>
                                                Acknowledged #dateFormat(acknowledged_at, "mm/dd/yyyy")#
                                            </div>
                                        </cfif>
                                    </div>
                                </div>
                            </div>

                            <!--- Actions Column --->
                            <div class="col-md-3">
                                <div class="action-buttons">
                                    <!--- PDF Actions --->
                                    <cfif len(pdf_path)>
                                        <a href="#pdf_path#" 
                                           target="_blank" 
                                           class="btn btn-success btn-action">
                                            <i class="fas fa-file-pdf me-1"></i>
                                            View PDF
                                        </a>
                                    <cfelseif isDoc AND len(event_url)>
                                        <button class="btn btn-primary btn-action get-pdf-btn"
                                                data-event-id="#events.id#"
                                                data-event-url="#event_url#"
                                                data-case-id="#fk_cases#">
                                            <i class="fas fa-download me-1"></i>
                                            Get PDF
                                        </button>
                                    </cfif>

                                    <!--- Summary Actions --->
                                    <cfif len(summary_ai_html)>
                                        <button class="btn btn-info btn-action"
                                                data-bs-toggle="modal"
                                                data-bs-target="##summaryModal#events.id#">
                                            <i class="fas fa-brain me-1"></i>
                                            View Summary
                                        </button>
                                    <cfelse>
                                        <button class="btn btn-outline-info btn-action generate-summary-btn"
                                                data-event-id="#events.id#">
                                            <i class="fas fa-magic me-1"></i>
                                            Generate Summary
                                        </button>
                                    </cfif>

                                    <!--- TMZ Article Generator --->
                                    <button class="btn btn-warning btn-action generate-tmz-btn"
                                            data-event-id="#events.id#"
                                            data-case-name="#htmlEditFormat(case_name)#">
                                        <i class="fas fa-newspaper me-1"></i>
                                        TMZ Article
                                    </button>

                                    <!--- Navigation Links --->
                                    <a href="case_details.cfm?id=#fk_cases#" 
                                       class="btn btn-outline-primary btn-action">
                                        <i class="fas fa-eye me-1"></i>
                                        Case Details
                                    </a>

                                    <cfif len(case_url)>
                                        <a href="#case_url#" 
                                           target="_blank" 
                                           class="btn btn-outline-secondary btn-action">
                                            <i class="fas fa-external-link-alt me-1"></i>
                                            External Link
                                        </a>
                                    </cfif>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                </cfoutput>
            </div>
            </cfloop>
        </cfif>
    </div>
</div>

<!--- Summary Modals --->
<cfloop query="events">
    <cfif len(summary_ai_html)>
        <cfoutput>
    <div class="modal fade" id="summaryModal#events.id#" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-brain me-2"></i>
                AI Summary - Event #events.event_no#
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <strong>Case:</strong> #case_name# (#case_number#)<br>
                            <strong>Event:</strong> #event_description#
                        </div>
                        <hr>
                        <div class="summary-content">
                            #summary_ai_html#
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
        </cfoutput>
    </cfif>
</cfloop>

<script>
$(document).ready(function() {
    
    // Auto-refresh every 30 seconds
    setInterval(function() {
        if (document.visibilityState === 'visible') {
            updateEventCounts();
        }
    }, 30000);

    // Get PDF functionality
    $('body').on('click', '.get-pdf-btn', function() {
        var button = $(this);
        var eventId = button.data('event-id');
        var eventUrl = button.data('event-url');
        var caseId = button.data('case-id');

        button.prop('disabled', true).html(`
            <span class="spinner-border spinner-border-sm me-1"></span>
            Getting PDF...
        `);

        $.ajax({
            url: 'ajax_getPacerDoc.cfm',
            method: 'POST',
            data: {
                docID: eventId,
                eventURL: eventUrl,
                caseID: caseId
            },
            dataType: 'json',
            success: function(response) {
                if (response.STATUS === 'SUCCESS') {
                    button.replaceWith(`
                        <a href="${response.FILEPATH}" 
                           target="_blank" 
                           class="btn btn-success btn-action">
                            <i class="fas fa-file-pdf me-1"></i>
                            View PDF
                        </a>
                    `);
                    
                    showNotification('success', 'PDF downloaded successfully!');
                } else {
                    showNotification('error', 'Failed to download PDF: ' + (response.MESSAGE || 'Unknown error'));
                    button.prop('disabled', false).html(`
                        <i class="fas fa-download me-1"></i>
                        Get PDF
                    `);
                }
            },
            error: function() {
                showNotification('error', 'Network error occurred');
                button.prop('disabled', false).html(`
                    <i class="fas fa-download me-1"></i>
                    Get PDF
                `);
            }
        });
    });

    // Generate Summary functionality
    $('body').on('click', '.generate-summary-btn', function() {
        var button = $(this);
        var eventId = button.data('event-id');

        button.prop('disabled', true).html(`
            <span class="spinner-border spinner-border-sm me-1"></span>
            Generating...
        `);

        $.ajax({
            url: 'ajax_generateSummary.cfm',
            method: 'POST',
            data: { eventId: eventId },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    button.replaceWith(`
                        <button class="btn btn-info btn-action"
                                data-bs-toggle="modal"
                                data-bs-target="#summaryModal${eventId}">
                            <i class="fas fa-brain me-1"></i>
                            View Summary
                        </button>
                    `);
                    
                    // Add the modal to the page
                    $('body').append(response.modalHtml);
                    
                    showNotification('success', 'Summary generated successfully!');
                } else {
                    showNotification('error', 'Failed to generate summary: ' + (response.message || 'Unknown error'));
                    button.prop('disabled', false).html(`
                        <i class="fas fa-magic me-1"></i>
                        Generate Summary
                    `);
                }
            },
            error: function() {
                showNotification('error', 'Network error occurred');
                button.prop('disabled', false).html(`
                    <i class="fas fa-magic me-1"></i>
                    Generate Summary
                `);
            }
        });
    });

    // Generate TMZ Article functionality
    $('body').on('click', '.generate-tmz-btn', function() {
        var button = $(this);
        var eventId = button.data('event-id');
        var caseName = button.data('case-name');

        button.prop('disabled', true).html(`
            <span class="spinner-border spinner-border-sm me-1"></span>
            Writing...
        `);

        // Simulate TMZ article generation
        setTimeout(function() {
            Swal.fire({
                title: 'TMZ Article Generated!',
                html: `
                    <div class="text-left">
                        <h6>BREAKING: ${caseName} - New Court Filing!</h6>
                        <p class="small text-muted">
                            [MOCK ARTICLE] In a shocking turn of events, new court documents have been filed in the ${caseName} case. 
                            Sources close to the situation say this could be a game-changer. Stay tuned for more updates as this story develops...
                        </p>
                        <div class="mt-3">
                            <button class="btn btn-sm btn-primary me-2">Share on Social</button>
                            <button class="btn btn-sm btn-outline-secondary">Save Draft</button>
                        </div>
                    </div>
                `,
                icon: 'success',
                width: 600,
                showConfirmButton: false,
                timer: 5000
            });

            button.prop('disabled', false).html(`
                <i class="fas fa-newspaper me-1"></i>
                TMZ Article
            `);
        }, 2000);
    });
});

// Acknowledge single event
function acknowledgeEvent(eventId) {
    $.ajax({
        url: 'ajax_acknowledgeEvent.cfm',
        method: 'POST',
        data: { eventId: eventId },
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                const eventCard = $('#event-' + eventId);
                eventCard.removeClass('unacknowledged').addClass('acknowledged');
                
                // Update acknowledge button
                const ackBtn = eventCard.find('.acknowledge-btn');
                ackBtn.addClass('acknowledged').html('<i class="fas fa-check"></i>').prop('onclick', null);
                
                // Update status badge
                eventCard.find('.event-status .badge').removeClass('status-new').addClass('status-acknowledged').text('ACKNOWLEDGED');
                
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

// Acknowledge all visible events
function acknowledgeAll() {
    const unacknowledged = $('.event-alert.unacknowledged');
    if (unacknowledged.length === 0) {
        showNotification('info', 'No events need acknowledgment');
        return;
    }

    Swal.fire({
        title: 'Acknowledge All Events?',
        text: `This will acknowledge ${unacknowledged.length} visible events.`,
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

// Update filters
function updateFilters() {
    const status = $('#statusFilter').val();
    const acknowledged = $('#ackFilter').val();
    
    let url = window.location.pathname + '?';
    const params = [];
    
    if (status !== 'all') params.push('status=' + encodeURIComponent(status));
    if (acknowledged !== 'all') params.push('acknowledged=' + encodeURIComponent(acknowledged));
    
    window.location.href = url + params.join('&');
}

// Export events (placeholder)
function exportEvents() {
    showNotification('info', 'Export functionality coming soon!');
}

// Update event counts
function updateEventCounts() {
    $.ajax({
        url: 'ajax_getEventCounts.cfm',
        method: 'GET',
        dataType: 'json',
        success: function(data) {
            $('.stat-card:nth-child(1) .stat-number').text(data.total);
            $('.stat-card:nth-child(2) .stat-number').text(data.unacknowledged);
            $('.stat-card:nth-child(3) .stat-number').text(data.acknowledged);
            $('.stat-card:nth-child(4) .stat-number').text(data.withDocs);
        }
    });
}

// Show notifications
function showNotification(type, message) {
    if (typeof Swal !== 'undefined') {
        const icons = { success: 'success', error: 'error', info: 'info' };
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
