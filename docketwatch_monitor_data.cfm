<cfheader name="Content-Type" value="application/json">
<cfcontent reset="true">
<cfset response = {}>

<cftry>
    <!--- Get parameters --->
    <cfparam name="url.last_update_id" default="">
    <cfset lastUpdateId = trim(url.last_update_id)>
    
    <!--- Query for recent case events/updates --->
    <cfquery name="updates" datasource="Reach">
        SELECT TOP 50
            e.[id],
            e.[fk_cases] as case_id,
            e.[event_date],
            e.[event_description],
            e.[created_at],
            ISNULL(e.[event_result], '') as event_result,
            ISNULL(e.[additional_information], '') as additional_information,
            ISNULL(e.[emailed], 0) as emailed,
            ISNULL(e.[summarize], 0) as summarize,
            ISNULL(e.[tmz_summarize], 0) as tmz_summarize,
            ISNULL(e.[event_url], '') as event_url,
            
            -- Case information
            c.[case_number],
            c.[case_name],
            c.[status] as case_status,
            ISNULL(c.[summarize_html], '') as summarize_html,
            c.[last_updated] as case_last_updated,
            
            -- Tool information
            ISNULL(t.[tool_name], 'Unknown') as tool_name,
            ISNULL(t.[id], 0) as tool_id,
            
            -- Priority logic (you can adjust this based on your business rules)
            CASE 
                WHEN ISNULL(e.[tmz_summarize], 0) = 1 OR c.[status] = 'Tracked' THEN 1  -- Urgent
                WHEN ISNULL(e.[summarize], 0) = 1 THEN 2  -- Normal
                ELSE 3  -- Low
            END as priority_level,
            
            -- Acknowledgment status (check if column exists, default to 0 if not)
            0 as acknowledged,
            
            -- Story worthiness indicator
            CASE 
                WHEN ISNULL(e.[tmz_summarize], 0) = 1 THEN 1
                WHEN ISNULL(e.[summarize], 0) = 1 THEN 1
                ELSE 0
            END as is_storyworthy
            
        FROM [docketwatch].[dbo].[case_events] e
        INNER JOIN [docketwatch].[dbo].[cases] c ON c.id = e.fk_cases
        LEFT JOIN [docketwatch].[dbo].[tools] t ON t.id = c.fk_tool
        
        WHERE 
            -- Only get updates from last 24 hours (or all if no last_update_id provided)
            e.[created_at] >= DATEADD(hour, -24, GETDATE())
            <cfif len(lastUpdateId) GT 0 AND isValid("guid", lastUpdateId)>
                AND e.[id] > <cfqueryparam value="#lastUpdateId#" cfsqltype="cf_sql_varchar">
            </cfif>
            -- Only include cases that are being tracked or reviewed
            AND c.[status] IN ('Tracked', 'Review')
            -- Filter out unfiled cases
            AND c.[case_number] != 'unfiled'
            
        ORDER BY e.[created_at] DESC, e.[id] DESC
    </cfquery>
    
    <!--- Query for celebrity matches if any exist --->
    <cfif updates.recordCount GT 0>
        <cfquery name="celebrity_matches" datasource="Reach">
            SELECT 
                ccm.fk_case,
                c.name as celebrity_name,
                c.id as celebrity_id,
                ccm.match_status,
                ccm.probability_score,
                '' as avatar_url
            FROM [docketwatch].[dbo].[case_celebrity_matches] ccm
            INNER JOIN [docketwatch].[dbo].[celebrities] c ON c.id = ccm.fk_celebrity
            WHERE ccm.fk_case IN (
                <cfloop query="updates">
                    <cfqueryparam value="#updates.case_id#" cfsqltype="cf_sql_varchar">
                    <cfif updates.currentRow NEQ updates.recordCount>,</cfif>
                </cfloop>
            )
            AND ccm.match_status <> 'Removed'
            AND ccm.probability_score > 0.7  -- Only high-confidence matches
        </cfquery>
        
        <!--- Query for PDFs/documents associated with these events --->
        <cfquery name="event_pdfs" datasource="Reach">
            SELECT 
                ep.fk_case_event,
                ep.pdf_title,
                ep.local_pdf_filename,
                ep.isDownloaded,
                ep.pdf_type
            FROM [docketwatch].[dbo].[case_events_pdf] ep
            WHERE ep.fk_case_event IN (
                <cfloop query="updates">
                    <cfqueryparam value="#updates.id#" cfsqltype="cf_sql_varchar">
                    <cfif updates.currentRow NEQ updates.recordCount>,</cfif>
                </cfloop>
            )
            AND ep.isDownloaded = 1
            AND ep.local_pdf_filename IS NOT NULL
        </cfquery>
    <cfelse>
        <!--- Create empty query objects if no updates found --->
        <cfset celebrity_matches = queryNew("fk_case,celebrity_name,celebrity_id,match_status,probability_score,avatar_url")>
        <cfset event_pdfs = queryNew("fk_case_event,pdf_title,local_pdf_filename,isDownloaded,pdf_type")>
    </cfif>
    
    <!--- Build the response data structure --->
    <cfset updatesList = []>
    <cfset stats = {
        total = updates.recordCount,
        urgent = 0,
        acknowledged = 0,
        new_since_last = 0
    }>
    
    <cfloop query="updates">
        <!--- Count stats --->
        <cfif updates.priority_level EQ 1>
            <cfset stats.urgent++>
        </cfif>
        <cfif updates.acknowledged EQ 1>
            <cfset stats.acknowledged++>
        </cfif>
        <!--- For GUIDs, we can't do simple comparison, so count all as new for now --->
        <cfif len(lastUpdateId) EQ 0 OR updates.created_at GTE dateAdd("n", -30, now())>
            <cfset stats.new_since_last++>
        </cfif>
        
        <!--- Build summary preview from available fields --->
        <cfset summaryPreview = "">
        <cfif len(trim(updates.summarize_html))>
            <!--- Extract first sentence from HTML summary --->
            <cfset cleanSummary = reReplace(updates.summarize_html, "<[^>]*>", "", "all")>
            <cfset cleanSummary = reReplace(cleanSummary, "\s+", " ", "all")>
            <cfif len(cleanSummary) GT 150>
                <cfset summaryPreview = left(cleanSummary, 150) & "...">
            <cfelse>
                <cfset summaryPreview = cleanSummary>
            </cfif>
        <cfelseif len(trim(updates.event_description)) GT 0>
            <!--- Fallback to event description --->
            <cfif len(updates.event_description) GT 100>
                <cfset summaryPreview = left(updates.event_description, 100) & "...">
            <cfelse>
                <cfset summaryPreview = updates.event_description>
            </cfif>
        <cfelse>
            <cfset summaryPreview = "New case activity detected. Click for details.">
        </cfif>
        
        <!--- Find celebrity info for this case --->
        <cfset celebInfo = "">
        <cfloop query="celebrity_matches">
            <cfif celebrity_matches.fk_case EQ updates.case_id>
                <!--- For tracked cases, show 100% confidence since they're manually verified --->
                <cfset confidencePercent = updates.case_status EQ "Tracked" ? "100" : numberFormat(celebrity_matches.probability_score * 100, "0")>
                <cfset celebInfo = {
                    name = celebrity_matches.celebrity_name,
                    id = celebrity_matches.celebrity_id,
                    avatar = celebrity_matches.avatar_url,
                    role = "Celebrity Match (" & confidencePercent & "% confidence)"
                }>
                <cfbreak>
            </cfif>
        </cfloop>
        
        <!--- Find PDF links for this event --->
        <cfset pdfLinks = "">
        <cfloop query="event_pdfs">
            <cfif event_pdfs.fk_case_event EQ updates.id>
                <cfset pdfLinks = pdfLinks & '<a href="/mediaroot/pacer_pdfs/' & event_pdfs.local_pdf_filename & '" target="_blank" class="btn-monitor btn-pdf btn-sm me-1" title="' & htmlEditFormat(event_pdfs.pdf_title) & '"><i class="fas fa-file-pdf"></i></a>'>
            </cfif>
        </cfloop>
        
        <!--- Extract parties from case name (basic extraction) --->
        <cfset parties = "">
        <cfif findNoCase(" v. ", updates.case_name) OR findNoCase(" vs. ", updates.case_name)>
            <cfset parties = updates.case_name>
        </cfif>
        
        <!--- Build update object --->
        <cfset updateObj = {
            id = updates.id,
            case_id = updates.case_id,
            case_number = updates.case_number,
            case_name = updates.case_name,
            tool_name = updates.tool_name ?: "Unknown",
            priority_level = updates.priority_level,
            acknowledged = updates.acknowledged,
            created_at = dateFormat(updates.created_at, "yyyy-mm-dd") & "T" & timeFormat(updates.created_at, "HH:mm:ss"),
            event_date = updates.event_date,
            summary_preview = summaryPreview,
            parties = parties,
            celebrity_info = celebInfo,
            pdf_links = pdfLinks,
            is_storyworthy = updates.is_storyworthy,
            event_url = updates.event_url
        }>
        
        <cfset arrayAppend(updatesList, updateObj)>
    </cfloop>
    
    <!--- Success response --->
    <cfset response = {
        success = true,
        data = updatesList,
        stats = stats,
        timestamp = now(),
        last_update_id = len(lastUpdateId) GT 0 ? lastUpdateId : ""
    }>

<cfcatch type="any">
    <!--- Error response with detailed information --->
    <cfset response = {
        success = false,
        message = "Error retrieving monitor data: " & cfcatch.message,
        detail = cfcatch.detail ?: "",
        sql_state = cfcatch.sqlState ?: "",
        error_code = cfcatch.errorCode ?: "",
        data = [],
        stats = {total=0, urgent=0, acknowledged=0, new_since_last=0},
        timestamp = now()
    }>
</cfcatch>
</cftry>

<!--- Output JSON response --->
<cfcontent reset="true" type="application/json">
<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>
