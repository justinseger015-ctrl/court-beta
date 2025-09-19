<!-- return JSON once -->
<cfcontent type="application/json" />

<!-- inputs -->
<cfparam name="form.docID"    type="string">
<cfparam name="form.eventURL" type="string">
<cfparam name="form.caseID"   type="string">

<cfset resp = { STATUS = "ERROR", MESSAGE = "Unknown error.", FILEPATH = "" }>

<cftry>
    <cfset started = now()>

    <!-- validate event -->
    <cfquery name="q" datasource="Reach">
        SELECT ce.id as event_id, ce.event_no, ce.event_url,
               c.case_name, c.case_number, t.tool_name
        FROM docketwatch.dbo.case_events ce
        JOIN docketwatch.dbo.cases c  ON c.id = ce.fk_cases
        LEFT JOIN docketwatch.dbo.tools t ON t.id = c.fk_tool
        WHERE ce.id = <cfqueryparam value="#form.docID#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfif q.recordCount EQ 0>
        <cfset resp.MESSAGE = "Event not found: #form.docID#">
        <cfoutput>#SerializeJSON(resp)#</cfoutput><cfabort>
    </cfif>
    <cfif q.tool_name NEQ "Pacer">
        <cfset resp.MESSAGE = "Only supported for PACER events. Tool: #q.tool_name#">
        <cfoutput>#SerializeJSON(resp)#</cfoutput><cfabort>
    </cfif>

    <!-- paths: use the same root your IIS /docs handler serves -->
    <!-- if you use a network share, prefer application.fileSharePath -->
    <cfset caseIdNum    = val(form.caseID)>
    <cfset pdfFileName  = "E#q.event_no#.pdf">
    <cfset webPath      = "/docs/cases/#caseIdNum#/#pdfFileName#">
    <cfset diskPathWeb  = ExpandPath(".") & "\docs\cases\" & caseIdNum & "\" & pdfFileName>
    <cfset diskFolderWeb= ExpandPath(".") & "\docs\cases\" & caseIdNum & "\" >

    <!-- ensure folder -->
    <cfif NOT DirectoryExists(diskFolderWeb)>
        <cfdirectory action="create" directory="#diskFolderWeb#">
    </cfif>

    <!-- run the worker: use BAT file instead of Python directly -->
    <cfset batFile = "U:\docketwatch\court-beta\pdf_download_processor.bat">
    <cfset args    = '"#form.docID#"'>
    <cfset outText = ""><cfset errText = "">

    <cfexecute name="#batFile#"
               arguments="#args#"
               variable="outText"
               errorVariable="errText"
               timeout="900">
    </cfexecute>

    <!-- evaluate result -->
    <cfset elapsed = dateDiff("s", started, now())>

    <cfif len(trim(errText))>
        <cflog file="docketwatch" type="error" text="ajax_getPacerDoc stderr: #left(errText,4000)#">
        <cfset resp.MESSAGE = "Python error. See logs.">
    <cfelseif FileExists(diskPathWeb)>
        <cfset resp = { STATUS="SUCCESS", MESSAGE="PDF ready in #elapsed#s.", FILEPATH=webPath }>
    <cfelse>
        <cfset resp = { STATUS="PROCESSING", MESSAGE="Worker ran. File not present yet.", FILEPATH=webPath }>
    </cfif>

    <cfcatch>
        <cflog file="docketwatch" type="error" text="ajax_getPacerDoc exception: #cfcatch.message# #cfcatch.detail#">
        <cfset resp.MESSAGE = "Exception: #cfcatch.message#">
    </cfcatch>
</cftry>

<cfoutput>#SerializeJSON(resp)#</cfoutput>
