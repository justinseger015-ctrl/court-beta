<cfheader name="Content-Type" value="application/json">

<cftry>
    <!--- Get current statistics --->
    <cfquery name="stats" datasource="Reach">
        SELECT 
            COUNT(DISTINCT e.fk_cases) as active_cases,
            COUNT(*) as total_events,
            SUM(CASE WHEN ISNULL(acknowledged, 0) = 0 THEN 1 ELSE 0 END) as unacknowledged,
            SUM(CASE WHEN ISNULL(acknowledged, 0) = 1 THEN 1 ELSE 0 END) as acknowledged
        FROM docketwatch.dbo.case_events e
        INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
        WHERE c.status = 'Tracked'
          AND c.case_number <> 'Unfiled'
          AND CAST(e.created_at AS DATE) = CAST(GETDATE() AS DATE)
    </cfquery>
    
    <cfset response = structNew()>
    <cfset response.activeCases = stats.active_cases>
    <cfset response.total = stats.total_events>
    <cfset response.unacknowledged = stats.unacknowledged>
    <cfset response.acknowledged = stats.acknowledged>
    
    <cfcatch type="any">
        <cfset response = structNew()>
        <cfset response.error = cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
