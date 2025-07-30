<cfheader name="Content-Type" value="application/json">
<cfset response = {}>
 
<cftry>
    <!--- Get parameters --->
    <cfparam name="form.update_id" default="">
    <cfset updateId = trim(form.update_id)>
    
    <!--- Validate input - check if it's a valid GUID format --->
    <cfif len(updateId) EQ 0 OR NOT isValid("guid", updateId)>
        <cfset response = {
            success = false,
            message = "Invalid update ID provided (must be a valid GUID)"
        }>
    <cfelse>
        <!--- First, check if the acknowledged column exists, if not we'll need to add it --->
        <cftry>
            <!--- Try to update the acknowledgment status --->
            <cfquery name="acknowledge_update" datasource="Reach">
                UPDATE [docketwatch].[dbo].[case_events]
                SET 
                    acknowledged = 1,
                    acknowledged_at = GETDATE(),
                    acknowledged_by = <cfqueryparam value="#getAuthUser()#" cfsqltype="cf_sql_varchar">
                WHERE id = <cfqueryparam value="#updateId#" cfsqltype="cf_sql_varchar">
            </cfquery>
            
            <!--- Check if any rows were affected --->
            <cfif acknowledge_update.recordCount EQ 0>
                <!--- The update might not exist, let's check --->
                <cfquery name="check_exists" datasource="Reach">
                    SELECT id FROM [docketwatch].[dbo].[case_events]
                    WHERE id = <cfqueryparam value="#updateId#" cfsqltype="cf_sql_varchar">
                </cfquery>
                
                <cfif check_exists.recordCount EQ 0>
                    <cfset response = {
                        success = false,
                        message = "Update not found"
                    }>
                <cfelse>
                    <cfset response = {
                        success = true,
                        message = "Update acknowledged successfully"
                    }>
                </cfif>
            <cfelse>
                <cfset response = {
                    success = true,
                    message = "Update acknowledged successfully"
                }>
            </cfif>
            
        <cfcatch type="database">
            <!--- If we get a database error, it might be because the acknowledged column doesn't exist --->
            <cfif findNoCase("acknowledged", cfcatch.message)>
                <!--- Try to add the columns to the table --->
                <cftry>
                    <cfquery name="add_columns" datasource="Reach">
                        ALTER TABLE [docketwatch].[dbo].[case_events]
                        ADD 
                            acknowledged bit DEFAULT 0,
                            acknowledged_at datetime NULL,
                            acknowledged_by varchar(50) NULL
                    </cfquery>
                    
                    <!--- Now try the update again --->
                    <cfquery name="acknowledge_update_retry" datasource="Reach">
                        UPDATE [docketwatch].[dbo].[case_events]
                        SET 
                            acknowledged = 1,
                            acknowledged_at = GETDATE(),
                            acknowledged_by = <cfqueryparam value="#getAuthUser()#" cfsqltype="cf_sql_varchar">
                        WHERE id = <cfqueryparam value="#updateId#" cfsqltype="cf_sql_varchar">
                    </cfquery>
                    
                    <cfset response = {
                        success = true,
                        message = "Update acknowledged successfully (database schema updated)"
                    }>
                    
                <cfcatch type="any">
                    <cfset response = {
                        success = false,
                        message = "Database schema needs to be updated. Please contact administrator."
                    }>
                </cfcatch>
                </cftry>
            <cfelse>
                <cfset response = {
                    success = false,
                    message = "Database error: " & cfcatch.message
                }>
            </cfif>
        </cfcatch>
        </cftry>
    </cfif>

<cfcatch type="any">
    <!--- General error response --->
    <cfset response = {
        success = false,
        message = "Error acknowledging update: " & cfcatch.message
    }>
</cfcatch>
</cftry>

<!--- Output JSON response --->
<cfoutput>#serializeJSON(response)#</cfoutput>
