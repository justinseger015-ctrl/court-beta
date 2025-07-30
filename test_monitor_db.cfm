<cfheader name="Content-Type" value="application/json">
<cfset response = {}>

<cftry>
    <!--- Simple test query first --->
    <cfquery name="test_cases" datasource="Reach">
        SELECT TOP 10
            c.[id],
            c.[case_number],
            c.[case_name],
            c.[status],
            c.[created_at]
        FROM [docketwatch].[dbo].[cases] c
        WHERE c.[status] IN ('Tracked', 'Review')
        ORDER BY c.[created_at] DESC
    </cfquery>
    
    <!--- Test case_events table --->
    <cfquery name="test_events" datasource="Reach">
        SELECT TOP 10
            e.[id],
            e.[fk_cases],
            e.[event_description],
            e.[created_at]
        FROM [docketwatch].[dbo].[case_events] e
        ORDER BY e.[created_at] DESC
    </cfquery>
    
    <!--- Build simple response --->
    <cfset testData = []>
    <cfloop query="test_events">
        <cfset arrayAppend(testData, {
            id = test_events.id,
            case_id = test_events.fk_cases,
            description = test_events.event_description,
            created_at = dateFormat(test_events.created_at, "yyyy-mm-dd") & "T" & timeFormat(test_events.created_at, "HH:mm:ss")
        })>
    </cfloop>
    
    <cfset response = {
        success = true,
        message = "Database connection successful",
        cases_found = test_cases.recordCount,
        events_found = test_events.recordCount,
        sample_events = testData,
        timestamp = now()
    }>

<cfcatch type="any">
    <cfset response = {
        success = false,
        message = "Database error: " & cfcatch.message,
        detail = cfcatch.detail,
        sql_state = cfcatch.sqlState,
        error_code = cfcatch.errorCode,
        timestamp = now()
    }>
</cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
