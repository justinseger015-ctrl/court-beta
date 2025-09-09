<cfheader name="Content-Type" value="application/json">

<cfparam name="form.eventId" default="">

<cfset response = structNew()>
<cfset response.success = false>
<cfset response.message = "">
<cfset response.modalHtml = "">

<cftry>
    <cfif len(form.eventId)>
        <!--- Get event details --->
        <cfquery name="eventDetails" datasource="Reach">
            SELECT 
                e.id,
                e.event_no,
                e.event_description,
                c.case_name,
                c.case_number,
                d.search_text
            FROM docketwatch.dbo.case_events e
            INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases
            LEFT JOIN docketwatch.dbo.documents d ON d.fk_case_event = e.id
            WHERE e.id = <cfqueryparam value="#form.eventId#" cfsqltype="cf_sql_integer">
        </cfquery>
        
        <cfif eventDetails.recordcount GT 0>
            <!--- Simulate AI summary generation --->
            <cfset summaryText = "">
            <cfif len(eventDetails.search_text)>
                <cfset summaryText = "<h6>Document Summary</h6><p>This document contains important legal proceedings related to " & eventDetails.case_name & ". Key points include filing of motions, case developments, and procedural matters that advance the litigation process.</p>">
            <cfelse>
                <cfset summaryText = "<h6>Event Summary</h6><p>This case event represents a significant development in " & eventDetails.case_name & ". The filing includes procedural updates and legal arguments that may impact the direction of the case.</p>">
            </cfif>
            
            <cfset summaryText &= "<p><strong>AI Analysis:</strong> [Mock] This appears to be a routine court filing with standard legal language. No immediate red flags detected. Recommended for standard processing.</p>">
            
            <!--- Update the database with the generated summary --->
            <cfquery name="updateSummary" datasource="Reach">
                UPDATE docketwatch.dbo.documents 
                SET summary_ai_html = <cfqueryparam value="#summaryText#" cfsqltype="cf_sql_longvarchar">
                WHERE fk_case_event = <cfqueryparam value="#form.eventId#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <!--- Generate modal HTML --->
            <cfset modalHtml = '
                <div class="modal fade" id="summaryModal' & form.eventId & '" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog modal-lg modal-dialog-scrollable">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">
                                    <i class="fas fa-brain me-2"></i>
                                    AI Summary - Event #' & eventDetails.event_no & '
                                </h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <div class="mb-3">
                                    <strong>Case:</strong> ' & eventDetails.case_name & ' (' & eventDetails.case_number & ')<br>
                                    <strong>Event:</strong> ' & eventDetails.event_description & '
                                </div>
                                <hr>
                                <div class="summary-content">
                                    ' & summaryText & '
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                            </div>
                        </div>
                    </div>
                </div>'>
            
            <cfset response.success = true>
            <cfset response.message = "Summary generated successfully">
            <cfset response.modalHtml = modalHtml>
        <cfelse>
            <cfset response.message = "Event not found">
        </cfif>
    <cfelse>
        <cfset response.message = "Event ID is required">
    </cfif>
    
    <cfcatch type="any">
        <cfset response.success = false>
        <cfset response.message = "Error: " & cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
