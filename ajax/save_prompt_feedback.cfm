<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<!---
================================================================================
Save Prompt Feedback - User Feedback Collection
================================================================================

PURPOSE:
--------
Saves user feedback (thumbs up/down, comments) for AI responses.
Used to track accuracy and improve prompts over time.

USAGE:
------
POST /ajax/save_prompt_feedback.cfm
Body: JSON with prompt_id, rating, comment (optional)

REQUEST:
--------
{
    "prompt_id": 12345,
    "rating": 5,  // 1-5 scale, or use 1 for thumbs down, 5 for thumbs up
    "comment": "Accurate and helpful!" // Optional
}

RESPONSE:
---------
{
    "ok": true,
    "message": "Feedback saved successfully"
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
- /tools/summarize/view.cfm - Frontend feedback UI
- docketwatch.dbo.document_prompts - Storage table

================================================================================
--->

<cftry>
    <!--- Parse JSON request body --->
    <cfset requestBody = toString(getHttpRequestData().content)>

    <cftry>
        <cfset requestData = deserializeJSON(requestBody)>
        <cfcatch type="any">
            <cfheader statuscode="400" statustext="Bad Request">
            <cfset errorResponse = {"ok": false, "error": "Invalid JSON in request body"}>
            <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
            <cfabort>
        </cfcatch>
    </cftry>

    <!--- Extract parameters --->
    <cfset promptId = requestData.prompt_id ?: 0>
    <cfset rating = requestData.rating ?: 0>
    <cfset comment = requestData.comment ?: "">

    <!--- Validate required parameters --->
    <cfif NOT isNumeric(promptId) OR promptId LTE 0>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {"ok": false, "error": "Invalid or missing prompt_id"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Validate rating (1-5 scale) --->
    <cfif NOT isNumeric(rating) OR rating LT 1 OR rating GT 5>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {"ok": false, "error": "Rating must be between 1 and 5"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Get current user --->
    <cfset currentUser = getAuthUser()>
    <cfif NOT len(trim(currentUser))>
        <cfset currentUser = "anonymous">
    </cfif>

    <!--- Verify prompt exists and belongs to current user (security check) --->
    <cfquery name="checkPrompt" datasource="Reach">
        SELECT id, user_name, feedback_rating
        FROM docketwatch.dbo.document_prompts
        WHERE id = <cfqueryparam value="#promptId#" cfsqltype="cf_sql_bigint">
    </cfquery>

    <cfif checkPrompt.recordCount EQ 0>
        <cfheader statuscode="404" statustext="Not Found">
        <cfset errorResponse = {"ok": false, "error": "Prompt not found"}>
        <cflog file="document_prompts" type="error" text="Prompt not found: #promptId#">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Security check: Only allow users to rate their own prompts --->
    <cfif checkPrompt.user_name NEQ currentUser>
        <cfheader statuscode="403" statustext="Forbidden">
        <cfset errorResponse = {"ok": false, "error": "You can only provide feedback on your own questions"}>
        <cflog file="document_prompts" type="warning"
               text="User #currentUser# attempted to rate prompt #promptId# owned by #checkPrompt.user_name#">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Check if feedback already exists --->
    <cfif NOT isNull(checkPrompt.feedback_rating) AND checkPrompt.feedback_rating NEQ "">
        <cflog file="document_prompts" type="information"
               text="Updating existing feedback for prompt #promptId# (was #checkPrompt.feedback_rating#, now #rating#)">
    </cfif>

    <!--- UPDATE PROMPT with feedback --->
    <cfquery name="updateFeedback" datasource="Reach">
        UPDATE docketwatch.dbo.document_prompts
        SET
            feedback_rating = <cfqueryparam value="#rating#" cfsqltype="cf_sql_tinyint">,
            feedback_comment = <cfqueryparam value="#comment#" cfsqltype="cf_sql_longvarchar" null="#NOT len(trim(comment))#">,
            feedback_submitted_at = SYSUTCDATETIME()
        WHERE id = <cfqueryparam value="#promptId#" cfsqltype="cf_sql_bigint">
    </cfquery>

    <cflog file="document_prompts" type="information"
           text="Feedback saved for prompt #promptId#: rating=#rating#, has_comment=#len(trim(comment)) GT 0#">

    <!--- Return success response --->
    <cfset successResponse = {
        "ok": true,
        "message": "Feedback saved successfully",
        "prompt_id": promptId,
        "rating": rating
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
               text="Error saving feedback for prompt #promptId#: #cfcatch.message#">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
    </cfcatch>
</cftry>
