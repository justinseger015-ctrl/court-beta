<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<!---
================================================================================
Ask Document Question - Interactive Q&A Endpoint
================================================================================

PURPOSE:
--------
Processes user questions about documents and returns AI-generated answers
based ONLY on the extracted JSON facts (FACT_GUARD principle).

USAGE:
------
POST /ajax/ask_document_question.cfm?bypass=1
Body: JSON with doc_uid, prompt_text, session_id

RESPONSE:
---------
{
    "ok": true,
    "prompt_id": 12345,
    "response_text": "Based on the extracted facts...",
    "cited_fields": ["fields.settlement_amount"],
    "model_name": "gemini-2.5-flash",
    "processing_ms": 1200,
    "tokens_input": 450,
    "tokens_output": 85
}

ERROR RESPONSE:
---------------
{
    "ok": false,
    "error": "Error message here"
}

RELATED FILES:
--------------
- /python/answer_from_json.py - Python Q&A script
- /tools/summarize/view.cfm - Frontend results page
- docketwatch.dbo.document_prompts - Logging table

SECURITY:
---------
- Rate limiting: 50 prompts per hour per user
- Access control: User must have access to document
- Input validation: Prompt length limits, injection checks

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
    <cfset docUid = requestData.doc_uid ?: "">
    <cfset promptText = requestData.prompt_text ?: "">
    <cfset sessionId = requestData.session_id ?: createUUID()>

    <!--- Validate required parameters --->
    <cfif NOT len(trim(docUid))>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {"ok": false, "error": "Missing required parameter: doc_uid"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <cfif NOT len(trim(promptText))>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {"ok": false, "error": "Missing required parameter: prompt_text"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Validate prompt length --->
    <cfif len(promptText) GT 1000>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {"ok": false, "error": "Prompt too long (maximum 1000 characters)"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <cfif len(trim(promptText)) LT 3>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {"ok": false, "error": "Prompt too short (minimum 3 characters)"}>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Check for potential injection patterns --->
    <cfset forbiddenPatterns = ["ignore previous", "disregard instructions", "new task:", "system:", "forget"]>
    <cfset promptLower = lCase(promptText)>
    <cfloop array="#forbiddenPatterns#" index="pattern">
        <cfif findNoCase(pattern, promptLower)>
            <cfheader statuscode="400" statustext="Bad Request">
            <cfset errorResponse = {"ok": false, "error": "Invalid prompt detected. Please rephrase your question."}>
            <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
            <cfabort>
        </cfif>
    </cfloop>

    <!--- Get current authenticated user --->
    <cfset currentUser = getAuthUser()>
    <cfif NOT len(trim(currentUser))>
        <cfset currentUser = "anonymous">
    </cfif>

    <!--- Log request --->
    <cflog file="document_prompts" type="information"
           text="User #currentUser# asking question about doc #docUid#: #left(promptText, 100)#">

    <!--- RATE LIMITING: Check if user has exceeded hourly limit --->
    <cfquery name="checkRate" datasource="Reach">
        SELECT COUNT(*) as prompt_count
        FROM docketwatch.dbo.document_prompts
        WHERE user_name = <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar">
        AND created_at > DATEADD(hour, -1, SYSUTCDATETIME())
    </cfquery>

    <cfif checkRate.prompt_count GTE 50>
        <cfheader statuscode="429" statustext="Too Many Requests">
        <cfset errorResponse = {
            "ok": false,
            "error": "Rate limit exceeded. Maximum 50 prompts per hour. Please try again later."
        }>
        <cflog file="document_prompts" type="warning"
               text="Rate limit exceeded for user #currentUser# (#checkRate.prompt_count# prompts in last hour)">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- DOCUMENT ACCESS: Verify document exists and user has access --->
    <cfquery name="getDoc" datasource="Reach">
        SELECT
            d.doc_uid,
            d.pdf_title,
            d.summary_ai_extraction_json,
            d.fk_case_event,
            c.owner as case_owner
        FROM docketwatch.dbo.documents d
        LEFT JOIN docketwatch.dbo.case_events ce ON ce.event_uid = d.fk_case_event
        LEFT JOIN docketwatch.dbo.cases c ON c.id = ce.fk_case
        WHERE d.doc_uid = <cfqueryparam value="#docUid#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfif getDoc.recordCount EQ 0>
        <cfheader statuscode="404" statustext="Not Found">
        <cfset errorResponse = {"ok": false, "error": "Document not found"}>
        <cflog file="document_prompts" type="error" text="Document not found: #docUid#">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Check if extraction JSON exists --->
    <cfif NOT len(trim(getDoc.summary_ai_extraction_json))>
        <cfheader statuscode="400" statustext="Bad Request">
        <cfset errorResponse = {
            "ok": false,
            "error": "This document has not been processed for Q&A yet. No extracted facts available."
        }>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Access control: Check if user has access to this document --->
    <!--- Ad-hoc uploads (fk_case_event = all zeros) are accessible to all logged-in users --->
    <!--- Case-linked documents require user to be the case owner or have explicit access --->
    <cfset isAdHocUpload = (getDoc.fk_case_event EQ "00000000-0000-0000-0000-000000000000")>
    <cfset hasAccess = isAdHocUpload OR (getDoc.case_owner EQ currentUser)>

    <!--- TODO: Add more sophisticated permission checking here if needed --->
    <!--- For now, allow all authenticated users to access ad-hoc uploads --->
    <cfif NOT hasAccess AND NOT isAdHocUpload>
        <cfheader statuscode="403" statustext="Forbidden">
        <cfset errorResponse = {"ok": false, "error": "Access denied to this document"}>
        <cflog file="document_prompts" type="warning"
               text="Access denied for user #currentUser# to doc #docUid#">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- CALL PYTHON SCRIPT to answer question --->
    <cfset pythonExe = "C:\Program Files\Python312\python.exe">
    <cfset scriptPath = "U:\docketwatch\court-beta\python\answer_from_json.py">

    <cflog file="document_prompts" type="information"
           text="Calling Python Q&A script for doc #docUid#">

    <cftry>
        <cfexecute name="#pythonExe#"
                   arguments="#[scriptPath, '--doc_uid', docUid, '--prompt', promptText]#"
                   timeout="60"
                   variable="pyOutput"
                   errorVariable="pyError">
        </cfexecute>

        <!--- Log Python output for debugging --->
        <cfif len(trim(pyError))>
            <cflog file="document_prompts" type="warning"
                   text="Python stderr: #left(pyError, 500)#">
        </cfif>

        <!--- Parse Python JSON response --->
        <cfset trimmedOutput = trim(pyOutput)>

        <!--- Validate JSON format --->
        <cfif NOT (left(trimmedOutput, 1) EQ "{")>
            <cfthrow message="Python script returned non-JSON output">
        </cfif>

        <cfset pythonResponse = deserializeJSON(trimmedOutput)>

        <!--- Check for Python-side errors --->
        <cfif structKeyExists(pythonResponse, "error") AND len(trim(pythonResponse.error))>
            <cfthrow message="Python error: #pythonResponse.error#">
        </cfif>

        <cfcatch type="any">
            <cfheader statuscode="500" statustext="Internal Server Error">
            <cfset errorResponse = {
                "ok": false,
                "error": "Failed to process question: #cfcatch.message#",
                "python_output": left(pyOutput, 500)
            }>
            <cflog file="document_prompts" type="error"
                   text="Python execution error: #cfcatch.message# - Output: #left(pyOutput, 200)#">
            <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
            <cfabort>
        </cfcatch>
    </cftry>

    <!--- GET NEXT PROMPT SEQUENCE for this session --->
    <cfquery name="getMaxSequence" datasource="Reach">
        SELECT ISNULL(MAX(prompt_sequence), 0) as max_seq
        FROM docketwatch.dbo.document_prompts
        WHERE session_id = <cfqueryparam value="#sessionId#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfset nextSequence = getMaxSequence.max_seq + 1>

    <!--- INSERT PROMPT RECORD into database --->
    <cfquery name="insertPrompt" datasource="Reach">
        INSERT INTO docketwatch.dbo.document_prompts (
            fk_doc_uid,
            user_name,
            prompt_text,
            prompt_response,
            model_name,
            tokens_input,
            tokens_output,
            processing_ms,
            cited_fields,
            session_id,
            prompt_sequence,
            created_at
        )
        VALUES (
            <cfqueryparam value="#docUid#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#currentUser#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#promptText#" cfsqltype="cf_sql_longvarchar">,
            <cfqueryparam value="#pythonResponse.response_text#" cfsqltype="cf_sql_longvarchar">,
            <cfqueryparam value="#pythonResponse.model_name#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#pythonResponse.tokens_input#" cfsqltype="cf_sql_integer" null="#pythonResponse.tokens_input EQ 0#">,
            <cfqueryparam value="#pythonResponse.tokens_output#" cfsqltype="cf_sql_integer" null="#pythonResponse.tokens_output EQ 0#">,
            <cfqueryparam value="#pythonResponse.processing_ms#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#serializeJSON(pythonResponse.cited_fields)#" cfsqltype="cf_sql_longvarchar">,
            <cfqueryparam value="#sessionId#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#nextSequence#" cfsqltype="cf_sql_integer">,
            SYSUTCDATETIME()
        );
        SELECT SCOPE_IDENTITY() AS prompt_id;
    </cfquery>

    <cfset promptId = insertPrompt.prompt_id>

    <cflog file="document_prompts" type="information"
           text="Prompt #promptId# saved successfully for doc #docUid#">

    <!--- BUILD SUCCESS RESPONSE --->
    <cfset successResponse = {
        "ok": true,
        "prompt_id": promptId,
        "response_text": pythonResponse.response_text,
        "cited_fields": pythonResponse.cited_fields,
        "model_name": pythonResponse.model_name,
        "processing_ms": pythonResponse.processing_ms,
        "tokens_input": pythonResponse.tokens_input,
        "tokens_output": pythonResponse.tokens_output,
        "prompt_sequence": nextSequence
    }>

    <!--- Return success response --->
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
               text="Unhandled error: #cfcatch.message# - #cfcatch.detail#">
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
    </cfcatch>
</cftry>
