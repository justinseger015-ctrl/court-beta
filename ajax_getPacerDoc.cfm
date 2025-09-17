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
    <cfset vbsLauncherPath = "u:\docketwatch\python\launch_pdf_processor.vbs">
    
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
        <!--- Execute the VBScript launcher that runs async --->
        <cfexecute
            name="cscript.exe"
            arguments="//NoLogo #vbsLauncherPath# #form.docID#"
            timeout="2"
        />

        <!--- Return immediate success - processing started --->
        <cfset response.STATUS = "PROCESSING">
        <cfset response.MESSAGE = "PDF download process started. Please check back in a few moments.">
        <cfset response.FILEPATH = webAccessiblePath>
    </cfif>
</cfif>

<cfoutput>#SerializeJSON(response)#</cfoutput>