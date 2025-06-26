import csv
import os

def generate_script(input_csv_path, output_script_path, output_json_path, excluded_queries):
    ps_entries = []

    with open(input_csv_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        for row in reader:
            method = row['query_method'].strip().strip('"').lower()
            audit_name = row['audit_name'].strip().strip('"')
            path = row['reg_query_path'].strip().strip('"') if row['reg_query_path'] else ""
            name = row['reg_query_name'].strip().strip('"') if row['reg_query_name'] else ""

            if audit_name in excluded_queries:
                continue


            if "[USER SID]" in path:
                path = path.replace("[USER SID]", "$currentUserSid")

            if method == "registry":
                command = f'Get-RegistryValueWithFallback -Path "{path}" -Name "{name}"'
            elif method == "local_group_policy":
                command = f'Get-LocalPolicyEntry -SettingName "{name}"'
            elif method == "auditpol":
                command = f'Get-AuditPolicySetting -Subcategory "{name}"'
            else:
                command = f'Write-Output "Unsupported query_method: {method}"'

            escaped_command = command.replace('"', '`"')
            escaped_audit_name = audit_name.replace('"', '`"')

            ps_entries.append(f"""@{{ 
    audit_name = "{escaped_audit_name}"
    command = "{escaped_command}"
}}""")

    ps_array = "\n".join(ps_entries)

    # PowerShell function definitions (unchanged)
    ps_functions = r"""
function Get-RegistryValueWithFallback {
    param (
        [string]$Path,
        [string]$Name
    )
    $queryResult = @{}
    try {
        $regItem = Get-ItemProperty -Path $Path -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($Name)) {
            $allProps = $regItem.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
            foreach ($prop in $allProps) {
                $queryResult[$prop.Name] = $prop.Value
            }
        } else {
            $valueNames = $Name -split ',' | ForEach-Object { $_.Trim() }
            foreach ($vName in $valueNames) {
                $prop = $regItem.PSObject.Properties[$vName]
                if ($prop) {
                    $queryResult[$vName] = $prop.Value
                } else {
                    $queryResult[$vName] = "Key Found, Value Not Present"
                }
            }
        }
    } catch {
        try {
            $null = Get-Item -Path $Path -ErrorAction Stop
            $valueNames = $Name -split ',' | ForEach-Object { $_.Trim() }
            foreach ($vName in $valueNames) {
                if ($vName) {
                    $queryResult[$vName] = "Key Found, Value Not Present"
                }
            }
        } catch {
            $valueNames = $Name -split ',' | ForEach-Object { $_.Trim() }
            foreach ($vName in $valueNames) {
                if ($vName) {
                    $queryResult[$vName] = "Registry Key Not Found"
                }
            }
            if (-not $Name) {
                $queryResult["RegistryKey"] = "Registry Key Not Found"
            }
        }
    }
    return $queryResult
}


function Get-LocalPolicyEntry {
    param (
        [string]$SettingName
    )
    $queryResult = @{ }
        if (-not (Test-Path $seceditExportPath)) {
        $queryResult["Error"] = "secpol.cfg does not exist"
        return $queryResult
    }
    try {
        $policyContent = Get-Content $seceditExportPath
        $line = $policyContent | Where-Object { $_ -match "^\s*$SettingName\s*=" }

        if ($line) {
            $sidRaw   = ($line -split "=")[1].Trim().Trim('"')
            $sidParts = $sidRaw -split ","

            $resolvedNames = $sidParts | ForEach-Object {
                $entry = $_.Trim()
                if ($entry -like "*S-1-*") {
                    try {
                        $sidObj = New-Object System.Security.Principal.SecurityIdentifier ($entry.TrimStart('*'))
                        $sidObj.Translate([System.Security.Principal.NTAccount]).Value
                    } catch {
                        $entry
                    }
                } else {
                    try {
                        (New-Object System.Security.Principal.NTAccount($entry)).Translate([System.Security.Principal.NTAccount]).Value
                    } catch {
                        $entry
                    }
                }
            }

            $resolvedNames = $resolvedNames | ForEach-Object {
                ($_ -replace '^(NT AUTHORITY|BUILTIN|RESTRICTED SERVICES|NT SERVICE)\\', '').Trim()
            }

            $queryResult[$SettingName] = ($resolvedNames -join ", ")
        } else {
            $queryResult[$SettingName] = "Not Applicable"
        }
    } catch {
        $queryResult[$SettingName] = "Secedit Parsing Failed"
    }
    return $queryResult
}

function Get-AuditPolicySetting {
    param (
        [string]$Subcategory
    )
    $queryResult = @{}
    try {
        $fullCommand = "auditpol /get /subcategory:`"$Subcategory`""
        $auditOutput = Invoke-Expression $fullCommand 2>$null

        if ($LASTEXITCODE -ne 0 -or !$auditOutput) {
            $queryResult[$Subcategory] = "Auditpol Query Failed"
        } else {
            $value = "Unknown"
            foreach ($line in $auditOutput) {
                if ($line -match "^\s*$Subcategory\s+(.+)$") {
                    $value = $matches[1].Trim()
                    break
                }
            }
            $queryResult[$Subcategory] = $value
        }
    } catch {
        $queryResult[$Subcategory] = "Auditpol Command Failed"
    }
    return $queryResult
}
"""

    # PowerShell script body
    ps_script = f"""\

# Auto-generated PowerShell script

$outputJsonPath = "{os.path.basename(output_json_path)}"
$seceditExportPath = "C:\\\\secpol.cfg"
$currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

# Export Local Security Policy
secedit /export /cfg $seceditExportPath | Out-Null

{ps_functions}

$queries = @(
{ps_array}
)

$results = @()

foreach ($item in $queries) {{
    try {{
        $queryResult = Invoke-Expression $item.command
    }} catch {{
        $queryResult = @{{ "Error" = $_.Exception.Message }}
    }}
    $results += [PSCustomObject]@{{
        audit_name = $item.audit_name
        command    = $item.command
        result     = $queryResult
    }}
}}

# Convert results to JSON and save to file
$json = $results | ConvertTo-Json -Depth 5
$json = $json -replace '\\u0027', "'"

$outputFullPath = [System.IO.Path]::GetFullPath("{output_json_path}")
[System.IO.File]::WriteAllText($outputFullPath, $json, [System.Text.Encoding]::UTF8)

Write-Host "Output successfully written to: $outputFullPath"
"""

    os.makedirs(os.path.dirname(output_script_path), exist_ok=True)
    with open(output_script_path, "w", encoding="utf-8") as f:
        f.write(ps_script)

    print(f"PowerShell script written to: {output_script_path}")