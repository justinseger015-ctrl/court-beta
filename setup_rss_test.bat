@echo off
echo Creating stored procedures...
sqlcmd -S localhost -E -d docketwatch -i delete_event_procedures.sql > nul 2>&1

echo.
echo Showing recent events with RSS entries...
echo.

sqlcmd -S localhost -E -d docketwatch -Q "SELECT TOP 5 ROW_NUMBER() OVER (ORDER BY e.created_at DESC) as [#], CAST(e.id AS VARCHAR(50)) as [Event_GUID], e.event_no as [Event_No], LEFT(e.event_description, 35) as [Description], LEFT(c.case_name, 25) as [Case_Name] FROM docketwatch.dbo.case_events e INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases INNER JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no WHERE e.created_at >= DATEADD(hour, -72, GETDATE()) AND c.status = 'Tracked' AND c.pacer_id IS NOT NULL ORDER BY e.created_at DESC"

echo.
echo Generating delete commands...
echo.

sqlcmd -S localhost -E -d docketwatch -Q "SELECT TOP 3 ROW_NUMBER() OVER (ORDER BY e.created_at DESC) as [Cmd#], 'EXEC delete_event_for_test ''' + CAST(e.id AS VARCHAR(50)) + ''';' as [Copy_This_Command] FROM docketwatch.dbo.case_events e INNER JOIN docketwatch.dbo.cases c ON c.id = e.fk_cases INNER JOIN docketwatch.dbo.rss_feed_entries r ON r.pacer_id = c.pacer_id AND r.event_no = e.event_no WHERE e.created_at >= DATEADD(hour, -72, GETDATE()) AND c.status = 'Tracked' AND c.pacer_id IS NOT NULL ORDER BY e.created_at DESC"

echo.
echo ================================
echo INSTRUCTIONS:
echo 1. Copy one of the commands from [Copy_This_Command] column above
echo 2. Run the command in SQL Server Management Studio or sqlcmd
echo 3. Then test: http://your-server/docketwatch_rss_trigger_plus.cfm?bypass=1
echo 4. Monitor with: sqlcmd -S localhost -E -d docketwatch -Q "EXEC check_rss_test_results"
echo ================================
