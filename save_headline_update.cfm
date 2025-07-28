<cfparam name="fk_asset" default="0">
<cfparam name="headline_final" default="">
<cfparam name="headline_type_final" default="">
<cfparam name="approved" default="0">

<cfquery datasource="reach">
UPDATE docketwatch.dbo.damz_test
SET
  headline_final = <cfqueryparam value="#headline_final#" cfsqltype="cf_sql_varchar">,
  headline_type_final = <cfqueryparam value="#headline_type_final#" cfsqltype="cf_sql_varchar">,
  approved = <cfqueryparam value="#approved#" cfsqltype="cf_sql_bit">
WHERE fk_asset = <cfqueryparam value="#fk_asset#" cfsqltype="cf_sql_varchar">
</cfquery>

<cfoutput>{"success":true}</cfoutput>
