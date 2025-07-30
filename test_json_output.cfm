<cfheader name="Content-Type" value="application/json">
<cfcontent reset="true">

<cfset testResponse = {
    message = "Clean JSON test",
    timestamp = now()
}>

<cfcontent type="application/json">
<cfoutput>#serializeJSON(testResponse)#</cfoutput>
<cfabort>
