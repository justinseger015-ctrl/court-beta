<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfheader name="Content-Type" value="application/json">

<cftry>
    <cfset pythonExe = "C:\Python312\python.exe">
    <cfset pythonScript = "U:\docketwatch\python\summarize_upload_cli.py">
    
    <!--- Test 1: Check if Python exists --->
    <cfset pythonExists = fileExists(pythonExe)>
    <cfset scriptExists = fileExists(pythonScript)>
    
    <!--- Test 2: Run Python version check --->
    <cfexecute name="#pythonExe#"
               arguments="--version"
               timeout="10"
               variable="pyVersion"
               errorVariable="pyVersionError">
    </cfexecute>
    
    <!--- Test 3: Try to run the script with --help --->
    <cfexecute name="#pythonExe#"
               arguments="#pythonScript# --help"
               timeout="30"
               variable="pyHelp"
               errorVariable="pyHelpError">
    </cfexecute>
    
    <cfset response = {
        "python_exe": pythonExe,
        "python_exists": pythonExists,
        "python_script": pythonScript,
        "script_exists": scriptExists,
        "python_version": pyVersion,
        "python_version_error": pyVersionError,
        "script_help_output": pyHelp,
        "script_help_error": pyHelpError
    }>
    
    <cfoutput>#serializeJSON(response)#</cfoutput>
    
    <cfcatch type="any">
        <cfset errorResponse = {
            "error": cfcatch.message,
            "detail": cfcatch.detail,
            "type": cfcatch.type
        }>
        <cfoutput>#serializeJSON(errorResponse)#</cfoutput>
    </cfcatch>
</cftry>
