<cfcontent type="application/json" />
<cfquery name="q" datasource="reach">
SELECT 
  CAST(fk_asset AS varchar(36)) AS fk_asset,
  headline,
  headline_final,
  headline_type_final,
  approved
FROM docketwatch.dbo.damz_test
WHERE headline_optimized IS NOT NULL
</cfquery>

<cfset rows = []>
<cfloop query="q">
  <cfset arrayAppend(rows, {
    "fk_asset": q.fk_asset,
    "headline": q.headline,
    "headline_final": q.headline_final,
    "headline_type_final": q.headline_type_final,
    "approved": q.approved
  })>
</cfloop>
<cfoutput>#serializeJSON(rows)#</cfoutput>
