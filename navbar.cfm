<!--- Navigation Bar --->
<nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-sm">
    <div class="container-fluid">
        <!--- App Title with Logo --->
        <a class="navbar-brand fw-bold" href="./index.cfm">
            <i class="fas fa-gavel me-2 text-warning"></i>
            <cfoutput>#application.appType eq "docketwatch" ? "DocketWatch" : "TMZ Tools"#</cfoutput>
        </a>

        <!--- Navbar Toggle (For Mobile View) --->
        <button class="navbar-toggler border-0" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto">
                <!--- Dashboard --->
                <li class="nav-item">
                    <a class="nav-link <cfif cgi.script_name contains 'index.cfm' AND NOT url.keyExists('status')>active</cfif>" href="./index.cfm">
                        <i class="fas fa-tachometer-alt me-1"></i>Dashboard
                    </a>
                </li>

                <!--- Case Management Dropdown --->
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="caseManagementDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                        <i class="fas fa-folder-open me-1"></i>Case Management
                    </a>
                    <ul class="dropdown-menu shadow">
                        <li><a class="dropdown-item" href="./index.cfm?status=Review">
                            <i class="fas fa-eye me-2"></i>New Cases Review
                        </a></li>
                        <li><a class="dropdown-item" href="./index.cfm?status=Tracked">
                            <i class="fas fa-bookmark me-2"></i>Tracked Cases
                        </a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="./case_events.cfm">
                            <i class="fas fa-calendar-check me-2"></i>Case Events
                        </a></li>
                        <li><a class="dropdown-item" href="./latest_pacer_pdfs.cfm">
                            <i class="fas fa-file-pdf me-2"></i>Latest Pacer PDFs
                        </a></li>
                        <li><a class="dropdown-item" href="./case_matches.cfm">
                            <i class="fas fa-star me-2"></i>Celebrity Matches
                        </a></li>
                        <li><a class="dropdown-item" href="./pardons.cfm">
                            <i class="fas fa-hand-holding-heart me-2"></i>Pardons
                        </a></li>
                        <li><a class="dropdown-item" href="./calendar.cfm">
                            <i class="fas fa-calendar me-2"></i>Calendar
                        </a></li>
                    </ul>
                </li>

                <!--- Reports Dropdown --->
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="reportsDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                        <i class="fas fa-chart-bar me-1"></i>Reports
                    </a>
                    <ul class="dropdown-menu shadow">
                        <li><a class="dropdown-item" href="./case_tracking_summary.cfm">
                            <i class="fas fa-list-check me-2"></i>Tracking Summary
                        </a></li>
                        <li><a class="dropdown-item" href="./scheduled_task_log.cfm">
                            <i class="fas fa-clock me-2"></i>Scheduled Log
                        </a></li>
                        <li><a class="dropdown-item" href="./pacer_costs.cfm">
                            <i class="fas fa-dollar-sign me-2"></i>Pacer Costs
                        </a></li>
                        <li><a class="dropdown-item" href="./not_found.cfm">
                            <i class="fas fa-exclamation-triangle me-2"></i>Tracked Cases Not Found
                        </a></li>
                    </ul>
                </li>

                <!--- Admin Dropdown --->
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="adminDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                        <i class="fas fa-cog me-1"></i>Admin
                    </a>
                    <ul class="dropdown-menu shadow">
                        <li><a class="dropdown-item" href="./celebrity_gallery.cfm">
                            <i class="fas fa-users me-2"></i>Celebrities
                        </a></li>
                        <li><a class="dropdown-item" href="./tools.cfm">
                            <i class="fas fa-tools me-2"></i>Tools
                        </a></li>
                        <cfif application.appType eq "docketwatch">
                            <li><a class="dropdown-item" href="./docketwatch_tools.cfm">
                                <i class="fas fa-wrench me-2"></i>DocketWatch Tools
                            </a></li>
                        <cfelseif application.appType eq "tmztools">
                            <li><a class="dropdown-item" href="./tmz_tools.cfm">
                                <i class="fas fa-wrench me-2"></i>TMZ Tools
                            </a></li>
                        </cfif>
                    </ul>
                </li>

                <!--- Archive Dropdown --->
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="archiveDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                        <i class="fas fa-archive me-1"></i>Archive
                    </a>
                    <ul class="dropdown-menu shadow">
                        <li><a class="dropdown-item" href="./index.cfm?status=Removed">
                            <i class="fas fa-trash-alt me-2"></i>Removed Cases
                        </a></li>
                    </ul>
                </li>
            </ul>
            
            <!--- Right-aligned User and Logout section --->
            <ul class="navbar-nav">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle text-light d-flex align-items-center" href="#" id="userDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                        <i class="fas fa-user-circle me-2"></i>
                        <cfoutput>#session.user_login#</cfoutput>
                    </a>
                    <ul class="dropdown-menu dropdown-menu-end shadow">
                        <li><h6 class="dropdown-header">
                            <i class="fas fa-user me-2"></i>Signed in as <strong><cfoutput>#session.user_login#</cfoutput></strong>
                        </h6></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item text-danger" href="./logout.cfm">
                            <i class="fas fa-sign-out-alt me-2"></i>Sign Out
                        </a></li>
                    </ul>
                </li>
            </ul>

        </div>
    </div>
</nav>
