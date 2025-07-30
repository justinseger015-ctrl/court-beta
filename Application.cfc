<cfcomponent>

    <!--- Application settings --->
    <cfset this.name = "court_beta">
    <cfset this.sessionManagement = true>
    <cfset this.loginStorage = "session">

    <!--- Optional settings you can tune --->
    <cfset this.sessionTimeout = CreateTimeSpan(0, 4, 0, 0)> 
    <cfset this.applicationTimeout = CreateTimeSpan(2, 0, 0, 0)> 

    <!--- Application start logic --->
    <cffunction name="onApplicationStart" returnType="boolean">
        <cfset application.ReachFolder = "reach">
        
        <!--- Determine environment based on CGI server name --->
        <cfscript>
            // Get the server name from CGI
            serverName = cgi.server_name;
            
            // Set environment variables based on server name
            if (serverName contains "docketwatch") {
                application.serverDomain = "docketwatch.tmz.local";
                application.fileSharePath = "\\10.146.176.84\general\DOCKETWATCH\";
                application.appType = "docketwatch";
            } else {
                application.serverDomain = "tmztools.tmz.local";
                application.fileSharePath = "\\10.146.176.84\general\TMZTOOLS\wwwroot\";
                application.appType = "tmztools";
            }
            
            // Log which environment we're using (helpful for debugging)
            writeLog(file="docketwatch", text="Application started in environment: #application.appType# on server: #serverName#");
            
            // Set site title based on environment
            application.siteTitle = application.appType eq "docketwatch" ? "DocketWatch" : "TMZ Tools";
            
            // Set web root for relative paths
            application.webRoot = "./";
        </cfscript>
        
        <cfreturn true>
    </cffunction>

    <!--- Request initialization --->
    <cffunction name="onRequestStart" returnType="boolean">
        <cfargument name="request" required="true">

        <!--- Skip authentication for logout page --->
        <cfif arguments.request contains "logout.cfm">
            <!--- Clear all session variables --->
            <cfset SessionInvalidate()>
            <!--- Clear any authentication --->
            <cflogout>
            <!--- Redirect to login (which will be triggered by authentication logic below) --->
            <cflocation url="./index.cfm" addtoken="false">
        </cfif>

        <!--- Authentication (skip if Bypass flag is present) --->
        <cfif not isDefined("Bypass")>

            <!-- Handle logout -->
            <cfif isDefined("FORM.logout")>
                <!--- Clear all session variables --->
                <cfset SessionInvalidate()>
                <cflogout>
                <!--- Redirect to login --->
                <cflocation url="./index.cfm" addtoken="false">
            </cfif>

            <!-- Login prompt and validation --->
            <cflogin idleTimeout="86400">
                <cfif not isDefined("cflogin")>
                    <cfinclude template="/dwloginform.cfm">
                    <cfabort>
                <cfelse>
                    <cfif trim(cflogin.name) EQ "">
                        <cfset Login_Message = "You must enter your FOX Username and Password.">
                        <cfinclude template="/dwloginform.cfm">
                        <cfabort>
                    <cfelse>
                        <cfnTAuthenticate 
                            username="#cflogin.name#" 
                            password="#cflogin.password#" 
                            domain="tmz" 
                            result="authResult" 
                            listGroups="yes" 
                            throwOnError="false">

                        <cfif authResult.auth EQ "YES">
                            <cfloginuser 
                                name="#cflogin.name#" 
                                password="#cflogin.password#" 
                                roles="#authResult.groups#">
                            <cfset session.user_login = cflogin.name>
                        <cfelse>
                            <cfset Login_Message = "Your login information is not valid.<br>Please try again.">
                            <cfinclude template="/dwloginform.cfm">
                            <cfabort>
                        </cfif>
                    </cfif>
                </cfif>
            </cflogin>

        </cfif>

        <!--- User tracking: get authenticated username or fallback --->
        <cfset var userId = "System">
        <cfif GetAuthUser() NEQ "">
            <cfset userId = GetAuthUser()>
        <cfelseif structKeyExists(session, "user_login")>
            <cfset userId = session.user_login>
        </cfif>

        <cfreturn true>
    </cffunction>

</cfcomponent>
