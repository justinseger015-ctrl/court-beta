<cfcontent type="application/json" />

<cfparam name="form.docID" type="string">
<cfparam name="form.eventURL" type="string">
<cfparam name="form.caseID" type="string">

<cfset response = {
    STATUS = "ERROR",
    MESSAGE = "An unknown error occurred.",
    FILEPATH = ""
}>

<cftry>
    <cfset startTime = now()>
    <cfset taskName = "Single Case Event PDF Processing">
    
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
        <!--- Create case-specific folder structure --->
        <cfset pdfSaveFolder = "#ExpandPath('.')#\docs\cases\#form.caseID#\">
        <cfif NOT DirectoryExists(pdfSaveFolder)>
            <cfdirectory action="create" directory="#pdfSaveFolder#" mode="755">
        </cfif>
        
        <!--- Create filename based on event number --->
        <cfset pdfFilename = "E#checkEvent.event_no#.pdf">
        <cfset fullPdfPath = pdfSaveFolder & pdfFilename>
        <cfset webAccessiblePath = "/docs/cases/#form.caseID#/#pdfFilename#">

        <!--- Execute the batch file using the scheduler pattern --->
        <cfexecute name="u:\docketwatch\python\process_single_case_event.bat"
                   arguments="#form.docID#"
                   timeout="300"
                   variable="output"
                   errorVariable="errorOutput">
        </cfexecute>

        <cfset endTime = now()>
        <cfset executionTime = dateDiff("s", startTime, endTime)>

        <!--- Check for errors --->
        <cfif len(trim(errorOutput)) GT 0>
            <cfset response.MESSAGE = "Python script error: #HtmlEditFormat(errorOutput)#">
        <cfelse>
            <!--- Check if PDF file was created --->
            <cfif FileExists(fullPdfPath)>
                <cfset response.STATUS = "SUCCESS">
                <cfset response.MESSAGE = "PDF downloaded successfully in #executionTime# seconds.">
                <cfset response.FILEPATH = webAccessiblePath>
            <cfelse>
                <cfset response.STATUS = "PROCESSING">
                <cfset response.MESSAGE = "PDF processing completed. Check back in a moment for the file.">
                <cfset response.FILEPATH = webAccessiblePath>
            </cfif>
        </cfif>
    </cfif>

    <cfcatch>
        <cfset response.MESSAGE = "Script execution failed: #cfcatch.message#">
    </cfcatch>
</cftry>

<cfoutput>#SerializeJSON(response)#</cfoutput>