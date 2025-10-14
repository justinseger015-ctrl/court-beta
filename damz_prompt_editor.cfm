<!DOCTYPE html>
<html>
<head>
    <title>DAMZ Prompt Rules Editor</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .file-tabs .nav-link {
            cursor: pointer;
        }
        .file-tabs .nav-link.active {
            background-color: #0d6efd;
            color: white;
        }
        textarea {
            font-family: 'Courier New', monospace;
            font-size: 14px;
        }
        .save-success {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 9999;
        }
    </style>
</head>
<body>

<cfset baseNetworkPath = "\\10.146.176.84\general\docketwatch\python\">
<cfset files = {
    "headline": {
        "path": baseNetworkPath & "prompt_rules.txt",
        "title": "Headline Type & Optimization Rules",
        "description": "Rules for classifying headline types and optimizing headlines (TASK 1)"
    },
    "shotdesc": {
        "path": baseNetworkPath & "prompt_shotdesc.txt",
        "title": "Shot Description Rules",
        "description": "Rules for cleaning and formatting shot descriptions (TASK 2)"
    },
    "keywords": {
        "path": baseNetworkPath & "prompt_keywords.txt",
        "title": "Keyword Rules",
        "description": "Rules for cleaning and validating keywords (TASK 3)"
    }
}>

<cfparam name="URL.tab" default="headline">
<cfset currentTab = URL.tab>
<cfif NOT structKeyExists(files, currentTab)>
    <cfset currentTab = "headline">
</cfif>

<!--- Handle save action --->
<cfif structKeyExists(FORM, "save_file") AND structKeyExists(FORM, "file_content") AND structKeyExists(FORM, "file_key")>
    <cfif structKeyExists(files, FORM.file_key)>
        <cftry>
            <cfset filePath = files[FORM.file_key].path>
            
            <!--- Create backup before saving --->
            <cfset backupPath = filePath & ".backup." & dateFormat(now(), "yyyymmdd") & "." & timeFormat(now(), "HHmmss")>
            <cfif fileExists(filePath)>
                <cffile action="copy" source="#filePath#" destination="#backupPath#">
            </cfif>
            
            <!--- Save the new content --->
            <cffile action="write" 
                    file="#filePath#" 
                    output="#FORM.file_content#" 
                    charset="utf-8">
            
            <cfset saveSuccess = true>
            <cfset saveMessage = "File saved successfully! Backup created: #getFileFromPath(backupPath)#">
            <cfset currentTab = FORM.file_key>
            
            <cfcatch type="any">
                <cfset saveError = true>
                <cfset saveMessage = "Error saving file: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!--- Load current file content --->
<cfset currentFile = files[currentTab]>
<cftry>
    <cffile action="read" file="#currentFile.path#" variable="fileContent" charset="utf-8">
    <cfset fileExists = true>
    <cfcatch type="any">
        <cfset fileExists = false>
        <cfset fileContent = "Error loading file: #cfcatch.message#">
    </cfcatch>
</cftry>

<cfoutput>
<div class="container-fluid mt-4">
    <div class="row">
        <div class="col-12">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <div>
                    <h1>DAMZ Prompt Rules Editor</h1>
                    <p class="text-muted">Edit AI prompt instruction files for the comprehensive processor</p>
                </div>
                <div>
                    <a href="damz_compare.cfm" class="btn btn-secondary">Back to Compare</a>
                </div>
            </div>

            <!--- Success/Error alerts --->
            <cfif isDefined("saveSuccess")>
                <div class="alert alert-success alert-dismissible fade show save-success">
                    <strong>Success!</strong> #saveMessage#
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>
            <cfif isDefined("saveError")>
                <div class="alert alert-danger alert-dismissible fade show save-success">
                    <strong>Error!</strong> #saveMessage#
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>

            <!--- File tabs --->
            <ul class="nav nav-tabs file-tabs mb-3">
                <cfloop collection="#files#" item="key">
                    <li class="nav-item">
                        <a class="nav-link <cfif currentTab EQ key>active</cfif>" 
                           href="damz_prompt_editor.cfm?tab=#key#">
                            #files[key].title#
                        </a>
                    </li>
                </cfloop>
            </ul>

            <!--- File editor card --->
            <div class="card">
                <div class="card-header bg-primary text-white">
                    <h4 class="mb-0">#currentFile.title#</h4>
                    <small>#currentFile.description#</small>
                </div>
                <div class="card-body">
                    <div class="alert alert-info mb-3">
                        <strong>File Path:</strong> <code>#currentFile.path#</code><br>
                        <strong>Note:</strong> A timestamped backup will be created automatically before saving.
                    </div>

                    <cfif fileExists>
                        <form method="post" action="damz_prompt_editor.cfm?tab=#currentTab#">
                            <input type="hidden" name="file_key" value="#currentTab#">
                            
                            <div class="mb-3">
                                <label for="file_content" class="form-label">
                                    <strong>File Content:</strong>
                                    <span class="text-muted">(#len(fileContent)# characters)</span>
                                </label>
                                <textarea name="file_content" 
                                          id="file_content" 
                                          class="form-control" 
                                          rows="25" 
                                          style="white-space: pre-wrap;">#htmlEditFormat(fileContent)#</textarea>
                            </div>

                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <button type="submit" name="save_file" class="btn btn-success btn-lg">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-save" viewBox="0 0 16 16">
                                            <path d="M2 1a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H9.5a1 1 0 0 0-1 1v7.293l2.646-2.647a.5.5 0 0 1 .708.708l-3.5 3.5a.5.5 0 0 1-.708 0l-3.5-3.5a.5.5 0 1 1 .708-.708L7.5 9.293V2a2 2 0 0 1 2-2H14a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h2.5a.5.5 0 0 1 0 1H2z"/>
                                        </svg>
                                        Save Changes
                                    </button>
                                    <button type="button" class="btn btn-warning" onclick="if(confirm('Are you sure you want to reload and lose your changes?')) location.reload();">
                                        Reset
                                    </button>
                                </div>
                                <div class="text-muted">
                                    <small>Last modified: 
                                        <cfset fileInfo = getFileInfo(currentFile.path)>
                                        #dateFormat(fileInfo.lastModified, "mm/dd/yyyy")# 
                                        #timeFormat(fileInfo.lastModified, "h:mm:ss tt")#
                                    </small>
                                </div>
                            </div>
                        </form>
                    <cfelse>
                        <div class="alert alert-danger">
                            <h5>Unable to load file</h5>
                            <p>#htmlEditFormat(fileContent)#</p>
                        </div>
                    </cfif>
                </div>
            </div>

            <!--- Help section --->
            <div class="card mt-4">
                <div class="card-header">
                    <h5>💡 Usage Tips</h5>
                </div>
                <div class="card-body">
                    <ul>
                        <li><strong>Automatic Backups:</strong> Each save creates a timestamped backup file (e.g., <code>prompt_rules.txt.backup.20251014.143022</code>)</li>
                        <li><strong>Testing:</strong> After editing, test your changes using the "Run Test" feature in the Compare page</li>
                        <li><strong>Valid Headline Types:</strong> General, Stock, Presser, Commercial, Government, Police Footage, Court, Movie, Music Video, Social Media, TV Show, Live Sports Event, Live Event, Print</li>
                        <li><strong>Valid Emotions:</strong> HAPPY, EXCITED, SERIOUS, CONFIDENT, SURPRISED, ANGRY, SAD, CONCERNED, CONTEMPLATIVE, RELAXED, PLAYFUL, NEUTRAL</li>
                        <li><strong>Format:</strong> The AI receives these rules exactly as written - be clear and specific</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</div>
</cfoutput>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
// Auto-hide success alerts after 5 seconds
setTimeout(function() {
    var alerts = document.querySelectorAll('.save-success');
    alerts.forEach(function(alert) {
        var bsAlert = new bootstrap.Alert(alert);
        bsAlert.close();
    });
}, 5000);

// Warn before leaving page with unsaved changes
var originalContent = document.getElementById('file_content') ? document.getElementById('file_content').value : '';
var formSubmitted = false;

document.addEventListener('submit', function() {
    formSubmitted = true;
});

window.addEventListener('beforeunload', function(e) {
    var currentContent = document.getElementById('file_content') ? document.getElementById('file_content').value : '';
    if (!formSubmitted && currentContent !== originalContent) {
        e.preventDefault();
        e.returnValue = '';
        return '';
    }
});
</script>

</body>
</html>
