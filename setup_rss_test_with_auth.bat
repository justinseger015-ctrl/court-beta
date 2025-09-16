@echo off
echo DocketWatch RSS Test Setup
echo =========================
echo.
echo Choose your SQL Server authentication method:
echo 1. Windows Authentication (current user)
echo 2. SQL Server Authentication (username/password)
echo.
set /p auth_choice="Enter choice (1 or 2): "

if "%auth_choice%"=="1" (
    set "sql_auth=-E"
    echo Using Windows Authentication...
) else if "%auth_choice%"=="2" (
    set /p sql_user="Enter SQL username: "
    set /p sql_pass="Enter SQL password: "
    set "sql_auth=-U %sql_user% -P %sql_pass%"
    echo Using SQL Server Authentication...
) else (
    echo Invalid choice. Defaulting to Windows Authentication.
    set "sql_auth=-E"
)

echo.
echo Testing connection...
sqlcmd -S localhost %sql_auth% -d docketwatch -Q "SELECT 'Connection successful' as status" 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Could not connect to database. Please check your credentials.
    pause
    exit /b 1
)

echo Connection successful!
echo.
echo Creating stored procedures...
sqlcmd -S localhost %sql_auth% -d docketwatch -i delete_event_procedures.sql

echo.
echo Finding recent events with RSS entries...
echo.

sqlcmd -S localhost %sql_auth% -d docketwatch -Q "SELECT TOP 5 ROW_NUMBER() OVER (ORDER BY e.created_at DESC) as [Row], CAST(e.id AS VARCHAR(50)) as [Event_GUID], e.event_no as [Event_No], LEFT(e.event_description, 30) as [Description], LEFT(c.case_name, 20) as [Case_Name], CONVERT(VARCHAR, e.created_at, 120) as [Created] FROM docketwatch.dbo.case_events e INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases INNER JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no WHERE e.created_at >= DATEADD(hour, -72, GETDATE()) AND c.status = 'Tracked' AND c.pacer_id IS NOT NULL ORDER BY e.created_at DESC"

echo.
echo Ready-to-copy delete commands:
echo.

sqlcmd -S localhost %sql_auth% -d docketwatch -Q "SELECT TOP 3 'sqlcmd -S localhost %sql_auth% -d docketwatch -Q \"EXEC delete_event_for_test ''' + CAST(e.id AS VARCHAR(50)) + ''';\"' as [Copy_This_Full_Command] FROM docketwatch.dbo.case_events e INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases INNER JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no WHERE e.created_at >= DATEADD(hour, -72, GETDATE()) AND c.status = 'Tracked' AND c.pacer_id IS NOT NULL ORDER BY e.created_at DESC"

echo.
echo ================================
echo NEXT STEPS:
echo 1. Copy one of the commands from above
echo 2. Paste and run it in this command prompt
echo 3. Test RSS: http://your-server/docketwatch_rss_trigger_plus.cfm?bypass=1
echo 4. Monitor: sqlcmd -S localhost %sql_auth% -d docketwatch -Q "EXEC check_rss_test_results"
echo ================================
echo.
pause
