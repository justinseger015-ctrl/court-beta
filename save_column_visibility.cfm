<cfcontent type="application/json">
<cftry>

<!--- Step 1: Parse JSON input --->
<cfset httpData = getHttpRequestData()>
<cfif structKeyExists(httpData, "content") AND len(httpData.content)>
    <cfset rawData = toString(httpData.content)>
<cfelse>
    <!--- Fallback for form data --->
    <cfset rawData = form.data>
</cfif>
<cfset requestData = deserializeJson(rawData)>
<cfset currentUser = getAuthUser()>

<!--- Debug: Check what getAuthUser() returns --->
<cfif NOT isDefined("currentUser") OR len(trim(currentUser)) EQ 0>
    <cfset currentUser = "UNKNOWN_USER">
    <cflog file="column_visibility" text="Warning: getAuthUser() returned empty or undefined value">
</cfif>

<cfset status = trim(requestData.status)>
<cfset updates = requestData.updates>

<!--- Debug: Log the current user to see what we're getting --->
<cflog file="column_visibility" text="Processing column visibility for user: '#currentUser#', status: '#status#'">

<!--- Validate input --->
<cfif NOT structKeyExists(requestData, "status") OR NOT isArray(updates)>
    <cfoutput>{"success": false, "message": "Missing or invalid input."}</cfoutput>
    <cfexit>
</cfif>

<!--- Step 2: Ensure user has all default records for both Review and Tracked statuses --->
<!--- First, check what records exist for this user --->
<cfquery name="userRecords" datasource="Reach">
    SELECT status, column_key, is_visible
    FROM docketwatch.dbo.column_visibility_defaults
    WHERE username = <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar">
</cfquery>

<!--- Get all default records to copy from --->
<cfquery name="defaultRecords" datasource="Reach">
    SELECT status, column_key, is_visible
    FROM docketwatch.dbo.column_visibility_defaults
    WHERE username = 'DEFAULT'
    ORDER BY status, column_key
</cfquery>

<!--- Create a lookup of existing user records --->
<cfset existingRecords = {}>
<cfloop query="userRecords">
    <cfset existingRecords["#status#_#column_key#"] = true>
</cfloop>

<!--- Insert missing records for this user from DEFAULT --->
<cfloop query="defaultRecords">
    <cfset recordKey = "#status#_#column_key#">
    <cfif NOT structKeyExists(existingRecords, recordKey)>
        <cfquery datasource="Reach">
            INSERT INTO docketwatch.dbo.column_visibility_defaults 
            (username, status, column_key, is_visible)
            VALUES (
                <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#status#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#column_key#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#is_visible#" cfsqltype="cf_sql_bit">
            )
        </cfquery>
    </cfif>
</cfloop>

<!--- Step 3: Loop over updates and apply them --->
<cfloop array="#updates#" index="item">
    <cfquery datasource="Reach">
        MERGE docketwatch.dbo.column_visibility_defaults AS target
        USING (SELECT 
            <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar"> AS username,
            <cfqueryparam value="#status#" cfsqltype="cf_sql_varchar"> AS status,
            <cfqueryparam value="#item.column_key#" cfsqltype="cf_sql_varchar"> AS column_key,
            <cfqueryparam value="#item.is_visible#" cfsqltype="cf_sql_bit"> AS is_visible
        ) AS source
        ON target.username = source.username
           AND target.status = source.status
           AND target.column_key = source.column_key
        WHEN MATCHED THEN
            UPDATE SET is_visible = source.is_visible
        WHEN NOT MATCHED THEN
            INSERT (username, status, column_key, is_visible)
            VALUES (source.username, source.status, source.column_key, source.is_visible);
    </cfquery>
</cfloop>

<!--- Step 4: Return success --->
<cfquery name="debugRecords" datasource="Reach">
    SELECT username, status, column_key, is_visible 
    FROM docketwatch.dbo.column_visibility_defaults
    WHERE username = <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar">
    ORDER BY status, column_key
</cfquery>

<!--- Log what records we have for this user after processing --->
<cflog file="column_visibility" text="User '#currentUser#' now has #debugRecords.recordCount# records">

<cfoutput>{"success": true}</cfoutput>

<cfcatch type="any">
    <cfoutput>
    {
        "success": false,
        "message": "#replace(cfcatch.message, '"', "'", "all")#"
    }
    </cfoutput>
</cfcatch>
</cftry>
