<!---
================================================================================
Cleanup Removed Unfiled PDFs
================================================================================
This script identifies and processes PDFs for cases that are:
1. Unfiled (case_number = "Unfiled")
2. Removed (status = "Removed")

This allows for cleanup of PDFs that are no longer needed.
================================================================================
--->

<!--- Authentication check --->
<cfif NOT isDefined("session.user_login")>
    <cflocation url="index.cfm" addtoken="false">
</cfif>

<!--- Get current authenticated user --->
<cfset currentuser = getAuthUser()>

<!--- Query to find all unfiled cases with "Removed" status --->
<cfquery name="getUnfiledRemovedCases" datasource="Reach">
    SELECT 
        c.id,
        c.case_number,
        c.case_name,
        c.status,
        c.created_at,
        c.last_updated,
        t.tool_name
    FROM docketwatch.dbo.cases c
    LEFT JOIN docketwatch.dbo.tools t ON c.fk_tool = t.id
    WHERE c.case_number = 'Unfiled'
    AND c.status = 'Removed'
    ORDER BY c.last_updated DESC
</cfquery>

<!--- Query to get associated documents for these cases --->
<cfquery name="getAssociatedDocuments" datasource="Reach">
    SELECT  * 
    FROM [docketwatch].[dbo].[documents] d
    INNER JOIN docketwatch.dbo.cases c ON c.id = d.fk_case
    WHERE c.[status] = 'Removed' AND c.case_number = 'Unfiled'
</cfquery>

<!--- Query to get case_events_pdf records for these cases --->
<cfquery name="getAssociatedPDFs" datasource="Reach">
    SELECT 
        p.id as pdf_id,
        p.fk_case_event,
        p.pdf_title,
        p.local_pdf_filename,
        p.isDownloaded,
        p.created_at as pdf_created_at,
        c.id as case_id,
        c.case_number,
        c.case_name
    FROM docketwatch.dbo.case_events_pdf p
    INNER JOIN docketwatch.dbo.case_events e ON p.fk_case_event = e.id
    INNER JOIN docketwatch.dbo.cases c ON e.fk_cases = c.id
    WHERE c.case_number = 'Unfiled'
    AND c.status = 'Removed'
    ORDER BY p.created_at DESC
</cfquery>

<!--- Alternative query: Direct lookup by case IDs from unfiled removed cases --->
<cfquery name="getDirectPDFs" datasource="Reach">
    SELECT 
        p.id as pdf_id,
        p.fk_case_event,
        p.pdf_title,
        p.local_pdf_filename,
        p.isDownloaded,
        p.created_at as pdf_created_at,
        c.id as case_id,
        c.case_number,
        c.case_name
    FROM docketwatch.dbo.case_events_pdf p
    INNER JOIN docketwatch.dbo.case_events e ON p.fk_case_event = e.id
    INNER JOIN docketwatch.dbo.cases c ON e.fk_cases = c.id
    WHERE c.id IN (
        SELECT id FROM docketwatch.dbo.cases 
        WHERE case_number = 'Unfiled' AND status = 'Removed'
    )
    ORDER BY p.created_at DESC
</cfquery>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><cfoutput>#application.siteTitle#</cfoutput> - Cleanup Removed Unfiled PDFs</title>
    <cfinclude template="head.cfm">
    
    <style>
        .summary-card {
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
            border-left: 4px solid #dc2626;
        }
        
        .file-path {
            font-family: 'Courier New', monospace;
            font-size: 0.85rem;
            background: #f1f5f9;
            padding: 0.25rem 0.5rem;
            border-radius: 4px;
            word-break: break-all;
        }
        
        .case-item {
            border-left: 3px solid #6b7280;
            padding-left: 1rem;
            margin-bottom: 1rem;
        }
        
        .doc-item {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 0.75rem;
            margin: 0.5rem 0;
        }
        
        .file-exists {
            color: #dc2626;
            font-weight: 600;
        }
        
        .file-missing {
            color: #6b7280;
            font-style: italic;
        }
    </style>
</head>
<body>

<cfinclude template="navbar.cfm">

<div class="container mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="mb-0">Cleanup: Removed Unfiled PDFs</h2>
        <a href="index.cfm" class="btn btn-outline-secondary">
            <i class="fas fa-arrow-left me-2"></i>Back to Cases
        </a>
    </div>
    
    <!--- Summary Section --->
    <div class="row mb-4">
        <div class="col-md-4">
            <div class="card summary-card">
                <div class="card-body text-center">
                    <h3 class="text-danger mb-2"><cfoutput>#getUnfiledRemovedCases.recordCount#</cfoutput></h3>
                    <p class="mb-0">Unfiled Removed Cases</p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card summary-card">
                <div class="card-body text-center">
                    <h3 class="text-warning mb-2"><cfoutput>#getAssociatedDocuments.recordCount#</cfoutput></h3>
                    <p class="mb-0">Associated Documents</p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card summary-card">
                <div class="card-body text-center">
                    <h3 class="text-info mb-2"><cfoutput>#getAssociatedPDFs.recordCount# / #getDirectPDFs.recordCount#</cfoutput></h3>
                    <p class="mb-0">PDF Files (Method 1 / Method 2)</p>
                </div>
            </div>
        </div>
    </div>
    
    <!--- Cases Section --->
    <div class="card mb-4">
        <div class="card-header">
            <h5 class="mb-0">
                <i class="fas fa-folder me-2"></i>
                Unfiled Cases with "Removed" Status
            </h5>
        </div>
        <div class="card-body">
            <cfif getUnfiledRemovedCases.recordCount GT 0>
                <cfoutput query="getUnfiledRemovedCases">
                    <div class="case-item">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <h6 class="mb-1">
                                    Case ID: #id# 
                                    <span class="badge bg-secondary ms-2">#tool_name#</span>
                                </h6>
                                <p class="mb-1"><strong>Name:</strong> #case_name#</p>
                                <p class="mb-1"><strong>Status:</strong> <span class="text-danger">#status#</span></p>
                                <small class="text-muted">
                                    Created: #dateFormat(created_at, "mm/dd/yyyy")# | 
                                    Updated: #dateFormat(last_updated, "mm/dd/yyyy")#
                                </small>
                            </div>
                            <a href="case_details.cfm?id=#id#" class="btn btn-sm btn-outline-primary" target="_blank">
                                <i class="fas fa-external-link-alt"></i>
                            </a>
                        </div>
                    </div>
                </cfoutput>
            <cfelse>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No unfiled cases with "Removed" status found.
                </div>
            </cfif>
        </div>
    </div>
    
    <!--- Documents Section --->
    <div class="card mb-4">
        <div class="card-header">
            <h5 class="mb-0">
                <i class="fas fa-file-pdf me-2"></i>
                Associated Documents (from documents table)
            </h5>
        </div>
        <div class="card-body">
            <cfif getAssociatedDocuments.recordCount GT 0>
                <cfoutput query="getAssociatedDocuments">
                    <div class="doc-item">
                        <div class="row">
                            <div class="col-md-8">
                                <h6 class="mb-1">Document ID: #doc_id#</h6>
                                <p class="mb-1"><strong>UID:</strong> #doc_uid#</p>
                                <p class="mb-1"><strong>Case:</strong> #case_name# (ID: #fk_case#)</p>
                                <p class="mb-1"><strong>Title:</strong> #pdf_title#</p>
                                <p class="mb-1"><strong>Relative Path:</strong> #rel_path#</p>
                                <cfif file_size GT 0>
                                    <p class="mb-1"><strong>Size:</strong> #numberFormat(file_size/1024, "999,999")# KB</p>
                                </cfif>
                                <cfif total_pages GT 0>
                                    <p class="mb-1"><strong>Pages:</strong> #total_pages#</p>
                                </cfif>
                                <small class="text-muted">Downloaded: #dateFormat(date_downloaded, "mm/dd/yyyy")#</small>
                            </div>
                            <div class="col-md-4">
                                <cfset fullFilePath = "\\10.146.176.84\general\DOCKETWATCH\docs\#rel_path#">
                                <div class="file-path">#fullFilePath#</div>
                                <cfset fileExists = fileExists(fullFilePath)>
                                <cfif fileExists>
                                    <span class="file-exists">
                                        <i class="fas fa-exclamation-triangle me-1"></i>File Exists
                                    </span>
                                <cfelse>
                                    <span class="file-missing">
                                        <i class="fas fa-times-circle me-1"></i>File Not Found
                                    </span>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </cfoutput>
            <cfelse>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No documents found for these cases.
                </div>
            </cfif>
        </div>
    </div>
    
    <!--- PDFs Section --->
    <div class="card mb-4">
        <div class="card-header">
            <h5 class="mb-0">
                <i class="fas fa-file-pdf me-2"></i>
                Associated PDFs (from case_events_pdf table)
            </h5>
        </div>
        <div class="card-body">
            <cfif getAssociatedPDFs.recordCount GT 0>
                <cfoutput query="getAssociatedPDFs">
                    <div class="doc-item">
                        <div class="row">
                            <div class="col-md-8">
                                <h6 class="mb-1">PDF ID: #pdf_id#</h6>
                                <p class="mb-1"><strong>Title:</strong> #pdf_title#</p>
                                <p class="mb-1"><strong>Case:</strong> #case_name# (ID: #case_id#)</p>
                                <p class="mb-1"><strong>Filename:</strong> #local_pdf_filename#</p>
                                <span class="badge bg-<cfif isDownloaded>success<cfelse>warning</cfif>">
                                    <cfif isDownloaded>Downloaded<cfelse>Not Downloaded</cfif>
                                </span>
                                <br><small class="text-muted">Created: #dateFormat(pdf_created_at, "mm/dd/yyyy")#</small>
                            </div>
                            <div class="col-md-4">
                                <!--- Construct PDF path based on local_pdf_filename --->
                                <cfif local_pdf_filename NEQ "">
                                    <cfset pdfPath = "\\10.146.176.84\general\DOCKETWATCH\docs\cases\#case_id#\#local_pdf_filename#">
                                    <div class="file-path">#pdfPath#</div>
                                    <cfset pdfExists = fileExists(pdfPath)>
                                    <cfif pdfExists>
                                        <span class="file-exists">
                                            <i class="fas fa-exclamation-triangle me-1"></i>File Exists
                                        </span>
                                    <cfelse>
                                        <span class="file-missing">
                                            <i class="fas fa-times-circle me-1"></i>File Not Found
                                        </span>
                                    </cfif>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </cfoutput>
            <cfelse>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No PDF files found for these cases (Method 1).
                </div>
            </cfif>
        </div>
    </div>
    
    <!--- Alternative PDFs Section --->
    <div class="card mb-4">
        <div class="card-header">
            <h5 class="mb-0">
                <i class="fas fa-file-pdf me-2"></i>
                Alternative PDF Search (Direct Case ID lookup)
            </h5>
        </div>
        <div class="card-body">
            <cfif getDirectPDFs.recordCount GT 0>
                <cfoutput query="getDirectPDFs">
                    <div class="doc-item">
                        <div class="row">
                            <div class="col-md-8">
                                <h6 class="mb-1">PDF ID: #pdf_id#</h6>
                                <p class="mb-1"><strong>Title:</strong> #pdf_title#</p>
                                <p class="mb-1"><strong>Case:</strong> #case_name# (ID: #case_id#)</p>
                                <p class="mb-1"><strong>Filename:</strong> #local_pdf_filename#</p>
                                <span class="badge bg-<cfif isDownloaded>success<cfelse>warning</cfif>">
                                    <cfif isDownloaded>Downloaded<cfelse>Not Downloaded</cfif>
                                </span>
                                <br><small class="text-muted">Created: #dateFormat(pdf_created_at, "mm/dd/yyyy")#</small>
                            </div>
                            <div class="col-md-4">
                                <!--- Construct PDF path based on local_pdf_filename --->
                                <cfif local_pdf_filename NEQ "">
                                    <cfset pdfPath = "\\10.146.176.84\general\DOCKETWATCH\docs\cases\#case_id#\#local_pdf_filename#">
                                    <div class="file-path">#pdfPath#</div>
                                    <cfset pdfExists = fileExists(pdfPath)>
                                    <cfif pdfExists>
                                        <span class="file-exists">
                                            <i class="fas fa-exclamation-triangle me-1"></i>File Exists
                                        </span>
                                    <cfelse>
                                        <span class="file-missing">
                                            <i class="fas fa-times-circle me-1"></i>File Not Found
                                        </span>
                                    </cfif>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </cfoutput>
            <cfelse>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No PDF files found for these cases (Method 2).
                </div>
            </cfif>
        </div>
    </div>
    
    <!--- Action Buttons --->
    <cfif getUnfiledRemovedCases.recordCount GT 0>
        <div class="card">
            <div class="card-header bg-danger text-white">
                <h5 class="mb-0">
                    <i class="fas fa-trash me-2"></i>
                    Cleanup Actions
                </h5>
            </div>
            <div class="card-body">
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    <strong>Warning:</strong> The following actions will permanently delete files and database records. This cannot be undone.
                </div>
                
                <div class="d-grid gap-2 d-md-flex">
                    <button type="button" class="btn btn-outline-danger" onclick="showDeletePreview()">
                        <i class="fas fa-search me-2"></i>Preview Deletion
                    </button>
                    <button type="button" class="btn btn-danger" onclick="confirmDeleteFiles()" disabled id="deleteFilesBtn">
                        <i class="fas fa-trash me-2"></i>Delete PDF Files
                    </button>
                </div>
            </div>
        </div>
    </cfif>

</div>

<cfinclude template="footer_script.cfm">

<script>
function showDeletePreview() {
    // Enable the delete button after preview
    document.getElementById('deleteFilesBtn').disabled = false;
    
    // Show a detailed preview of what will be deleted
    let message = `This will delete PDFs for:\n\n`;
    message += `• ${<cfoutput>#getUnfiledRemovedCases.recordCount#</cfoutput>} unfiled removed cases\n`;
    message += `• ${<cfoutput>#getAssociatedDocuments.recordCount#</cfoutput>} associated documents\n`;
    message += `• ${<cfoutput>#getAssociatedPDFs.recordCount#</cfoutput>} PDF files\n\n`;
    message += `Files will be checked for existence before deletion.`;
    
    Swal.fire({
        title: 'Deletion Preview',
        text: message,
        icon: 'info',
        confirmButtonText: 'I Understand'
    });
}

function confirmDeleteFiles() {
    Swal.fire({
        title: 'Are you absolutely sure?',
        html: `
            <p>This will <strong>permanently delete</strong> all PDF files associated with unfiled, removed cases.</p>
            <p class="text-danger"><strong>This action cannot be undone!</strong></p>
        `,
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#dc2626',
        cancelButtonColor: '#6b7280',
        confirmButtonText: 'Yes, Delete Files!',
        cancelButtonText: 'Cancel'
    }).then((result) => {
        if (result.isConfirmed) {
            // TODO: Implement actual deletion logic
            Swal.fire(
                'Ready for Implementation',
                'The deletion logic needs to be implemented in a separate processing file.',
                'info'
            );
        }
    });
}
</script>

</body>
</html>
