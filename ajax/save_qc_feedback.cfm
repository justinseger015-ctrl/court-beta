<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<cftry>
    <!--- Get JSON body from request --->
    <cfset requestBody = toString(getHttpRequestData().content)>
    
    <!--- Parse JSON --->
    <cfset payload = deserializeJSON(requestBody)>
    
    <!--- Get current user (from session or CGI) --->
    <cfset userName = "">
    <cfif structKeyExists(session, "username")>
        <cfset userName = session.username>
    <cfelseif structKeyExists(cgi, "remote_user") AND len(trim(cgi.remote_user))>
        <cfset userName = cgi.remote_user>
    <cfelseif structKeyExists(cgi, "auth_user") AND len(trim(cgi.auth_user))>
        <cfset userName = cgi.auth_user>
    <cfelse>
        <cfset userName = "anonymous">
    </cfif>
    
    <!--- Validate required fields --->
    <cfif NOT structKeyExists(payload, "success")>
        <cfthrow message="Missing required field: success">
    </cfif>
    
    <!--- Insert QC feedback --->
    <cfquery datasource="Reach">
        INSERT INTO docketwatch.dbo.summary_qc_feedback (
            doc_uid,
            upload_sha256,
            user_name,
            success,
            notes,
            model_name,
            created_at
        ) VALUES (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#payload.doc_uid ?: ''#" null="#!structKeyExists(payload, 'doc_uid') OR !len(trim(payload.doc_uid))#">,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#payload.upload_sha256 ?: ''#" null="#!structKeyExists(payload, 'upload_sha256') OR !len(trim(payload.upload_sha256))#">,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#userName#">,
            <cfqueryparam cfsqltype="cf_sql_bit" value="#payload.success#">,
            <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#payload.notes ?: ''#" null="#!structKeyExists(payload, 'notes') OR !len(trim(payload.notes))#">,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#payload.model_name ?: ''#" null="#!structKeyExists(payload, 'model_name') OR !len(trim(payload.model_name))#">,
            SYSUTCDATETIME()
        )
    </cfquery>
    
    <!--- Return success response --->
    <cfset response = {"ok": true, "message": "QC feedback saved successfully"}>
    <cfoutput>#serializeJSON(response)#</cfoutput>
    
    <cfcatch type="any">
        <!--- Log error --->
        <cflog file="summarize_upload_qc" text="Error saving QC feedback: #cfcatch.message# - #cfcatch.detail#">
        
        <!--- Return error response --->
        <cfheader statuscode="500" statustext="Internal Server Error">
        <cfset errorResponse = {
            "ok": false,
            "error": cfcatch.message,
            "detail": cfcatch.detail
        }>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
    </cfcatch>
</cftry>
