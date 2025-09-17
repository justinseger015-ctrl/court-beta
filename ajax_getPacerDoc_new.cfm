<cfcontent type="application/json" />

<cfparam name="form.docID" type="string">
<cfparam name="form.eventURL" type="string">
<cfparam name="form.caseID" type="string">

<cfset response = {
    STATUS = "ERROR",
    MESSAGE = "An unknown error occurred.",
    FILEPATH = ""
}>

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
<cfelseif checkEvent.tool_name NEQ "Pacer">
    <cfset response.MESSAGE = "This feature only works with Pacer events. Found tool: #checkEvent.tool_name#">
<cfelse>
    <!--- Define paths --->
    <cfset pythonExecutable = "C:\Program Files\Python312\python.exe">
    <cfset pythonScriptPath = "#ExpandPath('.')#\python\combined_pacer_pdf_processor.py">
    
    <!--- Create case-specific folder structure --->
    <cfset pdfSaveFolder = "#ExpandPath('.')#\docs\cases\#form.caseID#\">
    <cfif NOT DirectoryExists(pdfSaveFolder)>
        <cfdirectory action="create" directory="#pdfSaveFolder#" mode="755">
    </cfif>
    
    <!--- Create filename based on event number --->
    <cfset pdfFilename = "E#checkEvent.event_no#.pdf">
    <cfset fullPdfPath = pdfSaveFolder & pdfFilename>
    <cfset webAccessiblePath = "/docs/cases/#form.caseID#/#pdfFilename#">

    <!--- Get event URL --->
    <cfset eventURL = "">
    <cfif len(form.eventURL)>
        <cfset eventURL = form.eventURL>
    <cfelseif len(checkEvent.event_url)>
        <cfset eventURL = checkEvent.event_url>
    <cfelse>
        <cfset response.MESSAGE = "No event URL available for PDF download.">
    </cfif>
    
    <cfif len(eventURL)>
        <cfset scriptArgs = [pythonScriptPath, eventURL, fullPdfPath]>

        <!--- Execute the Python script --->
        <cfexecute
            name="#pythonExecutable#"
            arguments="#scriptArgs#"
            variable="pythonOutput"
            timeout="30"
            errorVariable="pythonError"
        />

        <cfif len(trim(pythonError))>
            <cfset response.MESSAGE = "Python execution error: #HtmlEditFormat(pythonError)#">
        <cfelse>
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
                    <cfset response.MESSAGE = "Python script failed: #HtmlEditFormat(pythonResponse.message)#">
                </cfif>
                <cfcatch type="json">
                     <cfset response.MESSAGE = "Failed to parse JSON response from Python script. Output: #HtmlEditFormat(pythonOutput)#">
                </cfcatch>
            </cftry>
        </cfif>
    </cfif>
</cfif>

<cfoutput>#SerializeJSON(response)#</cfoutput>