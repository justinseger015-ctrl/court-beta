<!DOCTYPE html>
<html>
<head>
    <title>DAMZ Asset Compare</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .text-truncate-hover {
            max-width: 300px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .image-placeholder {
            width: 400px;
            height: 400px;
            background-color: #f8f9fa;
            border: 2px dashed #dee2e6;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #6c757d;
            font-size: 18px;
        }
        .v0-row {
            font-weight: bold;
            background-color: #f8f9fa;
        }
    </style>
</head>
<body>

<!--- Parameter validation --->
<cfparam name="URL.fk_asset" default="">
<cfset isValidGuid = false>
<cfif len(trim(URL.fk_asset))>
    <!--- Check if it matches GUID pattern (8-4-4-4-12 characters) --->
    <cfset guidPattern = "^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$">
    <cfif REFind(guidPattern, trim(URL.fk_asset))>
        <cfset isValidGuid = true>
    </cfif>
</cfif>

<cfif NOT isValidGuid>
    <cfoutput>
    <div class="container mt-4">
        <div class="alert alert-danger">
            <h4>Invalid Asset ID</h4>
            <p>Please provide a valid fk_asset GUID in the URL.</p>
            <p class="text-muted">Received: #htmlEditFormat(URL.fk_asset)#</p>
        </div>
    </div>
    </cfoutput>
    <cfabort>
</cfif>

<!--- POST handling stub --->
<cfif structKeyExists(FORM, "fk_model")>
    <cfif NOT isNumeric(FORM.fk_model)>
        <cfset errorMessage = "Invalid model selection.">
    <cfelse>
        <cfset selectedModel = FORM.fk_model>
        <cfset promptNotes = structKeyExists(FORM, "prompt_notes") ? FORM.prompt_notes : "">
        
        <!--- Execute Python script --->
        <cfset pythonExecutable = "C:\Program Files\Python312\python.exe">
        <cfset pythonScriptPath = "U:\docketwatch\python\damz_comprehensive_processor.py">
        
        <!--- Always create a new version configuration record --->
        <cfquery datasource="Reach">
            INSERT INTO docketwatch.dbo.damz_test_version_model (version, fk_model, prompt_notes)
            SELECT 
                ISNULL(MAX(version), 0) + 1,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#selectedModel#">,
                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#promptNotes#" null="#NOT len(trim(promptNotes))#">
            FROM docketwatch.dbo.damz_test_version_model
        </cfquery>
        
        <!--- Build command arguments --->
        <cfset scriptArgs = [pythonScriptPath, "--fk_asset", URL.fk_asset]>
        
        <!--- Execute the Python script --->
        <cftry>
            <cfexecute
                name="#pythonExecutable#"
                arguments="#scriptArgs#"
                variable="pythonOutput"
                timeout="60"
                errorVariable="pythonError"
            />
            
            <cfif len(trim(pythonError))>
                <cfset errorMessage = "Python execution error: #HtmlEditFormat(pythonError)#">
            <cfelse>
                <cfset successMessage = "Test completed successfully! Refresh to see the new version.">
            </cfif>
            
            <cfcatch type="any">
                <cfset errorMessage = "Failed to execute Python script: #HtmlEditFormat(cfcatch.message)#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!--- Database queries --->
<cfquery name="Q_asset_v0" datasource="Reach">
    SELECT TOP 1 * 
    FROM docketwatch.dbo.damz_test
    WHERE fk_asset = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.fk_asset#">
      AND version = 0
</cfquery>

<cfquery name="Q_versions" datasource="Reach">
    SELECT t.*, gm.display_name AS model_display_name
    FROM docketwatch.dbo.damz_test t
    LEFT JOIN docketwatch.dbo.damz_test_version_model vm ON vm.version = t.version
    LEFT JOIN docketwatch.dbo.gemini_models gm ON gm.id = vm.fk_model
    WHERE t.fk_asset = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.fk_asset#">
      AND t.version <> 3
    ORDER BY t.version ASC
</cfquery>

<cfquery name="Q_models" datasource="Reach">
    SELECT id, display_name
    FROM docketwatch.dbo.gemini_models
    WHERE is_active = 1
    ORDER BY display_name
</cfquery>

<cfquery name="Q_image_path" datasource="Reach">
    SELECT u.path + i.path AS full_path
    FROM damz.dbo.asset_image i
    JOIN damz.dbo.storage_unit u ON u.id = i.fk_storage_unit
    WHERE i.type = 'THUMBNAIL' AND i.fk_asset = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.fk_asset#">
</cfquery>

<cfquery name="Q_next_record" datasource="Reach">
    SELECT TOP 1 fk_asset
    FROM docketwatch.dbo.damz_test
    WHERE version = 0 
      AND fk_asset > <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.fk_asset#">
    ORDER BY fk_asset ASC
</cfquery>


<!--- File copy logic for web-accessible images --->
<cfif Q_image_path.recordCount GT 0 AND len(trim(Q_image_path.full_path))>
    <cfset sourceFile = Q_image_path.full_path>
    <cfset destDir = "U:\docketwatch\damz_assets\">
    <cfset fileName = GetFileFromPath(sourceFile)>
    <cfset destFile = destDir & fileName>
    <cfset webImagePath = "/damz_assets/" & fileName>
    
    <!--- Check if destination directory exists, create if not --->
    <cfif NOT DirectoryExists(destDir)>
        <cfdirectory action="create" directory="#destDir#" mode="755">
    </cfif>
    
    <!--- Copy file to web-accessible location if it doesn't exist or is older --->
    <cfif NOT FileExists(destFile)>
        <cftry>
            <cffile action="copy" 
                    source="#sourceFile#" 
                    destination="#destFile#" 
                    nameconflict="overwrite">
            <cfset fileCopied = true>
            <cfcatch type="any">
                <cfset fileCopied = false>
                <cfset copyError = cfcatch.message>
            </cfcatch>
        </cftry>
    <cfelse>
        <cfset fileCopied = true>
    </cfif>
<cfelse>
    <cfset fileCopied = false>
    <cfset webImagePath = "">
</cfif>

<cfoutput>
<div class="container-fluid mt-4">
    <div class="row">
        <!--- Main content area - full width --->
        <div class="col-12">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <div>
                    <h1>DAMZ Asset Compare</h1>
                    <p class="text-muted">Asset ID: #URL.fk_asset#</p>
                </div>
                <div>
                    <a href="damz_prompt_editor.cfm" class="btn btn-secondary me-2">
                        Edit Prompt Rules
                    </a>
                    <button type="button" class="btn btn-success me-2" onclick="loadNextRecord()">
                        Next Record
                    </button>
                    <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="##runTestModal">
                        Run Test
                    </button>
                </div>
            </div>
            
            <!--- Success/Error messages --->
            <cfif isDefined("successMessage")>
                <div class="alert alert-success alert-dismissible fade show">
                    #successMessage#
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>
            <cfif isDefined("errorMessage")>
                <div class="alert alert-danger alert-dismissible fade show">
                    #errorMessage#
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>

            <!--- Check if version 0 exists --->
            <cfif Q_asset_v0.recordCount EQ 0>
                <div class="alert alert-warning">
                    <h4>No version 0 found for this asset.</h4>
                    <p>This asset does not have a baseline version in the system.</p>
                </div>
            <cfelse>
                <!--- Original version card --->
                <div class="card mb-4">
                    <div class="card-header">
                        <h3>Original (v0)</h3>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-8">
                                <div class="row">
                                    <div class="col-sm-3"><strong>Version:</strong></div>
                                    <div class="col-sm-9">#Q_asset_v0.version#</div>
                                </div>
                                <div class="row mt-2">
                                    <div class="col-sm-3"><strong>Headline Type:</strong></div>
                                    <div class="col-sm-9">#Q_asset_v0.headline_type#</div>
                                </div>
                                <div class="row mt-2">
                                    <div class="col-sm-3"><strong>Headline:</strong></div>
                                    <div class="col-sm-9" title="#htmlEditFormat(Q_asset_v0.headline)#">#htmlEditFormat(left(Q_asset_v0.headline, 100))##len(Q_asset_v0.headline) GT 100 ? '...' : ''#</div>
                                </div>
                                <div class="row mt-2">
                                    <div class="col-sm-3"><strong>Shot Description:</strong></div>
                                    <div class="col-sm-9" title="#htmlEditFormat(Q_asset_v0.shot_description)#">#htmlEditFormat(left(Q_asset_v0.shot_description, 100))##len(Q_asset_v0.shot_description) GT 100 ? '...' : ''#</div>
                                </div>
                                <div class="row mt-2">
                                    <div class="col-sm-3"><strong>Keywords:</strong></div>
                                    <div class="col-sm-9" title="#htmlEditFormat(Q_asset_v0.keywords)#">#htmlEditFormat(left(Q_asset_v0.keywords, 100))##len(Q_asset_v0.keywords) GT 100 ? '...' : ''#</div>
                                </div>
                                <div class="row mt-2">
                                    <div class="col-sm-3"><strong>Emotion:</strong></div>
                                    <div class="col-sm-9">#htmlEditFormat(Q_asset_v0.emotion)#</div>
                                </div>
                                <hr class="mt-3">
                                <div class="row">
                                    <div class="col-sm-3"><strong>Imported:</strong></div>
                                    <div class="col-sm-9">#dateFormat(Q_asset_v0.imported_at, "mm/dd/yyyy")# #timeFormat(Q_asset_v0.imported_at, "h:mm tt")#</div>
                                </div>
                                <div class="row mt-2">
                                    <div class="col-sm-3"><strong>Agency:</strong></div>
                                    <div class="col-sm-9">#htmlEditFormat(Q_asset_v0.agency)#</div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <cfif fileCopied AND len(trim(webImagePath))>
                                    <img src="#webImagePath#" 
                                         alt="Asset Image" 
                                         class="img-fluid" 
                                         style="max-width: 400px; max-height: 400px; border: 1px solid ##dee2e6;">
                                <cfelse>
                                    <div class="image-placeholder">
                                        <cfif isDefined("copyError")>
                                            Image copy failed: #htmlEditFormat(copyError)#
                                        <cfelse>
                                            No image available
                                        </cfif>
                                    </div>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </div>

                <!--- All versions table --->
                <div class="card">
                    <div class="card-header">
                        <h3>All Versions</h3>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped" style="width: 100%; table-layout: fixed;">
                                <thead>
                                    <tr>
                                        <th style="width: 4%;">Version</th>
                                        <th style="width: 8%;">Model</th>
                                        <th style="width: 8%;">Headline Type</th>
                                        <th style="width: 25%;">Headline</th>
                                        <th style="width: 40%;">Shot Description</th>
                                        <th style="width: 10%;">Keywords</th>
                                        <th style="width: 5%;">Emotion</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <cfloop query="Q_versions">
                                        <tr <cfif Q_versions.version EQ 0>class="v0-row"</cfif>>
                                            <td>#Q_versions.version#</td>
                                            <td>
                                                <cfif Q_versions.version EQ 0>
                                                    -
                                                <cfelse>
                                                    #htmlEditFormat(Q_versions.model_display_name)#
                                                </cfif>
                                            </td>
                                            <td>#htmlEditFormat(Q_versions.headline_type)#</td>
                                            <td style="word-wrap: break-word; white-space: normal;">
                                                #htmlEditFormat(Q_versions.headline)#
                                            </td>
                                            <td style="word-wrap: break-word; white-space: normal;">
                                                #htmlEditFormat(Q_versions.shot_description)#
                                            </td>
                                            <td style="word-wrap: break-word; white-space: normal;">
                                                #htmlEditFormat(Q_versions.keywords)#
                                            </td>
                                            <td>#htmlEditFormat(Q_versions.emotion)#</td>
                                        </tr>
                                    </cfloop>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </cfif>
        </div>
    </div>
</div>

<!--- Run Test Modal --->
<div class="modal fade" id="runTestModal" tabindex="-1" aria-labelledby="runTestModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="runTestModalLabel">Run Test</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="post" action="damz_compare.cfm?fk_asset=#htmlEditFormat(URL.fk_asset)#">
                <div class="modal-body">
                    <input type="hidden" name="fk_asset" value="#htmlEditFormat(URL.fk_asset)#">
                    
                    <div class="mb-3">
                        <label for="modal_fk_model" class="form-label">Model</label>
                        <select name="fk_model" id="modal_fk_model" class="form-select" required>
                            <option value="">Select a model...</option>
                            <cfloop query="Q_models">
                                <option value="#Q_models.id#"
                                        <cfif isDefined("selectedModel") AND selectedModel EQ Q_models.id>selected</cfif>>
                                    #htmlEditFormat(Q_models.display_name)#
                                </option>
                            </cfloop>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label for="modal_prompt_notes" class="form-label">Prompt Notes</label>
                        <textarea name="prompt_notes" id="modal_prompt_notes" 
                                  class="form-control" rows="4" 
                                  placeholder="Optional custom instructions..."><cfif isDefined("promptNotes")>#htmlEditFormat(promptNotes)#</cfif></textarea>
                        <div class="form-text">Custom instructions that will override default AI behavior.</div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary">Run Test</button>
                </div>
            </form>
        </div>
    </div>
</div>
</cfoutput>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
<cfoutput>
<script>
function loadNextRecord() {
    <cfif Q_next_record.recordCount GT 0>
        window.location.href = 'damz_compare.cfm?fk_asset=#Q_next_record.fk_asset#';
    <cfelse>
        alert('No more records found. This is the last record in the database.');
    </cfif>
}
</script>
</cfoutput>
</body>
</html>