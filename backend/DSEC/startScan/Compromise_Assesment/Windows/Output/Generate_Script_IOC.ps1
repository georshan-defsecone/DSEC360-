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
    @{"Name"="Current Running Process Signed"; "Command"={ # --- Running_Processes_NonMicrosoft (unique paths, SHA‑256, exclude Microsoft) ---
$procList = @()
$seenPath = @{}   # hashtable for de‑duplication

Get-Process | ForEach-Object {
    $p    = $_
    $path = $null

    # Direct Path (available in PS 3+)
    try { $path = $p.Path } catch { }

    # Fallback via CIM/WMI if Path still null (works on PS 2.0+)
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

    # 🚫 Skip if everything is null
    if (-not $path -and -not $company -and -not $sha256 -and -not $description) { return }

    $procList += New-Object psobject -Property @{
        Name        = $p.ProcessName
        PID         = $p.Id
        Path        = $path
        Company     = $company
        Description = $description
        Hash        = $sha256
    }
}

# Return array; Run_Check wrapper stores it in $results["Running_Processes_NonMicrosoft"]
$procList } }
    @{"Name"="Current Running Service Signed"; "Command"={ $services = Get-CimInstance -ClassName Win32_Service | ForEach-Object {
    $serviceName = $_.Name
    $displayName = $_.DisplayName
    $state       = $_.State
    $rawPath     = ($_.PathName -replace '"', '') -replace '^(.*?\.exe).*$', '$1'

    if ($rawPath -like "*svchost.exe") {
        $regPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$serviceName\Parameters"
        $serviceDll = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).ServiceDll

        if ($serviceDll -and (Test-Path $serviceDll)) {
            try {
                $hash = Get-FileHash -Path $serviceDll -Algorithm SHA256
                [PSCustomObject]@{
                    Name        = $serviceName
                    DisplayName = $displayName
                    State       = $state
                    FileType    = "Service DLL (svchost)"
                    PathName    = $serviceDll
                    Hash        = $hash.Hash
                }
            } catch {
                [PSCustomObject]@{
                    Name        = $serviceName
                    DisplayName = $displayName
                    State       = $state
                    FileType    = "Service DLL (svchost)"
                    PathName    = $serviceDll
                    Hash        = "Error: $($_.Exception.Message)"
                }
            }
        } else {
            [PSCustomObject]@{
                Name        = $serviceName
                DisplayName = $displayName
                State       = $state
                FileType    = "svchost (ServiceDll not found)"
                PathName    = "ServiceDll not found"
                Hash        = "N/A"
            }
        }
    } elseif (Test-Path $rawPath) {
        try {
            $hash = Get-FileHash -Path $rawPath -Algorithm SHA256
            [PSCustomObject]@{
                Name        = $serviceName
                DisplayName = $displayName
                State       = $state
                FileType    = "Executable"
                PathName    = $rawPath
                Hash        = $hash.Hash
            }
        } catch {
            [PSCustomObject]@{
                Name        = $serviceName
                DisplayName = $displayName
                State       = $state
                FileType    = "Executable"
                PathName    = $rawPath
                Hash        = "Error: $($_.Exception.Message)"
            }
        }
    } else {
        [PSCustomObject]@{
            Name        = $serviceName
            DisplayName = $displayName
            State       = $state
            FileType    = "File Not Found"
            PathName    = $rawPath
            Hash        = "File Not Found"
        }
    }
}

# Return the results to the wrapper function
$services } }
    @{"Name"="Check the service Everyone Permission"; "Command"={ # Function to check Everyone write permissions
function Check-EveryoneWritePermission {
    param ($filePath)
    try {
        $acl = Get-Acl -Path $filePath
        $everyoneAccess = $acl.Access | Where-Object { $_.IdentityReference -match 'Everyone' }
        foreach ($entry in $everyoneAccess) {
            if ($entry.FileSystemRights -match "Write" -or $entry.FileSystemRights -match "FullControl") {
                return "Yes"
            }
        }
        return "No"
    } catch {
        return "Error: $($_.Exception.Message)"
    }
}

if ($null -ne $PreCollectedServicesHash) {
    # Use pre-collected results, only check permissions
    $services = $PreCollectedServicesHash | ForEach-Object {
        $serviceName = $_.Name
        $displayName = $_.DisplayName
        $state       = $_.State
        $fileType    = $_.FileType
        $pathName    = $_.PathName
        $hash        = $_.Hash

        $everyoneWrite = if (Test-Path $pathName -and $fileType -ne "File Not Found") {
            Check-EveryoneWritePermission -filePath $pathName
        } else {
            "File Not Found"
        }

        [PSCustomObject]@{
            Name                = $serviceName
            DisplayName         = $displayName
            State               = $state
            FileType            = $fileType
            PathName            = $pathName
            Hash                = $hash
            EveryoneWriteAccess = $everyoneWrite
        }
    }
} else {
    # Full scan if no pre-collected results
    if ($null -eq $PreCollectedServices) {
        $PreCollectedServices = Get-CimInstance -ClassName Win32_Service
    }

    $services = $PreCollectedServices | ForEach-Object {
        $serviceName = $_.Name
        $displayName = $_.DisplayName
        $state       = $_.State
        $rawPath     = ($_.PathName -replace '"', '') -replace '^(.*?\.exe).*$', '$1'

        if ($rawPath -like "*svchost.exe*") {
            $regPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$serviceName\Parameters"
            $serviceDll = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).ServiceDll

            if ($serviceDll -and (Test-Path $serviceDll)) {
                try {
                    $hash = Get-FileHash -Path $serviceDll -Algorithm SHA256
                    $everyoneWrite = Check-EveryoneWritePermission -filePath $serviceDll
                    [PSCustomObject]@{
                        Name                = $serviceName
                        DisplayName         = $displayName
                        State               = $state
                        FileType            = "Service DLL (svchost)"
                        PathName            = $serviceDll
                        Hash                = $hash.Hash
                        EveryoneWriteAccess = $everyoneWrite
                    }
                } catch {
                    [PSCustomObject]@{
                        Name                = $serviceName
                        DisplayName         = $displayName
                        State               = $state
                        FileType            = "Service DLL (svchost)"
                        PathName            = $serviceDll
                        Hash                = "Error: $($_.Exception.Message)"
                        EveryoneWriteAccess = "Error"
                    }
                }
            } else {
                [PSCustomObject]@{
                    Name                = $serviceName
                    DisplayName         = $displayName
                    State               = $state
                    FileType            = "svchost (ServiceDll not found)"
                    PathName            = "ServiceDll not found"
                    Hash                = "N/A"
                    EveryoneWriteAccess = "N/A"
                }
            }
        } elseif (Test-Path $rawPath) {
            try {
                $hash = Get-FileHash -Path $rawPath -Algorithm SHA256
                $everyoneWrite = Check-EveryoneWritePermission -filePath $rawPath
                [PSCustomObject]@{
                    Name                = $serviceName
                    DisplayName         = $displayName
                    State               = $state
                    FileType            = "Executable"
                    PathName            = $rawPath
                    Hash                = $hash.Hash
                    EveryoneWriteAccess = $everyoneWrite
                }
            } catch {
                [PSCustomObject]@{
                    Name                = $serviceName
                    DisplayName         = $displayName
                    State               = $state
                    FileType            = "Executable"
                    PathName            = $rawPath
                    Hash                = "Error: $($_.Exception.Message)"
                    EveryoneWriteAccess = "Error"
                }
            }
        } else {
            [PSCustomObject]@{
                Name                = $serviceName
                DisplayName         = $displayName
                State               = $state
                FileType            = "File Not Found"
                PathName            = $rawPath
                Hash                = "File Not Found"
                EveryoneWriteAccess = "File Not Found"
            }
        }
    }
}

# Return the results
$services } }
    @{"Name"="Suspicious Directory"; "Command"={ $fullResultsList = @()
$extensions = @("*.exe", "*.msi")

# Get all user profiles
$userProfiles = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue

# Build list of all Downloads directories and Temp directories
$userDownloadsDirs = @()
$userTempDirs = @()

foreach ($profile in $userProfiles) {
    $userDownloads = "C:\Users\$($profile.Name)\Downloads"
    if (Test-Path $userDownloads) { $userDownloadsDirs += $userDownloads }

    $userTemp = "C:\Users\$($profile.Name)\AppData\Local\Temp"
    if (Test-Path $userTemp) { $userTempDirs += $userTemp }
}
# Add Public Downloads directory
$publicDownloadsDir = "C:\Users\Public\Downloads"
if (Test-Path $publicDownloadsDir) { $userDownloadsDirs += $publicDownloadsDir }
$windowsTempDir = "C:\Windows\Temp"

# Combine all directories to search
$directories = @() + $userDownloadsDirs + $userTempDirs + $windowsTempDir

# Search each directory for specified file types
foreach ($dir in $directories) {
    foreach ($ext in $extensions) {
        Get-ChildItem -Path $dir -Filter $ext -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $file = $_.FullName
            $sig = Get-AuthenticodeSignature -FilePath $file
            $isNotMicrosoft = ($sig.SignerCertificate -and $sig.SignerCertificate.Subject -notlike "*Microsoft*")

            if ($isNotMicrosoft -or $sig.Status -ne "Valid") {
                $hash = Get-FileHash -Path $file -Algorithm SHA256
                $fullResultsList += [PSCustomObject]@{
                    Name            = $file
                    Extension       = $_.Extension
                    SignatureStatus = $sig.Status
                    Signer          = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { "Unsigned" }
                    Issuer          = if ($sig.SignerCertificate) { $sig.SignerCertificate.Issuer } else { "Unknown" }
                    Hash            = $hash.Hash
                    SourceDirectory = $dir
                }
            }
        }
    }
}

# Return the results
$fullResultsList } }
    @{"Name"="Visual Basic for Applications"; "Command"={ # --- Office Macro Security Settings for Excel, Word, PowerPoint, Access ---

$OfficeApplications = @("Excel", "Word", "PowerPoint", "Access")
$OfficeVersions = @(
    "16.0", # Office 2016, 2019, 2021, Microsoft 365
    "15.0", # Office 2013
    "14.0"  # Office 2010
)

$results = @()

foreach ($OfficeApplication in $OfficeApplications) {
    foreach ($version in $OfficeVersions) {
        $registryPath = "HKCU:\Software\Microsoft\Office\$version\$OfficeApplication\Security"
        
        if (Test-Path $registryPath) {
            $vbaWarningsValue = Get-ItemProperty -Path $registryPath -Name "VBAWarnings" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty VBAWarnings

            $settingDescription = switch ($vbaWarningsValue) {
                1 { "Enable all macros (not recommended)" }
                2 { "Disable all macros except digitally signed macros" }
                3 { "Disable all macros with notification (Default)" }
                4 { "Disable all macros without notification" }
                default { "Unknown or not set" }
            }

            $results += [PSCustomObject]@{
                Application = $OfficeApplication
                OfficeVersion = $version
                RegistryPath = $registryPath
                VBAWarningsValue = $vbaWarningsValue
                SettingDescription = $settingDescription
            }
        }
    }
}

$results } }
    @{"Name"="Startup files"; "Command"={ # --- Startup Files with Hashes ---
$startupKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
)

$startupList = @()

foreach ($key in $startupKeys) {
    try {
        $entries = Get-ItemProperty -Path $key
        foreach ($entry in $entries.PSObject.Properties) {
            if ($entry.Name -like "PS*") { continue }

            $command = $entry.Value

            if ($command -match '"([^"]+)"') {
                $exePath = $matches[1]
            } else {
                $exePath = $command.Split(" ")[0]
            }

            if (Test-Path $exePath) {
                try {
                    $hash = Get-FileHash -Path $exePath -Algorithm SHA256
                    $startupList += [PSCustomObject]@{
                        EntryName = $entry.Name
                        Path      = $exePath
                        Hash      = $hash.Hash
                    }
                } catch {
                    $startupList += [PSCustomObject]@{
                        EntryName = $entry.Name
                        Path      = $exePath
                        Hash      = 'Hash Error'
                    }
                }
            } else {
                $startupList += [PSCustomObject]@{
                    EntryName = $entry.Name
                    Path      = $exePath
                    Hash      = 'File Not Found'
                }
            }
        }
    } catch {
        Write-Warning "Error reading registry key: $key"
    }
}

$startupList } }
    @{"Name"="Living off the Land"; "Command"={ # --- Living off the Land Binaries (LOLBins) Detection (Excluding Temp Directories) ---

# Get all user profiles
$userProfiles = Get-ChildItem -Path 'C:\Users' -Directory -ErrorAction SilentlyContinue

# Build list of all Downloads directories
$userDownloadsDirs = @()

foreach ($profile in $userProfiles) {
    $userDownloads = "C:\Users\$($profile.Name)\Downloads"
    if (Test-Path $userDownloads) { $userDownloadsDirs += $userDownloads }
}

# Add Public Downloads directory if it exists
$publicDownloadsDir = "C:\Users\Public\Downloads"
if (Test-Path $publicDownloadsDir) { $userDownloadsDirs += $publicDownloadsDir }

# Final list of directories to search (excluding Temp directories)
$targetDirs = @(
    "$env:SystemRoot\System32",
    "$env:SystemRoot\SysWOW64"
) + $userDownloadsDirs

# List of known LOLBins (your provided list)
$lolBins = @(
    'AddinUtil.exe', 'AppInstaller.exe', 'Aspnet_Compiler.exe', 'At.exe', 'Atbroker.exe', 'Bash.exe', 'Bitsadmin.exe', 'CertOC.exe', 'CertReq.exe', 'Certutil.exe', 'Cipher.exe', 'Cmd.exe', 'Cmdkey.exe', 'cmdl32.exe', 'Cmstp.exe', 'Colorcpl.exe', 'ComputerDefaults.exe', 'ConfigSecurityPolicy.exe', 'Conhost.exe', 'Control.exe', 'Csc.exe', 'Cscript.exe', 'CustomShellHost.exe', 'DataSvcUtil.exe', 'Desktopimgdownldr.exe', 'DeviceCredentialDeployment.exe', 'Dfsvc.exe', 'Diantz.exe', 'Diskshadow.exe', 'Dnscmd.exe', 'Esentutl.exe', 'Eventvwr.exe', 'Expand.exe', 'Explorer.exe', 'Extexport.exe', 'Extrac32.exe', 'Findstr.exe', 'Finger.exe', 'fltMC.exe', 'Forfiles.exe', 'Fsutil.exe', 'Ftp.exe', 'Gpscript.exe', 'Hh.exe', 'IMEWDBLD.exe', 'Ie4uinit.exe', 'iediagcmd.exe', 'Ieexec.exe', 'Ilasm.exe', 'Infdefaultinstall.exe', 'Installutil.exe', 'Jsc.exe', 'Ldifde.exe', 'Makecab.exe', 'Mavinject.exe', 'Microsoft.Workflow.Compiler.exe', 'Mmc.exe', 'MpCmdRun.exe', 'Msbuild.exe', 'Msconfig.exe', 'Msdt.exe', 'Msedge.exe', 'Mshta.exe', 'Msiexec.exe', 'Netsh.exe', 'Ngen.exe', 'Odbcconf.exe', 'OfflineScannerShell.exe', 'OneDriveStandaloneUpdater.exe', 'Pcalua.exe', 'Pcwrun.exe', 'Pktmon.exe', 'Pnputil.exe', 'Presentationhost.exe', 'Print.exe', 'PrintBrm.exe', 'Provlaunch.exe', 'Psr.exe', 'Rasautou.exe', 'rdrleakdiag.exe', 'Reg.exe', 'Regasm.exe', 'Regedit.exe', 'Regini.exe', 'Register-cimprovider.exe', 'Regsvcs.exe', 'Regsvr32.exe', 'Replace.exe', 'Rpcping.exe', 'Rundll32.exe', 'Runexehelper.exe', 'Runonce.exe', 'Runscripthelper.exe', 'Sc.exe', 'Schtasks.exe', 'Scriptrunner.exe', 'Setres.exe', 'SettingSyncHost.exe', 'Sftp.exe', 'ssh.exe', 'Stordiag.exe', 'SyncAppvPublishingServer.exe', 'Tar.exe', 'Ttdinject.exe', 'Tttracer.exe', 'Unregmp2.exe', 'vbc.exe', 'Verclsid.exe', 'Wab.exe', 'wbadmin.exe', 'wbemtest.exe', 'winget.exe', 'Wlrmdr.exe', 'Wmic.exe', 'WorkFolders.exe', 'Wscript.exe', 'Wsreset.exe', 'wuauclt.exe', 'Xwizard.exe', 'msedge_proxy.exe', 'msedgewebview2.exe', 'wt.exe', 'Advpack.dll', 'Desk.cpl', 'Dfshim.dll', 'Ieadvpack.dll', 'Ieframe.dll', 'Mshtml.dll', 'Pcwutl.dll', 'PhotoViewer.dll', 'Scrobj.dll', 'Setupapi.dll', 'Shdocvw.dll', 'Shell32.dll', 'Shimgvw.dll', 'Syssetup.dll', 'Url.dll', 'Zipfldr.dll', 'Comsvcs.dll', 'AccCheckConsole.exe', 'adplus.exe', 'AgentExecutor.exe', 'AppCert.exe', 'Appvlp.exe', 'Bginfo.exe', 'Cdb.exe', 'coregen.exe', 'Createdump.exe', 'csi.exe', 'DefaultPack.EXE', 'Devinit.exe', 'Devtoolslauncher.exe', 'dnx.exe', 'Dotnet.exe', 'dsdbutil.exe', 'dtutil.exe', 'Dump64.exe', 'DumpMinitool.exe', 'Dxcap.exe', 'ECMangen.exe', 'Excel.exe', 'Fsi.exe', 'FsiAnyCpu.exe', 'Mftrace.exe', 'Microsoft.NodejsTools.PressAnyKey.exe', 'MSAccess.exe', 'Msdeploy.exe', 'MsoHtmEd.exe', 'Mspub.exe', 'msxsl.exe', 'ntdsutil.exe', 'OpenConsole.exe', 'Powerpnt.exe', 'Procdump.exe', 'ProtocolHandler.exe', 'rcsi.exe', 'Remote.exe', 'Sqldumper.exe', 'Sqlps.exe', 'SQLToolsPS.exe', 'Squirrel.exe', 'te.exe', 'Teams.exe', 'TestWindowRemoteAgent.exe', 'Tracker.exe', 'Update.exe', 'VSDiagnostics.exe', 'VSIISExeLauncher.exe', 'Visio.exe', 'VisualUiaVerifyNative.exe', 'VSLaunchBrowser.exe', 'Vshadow.exe', 'vsjitdebugger.exe', 'WFMFormat.exe', 'Wfc.exe', 'WinProj.exe', 'Winword.exe', 'Wsl.exe', 'XBootMgrSleep.exe', 'devtunnel.exe', 'vsls-agent.exe', 'vstest.console.exe', 'winfile.exe', 'xsd.exe', 'CL_LoadAssembly.ps1', 'CL_Mutexverifiers.ps1', 'CL_Invocation.ps1', 'Launch-VsDevShell.ps1', 'Manage-bde.wsf', 'Pubprn.vbs', 'Syncappvpublishingserver.vbs', 'UtilityFunctions.ps1', 'winrm.vbs', 'Pester.bat'
)

# Store results
$lolresults = @()

foreach ($lolBin in $lolBins) {
    $foundPaths = @()

    foreach ($dir in $targetDirs) {
        $fullPath = Join-Path -Path $dir -ChildPath $lolBin
        if (Test-Path -Path $fullPath) {
            $foundPaths += $fullPath
        }
    }

    $status = if ($foundPaths.Count -gt 0) { "Yes" } else { "No" }
    $directory = if ($foundPaths.Count -gt 0) { $foundPaths -join "; " } else { "Not Found" }

    # Store in results array
    $lolresults += [PSCustomObject]@{
        LOLBin    = $lolBin
        Directories = $directory
        Status    = $status
    }
}

# ✅ Return the results to the Run_Check function
return $lolresults } }

)

foreach ($check in $selectedChecks) {
    Run_Check -Name $check.Name -Command $check.Command
}

# Export Results to JSON
$outputPath = "IOCoutput.json"
$results | ConvertTo-Json -Depth 5 | Out-File $outputPath -Encoding UTF8

Write-Host "`nAll checks completed. Results saved to: $outputPath"
