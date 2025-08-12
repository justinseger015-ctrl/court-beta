<!DOCTYPE html>
<html>
<head>
    <title>AI Success Rate Dashboard - DAMZ Headline Optimization</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #007bff;
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .metric-card h3 {
            margin: 0 0 10px 0;
            font-size: 16px;
        }
        .metric-card .number {
            font-size: 32px;
            font-weight: bold;
            margin: 10px 0;
        }
        .metric-card .percentage {
            font-size: 18px;
            opacity: 0.9;
        }
        .success { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); }
        .warning { background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); }
        .info { background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%); }
        .danger { background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%); }
        
        .status-good { color: #4CAF50; font-weight: bold; }
        .status-bad { color: #f44336; font-weight: bold; }
        .status-warning { color: #ff9800; font-weight: bold; }
        .status-neutral { color: #757575; }
        
        .section {
            margin: 30px 0;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 8px;
            background-color: #fafafa;
        }
        .section h2 {
            margin-top: 0;
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            background-color: white;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
            word-wrap: break-word;
            max-width: 300px;
        }
        th {
            background-color: #007bff;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .status-good { color: #4CAF50; font-weight: bold; }
        .status-bad { color: #f44336; font-weight: bold; }
        .status-neutral { color: #757575; }
        .refresh-btn {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-bottom: 20px;
        }
        .refresh-btn:hover {
            background-color: #0056b3;
        }
        .last-updated {
            text-align: right;
            color: #666;
            font-size: 14px;
            margin-top: 20px;
        }
    </style>
</head>
<body>

<div class="container">
    <div class="header">
        <h1>AI Success Rate Dashboard</h1>
        <p>DAMZ Headline Optimization Analysis</p>
        <button class="refresh-btn" onclick="location.reload()">Refresh Data</button>
    </div>

    <cfquery name="getOverallStats" datasource="docketwatch">
        SELECT 
            COUNT(*) as total_records,
            COUNT(CASE WHEN headline_optimized IS NOT NULL AND headline_type IS NOT NULL THEN 1 END) as ai_v1_processed,
            COUNT(CASE WHEN headline_v2 IS NOT NULL AND headline_type_v2 IS NOT NULL THEN 1 END) as ai_v2_processed,
            COUNT(CASE WHEN headline_v3 IS NOT NULL AND headline_type_v3 IS NOT NULL THEN 1 END) as ai_v3_processed,
            COUNT(CASE WHEN headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as user_reviewed,
            
            -- AI v1 Success: Both headline_optimized and headline_type match final versions
            COUNT(CASE WHEN headline_optimized = headline_final 
                          AND headline_type = headline_type_final 
                          AND headline_final IS NOT NULL 
                          AND headline_type_final IS NOT NULL THEN 1 END) as ai_v1_perfect,
            
            -- AI v2 Success: Both headline_v2 and headline_type_v2 match final versions  
            COUNT(CASE WHEN headline_v2 = headline_final 
                          AND headline_type_v2 = headline_type_final 
                          AND headline_final IS NOT NULL 
                          AND headline_type_final IS NOT NULL THEN 1 END) as ai_v2_perfect,
            
            -- AI v3 Success: Both headline_v3 and headline_type_v3 match final versions  
            COUNT(CASE WHEN headline_v3 = headline_final 
                          AND headline_type_v3 = headline_type_final 
                          AND headline_final IS NOT NULL 
                          AND headline_type_final IS NOT NULL THEN 1 END) as ai_v3_perfect,
            
            COUNT(CASE WHEN flagged = 1 THEN 1 END) as flagged_for_processing
        FROM docketwatch.dbo.damz_test
        WHERE headline_v2 IS NOT NULL 
    </cfquery>

    <!-- Key Metrics Cards -->
    <div class="metrics-grid">
        <div class="metric-card info">
            <h3>AI v1 Processed</h3>
            <div class="number"><cfoutput>#getOverallStats.ai_v1_processed#</cfoutput></div>
        </div>
        
        <div class="metric-card info">
            <h3>AI v2 Processed</h3>
            <div class="number"><cfoutput>#getOverallStats.ai_v2_processed#</cfoutput></div>
        </div>

        <div class="metric-card info">
            <h3>AI v3 Processed</h3>
            <div class="number"><cfoutput>#getOverallStats.ai_v3_processed#</cfoutput></div>
        </div>

        <div class="metric-card success">
            <h3>AI v1 Success Rate</h3>
            <div class="number">
                <cfoutput>
                    <cfif getOverallStats.user_reviewed GT 0>
                        #round((getOverallStats.ai_v1_perfect / getOverallStats.user_reviewed) * 100)#%
                    <cfelse>
                        N/A
                    </cfif>
                </cfoutput>
            </div>
            <div class="percentage">
                <cfoutput>
                    #getOverallStats.ai_v1_perfect# of #getOverallStats.user_reviewed# perfect
                </cfoutput>
            </div>
        </div>

        <div class="metric-card success">
            <h3>AI v2 Success Rate</h3>
            <div class="number">
                <cfoutput>
                    <cfif getOverallStats.user_reviewed GT 0>
                        #round((getOverallStats.ai_v2_perfect / getOverallStats.user_reviewed) * 100)#%
                    <cfelse>
                        N/A
                    </cfif>
                </cfoutput>
            </div>
            <div class="percentage">
                <cfoutput>
                    #getOverallStats.ai_v2_perfect# of #getOverallStats.user_reviewed# perfect
                </cfoutput>
            </div>
        </div>

        <div class="metric-card success">
            <h3>AI v3 Success Rate</h3>
            <div class="number">
                <cfoutput>
                    <cfif getOverallStats.user_reviewed GT 0>
                        #round((getOverallStats.ai_v3_perfect / getOverallStats.user_reviewed) * 100)#%
                    <cfelse>
                        N/A
                    </cfif>
                </cfoutput>
            </div>
            <div class="percentage">
                <cfoutput>
                    #getOverallStats.ai_v3_perfect# of #getOverallStats.user_reviewed# perfect
                </cfoutput>
            </div>
        </div>
    </div>

    <!-- Success Rate Calculation Breakdown -->
    <div class="section">
        <h2>Success Rate Calculation Details</h2>
        <cfquery name="getCalculationBreakdown" datasource="docketwatch">
            SELECT 
                -- Total records with user reviews (denominator)
                COUNT(CASE WHEN headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as total_reviewed,
                
                -- AI v1 breakdown
                COUNT(CASE WHEN headline_optimized IS NOT NULL AND headline_type IS NOT NULL THEN 1 END) as ai_v1_attempted,
                COUNT(CASE WHEN headline_optimized = headline_final AND headline_type = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v1_perfect_match,
                COUNT(CASE WHEN headline_optimized = headline_final AND headline_type != headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v1_headline_only,
                COUNT(CASE WHEN headline_optimized != headline_final AND headline_type = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v1_type_only,
                COUNT(CASE WHEN headline_optimized != headline_final AND headline_type != headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL 
                           AND headline_optimized IS NOT NULL AND headline_type IS NOT NULL THEN 1 END) as ai_v1_both_wrong,
                
                -- AI v2 breakdown  
                COUNT(CASE WHEN headline_v2 IS NOT NULL AND headline_type_v2 IS NOT NULL THEN 1 END) as ai_v2_attempted,
                COUNT(CASE WHEN headline_v2 = headline_final AND headline_type_v2 = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v2_perfect_match,
                COUNT(CASE WHEN headline_v2 = headline_final AND headline_type_v2 != headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v2_headline_only,
                COUNT(CASE WHEN headline_v2 != headline_final AND headline_type_v2 = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v2_type_only,
                COUNT(CASE WHEN headline_v2 != headline_final AND headline_type_v2 != headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL 
                           AND headline_v2 IS NOT NULL AND headline_type_v2 IS NOT NULL THEN 1 END) as ai_v2_both_wrong,
                
                -- AI v3 breakdown  
                COUNT(CASE WHEN headline_v3 IS NOT NULL AND headline_type_v3 IS NOT NULL THEN 1 END) as ai_v3_attempted,
                COUNT(CASE WHEN headline_v3 = headline_final AND headline_type_v3 = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v3_perfect_match,
                COUNT(CASE WHEN headline_v3 = headline_final AND headline_type_v3 != headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v3_headline_only,
                COUNT(CASE WHEN headline_v3 != headline_final AND headline_type_v3 = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v3_type_only,
                COUNT(CASE WHEN headline_v3 != headline_final AND headline_type_v3 != headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL 
                           AND headline_v3 IS NOT NULL AND headline_type_v3 IS NOT NULL THEN 1 END) as ai_v3_both_wrong
            FROM docketwatch.dbo.damz_test
            WHERE headline IS NOT NULL
        </cfquery>

        <p><strong>Formula:</strong> Success Rate = (Perfect Matches / Total Reviewed Records) × 100</p>
        <p><em>A "Perfect Match" requires BOTH the headline AND headline_type to exactly match the user's final choices.</em></p>

        <cfoutput query="getCalculationBreakdown">
            <table style="margin-bottom: 20px;">
                <thead>
                    <tr>
                        <th>Metric</th>
                        <th>AI v1</th>
                        <th>AI v2</th>
                        <th>AI v3</th>
                        <th>Notes</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Records Attempted</strong></td>
                        <td>#ai_v1_attempted#</td>
                        <td>#ai_v2_attempted#</td>
                        <td>#ai_v3_attempted#</td>
                        <td>Records where AI generated both headline and type</td>
                    </tr>
                    <tr>
                        <td><strong>Total User Reviewed</strong></td>
                        <td colspan="3" style="text-align: center;">#total_reviewed#</td>
                        <td>Records with both headline_final and headline_type_final (DENOMINATOR)</td>
                    </tr>
                    <tr class="status-good">
                        <td><strong>Perfect Matches</strong></td>
                        <td>#ai_v1_perfect_match#</td>
                        <td>#ai_v2_perfect_match#</td>
                        <td>#ai_v3_perfect_match#</td>
                        <td>Both headline AND type match user final (NUMERATOR)</td>
                    </tr>
                    <tr class="status-warning">
                        <td><strong>Headline Match, Type Wrong</strong></td>
                        <td>#ai_v1_headline_only#</td>
                        <td>#ai_v2_headline_only#</td>
                        <td>#ai_v3_headline_only#</td>
                        <td>Headline correct but type incorrect</td>
                    </tr>
                    <tr class="status-warning">
                        <td><strong>Type Match, Headline Wrong</strong></td>
                        <td>#ai_v1_type_only#</td>
                        <td>#ai_v2_type_only#</td>
                        <td>#ai_v3_type_only#</td>
                        <td>Type correct but headline incorrect</td>
                    </tr>
                    <tr class="status-bad">
                        <td><strong>Both Wrong</strong></td>
                        <td>#ai_v1_both_wrong#</td>
                        <td>#ai_v2_both_wrong#</td>
                        <td>#ai_v3_both_wrong#</td>
                        <td>Neither headline nor type match user final</td>
                    </tr>
                    <tr style="border-top: 2px solid ##007bff; font-weight: bold;">
                        <td><strong>Success Rate Calculation</strong></td>
                        <td>
                            <cfif total_reviewed GT 0>
                                #ai_v1_perfect_match# ÷ #total_reviewed# = #round((ai_v1_perfect_match / total_reviewed) * 100)#%
                            <cfelse>
                                N/A
                            </cfif>
                        </td>
                        <td>
                            <cfif total_reviewed GT 0>
                                #ai_v2_perfect_match# ÷ #total_reviewed# = #round((ai_v2_perfect_match / total_reviewed) * 100)#%
                            <cfelse>
                                N/A
                            </cfif>
                        </td>
                        <td>Perfect Matches ÷ Total Reviewed × 100</td>
                    </tr>
                </tbody>
            </table>

            <!-- Additional Analysis -->
            <h3>Key Points:</h3>
            <ul>
                <li><strong>Success Criteria:</strong> BOTH headline_optimized = headline_final AND headline_type = headline_type_final</li>
                <li><strong>Denominator:</strong> Only records where users provided final review (#total_reviewed# records)</li>
                <li><strong>Partial Credit:</strong> No partial credit given - must get both headline and type exactly right</li>
                <cfif total_reviewed GT 0>
                    <cfset ai_v1_partial = ai_v1_headline_only + ai_v1_type_only>
                    <cfset ai_v2_partial = ai_v2_headline_only + ai_v2_type_only>
                    <li><strong>Close Attempts:</strong> 
                        AI v1 got at least one component right in #ai_v1_partial# additional cases (#round((ai_v1_partial / total_reviewed) * 100)#%), 
                        AI v2 got at least one component right in #ai_v2_partial# additional cases (#round((ai_v2_partial / total_reviewed) * 100)#%)
                    </li>
                </cfif>
            </ul>
        </cfoutput>
    </div>

    <!-- AI v1 Analysis -->
    <div class="section">
        <h2>AI v1 Analysis (Original AI Rules)</h2>
        <cfquery name="getAIv1Details" datasource="docketwatch">
            SELECT 
                fk_asset,
                headline,
                headline_optimized,
                headline_final,
                headline_type,
                headline_type_final,
                CASE 
                    WHEN headline_optimized = headline_final AND headline_type = headline_type_final THEN 'Perfect Match'
                    WHEN headline_final IS NULL OR headline_type_final IS NULL THEN 'Not Reviewed'
                    WHEN headline_optimized = headline_final AND headline_type != headline_type_final THEN 'Headline Match, Type Wrong'
                    WHEN headline_optimized != headline_final AND headline_type = headline_type_final THEN 'Type Match, Headline Wrong'
                    ELSE 'Both Wrong'
                END as status
            FROM docketwatch.dbo.damz_test
            WHERE headline_optimized IS NOT NULL AND headline_type IS NOT NULL
            ORDER BY 
                CASE 
                    WHEN headline_optimized = headline_final AND headline_type = headline_type_final THEN 1
                    WHEN headline_final IS NULL OR headline_type_final IS NULL THEN 2
                    WHEN headline_optimized = headline_final AND headline_type != headline_type_final THEN 3
                    WHEN headline_optimized != headline_final AND headline_type = headline_type_final THEN 4
                    ELSE 5
                END,
                fk_asset
        </cfquery>

        <table>
            <thead>
                <tr>
                    <th>Asset ID</th>
                    <th>Original Headline</th>
                    <th>AI Generated (Batch 1)</th>
                    <th>User Final</th>
                    <th>AI Type</th>
                    <th>User Type</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="getAIv1Details" maxrows="50">
                    <tr>
                        <td>#left(fk_asset, 8)#...</td>
                        <td>#headline#</td>
                        <td>#headline_optimized#</td>
                        <td>
                            <cfif headline_final NEQ "">
                                #headline_final#
                            <cfelse>
                                <em>Not reviewed</em>
                            </cfif>
                        </td>
                        <td>#headline_type#</td>
                        <td>#headline_type_final#</td>
                        <td class="
                            <cfif status EQ 'Perfect Match'>status-good
                            <cfelseif status EQ 'Both Wrong'>status-bad
                            <cfelseif status EQ 'Headline Match, Type Wrong' OR status EQ 'Type Match, Headline Wrong'>status-warning
                            <cfelse>status-neutral</cfif>
                        ">#status#</td>
                    </tr>
                </cfoutput>
                <cfif getAIv1Details.recordCount GT 50>
                    <tr><td colspan="7"><em>Showing first 50 records. Total: <cfoutput>#getAIv1Details.recordCount#</cfoutput></em></td></tr>
                </cfif>
            </tbody>
        </table>
    </div>

    <!-- AI v2 Analysis -->
    <div class="section">
        <h2>AI v2 Analysis (Improved AI Rules)</h2>
        <cfquery name="getAIv2Details" datasource="docketwatch">
            SELECT 
                fk_asset,
                headline,
                headline_optimized,
                headline_v2,
                headline_final,
                headline_type,
                headline_type_v2,
                headline_type_final,
                CASE 
                    WHEN headline_v2 = headline_final AND headline_type_v2 = headline_type_final THEN 'Perfect Match'
                    WHEN headline_v2 IS NULL OR headline_type_v2 IS NULL THEN 'Not Processed'
                    WHEN headline_final IS NULL OR headline_type_final IS NULL THEN 'Not Reviewed'
                    WHEN headline_v2 = headline_final AND headline_type_v2 != headline_type_final THEN 'Headline Match, Type Wrong'
                    WHEN headline_v2 != headline_final AND headline_type_v2 = headline_type_final THEN 'Type Match, Headline Wrong'
                    ELSE 'Both Wrong'
                END as status
            FROM docketwatch.dbo.damz_test
            WHERE headline_v2 IS NOT NULL AND headline_type_v2 IS NOT NULL
            ORDER BY 
                CASE 
                    WHEN headline_v2 = headline_final AND headline_type_v2 = headline_type_final THEN 1
                    WHEN headline_v2 IS NULL OR headline_type_v2 IS NULL THEN 2
                    WHEN headline_final IS NULL OR headline_type_final IS NULL THEN 3
                    WHEN headline_v2 = headline_final AND headline_type_v2 != headline_type_final THEN 4
                    WHEN headline_v2 != headline_final AND headline_type_v2 = headline_type_final THEN 5
                    ELSE 6
                END,
                fk_asset
        </cfquery>

        <table>
            <thead>
                <tr>
                    <th>Asset ID</th>
                    <th>Original</th>
                    <th>AI v1</th>
                    <th>AI v2</th>
                    <th>User Final</th>
                    <th>Type (v1→v2→Final)</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="getAIv2Details" maxrows="50">
                    <tr>
                        <td>#left(fk_asset, 8)#...</td>
                        <td>#headline#</td>
                        <td>#headline_optimized#</td>
                        <td>
                            <cfif headline_v2 NEQ "">
                                #headline_v2#
                            <cfelse>
                                <em>Not processed</em>
                            </cfif>
                        </td>
                        <td>#headline_final#</td>
                        <td>
                            #headline_type# → 
                            <cfif headline_type_v2 NEQ "">#headline_type_v2#<cfelse>N/A</cfif> → 
                            #headline_type_final#
                        </td>
                        <td class="
                            <cfif status EQ 'Perfect Match'>status-good
                            <cfelseif status EQ 'Both Wrong'>status-bad
                            <cfelseif status EQ 'Headline Match, Type Wrong' OR status EQ 'Type Match, Headline Wrong'>status-warning
                            <cfelse>status-neutral</cfif>
                        ">#status#</td>
                    </tr>
                </cfoutput>
                <cfif getAIv2Details.recordCount GT 50>
                    <tr><td colspan="7"><em>Showing first 50 records. Total: <cfoutput>#getAIv2Details.recordCount#</cfoutput></em></td></tr>
                </cfif>
            </tbody>
        </table>
    </div>

    <!-- Type Analysis -->
    <div class="section">
        <h2>Headline Type Distribution</h2>
        <cfquery name="getTypeStats" datasource="docketwatch">
            SELECT 
                headline_type_final,
                COUNT(*) as count,
                COUNT(CASE WHEN headline_optimized = headline_final AND headline_type = headline_type_final THEN 1 END) as ai_v1_success,
                COUNT(CASE WHEN headline_v2 = headline_final AND headline_type_v2 = headline_type_final THEN 1 END) as ai_v2_success
            FROM docketwatch.dbo.damz_test
            WHERE headline_type_final IS NOT NULL
            GROUP BY headline_type_final
            ORDER BY count DESC
        </cfquery>

        <table>
            <thead>
                <tr>
                    <th>Headline Type</th>
                    <th>Total Count</th>
                    <th>AI v1 Successes</th>
                    <th>AI v2 Successes</th>
                    <th>AI v1 Success Rate</th>
                    <th>AI v2 Success Rate</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="getTypeStats">
                    <tr>
                        <td><strong>#headline_type_final#</strong></td>
                        <td>#count#</td>
                        <td>#ai_v1_success#</td>
                        <td>#ai_v2_success#</td>
                        <td>
                            <cfif count GT 0>
                                #round((ai_v1_success / count) * 100)#%
                            <cfelse>
                                0%
                            </cfif>
                        </td>
                        <td>
                            <cfif count GT 0>
                                #round((ai_v2_success / count) * 100)#%
                            <cfelse>
                                0%
                            </cfif>
                        </td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>

    <!-- Summary Insights -->
    <div class="section">
        <h2>Key Insights</h2>
        <cfquery name="getInsights" datasource="docketwatch">
            SELECT 
                COUNT(CASE WHEN headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as reviewed_count,
                COUNT(CASE WHEN headline_optimized = headline_final AND headline_type = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v1_perfect,
                COUNT(CASE WHEN headline_v2 = headline_final AND headline_type_v2 = headline_type_final 
                           AND headline_final IS NOT NULL AND headline_type_final IS NOT NULL THEN 1 END) as ai_v2_perfect,
                COUNT(CASE WHEN headline_optimized IS NOT NULL AND headline_type IS NOT NULL THEN 1 END) as ai_v1_processed,
                COUNT(CASE WHEN headline_v2 IS NOT NULL AND headline_type_v2 IS NOT NULL THEN 1 END) as ai_v2_processed
            FROM docketwatch.dbo.damz_test
            WHERE headline IS NOT NULL
        </cfquery>

        <cfoutput query="getInsights">
            <ul>
                <li><strong>AI v1 Performance:</strong> 
                    <cfif reviewed_count GT 0>
                        #round((ai_v1_perfect / reviewed_count) * 100)#% success rate (#ai_v1_perfect# perfect out of #reviewed_count# reviewed)
                    <cfelse>
                        No reviewed records found
                    </cfif>
                </li>
                <li><strong>AI v2 Performance:</strong> 
                    <cfif reviewed_count GT 0>
                        #round((ai_v2_perfect / reviewed_count) * 100)#% success rate (#ai_v2_perfect# perfect out of #reviewed_count# reviewed)
                    <cfelse>
                        No reviewed records found
                    </cfif>
                </li>
                <li><strong>Improvement from v1 to v2:</strong> 
                    <cfif reviewed_count GT 0>
                        <cfset improvement = ai_v2_perfect - ai_v1_perfect>
                        <cfset improvement_pct = round(((ai_v2_perfect / reviewed_count) - (ai_v1_perfect / reviewed_count)) * 100)>
                        <cfif improvement GT 0>
                            +#improvement_pct# percentage points improvement (#improvement# more perfect headlines)
                        <cfelseif improvement LT 0>
                            #improvement_pct# percentage points decline (#abs(improvement)# fewer perfect headlines)
                        <cfelse>
                            No change in performance
                        </cfif>
                    <cfelse>
                        No data available
                    </cfif>
                </li>
                <li><strong>Processing Coverage:</strong> 
                    AI v1 processed #ai_v1_processed# records, AI v2 processed #ai_v2_processed# records
                </li>
            </ul>
        </cfoutput>
    </div>

    <div class="last-updated">
        Last updated: <cfoutput>#dateFormat(now(), "mmm dd, yyyy")# at #timeFormat(now(), "h:mm tt")#</cfoutput>
    </div>
</div>

</body>
</html>
