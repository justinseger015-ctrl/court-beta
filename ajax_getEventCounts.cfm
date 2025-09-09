<cfheader name="Content-Type" value="application/json">

<cftry>
    <!--- Get current statistics --->
    <cfquery name="stats" datasource="Reach">
        SELECT 
            COUNT(*) as total_events,
            SUM(CASE WHEN ISNULL(acknowledged, 0) = 0 THEN 1 ELSE 0 END) as unacknowledged,
            SUM(CASE WHEN ISNULL(acknowledged, 0) = 1 THEN 1 ELSE 0 END) as acknowledged,
            SUM(CASE WHEN isDoc = 1 THEN 1 ELSE 0 END) as with_documents
        FROM docketwatch.dbo.case_events e
        INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
        WHERE c.status = 'Tracked'
    </cfquery>
    
    <cfset response = structNew()>
    <cfset response.total = stats.total_events>
    <cfset response.unacknowledged = stats.unacknowledged>
    <cfset response.acknowledged = stats.acknowledged>
    <cfset response.withDocs = stats.with_documents>
    
    <cfcatch type="any">
        <cfset response = structNew()>
        <cfset response.error = cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
