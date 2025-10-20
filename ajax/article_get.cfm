<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!--- Ensure case_id parameter is provided and numeric --->
<cfif NOT structKeyExists(URL, "case_id")>
    <cfoutput>#serializeJSON({"ok"=false, "error"="Missing required parameter case_id."})#</cfoutput>
    <cfabort>
</cfif>

<cfparam name="URL.case_id" type="numeric">

<!--- Flag for authentication bypass --->
<cfparam name="URL.bypass" default="1">

<!--- Optional: validate user access here if needed --->

<cfset todayDate = createODBCDate(now())>

<cftry>
    <cfquery name="qArticle" datasource="Reach">
        SELECT TOP 1
            id,
            fk_case,
            article_date,
            articleStatus,
            version,
            story_headline,
            story_sub_head,
            story_body,
            image_url,
            ai_model,
            ai_tokens_input,
            ai_tokens_output,
            ai_cost,
            generated_by,
            is_published,
            published_at,
            notes,
            created_at,
            updated_at
        FROM docketwatch.dbo.articles WITH (NOLOCK)
        WHERE fk_case = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.case_id#">
          AND article_date = <cfqueryparam cfsqltype="cf_sql_date" value="#todayDate#">
          AND generated_by = 'summary_parser'
          AND story_headline <> 'No Story Necessary.'
        ORDER BY updated_at DESC, created_at DESC
    </cfquery>

    <cfif qArticle.recordCount EQ 0>
        <cfoutput>#serializeJSON({"ok"=true, "found"=false})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset headlineClean = qArticle.story_headline ?: "">
    <cfset headlineClean = replace(headlineClean, chr(8212), "-", "all")>
    <cfset headlineClean = replace(headlineClean, chr(226) & chr(128) & chr(148), "-", "all")>

    <cfset subheadClean = qArticle.story_sub_head ?: "">
    <cfset subheadClean = replace(subheadClean, chr(8212), "-", "all")>
    <cfset subheadClean = replace(subheadClean, chr(226) & chr(128) & chr(148), "-", "all")>

    <cfset payload = {
        "ok"=true,
        "found"=true,
        "data"={
            "id"=qArticle.id,
            "headline"=headlineClean,
            "subhead"=subheadClean,
            "body_html"=qArticle.story_body,
            "image_url"=qArticle.image_url,
            "updated_at"=qArticle.updated_at ?: "",
            "article_date"=qArticle.article_date ?: "",
            "version"=qArticle.version,
            "ai_model"=qArticle.ai_model,
            "ai_tokens_input"=qArticle.ai_tokens_input,
            "ai_tokens_output"=qArticle.ai_tokens_output,
            "ai_cost"=qArticle.ai_cost
        }
    }>

    <cfif payload.data.updated_at NEQ "">
        <cfset payload.data.updated_at = dateTimeFormat(payload.data.updated_at, "yyyy-mm-dd HH:nn:ss")>
    </cfif>

    <cfoutput>#serializeJSON(payload)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"ok"=false, "error"=cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
