<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>DocketWatch Monitor - Real-Time Legal Activity</title>
    <cfinclude template="head.cfm">
    <style>
        /* DocketWatch Monitor Styling - TMZ Brand Colors */
        :root {
            --tmz-red: #d60000;
            --tmz-dark-red: #b50000;
            --priority-urgent: #ff4757;
            --priority-normal: #ffa502;
            --priority-low: #2ed573;
            --background-dark: #1a1a1a;
            --card-dark: #2c2c2c;
        }

        body {
            background: linear-gradient(135deg, #1a1a1a 0%, #2c2c2c 100%);
            color: #ffffff;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        /* Monitor Header */
        .monitor-header {
            background: linear-gradient(135deg, var(--tmz-red) 0%, var(--tmz-dark-red) 100%);
            color: white;
            padding: 1.5rem 0;
            box-shadow: 0 4px 15px rgba(214, 0, 0, 0.3);
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .monitor-title {
            font-size: 2.5rem;
            font-weight: 700;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            margin: 0;
        }

        .monitor-subtitle {
            font-size: 1.1rem;
            opacity: 0.9;
            margin-top: 0.25rem;
        }

        .live-indicator {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            background: rgba(255,255,255,0.2);
            padding: 0.5rem 1rem;
            border-radius: 25px;
            backdrop-filter: blur(10px);
        }

        .live-dot {
            width: 12px;
            height: 12px;
            background: #2ed573;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.7; transform: scale(1.2); }
            100% { opacity: 1; transform: scale(1); }
        }

        /* Control Panel */
        .control-panel {
            background: var(--card-dark);
            border-radius: 8px;
            padding: 1rem;
            margin: 1rem 0;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }

        .filter-controls {
            display: flex;
            gap: 0.75rem;
            flex-wrap: wrap;
            align-items: center;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 0.25rem;
        }

        .filter-group label {
            font-size: 0.8rem;
            color: #cccccc;
            font-weight: 500;
        }

        .form-select, .form-control {
            background: #3a3a3a;
            border: 1px solid #555;
            color: #ffffff;
            border-radius: 6px;
            padding: 0.375rem 0.75rem;
            font-size: 0.875rem;
        }

        .form-select:focus, .form-control:focus {
            background: #3a3a3a;
            border-color: var(--tmz-red);
            color: #ffffff;
            box-shadow: 0 0 0 0.2rem rgba(214, 0, 0, 0.25);
        }

        /* Update Cards */
        .updates-container {
            margin-top: 2rem;
        }

        .update-card {
            background: var(--card-dark);
            border-radius: 10px;
            padding: 1.25rem;
            margin-bottom: 1rem;
            border-left: 4px solid transparent;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            position: relative;
            overflow: hidden;
        }

        .update-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
        }

        .update-card.priority-1 {
            border-left-color: var(--priority-urgent);
            animation: urgentGlow 3s infinite;
        }

        .update-card.priority-2 {
            border-left-color: var(--priority-normal);
        }

        .update-card.priority-3 {
            border-left-color: var(--priority-low);
            opacity: 0.8;
        }

        .update-card.acknowledged {
            opacity: 0.6;
            background: #1e1e1e;
        }

        @keyframes urgentGlow {
            0%, 100% { box-shadow: 0 4px 15px rgba(255, 71, 87, 0.3); }
            50% { box-shadow: 0 4px 25px rgba(255, 71, 87, 0.6); }
        }

        .new-update {
            animation: slideInFromTop 0.5s ease-out;
        }

        @keyframes slideInFromTop {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* Card Content */
        .update-header {
            display: flex;
            justify-content: between;
            align-items: flex-start;
            margin-bottom: 1rem;
        }

        .update-meta {
            display: flex;
            flex-direction: column;
            gap: 0.25rem;
        }

        .timestamp {
            font-size: 0.9rem;
            color: #888;
            font-weight: 500;
        }

        .case-info {
            color: var(--tmz-red);
            font-weight: 600;
            font-size: 1.1rem;
        }

        .tool-badge {
            display: inline-block;
            background: #555;
            color: #fff;
            padding: 0.25rem 0.75rem;
            border-radius: 15px;
            font-size: 0.8rem;
            font-weight: 500;
            text-transform: uppercase;
        }

        .priority-badge {
            position: absolute;
            top: 1rem;
            right: 1rem;
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 600;
            text-transform: uppercase;
        }

        .priority-badge.priority-1 {
            background: var(--priority-urgent);
            color: white;
        }

        .priority-badge.priority-2 {
            background: var(--priority-normal);
            color: white;
        }

        .priority-badge.priority-3 {
            background: var(--priority-low);
            color: white;
        }

        .summary-preview {
            margin: 1rem 0;
            font-size: 0.95rem;
            line-height: 1.5;
            color: #ddd;
        }

        .parties-info {
            margin: 0.75rem 0;
            font-size: 0.9rem;
            color: #bbb;
        }

        .parties-info i {
            color: #888;
        }

        /* Action Buttons */
        .action-buttons {
            display: flex;
            gap: 0.75rem;
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #444;
            flex-wrap: wrap;
            align-items: center;
        }

        .btn-monitor {
            padding: 0.5rem 1rem;
            border-radius: 6px;
            font-weight: 500;
            font-size: 0.9rem;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            transition: all 0.2s ease;
            border: none;
            cursor: pointer;
            white-space: nowrap;
        }

        .btn-acknowledge {
            background: #28a745;
            color: white;
        }

        .btn-acknowledge:hover {
            background: #218838;
            color: white;
        }

        .btn-summary {
            background: var(--tmz-red);
            color: white;
        }

        .btn-summary:hover {
            background: var(--tmz-dark-red);
            color: white;
        }

        .btn-case {
            background: #6c757d;
            color: white;
        }

        .btn-case:hover {
            background: #5a6268;
            color: white;
        }

        .btn-pdf {
            background: #17a2b8;
            color: white;
        }

        .btn-pdf:hover {
            background: #138496;
            color: white;
        }

        /* Celebrity Integration */
        .celeb-info {
            display: flex;
            align-items: center;
            gap: 1rem;
            margin: 1rem 0;
            padding: 0.75rem 1rem;
            background: rgba(214, 0, 0, 0.08);
            border-radius: 8px;
            border-left: 3px solid var(--tmz-red);
            border-top: 1px solid rgba(214, 0, 0, 0.2);
            border-right: 1px solid rgba(214, 0, 0, 0.1);
            border-bottom: 1px solid rgba(214, 0, 0, 0.1);
        }

        .celeb-avatar {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid var(--tmz-red);
            box-shadow: 0 2px 8px rgba(214, 0, 0, 0.3);
        }

        .celeb-details {
            flex: 1;
        }

        .celeb-name {
            font-weight: 600;
            color: var(--tmz-red);
            margin-bottom: 0.25rem;
            font-size: 0.95rem;
        }

        .celeb-role {
            font-size: 0.85rem;
            color: #bbb;
        }

        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 4rem 2rem;
            color: #888;
        }

        .empty-state i {
            font-size: 4rem;
            margin-bottom: 1rem;
            color: #555;
        }

        /* Loading States */
        .loading-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0,0,0,0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 2000;
        }

        .loading-spinner {
            width: 50px;
            height: 50px;
            border: 3px solid #555;
            border-top: 3px solid var(--tmz-red);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Stats Bar */
        .stats-bar {
            display: flex;
            gap: 1rem;
            margin-bottom: 0.75rem;
        }

        .stat-item {
            text-align: center;
        }

        .stat-number {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--tmz-red);
        }

        .stat-label {
            font-size: 0.75rem;
            color: #888;
            text-transform: uppercase;
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .monitor-title {
                font-size: 1.75rem;
            }
            
            .filter-controls {
                flex-direction: column;
                align-items: stretch;
                gap: 0.5rem;
            }
            
            .action-buttons {
                flex-direction: column;
            }
            
            .stats-bar {
                flex-direction: column;
                gap: 0.5rem;
            }
            
            .control-panel {
                padding: 0.75rem;
                margin: 0.5rem 0;
            }
        }

        @media (max-width: 480px) {
            .monitor-title {
                font-size: 1.5rem;
            }
            
            .stat-number {
                font-size: 1.25rem;
            }
            
            .stat-label {
                font-size: 0.7rem;
            }
        }
    </style>
</head>
<body>

<cfinclude template="navbar.cfm">

<!-- Monitor Header -->
<div class="monitor-header">
    <div class="container">
        <div class="d-flex justify-content-between align-items-center">
            <div>
                <h1 class="monitor-title">
                    <i class="fas fa-radar me-3"></i>
                    DocketWatch Monitor
                </h1>
                <p class="monitor-subtitle">Real-Time Legal Activity Dashboard</p>
            </div>
            <div class="live-indicator">
                <div class="live-dot"></div>
                <span>LIVE</span>
            </div>
        </div>
    </div>
</div>

<div class="container-fluid">
    
    <!-- Control Panel -->
    <div class="control-panel">
        <div class="row">
            <div class="col-12">
                <div class="stats-bar">
                    <div class="stat-item">
                        <div class="stat-number" id="totalUpdates">0</div>
                        <div class="stat-label">Total Updates</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number" id="urgentUpdates">0</div>
                        <div class="stat-label">Urgent</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number" id="acknowledgedUpdates">0</div>
                        <div class="stat-label">Acknowledged</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number" id="lastRefresh">--</div>
                        <div class="stat-label">Last Refresh</div>
                    </div>
                </div>
            </div>
        </div>
        
        <hr style="border-color: #555; margin: 1.5rem 0;">
        
        <div class="filter-controls">
            <div class="filter-group">
                <label for="priorityFilter">Priority Filter</label>
                <select id="priorityFilter" class="form-select">
                    <option value="">All Priorities</option>
                    <option value="1">Urgent Only</option>
                    <option value="2">Normal Only</option>
                    <option value="3">Low Only</option>
                </select>
            </div>
            
            <div class="filter-group">
                <label for="toolFilter">Tool Filter</label>
                <select id="toolFilter" class="form-select">
                    <option value="">All Tools</option>
                    <option value="PACER">PACER</option>
                    <option value="MAPS">MAPS</option>
                    <option value="OTHER">Other</option>
                </select>
            </div>
            
            <div class="filter-group">
                <label for="statusFilter">Status Filter</label>
                <select id="statusFilter" class="form-select">
                    <option value="">All Updates</option>
                    <option value="new">Unacknowledged</option>
                    <option value="ack">Acknowledged</option>
                </select>
            </div>
            
            <div class="filter-group">
                <label for="searchFilter">Search</label>
                <input type="text" id="searchFilter" class="form-control" placeholder="Case name, number, or description...">
            </div>
            
            <div class="filter-group" style="margin-top: 1.5rem;">
                <button id="refreshBtn" class="btn btn-monitor btn-case">
                    <i class="fas fa-sync-alt"></i>
                    Refresh Now
                </button>
            </div>
        </div>
    </div>

    <!-- Updates Container -->
    <div class="updates-container" id="updatesContainer">
        <div class="empty-state" id="emptyState">
            <i class="fas fa-satellite-dish"></i>
            <h3>Monitoring for Updates...</h3>
            <p>Waiting for new legal case activity to appear.</p>
        </div>
    </div>

</div>

<!-- Summary Modal -->
<div class="modal fade" id="summaryModal" tabindex="-1" aria-labelledby="summaryModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content" style="background: var(--card-dark); border: none;">
            <div class="modal-header" style="border-bottom: 1px solid #555;">
                <h5 class="modal-title" id="summaryModalLabel" style="color: white;">
                    <i class="fas fa-robot me-2"></i>AI Summary
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="summaryContent" style="color: white;">
                <!-- Summary content will be loaded here -->
            </div>
            <div class="modal-footer" style="border-top: 1px solid #555;">
                <button type="button" class="btn btn-monitor btn-case" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<!-- Loading Overlay -->
<div class="loading-overlay" id="loadingOverlay" style="display: none;">
    <div class="loading-spinner"></div>
</div>

<cfinclude template="footer_script.cfm">

<script>
$(document).ready(function() {
    // Monitor Configuration
    const POLLING_INTERVAL = 300000; // 5 minutes (300,000 milliseconds)
    const SOUND_ENABLED = true;
    
    let currentFilters = {
        priority: '',
        tool: '',
        status: '',
        search: ''
    };
    
    let lastUpdateId = 0; // Always start from 0 to get all records
    let updatesList = [];
    
    // Initialize Monitor
    initializeMonitor();
    
    function initializeMonitor() {
        console.log('🚀 DocketWatch Monitor Starting...');
        
        // Set up event listeners
        setupEventListeners();
        
        // Initial data load
        loadUpdates();
        
        // Start polling
        setInterval(loadUpdates, POLLING_INTERVAL);
        
        console.log('✅ Monitor initialized successfully');
    }
    
    function setupEventListeners() {
        // Filter controls
        $('#priorityFilter, #toolFilter, #statusFilter').on('change', function() {
            updateFilters();
            applyFilters();
        });
        
        $('#searchFilter').on('input', debounce(function() {
            updateFilters();
            applyFilters();
        }, 300));
        
        // Manual refresh
        $('#refreshBtn').on('click', function() {
            loadUpdates(true);
        });
        
        // Acknowledge buttons (delegated)
        $(document).on('click', '.btn-acknowledge', function() {
            const updateId = $(this).data('update-id');
            acknowledgeUpdate(updateId);
        });
        
        // Summary buttons (delegated)
        $(document).on('click', '.btn-summary', function(e) {
            // Don't trigger if this is the refresh button
            if ($(this).attr('id') === 'refreshBtn') {
                return;
            }
            
            const caseId = $(this).data('case-id');
            showSummaryModal(caseId);
        });
    }
    
    function updateFilters() {
        currentFilters = {
            priority: $('#priorityFilter').val(),
            tool: $('#toolFilter').val(),
            status: $('#statusFilter').val(),
            search: $('#searchFilter').val().toLowerCase()
        };
    }
    
    function loadUpdates(forceRefresh = false) {
        if (forceRefresh) {
            showLoading();
            // Reset lastUpdateId to get all records on force refresh
            lastUpdateId = 0;
            updatesList = []; // Clear existing updates
        }
        
        // Make AJAX call to get updates
        $.ajax({
            url: 'docketwatch_monitor_data.cfm?bypass=1',
            method: 'GET',
            data: {
                last_update_id: forceRefresh ? 0 : lastUpdateId
            },
            dataType: 'json',
            success: function(response) {
                hideLoading();
                
                if (response.success) {
                    processUpdates(response.data, response.stats);
                    updateStats(response.stats);
                } else {
                    console.error('Failed to load updates:', response.message);
                }
                
                updateLastRefreshTime();
            },
            error: function(xhr, status, error) {
                hideLoading();
                console.error('Error loading updates:', error);
                updateLastRefreshTime();
            }
        });
    }
    
    function processUpdates(newUpdates, stats) {
        if (!newUpdates || newUpdates.length === 0) {
            return;
        }
        
        // Add new updates to our list
        newUpdates.forEach(update => {
            updatesList.unshift(update); // Add to beginning
            
            // Check if this is actually new (higher ID than last seen)
            if (update.id > lastUpdateId) {
                lastUpdateId = update.id;
                
                // Play sound for urgent updates
                if (update.priority_level === 1 && SOUND_ENABLED) {
                    playNotificationSound();
                }
            }
        });
        
        // Render all updates
        renderUpdates();
    }
    
    function renderUpdates() {
        const container = $('#updatesContainer');
        const emptyState = $('#emptyState');
        
        // Filter updates
        const filteredUpdates = applyFiltersToList(updatesList);
        
        if (filteredUpdates.length === 0) {
            container.html(emptyState);
            return;
        }
        
        // Hide empty state
        emptyState.hide();
        
        // Build HTML
        let html = '';
        filteredUpdates.forEach(update => {
            html += buildUpdateCard(update);
        });
        
        container.html(html);
        
        // Fetch Wikidata images for celebrities
        fetchWikidataImages();
        
        // Animate new cards
        $('.update-card').each(function(index) {
            const $card = $(this);
            setTimeout(() => {
                $card.addClass('new-update');
            }, index * 100);
        });
    }
    
    function buildUpdateCard(update) {
        const timeAgo = getTimeAgo(update.created_at);
        const priorityClass = `priority-${update.priority_level}`;
        const acknowledgedClass = update.acknowledged ? 'acknowledged' : '';
        const priorityText = getPriorityText(update.priority_level);
        
        let celebHtml = '';
        if (update.celebrity_info) {
            celebHtml = `
                <div class="celeb-info">
                    <img src="../services/avatar_placeholder.png" 
                         data-wikiid="${update.celebrity_info.wiki_id || ''}"
                         alt="${update.celebrity_info.name}" 
                         class="celeb-avatar">
                    <div class="celeb-details">
                        <div class="celeb-name">${update.celebrity_info.name}</div>
                        <div class="celeb-role">${update.celebrity_info.role || 'Celebrity'}</div>
                    </div>
                </div>
            `;
        }
        
        return `
            <div class="update-card ${priorityClass} ${acknowledgedClass}" data-update-id="${update.id}">
                <div class="priority-badge ${priorityClass}">${priorityText}</div>
                
                <div class="update-header">
                    <div class="update-meta">
                        <div class="timestamp">
                            <i class="fas fa-clock me-1"></i>${timeAgo}
                        </div>
                        <div class="case-info">
                            ${update.case_number} - ${update.case_name}
                        </div>
                        <div class="tool-badge">${update.tool_name || 'Unknown'}</div>
                    </div>
                </div>
                
                ${update.parties ? `<div class="parties-info"><i class="fas fa-users me-1"></i>${update.parties}</div>` : ''}
                
                <div class="summary-preview">
                    ${update.summary_preview || 'No summary available for this update.'}
                </div>
                
                ${celebHtml}
                
                <div class="action-buttons">
                    ${!update.acknowledged ? `
                        <button class="btn-monitor btn-acknowledge" data-update-id="${update.id}">
                            <i class="fas fa-check"></i>
                            Acknowledge
                        </button>
                    ` : `
                        <span class="btn-monitor btn-case" style="opacity: 0.6;">
                            <i class="fas fa-check"></i>
                            Acknowledged
                        </span>
                    `}
                    
                    <button class="btn-monitor btn-summary" data-case-id="${update.case_id}">
                        <i class="fas fa-robot"></i>
                        AI Summary
                    </button>
                    
                    <a href="case_details.cfm?id=${update.case_id}" class="btn-monitor btn-case" target="_blank">
                        <i class="fas fa-external-link-alt"></i>
                        Full Case
                    </a>
                    
                    ${update.pdf_links ? `
                        <div class="btn-group">
                            ${update.pdf_links}
                        </div>
                    ` : ''}
                </div>
            </div>
        `;
    }
    
    function applyFiltersToList(list) {
        return list.filter(update => {
            // Priority filter
            if (currentFilters.priority && update.priority_level != currentFilters.priority) {
                return false;
            }
            
            // Tool filter
            if (currentFilters.tool && update.tool_name !== currentFilters.tool) {
                return false;
            }
            
            // Status filter
            if (currentFilters.status === 'new' && update.acknowledged) {
                return false;
            }
            if (currentFilters.status === 'ack' && !update.acknowledged) {
                return false;
            }
            
            // Search filter
            if (currentFilters.search) {
                const searchText = currentFilters.search;
                const searchFields = [
                    update.case_name,
                    update.case_number,
                    update.summary_preview,
                    update.parties
                ].join(' ').toLowerCase();
                
                if (!searchFields.includes(searchText)) {
                    return false;
                }
            }
            
            return true;
        });
    }
    
    function applyFilters() {
        renderUpdates();
    }
    
    function acknowledgeUpdate(updateId) {
        $.ajax({
            url: 'docketwatch_monitor_acknowledge.cfm?bypass=1',
            method: 'POST',
            data: {
                update_id: updateId
            },
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    // Update local data
                    const update = updatesList.find(u => u.id == updateId);
                    if (update) {
                        update.acknowledged = true;
                    }
                    
                    // Re-render
                    renderUpdates();
                    
                    // Show success
                    showNotification('Update acknowledged successfully', 'success');
                } else {
                    showNotification('Failed to acknowledge update', 'error');
                }
            },
            error: function() {
                showNotification('Error acknowledging update', 'error');
            }
        });
    }
    
    function showSummaryModal(caseId) {
        console.log('🔍 Opening summary modal for case ID:', caseId);
        console.log('🔍 Case ID type:', typeof caseId);
        
        const modal = new bootstrap.Modal($('#summaryModal')[0]);
        $('#summaryContent').html('<div class="text-center"><div class="loading-spinner"></div></div>');
        modal.show();
        
        // Let's also test the URL directly
        const testUrl = `get_case_summary.cfm?bypass=1&case_id=${caseId}`;
        console.log('🔍 Test URL:', testUrl);
        
        $.ajax({
            url: 'get_case_summary.cfm?bypass=1',
            method: 'GET',
            data: { case_id: caseId },
            success: function(response) {
                console.log('✅ Summary response received for case:', caseId);
                console.log('📄 Response preview:', response.substring(0, 200) + '...');
                $('#summaryContent').html(response);
            },
            error: function(xhr, status, error) {
                console.error('❌ Summary error:', {
                    caseId: caseId,
                    status: status,
                    error: error,
                    responseText: xhr.responseText,
                    statusCode: xhr.status
                });
                
                let errorDetail = `
                    <div class="alert alert-danger">
                        <h6><i class="fas fa-exclamation-triangle me-2"></i>Error Loading Summary</h6>
                        <p><strong>Case ID:</strong> ${caseId}</p>
                        <p><strong>Status:</strong> ${status}</p>
                        <p><strong>Error:</strong> ${error}</p>
                        <p><strong>HTTP Status:</strong> ${xhr.status}</p>
                        ${xhr.responseText ? `<p><strong>Response:</strong><br><pre style="font-size: 0.8rem; max-height: 200px; overflow-y: auto;">${xhr.responseText}</pre></p>` : ''}
                    </div>
                `;
                
                $('#summaryContent').html(errorDetail);
            }
        });
    }
    
    function updateStats(stats) {
        $('#totalUpdates').text(stats.total || 0);
        $('#urgentUpdates').text(stats.urgent || 0);
        $('#acknowledgedUpdates').text(stats.acknowledged || 0);
    }
    
    function updateLastRefreshTime() {
        const now = new Date();
        const timeString = now.toLocaleTimeString();
        $('#lastRefresh').text(timeString);
    }
    
    function showLoading() {
        $('#loadingOverlay').show();
    }
    
    function hideLoading() {
        $('#loadingOverlay').hide();
    }
    
    function playNotificationSound() {
        // Create audio element for notification
        const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+Dx0HYTCC+U3+b5jiMCJ3nF5taQQAh...'); // Base64 encoded notification sound
        audio.volume = 0.3;
        audio.play().catch(e => {
            console.log('Could not play notification sound:', e);
        });
    }
    
    function showNotification(message, type) {
        // Simple notification system
        const alertClass = type === 'success' ? 'alert-success' : 'alert-danger';
        const notification = $(`
            <div class="alert ${alertClass} alert-dismissible fade show position-fixed" 
                 style="top: 20px; right: 20px; z-index: 9999; min-width: 300px;">
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `);
        
        $('body').append(notification);
        
        // Auto-dismiss after 3 seconds
        setTimeout(() => {
            notification.alert('close');
        }, 3000);
    }
    
    function getTimeAgo(dateString) {
        const now = new Date();
        const past = new Date(dateString);
        const diffMs = now - past;
        const diffMins = Math.floor(diffMs / 60000);
        
        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins}m ago`;
        
        const diffHours = Math.floor(diffMins / 60);
        if (diffHours < 24) return `${diffHours}h ago`;
        
        const diffDays = Math.floor(diffHours / 24);
        return `${diffDays}d ago`;
    }
    
    function getPriorityText(level) {
        switch(level) {
            case 1: return 'URGENT';
            case 2: return 'NORMAL';
            case 3: return 'LOW';
            default: return 'UNKNOWN';
        }
    }
    
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
    
    function fetchWikidataImages() {
        document.querySelectorAll('.celeb-avatar').forEach(img => {
            var wikiId = img.getAttribute('data-wikiid');
            if (wikiId) {
                fetch('https://www.wikidata.org/wiki/Special:EntityData/' + wikiId + '.json')
                    .then(response => response.json())
                    .then(data => {
                        try {
                            var entities = data.entities;
                            var entity = entities[wikiId];
                            var claims = entity.claims;
                            var p18 = claims.P18[0].mainsnak.datavalue.value;
                            var fileName = encodeURIComponent(p18);
                            var imageUrl = 'https://commons.wikimedia.org/wiki/Special:FilePath/' + fileName;
                            img.setAttribute('src', imageUrl);
                        } catch (error) {
                            console.log('No image found for celebrity wiki ID:', wikiId);
                        }
                    })
                    .catch(error => console.error('Error loading celebrity image for', wikiId, error));
            }
        });
    }
});
</script>

</body>
</html>
