# Final fix for the Python syntax error with correct finally block positioning
$inputFile = "u:\DOCKETWATCH\python\docketwatch_case_events.py"
$outputFile = "u:\DOCKETWATCH\python\docketwatch_case_events_fixed.py"

# Read all lines
$lines = Get-Content $inputFile

$output = @()

for ($i = 0; $i -lt $lines.Length; $i++) {
    $lineNum = $i + 1
    $line = $lines[$i]
    
    if ($lineNum -le 56) {
        # Copy lines 1-56 as-is (imports, setup, log_message function)
        $output += $line
    }
    elseif ($lineNum -eq 57) {
        # Add comment
        $output += $line
    }
    elseif ($lineNum -eq 58) {
        # Add function definition BEFORE try block
        $output += ""
        $output += "# Fetch CAPTCHA API Key"
        $output += "def get_captcha_api():"
        $output += "    cursor.execute(`"SELECT captcha_api FROM [docketwatch].[dbo].[utilities] WHERE id = 1`")"
        $output += "    api_key = cursor.fetchone()"
        $output += "    return api_key[0] if api_key else None"
        $output += ""
        $output += "# Wrap the entire script in error handling"
        $output += "try:"
    }
    elseif ($lineNum -eq 59) {
        # Convert to indented version
        $output += "    log_message(`"INFO`", `"=== CAPTCHA Bypass Script Started ===`")"
        $output += ""
    }
    elseif ($lineNum -in @(61,62,63,64,65)) {
        # Skip the function definition lines (already moved above)
        continue
    }
    elseif ($lineNum -eq 67) {
        # Add proper indentation for API_KEY assignment
        $output += "    API_KEY = get_captcha_api()"
    }
    elseif ($lineNum -ge 68 -and $lineNum -le 262) {
        # All content inside try block needs indentation (up to line 262)
        if ($line -match "^[^ ]" -and $line.Trim() -ne "") {
            # Line starts at beginning, add 4 spaces
            $output += "    " + $line
        }
        elseif ($line.Trim() -eq "") {
            # Empty line
            $output += $line
        }
        else {
            # Already indented, add 4 more spaces
            $output += "    " + $line
        }
    }
    elseif ($lineNum -eq 263) {
        # Empty line before finally
        $output += ""
    }
    else {
        # Lines 264+ (finally, except blocks) - keep as-is (no extra indentation)
        $output += $line
    }
}

# Write the fixed file
$output | Set-Content $outputFile

Write-Host "Final fix created: $outputFile"
Write-Host "Function moved outside try block, try content indented, finally/except at correct level"