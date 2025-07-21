# PowerShell IOC Scan Script
$results = [ordered]@{ }

function Run_Check {
    param (
        [string]$Name,
        [scriptblock]$Command
    )

    Write-Host "Running $Name..."
    try {
        $output = & $Command  
        $results[$Name] = $output
    } catch {
        $results[$Name] = "Error: $($_.Exception.Message)"
    }
}

# Execute Selected IOC Checks
$selectedChecks = @(
    @{"Name"="List All User Accounts"; "Command"={ # --- Local_User_Privileges_Info (Local users with privileges) ---

$userList = @()

# Get all local user accounts
$allUsers = Get-LocalUser

# Get members of the local Administrators group
$adminGroup = Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.ObjectClass -eq 'User' }

foreach ($user in $allUsers) {
    $privileges = @()

    # Local or domain
    if (-not ($user.Name -like "*\*")) {
        $privileges += "Local User"
    } else {
        $privileges += "Domain User"
    }

    # Is Admin
    if ($adminGroup.Name -contains $user.Name) {
        $privileges += "Administrator"
    }

    # Enabled or Disabled
    if ($user.Enabled) {
        $privileges += "Enabled"
    } else {
        $privileges += "Disabled"
    }

    # Password policies
    if ($user.PasswordNeverExpires) {
        $privileges += "Password Never Expires"
    }

    if ($user.UserMayNotChangePassword) {
        $privileges += "User Cannot Change Password"
    }

    $userList += [PSCustomObject]@{
        Username    = $user.Name
        FullName    = $user.FullName
        Description = $user.Description
        Privileges  = ($privileges -join ", ")
    }
}

# Return array; Run_Check wrapper stores it in $results["Local_User_Privileges_Info"]
$userList } }
    @{"Name"="Configuration Files"; "Command"={ # --- Inetpub_Config_Files_Info (Lists all config files under inetpub with permissions and hash) ---

$configFiles = @()

# Define root directory
$inetpubPath = "C:\inetpub"

# Define target file types
$filePatterns = @("*.config", "*.ini", "*.xml", "*.exe")  # Add more if needed

# Recursively search for files
foreach ($pattern in $filePatterns) {
    try {
        $foundFiles = Get-ChildItem -Path $inetpubPath -Recurse -Filter $pattern -ErrorAction SilentlyContinue
        foreach ($file in $foundFiles) {
            try {
                # Get ACL
                $acl = Get-Acl -Path $file.FullName
                $permissions = ($acl.Access | ForEach-Object {
                    "$($_.IdentityReference): $($_.FileSystemRights) ($($_.AccessControlType))"
                }) -join "; "
            } catch {
                $permissions = "Error retrieving permissions: $($_.Exception.Message)"
            }

            # Compute file hash
            try {
                $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
                $hashValue = $hash.Hash
            } catch {
                $hashValue = "Error computing hash: $($_.Exception.Message)"
            }

            $configFiles += [PSCustomObject]@{
                FileName     = $file.Name
                FilePath     = $file.FullName
                Extension    = $file.Extension
                Permissions  = $permissions
                HashSHA256   = $hashValue
            }
        }
    } catch {
        Write-Warning "Error searching for pattern '$pattern': $($_.Exception.Message)"
    }
}

# Return array; Run_Check wrapper stores it in $results["Inetpub_Config_Files_Info"]
$configFiles } }
    @{"Name"="PowerShell History"; "Command"={ # --- Powershell_Dangerous_Commands_History_Info ---
$dangerousCommands = @(
    'Remove-Item',
    'Format-Volume',
    'Clear-EventLog',
    'Add-MpPreference',
    'Set-ExecutionPolicy',
    'Invoke-WebRequest',
    'Start-Process',
    'Invoke-Expression',
    'New-LocalUser',
    'Add-LocalGroupMember',
    'schtasks',
    'Set-ItemProperty',
    'Invoke-Mimikatz',
    'DownloadString',
    'Stop-Computer',
    'Disable-ComputerRestore',
    'IEX',
    'Get-Credential',
    'Get-WmiObject',
    'Enter-PSSession',
    'Invoke-Command',
    'net use',
    'Unprotect'
)

$results = @()

$allUsers = Get-LocalUser

foreach ($user in $allUsers) {
    $username = $user.Name
    $profilePath = "C:\Users\$username"
    $historyPath = "$profilePath\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

    if (Test-Path $historyPath) {
        $lines = Get-Content $historyPath
        $lineNumber = 1

        foreach ($line in $lines) {
            $lineTrim = $line.Trim()

            foreach ($cmd in $dangerousCommands) {
                if ($lineTrim -match ("(?i)\b" + [regex]::Escape($cmd) + "\b")) {
                    # Add structured result for pipeline
                    $results += [PSCustomObject]@{
                        Username      = $username
                        LineNumber    = $lineNumber
                        Command        = $lineTrim
                        MatchedKeyword = $cmd
                    }
                    break  # avoid duplicate matches for one line
                }
            }

            $lineNumber++
        }
    }
}

# Return array; Run_Check wrapper stores it in $results["Powershell_Dangerous_Commands_History_Info"]
$results } }

)

foreach ($check in $selectedChecks) {
    Run_Check -Name $check.Name -Command $check.Command
}

# Export Results to JSON
$outputPath = "IOCoutput.json"
$results | ConvertTo-Json -Depth 5 | Out-File $outputPath -Encoding UTF8

Write-Host "`nAll checks completed. Results saved to: $outputPath"
