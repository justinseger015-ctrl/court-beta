<!DOCTYPE html>
<html>
<head>
    <title>Test Python Script Execution</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .success { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .error { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .info { background-color: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        pre { background-color: #f8f9fa; padding: 15px; border: 1px solid #e9ecef; border-radius: 5px; overflow-x: auto; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #dee2e6; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Python Script Execution Test</h1>
        
        <div class="section">
            <h2>Configuration</h2>
            <p><strong>Method:</strong> Two-Step Batch File Execution</p>
            <p><strong>Batch File:</strong> test_two_step_processor.bat</p>
            <p><strong>Step 1:</strong> combined_pacer_pdf_processor.py (metadata + download)</p>
            <p><strong>Step 2:</strong> extract_pacer_pdf_file.py (backup download)</p>
            <p><strong>Case Event ID:</strong> 664EBE70-7066-4A39-A265-9A50A6E21694</p>
            <p><strong>Execution Time:</strong> <cfoutput>#now()#</cfoutput></p>
        </div>

        <cfset startTime = now()>
        <cfset batFilePath = "u:\docketwatch\python\test_two_step_processor.bat">
        <cfset caseEventId = "664EBE70-7066-4A39-A265-9A50A6E21694">

        <div class="section">
            <h2>Executing Two-Step Batch File...</h2>
            <div class="info">
                <strong>Command:</strong> <cfoutput>#batFilePath# silent</cfoutput><br>
                <strong>Process:</strong> Metadata extraction → PDF download (with backup downloader)
            </div>
        </div>

        <cftry>
            <cfexecute name="#batFilePath#"
                       arguments="silent"
                       timeout="300"
                       variable="output"
                       errorVariable="errorOutput">
            </cfexecute>

            <cfset endTime = now()>
            <cfset executionTime = dateDiff("s", startTime, endTime)>

            <div class="section">
                <div class="success">
                    <h2>✅ Execution Completed Successfully</h2>
                    <p><strong>Execution Time:</strong> <cfoutput>#executionTime# seconds</cfoutput></p>
                </div>

                <h3>Python Script Output:</h3>
                <pre><cfoutput>#htmlEditFormat(output)#</cfoutput></pre>

                <cfif len(trim(errorOutput))>
                    <h3>Error Output:</h3>
                    <pre><cfoutput>#htmlEditFormat(errorOutput)#</cfoutput></pre>
                </cfif>
            </div>

        <cfcatch type="any">
            <cfset endTime = now()>
            <cfset executionTime = dateDiff("s", startTime, endTime)>
            
            <div class="section">
                <div class="error">
                    <h2>❌ Execution Failed</h2>
                    <p><strong>Execution Time:</strong> <cfoutput>#executionTime# seconds</cfoutput></p>
                    <p><strong>Error Type:</strong> <cfoutput>#cfcatch.type#</cfoutput></p>
                    <p><strong>Error Message:</strong> <cfoutput>#cfcatch.message#</cfoutput></p>
                    <cfif structKeyExists(cfcatch, "detail") and len(trim(cfcatch.detail))>
                        <p><strong>Error Detail:</strong> <cfoutput>#cfcatch.detail#</cfoutput></p>
                    </cfif>
                </div>

                <cfif isDefined("output") and len(trim(output))>
                    <h3>Partial Output Before Error:</h3>
                    <pre><cfoutput>#htmlEditFormat(output)#</cfoutput></pre>
                </cfif>

                <cfif isDefined("errorOutput") and len(trim(errorOutput))>
                    <h3>Error Output:</h3>
                    <pre><cfoutput>#htmlEditFormat(errorOutput)#</cfoutput></pre>
                </cfif>
            </div>
        </cfcatch>
        </cftry>

        <div class="section">
            <h2>Log File Check</h2>
            <p>You can check the Python script logs at:</p>
            <code>u:\docketwatch\python\logs\combined_pacer_pdf_processor.log</code>
            
            <br><br>
            
            <cftry>
                <cfset logFilePath = "u:\docketwatch\python\logs\combined_pacer_pdf_processor.log">
                <cfif fileExists(logFilePath)>
                    <cffile action="read" file="#logFilePath#" variable="logContent">
                    <cfset logLines = listToArray(logContent, chr(10))>
                    <cfset lastLines = "">
                    <cfset startIndex = max(1, arrayLen(logLines) - 19)>
                    
                    <div class="info">
                        <strong>Last 20 lines from log file:</strong>
                    </div>
                    <pre>
<cfloop from="#startIndex#" to="#arrayLen(logLines)#" index="i">
<cfoutput>#htmlEditFormat(logLines[i])#</cfoutput>
</cfloop>
                    </pre>
                <cfelse>
                    <div class="error">Log file not found at: <cfoutput>#logFilePath#</cfoutput></div>
                </cfif>
                
            <cfcatch type="any">
                <div class="error">
                    Error reading log file: <cfoutput>#cfcatch.message#</cfoutput>
                </div>
            </cfcatch>
            </cftry>
        </div>

        <div class="section">
            <h2>Database Check</h2>
            <p>Checking database for processing results...</p>
            
            <cftry>
                <cfquery name="checkDocuments" datasource="docketwatch">
                    SELECT COUNT(*) as doc_count,
                           SUM(CASE WHEN rel_path != 'pending' THEN 1 ELSE 0 END) as downloaded_count
                    FROM docketwatch.dbo.documents 
                    WHERE fk_case_event = <cfqueryparam value="#caseEventId#" cfsqltype="CF_SQL_VARCHAR">
                </cfquery>
                
                <cfquery name="checkEvent" datasource="docketwatch">
                    SELECT event_description, event_url
                    FROM docketwatch.dbo.case_events 
                    WHERE id = <cfqueryparam value="#caseEventId#" cfsqltype="CF_SQL_VARCHAR">
                </cfquery>
                
                <div class="info">
                    <cfif checkEvent.recordCount gt 0>
                        <p><strong>Event Found:</strong> <cfoutput>#checkEvent.event_description#</cfoutput></p>
                        <p><strong>Event URL:</strong> <cfoutput>#checkEvent.event_url#</cfoutput></p>
                    <cfelse>
                        <p><strong>Event:</strong> Not found in database</p>
                    </cfif>
                    
                    <p><strong>Total Documents:</strong> <cfoutput>#checkDocuments.doc_count#</cfoutput></p>
                    <p><strong>Downloaded Documents:</strong> <cfoutput>#checkDocuments.downloaded_count#</cfoutput></p>
                </div>
                
            <cfcatch type="any">
                <div class="error">
                    Error checking database: <cfoutput>#cfcatch.message#</cfoutput>
                </div>
            </cfcatch>
            </cftry>
        </div>

        <div class="section">
            <h2>Quick Actions</h2>
            <p><a href="test_python_execution.cfm">🔄 Run Test Again</a></p>
            <p><a href="javascript:window.location.reload()">🔁 Refresh Page</a></p>
        </div>
    </div>
</body>
</html>