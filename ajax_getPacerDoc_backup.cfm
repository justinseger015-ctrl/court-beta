<cfsetting showdebugoutput="false">

<!---
    This script handles the AJAX request from the case events page to download a PDF from PACER.
    It validates incoming parameters, securely calls a Python script to do the actual download,
    updates the database with the result, and returns a JSON response to the browser.
--->

<cfparam name="form.docID" type="string">
<cfparam name="form.eventURL" type="string">
<cfparam name="form.caseID" type="string">

<cfset response = {
    STATUS = "ERROR",
    MESSAGE = "An unknown error occurred.",
    FILEPATH = "",
    DEBUG = {
        docID = form.docID,
        eventURL = form.eventURL,
        caseID = form.caseID
    }
}>

<cftry>
    <!--- Check if this is a valid case event --->
    <cfquery name="checkEvent" datasource="Reach">
        SELECT 
            ce.id as event_id,
            ce.event_no,
            ce.event_description,
            ce.event_url,
            d.doc_uid,
            d.rel_path,
            d.doc_id,
            c.case_number,
            c.case_name,
            t.tool_name
        FROM docketwatch.dbo.case_events ce
        LEFT JOIN docketwatch.dbo.documents d ON ce.id = d.fk_case_event
        INNER JOIN docketwatch.dbo.cases c ON ce.fk_cases = c.id
        LEFT JOIN docketwatch.dbo.tools t ON t.id = c.fk_tool
        WHERE ce.id = <cfqueryparam value="#form.docID#" cfsqltype="cf_sql_varchar">
        ORDER BY d.pdf_type ASC
    </cfquery>
    
    <cfif checkEvent.recordCount EQ 0>
        <cfset response.MESSAGE = "Event not found. Searched for event ID: #form.docID#">
        <cfset response.DEBUG.queryRecordCount = 0>
    <cfelseif checkEvent.tool_name NEQ "Pacer">
        <cfset response.MESSAGE = "This feature only works with Pacer events. Found tool: #checkEvent.tool_name#">
        <cfset response.DEBUG.toolName = checkEvent.tool_name>
        <cfset response.DEBUG.queryRecordCount = checkEvent.recordCount>
    <cfelse>
        <cfset response.DEBUG.toolName = checkEvent.tool_name>
        <cfset response.DEBUG.queryRecordCount = checkEvent.recordCount>
        <cfset response.DEBUG.eventNo = checkEvent.event_no>
        
        <!--- Define full, absolute paths for the Python executable and your script --->
        <cfset pythonExecutable = "C:\Program Files\Python312\python.exe">
        <cfset pythonScriptPath = "#ExpandPath('.')#\python\combined_pacer_pdf_processor.py">
        <cfset response.DEBUG.pythonPath = pythonScriptPath>
        <cfset response.DEBUG.pythonExists = FileExists(pythonScriptPath)>
        
        <!--- Create case-specific folder structure --->
        <cfset pdfSaveFolder = "#ExpandPath('.')#\docs\cases\#form.caseID#\">
        <cfif NOT DirectoryExists(pdfSaveFolder)>
            <cfdirectory action="create" directory="#pdfSaveFolder#" mode="755">
        </cfif>
        
        <!--- Create filename based on event number --->
        <cfset pdfFilename = "E#checkEvent.event_no#.pdf">
        <cfset fullPdfPath = pdfSaveFolder & pdfFilename>
        <cfset webAccessiblePath = "/docs/cases/#form.caseID#/#pdfFilename#">

        <!--- Build the command line arguments - use event_url from database or form.eventURL --->
        <cfset eventURL = "">
        <cfif len(form.eventURL)>
            <cfset eventURL = form.eventURL>
            <cfset response.DEBUG.urlSource = "form">
        <cfelseif len(checkEvent.event_url)>
            <cfset eventURL = checkEvent.event_url>
            <cfset response.DEBUG.urlSource = "database">
        <cfelse>
            <cfset response.MESSAGE = "No event URL available for PDF download.">
            <cfset response.STATUS = "ERROR">
            <cfset response.DEBUG.urlSource = "none">
        </cfif>
        
        <cfset response.DEBUG.eventURL = eventURL>
        
        <cfif response.STATUS NEQ "ERROR">
            <cfset scriptArgs = [pythonScriptPath, eventURL, fullPdfPath]>
            <cfset response.DEBUG.scriptArgs = scriptArgs>
            <cfset response.DEBUG.pdfSaveFolder = pdfSaveFolder>
            <cfset response.DEBUG.fullPdfPath = fullPdfPath>

            <!--- Execute the Python script --->
            <cfexecute
                name="#pythonExecutable#"
                arguments="#scriptArgs#"
                variable="pythonOutput"
                timeout="30"
                errorVariable="pythonError"
            />
            
            <cfset response.DEBUG.pythonOutput = pythonOutput>
            <cfset response.DEBUG.pythonError = pythonError>

            <cfif len(trim(pythonError))>
                <!--- Catches errors from the Python execution environment itself --->
                <cfset response.MESSAGE = "Python execution error: #HtmlEditFormat(pythonError)#">
            <cfelse>
                <!--- The Python script should print a JSON string on success/failure --->
                <cftry>
                    <cfset pythonResponse = DeserializeJSON(pythonOutput)>

                    <cfif pythonResponse.status EQ "success">
                        <cfset response.STATUS = "SUCCESS">
                        <cfset response.MESSAGE = "PDF downloaded successfully.">
                        <cfset response.FILEPATH = webAccessiblePath>

                    <!--- Update or insert document record --->
                    <cfif len(checkEvent.doc_uid)>
                        <!--- Update existing document record --->
                        <cfquery datasource="Reach">
                            UPDATE docketwatch.dbo.documents
                            SET
                                rel_path = <cfqueryparam value="cases\#form.caseID#\#pdfFilename#" cfsqltype="cf_sql_varchar">,
                                updated_at = GETDATE()
                            WHERE doc_uid = <cfqueryparam value="#checkEvent.doc_uid#" cfsqltype="cf_sql_varchar">
                        </cfquery>
                    <cfelse>
                        <!--- Create new document record --->
                        <cfquery datasource="Reach">
                            INSERT INTO docketwatch.dbo.documents (
                                doc_uid,
                                fk_case_event,
                                pdf_title,
                                rel_path,
                                doc_id,
                                created_at,
                                updated_at
                            ) VALUES (
                                <cfqueryparam value="#CreateUUID()#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#form.docID#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="Event #checkEvent.event_no# - #checkEvent.event_description#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="cases\#form.caseID#\#pdfFilename#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#checkEvent.event_no#" cfsqltype="cf_sql_integer">,
                                GETDATE(),
                                GETDATE()
                            )
                        </cfquery>
                    </cfif>

                <cfelse>
                    <!--- The script ran, but reported a failure (e.g., auth failed, link broken) --->
                    <cfset response.MESSAGE = "Python script failed: #HtmlEditFormat(pythonResponse.message)#">
                </cfif>
                <cfcatch type="json">
                     <cfset response.MESSAGE = "Failed to parse JSON response from Python script. Output: #HtmlEditFormat(pythonOutput)#">
                </cfcatch>
                </cftry>
            </cfif>
        </cfif>
    </cfif>

    <cfcatch type="any">
        <cfset response.MESSAGE = "A ColdFusion error occurred: #HtmlEditFormat(cfcatch.Message)#">
        <cfset response.DEBUG.errorType = cfcatch.Type>
        <cfset response.DEBUG.errorDetail = cfcatch.Detail>
        <cfset response.DEBUG.errorTagContext = cfcatch.TagContext>
    </cfcatch>
</cftry>

<!--- Return the final JSON response to the browser's AJAX call --->
<cfcontent type="application/json">
<cfoutput>#SerializeJSON(response)#</cfoutput>