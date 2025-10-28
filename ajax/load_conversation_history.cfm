<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<!---
================================================================================
Load Conversation History - Retrieve Q&A History for Document
================================================================================

PURPOSE:
--------
Retrieves all previous questions and answers for a specific document.
Used to display conversation history when user revisits a document.

USAGE:
------
GET /ajax/load_conversation_history.cfm?doc_uid=<UUID>
Or
GET /ajax/load_conversation_history.cfm?doc_uid=<UUID>&session_id=<SESSION>

RESPONSE:
---------
{
    "ok": true,
    "prompts": [
        {
            "id": 123,
            "prompt_text": "What was the settlement amount?",
            "response_text": "Based on...",
            "created_at": "2025-01-28T14:45:00Z",
            "cited_fields": ["fields.settlement_amount"],
            "model_name": "gemini-2.5-flash",
            "tokens_input": 450,
            "tokens_output": 85,
            "processing_ms": 1200,
            "feedback_rating": 5,
            "feedback_comment": "Helpful!",
            "prompt_sequence": 1
        },
        ...
    ],
    "total_count": 5
}

ERROR RESPONSE:
---------------
{
    "ok": false,
    "error": "Error message here"
}

RELATED FILES:
--------------
- /ajax/ask_document_question.cfm - Creates prompts
- /tools/summarize/view.cfm - Displays history
- docketwatch.dbo.document_prompts - Storage table

================================================================================
--->

<cftry>
    <!--- Extract parameters from URL --->
    <cfset docUid = url.doc_uid ?: "">
    <cfset sessionId = url.session_id ?: "">
    <cfset limit = url.limit ?: 100>  <!--- Max prompts to return --->

    <!--- Validate required parameters --->
    <cfif NOT len(trim(docUid))>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {"ok": false, "error": "Missing required parameter: doc_uid"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Validate limit --->
    <cfif NOT isNumeric(limit) OR limit LT 1 OR limit GT 1000>
        <cfset limit = 100>
    </cfif>

    <!--- Get current user --->
    <cfset currentUser = getAuthUser()>
    <cfif NOT len(trim(currentUser))>
        <cfset currentUser = "anonymous">
    </cfif>

    <!--- DOCUMENT ACCESS: Verify document exists and user has access --->
    <cfquery name="checkDoc" datasource="Reach">
        SELECT
            d.doc_uid,
            d.fk_case_event,
            c.owner as case_owner
        FROM docketwatch.dbo.documents d
        LEFT JOIN docketwatch.dbo.case_events ce ON ce.event_uid = d.fk_case_event
        LEFT JOIN docketwatch.dbo.cases c ON c.id = ce.fk_case
        WHERE d.doc_uid = <cfqueryparam value="#docUid#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfif checkDoc.recordCount EQ 0>
        <cfheader statuscode="404" statustext="Not Found">
        <cfset errorResponse = {"ok": false, "error": "Document not found"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Access control: Check if user has access to this document --->
    <cfset isAdHocUpload = (checkDoc.fk_case_event EQ "00000000-0000-0000-0000-000000000000")>
    <cfset hasAccess = isAdHocUpload OR (checkDoc.case_owner EQ currentUser)>

    <!--- For now, allow all authenticated users to view history of ad-hoc uploads --->
    <!--- But only show prompts from the current user --->
    <cfif NOT hasAccess AND NOT isAdHocUpload>
        <cfheader statuscode="403" statustext="Forbidden">
        <cfset errorResponse = {"ok": false, "error": "Access denied to this document"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- QUERY CONVERSATION HISTORY --->
    <!--- If session_id provided, filter by session. Otherwise, get all prompts for this doc by current user --->
    <cfquery name="getHistory" datasource="Reach">
        SELECT TOP #limit#
            id,
            prompt_text,
            prompt_response,
            created_at,
            cited_fields,
            model_name,
            tokens_input,
            tokens_output,
            processing_ms,
            feedback_rating,
            feedback_comment,
            session_id,
            prompt_sequence
        FROM docketwatch.dbo.document_prompts
        WHERE fk_doc_uid = <cfqueryparam value="#docUid#" cfsqltype="cf_sql_varchar">
        AND user_name = <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar">
        <cfif len(trim(sessionId))>
            AND session_id = <cfqueryparam value="#sessionId#" cfsqltype="cf_sql_varchar">
        </cfif>
        ORDER BY created_at ASC, prompt_sequence ASC
    </cfquery>

    <!--- BUILD RESPONSE ARRAY --->
    <cfset prompts = []>

    <cfloop query="getHistory">
        <cfset promptObj = {
            "id": id,
            "prompt_text": prompt_text,
            "response_text": prompt_response ?: "",
            "created_at": dateFormat(created_at, "yyyy-mm-dd") & "T" & timeFormat(created_at, "HH:mm:ss") & "Z",
            "cited_fields": [],
            "model_name": model_name ?: "gemini-2.5-flash",
            "tokens_input": tokens_input ?: 0,
            "tokens_output": tokens_output ?: 0,
            "processing_ms": processing_ms ?: 0,
            "feedback_rating": NOT isNull(feedback_rating) ? feedback_rating : javaCast("null", ""),
            "feedback_comment": feedback_comment ?: "",
            "session_id": session_id ?: "",
            "prompt_sequence": prompt_sequence ?: 0
        }>

        <!--- Parse cited_fields JSON if present --->
        <cfif len(trim(cited_fields))>
            <cftry>
                <cfset promptObj.cited_fields = deserializeJSON(cited_fields)>
                <cfcatch type="any">
                    <!--- If JSON parse fails, leave as empty array --->
                    <cfset promptObj.cited_fields = []>
                </cfcatch>
            </cftry>
        </cfif>

        <cfset arrayAppend(prompts, promptObj)>
    </cfloop>

    <!--- LOG ACCESS --->
    <cflog file="document_prompts" type="information"
           text="User #currentUser# loaded #arrayLen(prompts)# prompts for doc #docUid#">

    <!--- Return success response --->
    <cfset successResponse = {
        "ok": true,
        "prompts": prompts,
        "total_count": arrayLen(prompts)
    }>

    <cfoutput>#serializeJSON(successResponse)#</cfoutput>

    <cfcatch type="any">
        <!--- Catch-all error handler --->
        <cfheader statuscode="500" statustext="Internal Server Error">
        <cfset errorResponse = {
            "ok": false,
            "error": cfcatch.message,
            "detail": cfcatch.detail ?: ""
        }>
        <cflog file="document_prompts" type="error"
               text="Error loading history for doc #docUid#: #cfcatch.message#">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
    </cfcatch>
</cftry>
