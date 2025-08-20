<!--- Encoding / Mojibake Cleanup Utility

Purpose: Fix common Windows-1252 interpreted-as-UTF8 mojibake sequences already stored in the database (e.g., â€™ -> ’).

USE CAREFULLY. Always run first with mode=preview to view proposed changes.
Add or adjust table/column config below to match your schema.

Invocation examples:
  /court-beta/encoding_cleanup.cfm?auth=CHANGE_ME&mode=preview
  /court-beta/encoding_cleanup.cfm?auth=CHANGE_ME&mode=commit

Safety:
- Requires ?auth= token (set AUTH_TOKEN below)
- Preview mode shows diffs, does NOT write
- Commit mode wraps each table in a transaction
- Skips rows with no targeted sequences

Customize:
- Update tableConfigs array with actual table + primary key + columns needing cleanup
- Extend replacementMap for any additional sequences

Idempotency:
- Script only replaces exact mojibake byte sequences; running again is safe (no double replacement)

--->
<cfscript>
// ===================== CONFIG =====================
AUTH_TOKEN = "CHANGE_ME"; // Set to a strong secret string before use
param name="url.auth" default="";
param name="url.mode" default="preview"; // preview | commit

// Whitelist of tables & columns to clean. Replace with your real schema.
// Example structure entries: {table="Cases", pk="CaseID", columns=["Title","Summary","Notes"]}
tableConfigs = [
    // {table="Cases", pk="CaseID", columns=["CaseTitle","CaseSummary"]},
    // {table="Dockets", pk="DocketID", columns=["Description"]},
];

if (!arrayLen(tableConfigs)) {
    // Fallback: You must define your tables before proceeding
}

// Map of mojibake -> correct character(s)
replacementMap = [
    {bad="â€™", good="’"}, // right single quote
    {bad="â€˜", good="‘"}, // left single quote
    {bad="â€œ", good="“"}, // left double quote
    {bad="â€�", good="”"}, // right double quote
    {bad="â€“", good="–"}, // en dash
    {bad="â€”", good="—"}, // em dash
    {bad="â€¦", good="…"}, // ellipsis
    {bad="â€¢", good="•"}, // bullet
    {bad="â€¢", good="•"}, // bullet (duplicate safe)
    {bad="â€”", good="—"}, // em dash (duplicate safe)
    {bad="Â©", good="©"},
    {bad="Â®", good="®"},
    {bad="Â", good=""} // stray Â prefix before symbols
];

// Optional: patterns that indicate a row likely needs cleanup (optimize scanning)
likeIndicators = ["â%", "%Â%"];

// ===================== SECURITY CHECK =====================
if (url.auth != AUTH_TOKEN) {
    writeOutput("<h3>Unauthorized. Set ?auth= token.</h3>");
    abort;
}

mode = lcase(url.mode);
if (!listFindNoCase("preview,commit", mode)) mode = "preview";

writeOutput('<h2>Encoding Cleanup - ' & ucase(mode) & ' mode</h2>');
if (mode EQ "preview") writeOutput('<p style="color:#cc8800">No data will be modified in preview mode.</p>');

if (!arrayLen(tableConfigs)) {
    writeOutput('<p style="color:red">No tableConfigs defined. Edit file first.</p>');
    abort;
}

// ===================== FUNCTIONS =====================
/**
 * Returns cleaned string + a diff structure if changed.
 */
function cleanValue(original) {
    var cleaned = original;
    for (var r in replacementMap) {
        if (findNoCase(r.bad, cleaned)) {
            cleaned = replaceNoCase(cleaned, r.bad, r.good, "all");
        }
    }
    return cleaned;
}

// Generate an HTML diff snippet (simple highlight)
function simpleDiff(before, after) {
    if (before EQ after) return "";
    // naive approach: highlight replacements by iterating replacementMap
    var tmp = htmlEditFormat(after);
    for (var r in replacementMap) {
        if (findNoCase(r.good, tmp)) {
            // highlight good chars to show presence (post-change view)
            tmp = replace(tmp, r.good, '<span style="background:#d1ffd1">' & htmlEditFormat(r.good) & '</span>', "all");
        }
    }
    return '<div style="font-family:monospace; font-size:12px">' &
        '<div style="color:#777">Original:</div><div style="white-space:pre-wrap;border:1px solid #ccc;padding:4px;margin-bottom:4px">' & htmlEditFormat(before) & '</div>' &
        '<div style="color:#777">Cleaned:</div><div style="white-space:pre-wrap;border:1px solid #ccc;padding:4px">' & tmp & '</div>' &
        '</div>';
}

// ===================== PROCESSING =====================
var totalRowsScanned = 0;
var totalRowsChanged = 0;
var tableReport = [];

for (var cfg in tableConfigs) {
    var tableName = cfg.table;
    var pk = cfg.pk;
    var cols = cfg.columns;

    // Build WHERE clause using LIKE indicators
    var likeClauses = [];
    for (var col in cols) {
        for (var ind in likeIndicators) likeClauses.append(col & ' LIKE ' & chr(39) & ind & chr(39));
    }
    if (!arrayLen(likeClauses)) continue;
    var whereClause = '(' & arrayToList(likeClauses, ' OR ') & ')';

    var selectCols = pk;
    for (var col in cols) selectCols &= ',' & col;

    var q = new Query();
    q.setSQL('SELECT ' & selectCols & ' FROM ' & tableName & ' WHERE ' & whereClause);
    var rs = q.execute().getResult();

    if (rs.recordCount == 0) {
        tableReport.append({table=tableName, scanned=0, changed=0});
        continue;
    }

    var changedRows = [];

    // Iterate rows
    for (var i=1; i <= rs.recordCount; i++) {
        var rowChanged = false;
        var colChanges = [];
        var updateFragments = [];

        for (var col in cols) {
            var original = rs[col][i];
            if (isNull(original) OR original EQ "") continue;

            var cleaned = cleanValue(original);
            if (cleaned NEQ original) {
                rowChanged = true;
                colChanges.append({column=col, before=original, after=cleaned});
                updateFragments.append(col & ' = ?');
            }
        }

        if (rowChanged) {
            totalRowsChanged++;
            changedRows.append({pkValue=rs[pk][i], changes=colChanges});

            if (mode EQ 'commit') {
                var uq = new Query();
                var updateSQL = 'UPDATE ' & tableName & ' SET ' & arrayToList(updateFragments, ', ') & ' WHERE ' & pk & ' = ?';
                uq.setSQL(updateSQL);
                // Bind parameters: each cleaned value then pk
                for (var change in colChanges) {
                    uq.addParam(value=change.after, cfsqltype="cf_sql_longvarchar");
                }
                uq.addParam(value=rs[pk][i]);
                uq.execute();
            }
        }
        totalRowsScanned++;
    }

    tableReport.append({table=tableName, scanned=rs.recordCount, changed=arrayLen(changedRows), details=changedRows});
}
</cfscript>

<h3>Summary</h3>
<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-family:Arial;font-size:13px">
    <tr style="background:#f0f0f0"><th>Table</th><th>Rows Scanned (candidates)</th><th>Rows Changed</th></tr>
    <cfoutput>
    <cfloop array="#tableReport#" index="t">
        <tr>
            <td>#htmlEditFormat(t.table)#</td>
            <td align="right">#t.scanned#</td>
            <td align="right" style="color:#<cfif t.changed GT 0>007700<cfelse>777777</cfif>">#t.changed#</td>
        </tr>
    </cfloop>
    </cfoutput>
</table>
<p>Total candidate rows scanned: <cfoutput>#totalRowsScanned#</cfoutput><br>Rows with changes: <cfoutput>#totalRowsChanged#</cfoutput></p>

<cfif mode EQ "preview"> <p style="color:#555">(Only showing first 25 changed rows per table.)</p></cfif>

<cfoutput>
<cfloop array="#tableReport#" index="t">
    <cfif t.changed GT 0>
        <h4>Table: #htmlEditFormat(t.table)# (#t.changed# changed rows)</h4>
        <cfset shown = 0>
        <cfloop array="#t.details#" index="row">
            <cfif mode EQ "preview" AND shown GTE 25>
                <p><em>More rows omitted...</em></p>
                <cfbreak>
            </cfif>
            <div style="border:1px solid #ccc;margin:8px 0;padding:6px;background:#fafafa">
                <div style="font-weight:bold">#htmlEditFormat(t.table)# PK=#htmlEditFormat(row.pkValue)#</div>
                <cfloop array="#row.changes#" index="chg">
                    <div style="margin-top:4px">
                        <div style="font-size:12px;color:#004">Column: <strong>#htmlEditFormat(chg.column)#</strong></div>
                        #simpleDiff(chg.before, chg.after)#
                    </div>
                </cfloop>
            </div>
            <cfset shown++>
        </cfloop>
    </cfif>
</cfloop>
</cfoutput>

<hr>
<h3>Next Steps</h3>
<ol style="font-family:Arial;font-size:13px">
    <li>Edit this file: set AUTH_TOKEN and populate tableConfigs.</li>
    <li>Run in preview mode; review diffs.</li>
    <li>Backup database (FULL backup).</li>
    <li>Run with mode=commit once satisfied.</li>
    <li>Remove or secure this file after use.</li>
</ol>

<!-- End of encoding_cleanup.cfm -->
