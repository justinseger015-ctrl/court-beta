<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<cftry>
    <cfset scriptName = "summarize_upload">
    <cfset uploadDir = "U:\docketwatch\uploads\">
    <cfset batchFile = "U:\docketwatch\court-beta\ajax\upload_and_summarize.bat">
    
    <!--- Ensure upload directory exists --->
    <cfif NOT directoryExists(uploadDir)>
        <cfdirectory action="create" directory="#uploadDir#">
    </cfif>
    
    <!--- Handle file upload --->
    <cffile action="upload" 
            filefield="file" 
            destination="#uploadDir#" 
            nameConflict="makeunique"
            accept="application/pdf"
            result="uploadResult">
    
    <cfset savedFileName = uploadResult.serverFile>
    <cfset absPath = uploadDir & savedFileName>
    
    <!--- Validate file is actually a PDF --->
    <cfset fileContent = fileReadBinary(absPath)>
    <cfset fileHeader = toString(fileContent)>
    <cfif NOT left(fileHeader, 4) EQ "%PDF">
        <cffile action="delete" file="#absPath#">
        <cfthrow message="Uploaded file is not a valid PDF">
    </cfif>
    
    <!--- Compute SHA-256 hash for de-duplication --->
    <cfset sha256 = hash(fileContent, "SHA-256")>
    
    <!--- Get extra instructions if provided --->
    <cfset extraInstructions = form.extra ?: "">
    
    <!--- Build batch file arguments --->
    <cfset batchArgs = [absPath]>
    <cfif len(trim(extraInstructions))>
        <cfset arrayAppend(batchArgs, extraInstructions)>
    </cfif>
    
    <!--- Execute batch file --->
    <cflog file="summarize_upload" type="information" text="Executing batch: #batchFile# with args: #arrayToList(batchArgs, ' ')#">
    <cflog file="summarize_upload" type="information" text="File: #savedFileName# (SHA-256: #left(sha256, 16)#...)">
    
    <cfexecute name="#batchFile#"
               arguments="#batchArgs#"
               timeout="300"
               variable="pyOutput"
               errorVariable="pyError">
    </cfexecute>
    
    <!--- Log raw output for debugging --->
    <cflog file="summarize_upload" type="information" text="Python stdout length: #len(pyOutput)#">
    <cflog file="summarize_upload" type="information" text="Python stderr: #pyError#">
    
    <!--- Log first 500 chars of output for inspection --->
    <cfif len(pyOutput) GT 0>
        <cflog file="summarize_upload" type="information" text="Python stdout preview: #left(pyOutput, 500)#">
    </cfif>
    
    <!--- Log stderr details if present --->
    <cfif len(trim(pyError)) GT 0>
        <cflog file="summarize_upload_errors" type="warning" text="Python stderr output: #pyError#">
    </cfif>
    
    <!--- Strip HTML comments from output (in case they leak through) --->
    <cfset cleanedOutput = reReplace(pyOutput, "<!--.*?-->", "", "ALL")>
    <cfset trimmedOutput = trim(cleanedOutput)>
    
    <!--- Check if output looks like JSON --->
    <cfset trimmedOutput = trim(trimmedOutput)>
    <cfif NOT (left(trimmedOutput, 1) EQ "{") AND NOT (left(trimmedOutput, 1) EQ "[")>
        <!--- Python returned non-JSON output (likely an error page or HTML) --->
        <cflog file="summarize_upload_errors" type="error" text="Python returned non-JSON output. First 500 chars: #left(pyOutput, 500)#">
        <cflog file="summarize_upload_errors" type="error" text="Full stderr: #pyError#">
        <cfset errorResponse = {
            "error": "Python script failed to return valid JSON",
            "python_stdout": left(pyOutput, 2000),
            "python_stderr": pyError,
            "upload_sha256": sha256
        }>
        <cfheader statuscode="500" statustext="Python Execution Error">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>
    
    <!--- Parse Python JSON output (using cleaned output) --->
    <cftry>
        <cfset data = deserializeJSON(trimmedOutput)>
        <cflog file="summarize_upload" type="information" text="Successfully parsed JSON response">
        
        <cfcatch type="any">
            <!--- If JSON parsing fails, return error with raw output for debugging --->
            <cflog file="summarize_upload_errors" type="error" text="JSON parse error: #cfcatch.message#">
            <cflog file="summarize_upload_errors" type="error" text="Raw output causing error: #left(trimmedOutput, 1000)#">
            <cfset errorResponse = {
                "error": "Failed to parse Python output as JSON",
                "parse_error": cfcatch.message,
                "raw_output": left(pyOutput, 2000),
                "python_error": pyError,
                "upload_sha256": sha256
            }>
            <cfheader statuscode="500" statustext="JSON Parse Error">
            <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
            <cfabort>
        </cfcatch>
    </cftry>
    
    <!--- Add upload metadata to response --->
    <cfset data.upload_sha256 = sha256>
    <cfset data.uploaded_filename = savedFileName>
    <cfset data.upload_time = now()>
    
    <!--- INSERT document record into database --->
    <!--- Use all-zeros GUID for ad-hoc uploads: 00000000-0000-0000-0000-000000000000 --->
    <cfset newDocUid = createUUID()>
    
    <!--- Log all values being inserted for debugging --->
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - doc_uid: #newDocUid#">
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - pdf_title: Ad-Hoc Upload: #savedFileName#">
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - rel_path: uploads/#savedFileName#">
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - ocr_text length: #structKeyExists(data, 'ocr_text') ? len(data.ocr_text) : 0#">
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - summary_text length: #structKeyExists(data, 'summary_text') ? len(data.summary_text) : 0#">
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - summary_html length: #structKeyExists(data, 'summary_html') ? len(data.summary_html) : 0#">
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - fields JSON length: #structKeyExists(data, 'fields') ? len(serializeJSON(data.fields)) : 0#">
    <cflog file="summarize_upload" type="information" text="INSERT VALUES - file_size: #uploadResult.fileSize ?: 'N/A'#">
    
    <cftry>
        <cfquery datasource="Reach">
            INSERT INTO docketwatch.dbo.documents (
                doc_uid,
                fk_case_event,
                pdf_title,
                rel_path,
                ocr_text,
                summary_ai,
                summary_ai_html,
                summary_ai_extraction_json,
                date_downloaded,
                ai_processed_at,
                file_size
            )
            VALUES (
                '#newDocUid#',
                '00000000-0000-0000-0000-000000000000',
                <cfqueryparam cfsqltype="cf_sql_varchar" value="Ad-Hoc Upload: #savedFileName#">,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="uploads/#savedFileName#">,
                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#structKeyExists(data, 'ocr_text') ? data.ocr_text : ''#" null="#!structKeyExists(data, 'ocr_text') OR !len(trim(data.ocr_text))#">,
                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#structKeyExists(data, 'summary_text') ? data.summary_text : ''#" null="#!structKeyExists(data, 'summary_text') OR !len(trim(data.summary_text))#">,
                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#structKeyExists(data, 'summary_html') ? data.summary_html : ''#" null="#!structKeyExists(data, 'summary_html') OR !len(trim(data.summary_html))#">,
                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#structKeyExists(data, 'fields') ? serializeJSON(data.fields) : ''#" null="#!structKeyExists(data, 'fields')#">,
                GETDATE(),
                GETDATE(),
                <cfqueryparam cfsqltype="cf_sql_integer" value="#uploadResult.fileSize#" null="#!structKeyExists(uploadResult, 'fileSize')#">
            )
        </cfquery>
        
        <!--- Set the doc_uid in response --->
        <cfset data.doc_uid = newDocUid>
        <cflog file="summarize_upload" type="information" text="Created document record: #newDocUid# for file: #savedFileName#">
        
        <cfcatch type="database">
            <cflog file="summarize_upload_errors" type="error" text="Database INSERT error: #cfcatch.message# - #cfcatch.detail#">
            <cflog file="summarize_upload_errors" type="error" text="SQL State: #cfcatch.sqlState ?: 'N/A'#, Native Error: #cfcatch.nativeErrorCode ?: 'N/A'#">
            <cflog file="summarize_upload_errors" type="error" text="SQL String: #cfcatch.sql ?: 'N/A'#">
            <!--- Don't fail the whole request, just log it --->
            <cfset data.doc_uid = "">
            <cfset data.db_error = cfcatch.message>
            <cfset data.db_error_detail = cfcatch.detail>
            <cfset data.db_error_sql = cfcatch.sql ?: "">
            <cfset data.db_error_sqlstate = cfcatch.sqlState ?: "">
            <cfset data.db_error_native = cfcatch.nativeErrorCode ?: "">
            <cfset data.db_insert_params = {
                "doc_uid": newDocUid,
                "fk_case_event": "00000000-0000-0000-0000-000000000000",
                "pdf_title": "Ad-Hoc Upload: #savedFileName#",
                "rel_path": "uploads/#savedFileName#",
                "ocr_text_length": structKeyExists(data, 'ocr_text') ? len(data.ocr_text) : 0,
                "summary_text_length": structKeyExists(data, 'summary_text') ? len(data.summary_text) : 0,
                "summary_html_length": structKeyExists(data, 'summary_html') ? len(data.summary_html) : 0,
                "fields_json_length": structKeyExists(data, 'fields') ? len(serializeJSON(data.fields)) : 0,
                "file_size": uploadResult.fileSize ?: 0
            }>
        </cfcatch>
    </cftry>
    
    <!--- Update structured fields if extraction succeeded --->
    <cfif structKeyExists(data, "fields") AND isStruct(data.fields) AND structKeyExists(data, "doc_uid") AND len(trim(data.doc_uid))>
        <cftry>
            <cfset fields = data.fields>
            
            <cfquery datasource="Reach">
                UPDATE docketwatch.dbo.documents
                SET
                    event_summary = <cfqueryparam cfsqltype="cf_sql_varchar" value="#structKeyExists(fields, 'filing_action_summary') ? left(fields.filing_action_summary, 500) : ''#" null="#!structKeyExists(fields, 'filing_action_summary') OR !len(trim(fields.filing_action_summary))#">,
                    newsworthiness = <cfqueryparam cfsqltype="cf_sql_varchar" value="#structKeyExists(fields, 'newsworthiness') ? fields.newsworthiness : ''#" null="#!structKeyExists(fields, 'newsworthiness') OR !len(trim(fields.newsworthiness))#">,
                    newsworthiness_reason = <cfqueryparam cfsqltype="cf_sql_varchar" value="#structKeyExists(fields, 'newsworthiness_reason') ? left(fields.newsworthiness_reason, 200) : ''#" null="#!structKeyExists(fields, 'newsworthiness_reason') OR !len(trim(fields.newsworthiness_reason))#">
                WHERE doc_uid = '#data.doc_uid#'
            </cfquery>
            
            <cflog file="summarize_upload" type="information" text="Updated structured fields for doc_uid: #data.doc_uid#">
            
            <cfcatch type="database">
                <cflog file="summarize_upload_errors" type="error" text="Database UPDATE error: #cfcatch.message# - #cfcatch.detail#">
                <!--- Don't fail the whole request --->
            </cfcatch>
        </cftry>
    </cfif>
    
    <!--- Log errors if any occurred during processing --->
    <cfif structKeyExists(data, "errors") AND isArray(data.errors) AND arrayLen(data.errors) GT 0>
        <cflog file="summarize_upload" type="error" text="Processing errors for doc #data.doc_uid#: #arrayToList(data.errors, '; ')#">
        
        <!--- Log detailed error information for debugging --->
        <cfloop array="#data.errors#" index="err">
            <cflog file="summarize_upload_errors" type="error" text="Error detail: #err#">
        </cfloop>
        
        <!--- Log entire response for debugging when errors occur --->
        <cflog file="summarize_upload_errors" type="error" text="Full response with errors: #serializeJSON(data)#">
    </cfif>
    
    <!--- Log successful processing with key metrics --->
    <cfif NOT structKeyExists(data, "errors") OR arrayLen(data.errors) EQ 0>
        <cfset hasFields = structKeyExists(data, "fields") AND isStruct(data.fields)>
        <cfset fieldCount = hasFields ? structCount(data.fields) : 0>
        <cflog file="summarize_upload" type="information" text="Successful processing for doc #data.doc_uid#. Fields extracted: #fieldCount#. Model: #data.model_name ?: 'unknown'#">
    </cfif>
    
    <!--- Clean up uploaded file after processing (optional - comment out to keep files) --->
    <!--- <cffile action="delete" file="#absPath#"> --->
    
    <!--- Return successful response --->
    <cfoutput>#serializeJSON(data)#</cfoutput>
    
    <cfcatch type="any">
        <!--- Log error --->
        <cflog file="summarize_upload_errors" type="error" text="Unhandled error: #cfcatch.message# - #cfcatch.detail#">
        <cflog file="summarize_upload_errors" type="error" text="Error type: #cfcatch.type#, Tag context: #cfcatch.tagContext[1].template ?: 'unknown'# line #cfcatch.tagContext[1].line ?: 'unknown'#">
        
        <!--- Return error response --->
        <cfheader statuscode="500" statustext="Internal Server Error">
        <cfset errorResponse = {
            "error": cfcatch.message,
            "detail": cfcatch.detail,
            "type": cfcatch.type
        }>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
    </cfcatch>
</cftry>
