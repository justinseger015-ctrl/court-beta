<cfcontent reset="true">
<cfsetting enablecfoutputonly="true">

<!--- Reset All Acknowledgments Endpoint for DocketWatch Monitor --->
<cfparam name="url.bypass" default="">

<!--- Security check - only allow xkking --->
<cfif NOT isDefined("session.user_login") OR session.user_login NEQ "xkking">
    <cfset response = {
        "success" = false,
        "message" = "Unauthorized access"
    }>
    <cfoutput>#serializeJSON(response)#</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <!--- Reset all acknowledged fields to NULL --->
    <cfquery name="resetAcknowledgments" datasource="cmtemp">
        UPDATE case_events 
        SET 
            acknowledged = NULL,
            acknowledged_at = NULL,
            acknowledged_by = NULL
        WHERE acknowledged IS NOT NULL
    </cfquery>
    
    <!--- Success response --->
    <cfset response = {
        "success" = true,
        "message" = "All acknowledgments have been reset",
        "recordsReset" = resetAcknowledgments.recordCount
    }>
    
    <cfcatch>
        <!--- Error response --->
        <cfset response = {
            "success" = false,
            "message" = "Error resetting acknowledgments: " & cfcatch.message,
            "detail" = cfcatch.detail
        }>
    </cfcatch>
</cftry>

<!--- Return JSON response --->
<cfcontent type="application/json">
<cfoutput>#serializeJSON(response)#</cfoutput>
