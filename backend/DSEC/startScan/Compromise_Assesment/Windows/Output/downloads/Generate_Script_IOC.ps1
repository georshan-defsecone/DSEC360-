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
    @{"Name"="Windows Events"; "Command"={ # --- Combined Windows Event Checks ---

$windowsResults = [ordered]@{}

# 1. User_Account_Creations
$StartTime = (Get-Date).AddDays(-7)
$userEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Security';
    Id = 4720;
    StartTime = $StartTime
} | ForEach-Object {
    $msg = $_.Message
    $created = if ($msg -match "New Account:\r?\n\s*Security ID:\s*.+?\r?\n\s*Account Name:\s*([^\r\n]+)") {
        $matches[1].Trim()
    } else { "N/A" }
    $creator = if ($msg -match "Subject:\r?\n\s*Security ID:.*\r?\n\s*Account Name:\s*([^\r\n]+)") {
        $matches[1].Trim()
    } else { "N/A" }
    [PSCustomObject]@{
        Time           = $_.TimeCreated
        EventID        = $_.Id
        CreatedAccount = $created
        CreatorAccount = $creator
    }
}
$windowsResults["User_Account_Creations"] = $userEvents


# 2. File_Creation_Deletion_Events
$fileEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Security';
    Id = 4663;
    StartTime = $StartTime
} | Where-Object { $_.Message -match 'Accesses:\s+.*(WriteData|Delete)' } |
ForEach-Object {
    $object = if ($_.Message -match "Object Name:\s+(.+?)\r") { $matches[1] } else { "N/A" }
    $access = if ($_.Message -match "Accesses:\s+(.+?)\r") { $matches[1] } else { "N/A" }
    [PSCustomObject]@{
        Time    = $_.TimeCreated
        EventID = $_.Id
        Object  = $object
        Access  = $access
    }
}
$windowsResults["File_Creation_Deletion_Events"] = $fileEvents


# 3. BAT_File_Creation
$batEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Security';
    Id = 4663;
    StartTime = $StartTime
} | Where-Object { $_.Message -match '\.bat' -and $_.Message -match 'WriteData' } |
ForEach-Object {
    $object = if ($_.Message -match "Object Name:\s+(.+?\.bat.*?)\r") { $matches[1] } else { "N/A" }
    $access = if ($_.Message -match "Accesses:\s+(.+?)\r") { $matches[1] } else { "N/A" }
    [PSCustomObject]@{
        Time    = $_.TimeCreated
        EventID = $_.Id
        Object  = $object
        Access  = $access
    }
}
$windowsResults["BAT_File_Creation"] = $batEvents


# 4. Failed_Logon_Attempts
$logonFailEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Security';
    Id = 4625;
    StartTime = $StartTime
} | ForEach-Object {
    $msg = $_.Message
    $accountName = if ($msg -match "Account Name:\s+([^\r\n]+)") { $matches[1].Trim() } else { "N/A" }
    $ipAddress   = if ($msg -match "Source Network Address:\s+([^\r\n]+)") { $matches[1].Trim() } else { "N/A" }
    $logonType   = if ($msg -match "Logon Type:\s+(\d+)") { $matches[1] } else { "N/A" }
    $failure     = if ($msg -match "Failure Reason:\s+([^\r\n]+)") { $matches[1].Trim() } else { "N/A" }
    [PSCustomObject]@{
        Time          = $_.TimeCreated
        EventID       = $_.Id
        Account       = $accountName
        IPAddress     = $ipAddress
        LogonType     = $logonType
        FailureReason = $failure
    }
}
$windowsResults["Failed_Logon_Attempts"] = $logonFailEvents


# 5. After_Hours_Logons
$today = [datetime]::Today
$afterHours = $today.AddHours(18)  # 6 PM
$afterHourEvents = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4624
    StartTime = $today
} | ForEach-Object {
    $event = [xml]$_.ToXml()
    $logonTime = $_.TimeCreated
    $user = $event.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" }
    if ($logonTime -gt $afterHours -and $user.'#text' -ne 'ANONYMOUS LOGON') {
        [PSCustomObject]@{
            TimeCreated = $logonTime
            UserName    = $user.'#text'
        }
    }
}
$windowsResults["After_Hours_Logons"] = $afterHourEvents


# 6. Suspicious_Open_Ports
$startHour = 9
$endHour = 18
$currentHour = (Get-Date).Hour
$ports = @{
    "RDP" = 3389
    "SSH" = 22
    "FTP" = 21
}
function Test-Port {
    param ([int]$port)
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect("localhost", $port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne(2000, $false)
        if ($wait -and $tcpClient.Connected) {
            $tcpClient.Close()
            return $true
        }
    } catch {
        return $false
    }
    return $false
}
$openPorts = @()
if ($currentHour -lt $startHour -or $currentHour -ge $endHour) {
    foreach ($service in $ports.Keys) {
        $port = $ports[$service]
        if (Test-Port -port $port) {
            $openPorts += [PSCustomObject]@{
                Service = $service
                Port    = $port
                Status  = "OPEN"
            }
        }
    }
}
$windowsResults["Suspicious_Open_Ports"] = $openPorts

# Return all grouped results
$windowsResults } }

)

foreach ($check in $selectedChecks) {
    Run_Check -Name $check.Name -Command $check.Command
}

# Export Results to JSON
$outputPath = "IOCoutput.json"
$results | ConvertTo-Json -Depth 5 | Out-File $outputPath -Encoding UTF8

Write-Host "`nAll checks completed. Results saved to: $outputPath"
