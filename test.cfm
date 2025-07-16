<!---  fixMissingPacerDocs_tag.cfm  --->

<!--- ----------------------------------------------------------------
      CONFIG
------------------------------------------------------------------->
<cfset datasource = "reach">
<cfset basePath   = "U:\TMZTOOLS\mediaroot\pacer_pdfs\">
<cfset logName    = "docketwatch_missing_pdfs">

<!--- ----------------------------------------------------------------
      1. Fetch rows that claim to be downloaded
------------------------------------------------------------------->
<cfquery name="qRows" datasource="#datasource#">
    SELECT id, local_pdf_filename
    FROM   docketwatch.dbo.case_events_pdf
    WHERE  isdownloaded = 1
</cfquery>

<!--- ----------------------------------------------------------------
      2. Loop — flag rows whose file is gone
------------------------------------------------------------------->
<cfset missing = 0>
<cfoutput>
<cfloop query="qRows">
    <cfset pdfFull = basePath & qRows.local_pdf_filename>

    <cfif NOT fileExists(pdfFull)>
        <!--- mark as NOT downloaded --->
        <cfquery datasource="#datasource#">
            UPDATE docketwatch.dbo.case_events_pdf
            SET    isdownloaded = 0
            WHERE  id = <cfqueryparam cfsqltype="CF_SQL_CHAR" value="#qRows.id#">
        </cfquery>
Missing: #qRows.id# <BR>
        <!--- log --->
        <cflog file="#logName#" type="warning"
               text="Missing PDF flagged. id=#qRows.id#, expected=#pdfFull#">
        <cfset missing = missing + 1>
        <Cfelse>
        Found: #qRows.id# <BR>
    </cfif>
</cfloop>

<!--- ----------------------------------------------------------------
      3. Summary
------------------------------------------------------------------->
<cflog file="#logName#" type="information"
       text="PDF fix script complete. Missing flagged: #missing#">

<p>Done. Missing PDFs flagged: #missing#</p>
</cfoutput>