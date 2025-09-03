<cfheader name="Content-Type" content="application/json">

<cfparam name="form.eventId" default="">

<cfset response = structNew()>
<cfset response.success = false>
<cfset response.message = "">

<cftry>
    <cfif len(form.eventId)>
        <!--- Update the event to mark as acknowledged --->
        <cfquery name="updateEvent" datasource="Reach">
            UPDATE docketwatch.dbo.case_events 
            SET acknowledged = 1,
                acknowledged_at = GETDATE(),
                acknowledged_by = <cfqueryparam value="#getauthuser()#" cfsqltype="cf_sql_varchar">
            WHERE id = <cfqueryparam value="#form.eventId#" cfsqltype="cf_sql_integer">
        </cfquery>
        
        <cfset response.success = true>
        <cfset response.message = "Event acknowledged successfully">
    <cfelse>
        <cfset response.message = "Event ID is required">
    </cfif>
    
    <cfcatch type="any">
        <cfset response.success = false>
        <cfset response.message = "Error: " & cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
