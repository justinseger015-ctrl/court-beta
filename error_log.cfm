<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>DocketWatch - Error Log</title>
    <cfinclude template="head.cfm">
    <style>
        .severity-critical { color: #dc3545; font-weight: bold; }
        .severity-error { color: #fd7e14; }
        .severity-warning { color: #ffc107; }
        .severity-info { color: #0dcaf0; }
        .resolved-yes { color: #198754; }
        .resolved-no { color: #dc3545; }
        .error-row.resolved { opacity: 0.7; }
        
        /* Column width constraints */
        .date-column { max-width: 75px; width: 75px; font-size: 13px; }
        .time-column { max-width: 75px; width: 75px; font-size: 13px; }
        .script-column { 
            min-width: 180px;
            max-width: 200px; 
            width: 180px; 
            word-break: break-word;
            font-size: 13px;
        }
        .severity-column { max-width: 80px; width: 80px; font-size: 13px; }
        .error-type-column { 
            min-width: 150px;
            max-width: 180px; 
            width: 150px; 
            word-break: break-word;
            font-size: 13px;
        }
        .error-message-column { 
            min-width: 350px; 
            max-width: 450px; 
            width: 40%; 
            word-break: break-word;
            font-size: 13px;
        }
        .context-column { max-width: 80px; width: 80px; font-size: 13px; }
        .stack-trace-column { max-width: 80px; width: 80px; font-size: 13px; }
        .email-column { max-width: 60px; width: 60px; font-size: 13px; }
        .resolved-column { max-width: 100px; width: 100px; font-size: 13px; }
        .actions-column { max-width: 80px; width: 80px; font-size: 13px; }
        
        .nowrap {
            white-space: nowrap;
        }
        .btn-resolve {
            padding: 2px 8px;
            font-size: 0.75rem;
        }
        
        /* Ensure table uses full width efficiently */
        #errorLogTable {
            table-layout: fixed;
            width: 100% !important;
        }
    </style>
</head>
<body>

<cfinclude template="navbar.cfm">

<div class="container-fluid mt-4">
    <div class="row">
        <div class="col-12">
            <h2 class="mb-4">Error Log & Notifications</h2>
            
            <!-- Filter Controls -->
            <div class="row mb-3">
                <div class="col-md-3">
                    <label for="severityFilter" class="form-label">Severity</label>
                    <select id="severityFilter" class="form-select">
                        <option value="">All Severities</option>
                        <option value="CRITICAL">Critical</option>
                        <option value="ERROR">Error</option>
                        <option value="WARNING">Warning</option>
                        <option value="INFO">Info</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label for="scriptFilter" class="form-label">Script</label>
                    <select id="scriptFilter" class="form-select">
                        <option value="">All Scripts</option>
                        <!-- Will be populated via AJAX -->
                    </select>
                </div>
                <div class="col-md-3">
                    <label for="resolvedFilter" class="form-label">Status</label>
                    <select id="resolvedFilter" class="form-select">
                        <option value="">All</option>
                        <option value="0">Unresolved</option>
                        <option value="1">Resolved</option>
                    </select>
                </div>
                <div class="col-md-3 d-flex align-items-end">
                    <button id="refreshBtn" class="btn btn-primary me-2">
                        <i class="fa-solid fa-refresh"></i> Refresh
                    </button>
                    <button id="clearFiltersBtn" class="btn btn-outline-secondary">
                        Clear Filters
                    </button>
                </div>
            </div>

            <table id="errorLogTable" class="table table-striped table-bordered w-100">
                <thead class="table-dark">
                    <tr>
                        <th class="date-column">Date</th>
                        <th class="time-column">Time</th>
                        <th class="script-column">Script</th>
                        <th class="severity-column">Severity</th>
                        <th class="error-type-column">Error Type</th>
                        <th class="error-message-column">Error Message</th>
                        <th class="context-column">Context</th>
                        <th class="stack-trace-column">Stack Trace</th>
                        <th class="email-column">Email Sent</th>
                        <th class="resolved-column">Resolved</th>
                        <th class="actions-column">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <!--- Will be populated via AJAX --->
                </tbody>
            </table>
        </div>
    </div>
</div>

<cfinclude template="footer_script.cfm">

<script>
$(document).ready(function() {
    var table = $('#errorLogTable').DataTable({
        ajax: {
            url: 'error_log_data.cfm',
            dataSrc: ''
        },
        columns: [
            {
                data: "sortable_created_at",
                className: "date-column nowrap",
                render: function (data, type, row) {
                    if (type === 'display') {
                        return row.formatted_date || "(No Date)";
                    }
                    return data;
                }
            },
            {
                data: "sortable_created_at",
                className: "time-column nowrap",
                render: function (data, type, row) {
                    if (type === 'display') {
                        return row.formatted_time || "(No Time)";
                    }
                    return data;
                }
            },
            {
                data: 'script_name',
                className: "script-column"
            },
            {
                data: 'severity',
                className: "severity-column nowrap text-center",
                render: function(data, type, row) {
                    if (type === 'display') {
                        const severityClass = `severity-${data.toLowerCase()}`;
                        return `<span class="${severityClass}">${data}</span>`;
                    }
                    return data;
                }
            },
            {
                data: 'error_type',
                className: "error-type-column"
            },
            {
                data: 'error_message',
                className: "error-message-column",
                render: function (data, type, row) {
                    if (type === 'display' && data && data.length > 200) {
                        var shortText = data.substr(0, 200);
                        shortText = shortText.substr(0, Math.min(shortText.length, shortText.lastIndexOf(" ")));

                        return `
                            <div class="error-message-wrapper">
                                <span class="short-desc">${shortText}...</span>
                                <span class="full-desc" style="display: none;">${data}</span>
                                <a href="#" class="read-more ms-1">Read More</a>
                            </div>`;
                    }
                    return data;
                }
            },
            {
                data: 'additional_context',
                className: "context-column text-center",
                render: function (data, type, row) {
                    if (!data) return '<em class="text-muted">None</em>';
                    
                    if (type === 'display') {
                        return `<button class="btn btn-sm btn-outline-secondary context-btn" data-error-id="${row.id}" data-context="${data.replace(/"/g, '&quot;')}">
                                    <i class="fa-solid fa-info-circle"></i> View
                                </button>`;
                    }
                    return data;
                }
            },
            {
                data: 'stack_trace',
                className: "stack-trace-column text-center",
                render: function (data, type, row) {
                    if (!data) return '<em class="text-muted">None</em>';
                    
                    if (type === 'display') {
                        return `<button class="btn btn-sm btn-outline-info" onclick="showStackTrace(${row.id})">
                                    <i class="fa-solid fa-code"></i> View
                                </button>`;
                    }
                    return data;
                }
            },
            {
                data: 'email_sent',
                className: "email-column nowrap text-center",
                render: function(data, type, row) {
                    if (type === 'display') {
                        if (data == 1) {
                            return `<i class="fa-solid fa-check text-success" title="Email sent: ${row.formatted_email_sent_timestamp}"></i>`;
                        } else {
                            return `<i class="fa-solid fa-times text-danger" title="No email sent"></i>`;
                        }
                    }
                    return data;
                }
            },
            {
                data: 'resolved',
                className: "resolved-column nowrap text-center",
                render: function(data, type, row) {
                    if (type === 'display') {
                        if (data == 1) {
                            return `<span class="resolved-yes">
                                        <i class="fa-solid fa-check-circle"></i> Yes
                                        <br><small class="text-muted">${row.resolved_by || 'Unknown'}</small>
                                        <br><small class="text-muted">${row.formatted_resolved_timestamp}</small>
                                    </span>`;
                        } else {
                            return `<span class="resolved-no">
                                        <i class="fa-solid fa-times-circle"></i> No
                                    </span>`;
                        }
                    }
                    return data;
                }
            },
            {
                data: null,
                orderable: false,
                className: "actions-column nowrap text-center",
                render: function(data, type, row) {
                    if (type === 'display') {
                        if (row.resolved == 0) {
                            return `<button class="btn btn-sm btn-success btn-resolve" onclick="resolveError(${row.id})">
                                        <i class="fa-solid fa-check"></i> Resolve
                                    </button>`;
                        } else {
                            return `<button class="btn btn-sm btn-warning btn-resolve" onclick="unresolveError(${row.id})">
                                        <i class="fa-solid fa-undo"></i> Unresolve
                                    </button>`;
                        }
                    }
                    return '';
                }
            }
        ],

        columnDefs: [
            {
                targets: [5], // Error message column only
                className: 'text-break'
            }
        ],

        order: [[0, 'desc'], [1, 'desc']], // Order by date, then time
        paging: true,
        searching: true,
        ordering: true,
        info: true,
        pageLength: 25,
        lengthMenu: [[10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]],
        createdRow: function(row, data, dataIndex) {
            if (data.resolved == 1) {
                $(row).addClass('error-row resolved');
            }
        }
    });

    // Handle Read More clicks
    $('#errorLogTable tbody').on('click', 'a.read-more', function(e) {
        e.preventDefault();

        var wrapper = $(this).closest('.error-message-wrapper');
        wrapper.find('.short-desc').hide();
        $(this).hide();
        wrapper.find('.full-desc').show();
    });

    // Handle Context View clicks
    $('#errorLogTable tbody').on('click', 'button.context-btn', function(e) {
        e.preventDefault();
        var errorId = $(this).data('error-id');
        var contextText = $(this).data('context');
        showContext(errorId, contextText);
    });

    // Filter handlers
    $('#severityFilter, #scriptFilter, #resolvedFilter').on('change', function() {
        table.draw();
    });

    $('#refreshBtn').on('click', function() {
        table.ajax.reload();
    });

    $('#clearFiltersBtn').on('click', function() {
        $('#severityFilter, #scriptFilter, #resolvedFilter').val('');
        table.draw();
    });

    // Custom search function
    $.fn.dataTable.ext.search.push(function(settings, data, dataIndex) {
        if (settings.nTable.id !== 'errorLogTable') {
            return true;
        }

        var severityFilter = $('#severityFilter').val();
        var scriptFilter = $('#scriptFilter').val();
        var resolvedFilter = $('#resolvedFilter').val();

        var severity = data[3] || '';
        var script = data[2] || '';
        var resolved = table.row(dataIndex).data().resolved;

        if (severityFilter && !severity.includes(severityFilter)) {
            return false;
        }

        if (scriptFilter && script !== scriptFilter) {
            return false;
        }

        if (resolvedFilter !== '' && resolved != resolvedFilter) {
            return false;
        }

        return true;
    });

    // Load script filter options
    loadScriptFilterOptions();

    // Auto-refresh every 2 minutes
    setInterval(function() {
        console.log("Refreshing Error Log...");
        table.ajax.reload(null, false);
    }, 120000);
});

// Show Context Modal
function showContext(errorId, contextText) {
    $('#contextModalTitle').text('Error Context #' + errorId);
    $('#contextModalBody').text(contextText || 'No context available');
    $('#contextModal').modal('show');
}

function loadScriptFilterOptions() {
    $.ajax({
        url: 'error_log_data.cfm?action=getScripts',
        method: 'GET',
        success: function(data) {
            var scripts = (typeof data === 'string') ? JSON.parse(data) : data;
            var select = $('#scriptFilter');
            select.find('option:not(:first)').remove();
            
            scripts.forEach(function(script) {
                select.append(`<option value="${script}">${script}</option>`);
            });
        },
        error: function() {
            console.error('Failed to load script filter options');
        }
    });
}

function showStackTrace(errorId) {
    $.ajax({
        url: 'error_log_data.cfm?action=getStackTrace&id=' + errorId,
        method: 'GET',
        success: function(data) {
            // jQuery automatically parses JSON when Content-Type is application/json
            var result = (typeof data === 'string') ? JSON.parse(data) : data;
            if (result.stack_trace) {
                var modal = `
                    <div class="modal fade" id="stackTraceModal" tabindex="-1">
                        <div class="modal-dialog modal-lg">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title">Stack Trace - Error ID: ${errorId}</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <pre class="bg-light p-3" style="max-height: 400px; overflow-y: auto;">${result.stack_trace}</pre>
                                </div>
                                <div class="modal-footer">
                                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>`;
                
                // Remove existing modal if any
                $('#stackTraceModal').remove();
                
                // Add and show new modal
                $('body').append(modal);
                $('#stackTraceModal').modal('show');
            } else {
                alert('No stack trace available for this error.');
            }
        },
        error: function() {
            alert('Failed to load stack trace.');
        }
    });
}

function resolveError(errorId) {
    if (confirm('Mark this error as resolved?')) {
        updateErrorStatus(errorId, 1);
    }
}

function unresolveError(errorId) {
    if (confirm('Mark this error as unresolved?')) {
        updateErrorStatus(errorId, 0);
    }
}

function updateErrorStatus(errorId, resolved) {
    $.ajax({
        url: 'error_log_data.cfm?action=updateStatus',
        method: 'POST',
        data: {
            id: errorId,
            resolved: resolved
        },
        success: function(data) {
            var result = (typeof data === 'string') ? JSON.parse(data) : data;
            if (result.success) {
                $('#errorLogTable').DataTable().ajax.reload(null, false);
            } else {
                alert('Failed to update error status: ' + (result.message || 'Unknown error'));
            }
        },
        error: function() {
            alert('Failed to update error status.');
        }
    });
}
</script>

<!-- Context Modal -->
<div class="modal fade" id="contextModal" tabindex="-1" aria-labelledby="contextModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="contextModalTitle">Error Context</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <pre id="contextModalBody" style="white-space: pre-wrap; word-wrap: break-word;"></pre>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

</body>
</html>
