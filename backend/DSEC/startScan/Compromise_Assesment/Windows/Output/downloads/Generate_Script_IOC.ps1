# PowerShell IOC Scan Script
$results = @{}

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
    @{"Name"="Download Directory"; "Command"={ $resultsList = @()
$downloadPath = "$env:USERPROFILE\Downloads"
$extensions = @("*.exe", "*.msi")

foreach ($ext in $extensions) {
    Get-ChildItem -Path $downloadPath -Filter $ext -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $file = $_.FullName
        $sig = Get-AuthenticodeSignature -FilePath $file
        $isNotMicrosoft = ($sig.SignerCertificate -and $sig.SignerCertificate.Subject -notlike "*Microsoft*")

        if ($isNotMicrosoft -or $sig.Status -ne "Valid") {
            $hash = Get-FileHash -Path $file -Algorithm SHA256
            $resultsList += [PSCustomObject]@{
                FileName        = $file
                Extension       = $_.Extension
                SignatureStatus = $sig.Status
                Signer          = $sig.SignerCertificate.Subject
                Issuer          = $sig.SignerCertificate.Issuer
                SHA256Hash      = $hash.Hash
            }
        }
    }
}

$resultsList } }
    @{"Name"="Current Running Process Signed"; "Command"={ # --- Running_Processes_NonMicrosoft (unique paths, SHA‑256, exclude Microsoft) ---
$procList = @()
$seenPath = @{}   # hashtable for de‑duplication

Get-Process | ForEach-Object {
    $p    = $_
    $path = $null

    # 1️⃣ Direct Path (available in PS 3+)
    try { $path = $p.Path } catch { }

    # 2️⃣ Fallback via CIM/WMI if Path still null (works on PS 2.0+)
    if (-not $path) {
        try {
            $wmi  = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue
            $path = $wmi.ExecutablePath
        } catch { }
    }

    # Build key for de‑duplication
    $key = if ($path) { $path.ToLower() } else { "$($p.ProcessName)_$($p.Id)" }
    if ($seenPath.ContainsKey($key)) { return }   # already processed
    $seenPath[$key] = $true

    # Pull version info (if we have a path) to get Company & Description
    $company     = $null
    $description = $null
    $sha256      = $null

    if ($path) {
        try {
            $ver         = (Get-Item $path).VersionInfo
            $company     = $ver.CompanyName
            $description = $ver.FileDescription
        } catch { }
    }

    # Skip anything signed by Microsoft
    if ($company -and $company -like "*Microsoft*") { return }

    # Hash the file (optional but useful)
    if ($path) {
        try { $sha256 = (Get-FileHash -Path $path -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash } catch { }
    }

    $procList += New-Object psobject -Property @{
        Name        = $p.ProcessName
        PID         = $p.Id
        Path        = $path
        Company     = $company
        Description = $description
        SHA256Hash  = $sha256
    }
}

# Return array; Run_Check wrapper stores it in $results["Running_Processes_NonMicrosoft"]
$procList } }

)

foreach ($check in $selectedChecks) {
    Run_Check -Name $check.Name -Command $check.Command
}

# Export Results to JSON
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = "results_$timestamp.json"
$results | ConvertTo-Json -Depth 3 | Out-File $outputPath -Encoding UTF8

Write-Host "`nAll checks completed. Results saved to: $outputPath"
