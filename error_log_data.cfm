<cfparam name="url.action" default="getData">

<cfif url.action EQ "getData">
    <!--- Main data query for DataTable --->
    <cfquery name="getErrorLog" datasource="reach">
        SELECT TOP 1000
            id,
            script_name,
            error_type,
            error_message,
            error_timestamp,
            stack_trace,
            fk_task_run,
            fk_case,
            email_sent,
            email_sent_timestamp,
            severity,
            environment,
            resolved,
            resolved_timestamp,
            resolved_by,
            additional_context,
            created_at,
            updated_at
        FROM docketwatch.dbo.error_notifications
        ORDER BY created_at DESC
    </cfquery>

    <cfset errorArray = []>

    <cfloop query="getErrorLog">
        <cfset errorData = {}>
        <cfset errorData.id = id>
        <cfset errorData.script_name = script_name>
        <cfset errorData.error_type = error_type ?: "Unknown">
        <cfset errorData.error_message = error_message ?: "">
        <cfset errorData.error_timestamp = error_timestamp>
        <cfset errorData.stack_trace = stack_trace ?: "">
        <cfset errorData.fk_task_run = fk_task_run ?: "">
        <cfset errorData.fk_case = fk_case ?: "">
        <cfset errorData.email_sent = email_sent ?: 0>
        <cfset errorData.email_sent_timestamp = email_sent_timestamp>
        <cfset errorData.severity = severity ?: "ERROR">
        <cfset errorData.environment = environment ?: "">
        <cfset errorData.resolved = resolved ?: 0>
        <cfset errorData.resolved_timestamp = resolved_timestamp>
        <cfset errorData.resolved_by = resolved_by ?: "">
        <cfset errorData.additional_context = additional_context ?: "">
        <cfset errorData.created_at = created_at>
        <cfset errorData.updated_at = updated_at>

        <!--- Format timestamps for display --->
        <cfif IsDate(created_at)>
            <cfset errorData.formatted_created_at = DateFormat(created_at, "mm/dd/yyyy") & " " & TimeFormat(created_at, "hh:mm:ss tt")>
            <cfset errorData.sortable_created_at = DateFormat(created_at, "yyyy-mm-dd") & " " & TimeFormat(created_at, "HH:mm:ss")>
        <cfelse>
            <cfset errorData.formatted_created_at = "No Date">
            <cfset errorData.sortable_created_at = "">
        </cfif>

        <cfif IsDate(email_sent_timestamp)>
            <cfset errorData.formatted_email_sent_timestamp = DateFormat(email_sent_timestamp, "mm/dd/yyyy") & " " & TimeFormat(email_sent_timestamp, "hh:mm:ss tt")>
        <cfelse>
            <cfset errorData.formatted_email_sent_timestamp = "">
        </cfif>

        <cfif IsDate(resolved_timestamp)>
            <cfset errorData.formatted_resolved_timestamp = DateFormat(resolved_timestamp, "mm/dd/yyyy") & " " & TimeFormat(resolved_timestamp, "hh:mm:ss tt")>
        <cfelse>
            <cfset errorData.formatted_resolved_timestamp = "">
        </cfif>

        <cfset ArrayAppend(errorArray, errorData)>
    </cfloop>

    <cfcontent type="application/json">
    <cfoutput>#SerializeJSON(errorArray)#</cfoutput>

<cfelseif url.action EQ "getScripts">
    <!--- Get unique script names for filter dropdown --->
    <cfquery name="getScripts" datasource="reach">
        SELECT DISTINCT script_name 
        FROM docketwatch.dbo.error_notifications
        WHERE script_name IS NOT NULL
        ORDER BY script_name
    </cfquery>

    <cfset scriptArray = []>
    <cfloop query="getScripts">
        <cfset ArrayAppend(scriptArray, script_name)>
    </cfloop>

    <cfcontent type="application/json">
    <cfoutput>#SerializeJSON(scriptArray)#</cfoutput>

<cfelseif url.action EQ "getStackTrace">
    <!--- Get stack trace for specific error --->
    <cfparam name="url.id" default="0">
    
    <cfquery name="getStackTrace" datasource="reach">
        SELECT stack_trace
        FROM docketwatch.dbo.error_notifications
        WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset result = {}>
    <cfif getStackTrace.recordCount GT 0>
        <cfset result.stack_trace = getStackTrace.stack_trace ?: "">
    <cfelse>
        <cfset result.stack_trace = "">
    </cfif>

    <cfcontent type="application/json">
    <cfoutput>#SerializeJSON(result)#</cfoutput>

<cfelseif url.action EQ "updateStatus">
    <!--- Update error resolution status --->
    <cfparam name="form.id" default="0">
    <cfparam name="form.resolved" default="0">

    <cfset result = {}>
    
    <cftry>
        <cfquery name="updateError" datasource="reach">
            UPDATE docketwatch.dbo.error_notifications
            SET 
                resolved = <cfqueryparam value="#form.resolved#" cfsqltype="cf_sql_bit">,
                resolved_timestamp = <cfif form.resolved EQ 1>GETDATE()<cfelse>NULL</cfif>,
                resolved_by = <cfif form.resolved EQ 1><cfqueryparam value="Admin User" cfsqltype="cf_sql_varchar"><cfelse>NULL</cfif>,
                updated_at = GETDATE()
            WHERE id = <cfqueryparam value="#form.id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset result.success = true>
        <cfset result.message = "Status updated successfully">

        <cfcatch type="any">
            <cfset result.success = false>
            <cfset result.message = "Database error: " & cfcatch.message>
        </cfcatch>
    </cftry>

    <cfcontent type="application/json">
    <cfoutput>#SerializeJSON(result)#</cfoutput>

<cfelse>
    <!--- Invalid action --->
    <cfset result = {}>
    <cfset result.success = false>
    <cfset result.message = "Invalid action">

    <cfcontent type="application/json">
    <cfoutput>#SerializeJSON(result)#</cfoutput>
</cfif>
