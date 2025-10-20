<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<cftry>
    <cfset scriptName = "summarize_upload">
    <cfset uploadDir = "U:\docketwatch\uploads\">
    <cfset pythonExe = "C:\Program Files\Python312\python.exe">
    <cfset pythonScript = "U:\docketwatch\python\summarize_upload_cli.py">
    
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
    <cfset fileHeader = toString(binarySubstring(fileContent, 1, 4))>
    <cfif NOT find("%PDF", fileHeader)>
        <cffile action="delete" file="#absPath#">
        <cfthrow message="Uploaded file is not a valid PDF">
    </cfif>
    
    <!--- Compute SHA-256 hash for de-duplication --->
    <cfset sha256 = hash(fileContent, "SHA-256")>
    
    <!--- Get extra instructions if provided --->
    <cfset extraInstructions = form.extra ?: "">
    
    <!--- Build Python command arguments as array --->
    <cfset scriptArgs = [pythonScript, "--in", absPath]>
    <cfif len(trim(extraInstructions))>
        <cfset arrayAppend(scriptArgs, "--extra")>
        <cfset arrayAppend(scriptArgs, extraInstructions)>
    </cfif>
    
    <!--- Execute Python script --->
    <cfexecute name="#pythonExe#"
               arguments="#scriptArgs#"
               timeout="300"
               variable="pyOutput"
               errorVariable="pyError">
    </cfexecute>
    
    <!--- Log raw output for debugging --->
    <cflog file="summarize_upload" text="Python stdout length: #len(pyOutput)#">
    <cflog file="summarize_upload" text="Python stderr: #pyError#">
    
    <!--- Check if output looks like JSON --->
    <cfset trimmedOutput = trim(pyOutput)>
    <cfif NOT (left(trimmedOutput, 1) EQ "{") AND NOT (left(trimmedOutput, 1) EQ "[")>
        <!--- Python returned non-JSON output (likely an error page or HTML) --->
        <cflog file="summarize_upload" text="Python returned non-JSON: #left(pyOutput, 500)#">
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
    
    <!--- Parse Python JSON output --->
    <cftry>
        <cfset data = deserializeJSON(pyOutput)>
        
        <cfcatch type="any">
            <!--- If JSON parsing fails, return error with raw output for debugging --->
            <cflog file="summarize_upload" text="JSON parse error: #cfcatch.message#">
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
    
    <!--- Optional: Persist to documents table if doc_uid was generated --->
    <!--- This allows reuse of the document in other parts of the system --->
    <cfif structKeyExists(data, "doc_uid") AND len(trim(data.doc_uid))>
        <cfquery datasource="Reach">
            UPDATE docketwatch.dbo.documents
            SET summary_ai = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#data.summary_text#" null="#!structKeyExists(data, 'summary_text') OR !len(trim(data.summary_text))#">,
                summary_ai_html = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#data.summary_html#" null="#!structKeyExists(data, 'summary_html') OR !len(trim(data.summary_html))#">,
                ocr_text = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#data.ocr_text#" null="#!structKeyExists(data, 'ocr_text') OR !len(trim(data.ocr_text))#">,
                ai_processed_at = GETDATE()
            WHERE doc_uid = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#data.doc_uid#"> AS UNIQUEIDENTIFIER)
        </cfquery>
    </cfif>
    
    <!--- Clean up uploaded file after processing (optional - comment out to keep files) --->
    <!--- <cffile action="delete" file="#absPath#"> --->
    
    <!--- Return successful response --->
    <cfoutput>#serializeJSON(data)#</cfoutput>
    
    <cfcatch type="any">
        <!--- Log error --->
        <cflog file="summarize_upload" text="Error: #cfcatch.message# - #cfcatch.detail#">
        
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
