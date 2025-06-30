
# Auto-generated PowerShell script

$outputJsonPath = "Microsoft_Windows_11_Stand-alone_v3.0.0_output.json"
$seceditExportPath = "C:\\secpol.cfg"
$currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

# Export Local Security Policy
secedit /export /cfg $seceditExportPath | Out-Null


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


$queries = @(
@{ 
    audit_name = "1.1.1 (L1) Ensure 'Enforce password history' is set to '24 or more password(s)' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"PasswordHistorySize`""
}
@{ 
    audit_name = "1.1.2 (L1) Ensure 'Maximum password age' is set to '365 or fewer days, but not 0' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"MaximumPasswordAge`""
}
@{ 
    audit_name = "1.1.3 (L1) Ensure 'Minimum password age' is set to '1 or more day(s)' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"MinimumPasswordAge`""
}
@{ 
    audit_name = "1.1.4 (L1) Ensure 'Minimum password length' is set to '14 or more character(s)' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"MinimumPasswordLength`""
}
@{ 
    audit_name = "1.1.5 (L1) Ensure 'Password must meet complexity requirements' is set to 'Enabled' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"PasswordComplexity`""
}
@{ 
    audit_name = "1.1.6 (L1) Ensure 'Relax minimum password length limits' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\System\CurrentControlSet\Control\SAM`" -Name `"RelaxMinimumPasswordLengthLimits`""
}
@{ 
    audit_name = "1.1.7 (L1) Ensure 'Store passwords using reversible encryption' is set to 'Disabled' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"ClearTextPassword`""
}
@{ 
    audit_name = "1.2.1 (L1) Ensure 'Account lockout duration' is set to '15 or more minute(s)' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"LockoutDuration`""
}
@{ 
    audit_name = "1.2.2 (L1) Ensure 'Account lockout threshold' is set to '5 or fewer invalid logon attempt(s), but not 0' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"LockoutBadCount`""
}
@{ 
    audit_name = "1.2.3 (L1) Ensure 'Allow Administrator account lockout' is set to 'Enabled' (Manual)"
    command = "Get-LocalPolicyEntry -SettingName `"AllowAdminLockout`""
}
@{ 
    audit_name = "1.2.4 (L1) Ensure 'Reset account lockout counter after' is set to '15 or more minute(s)' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"ResetLockoutCount`""
}
@{ 
    audit_name = "2.2.1 (L1) Ensure 'Access Credential Manager as a trusted caller' is set to 'No One' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"AccessCredentialManager`""
}
@{ 
    audit_name = "2.2.2 (L1) Ensure 'Access this computer from the network' is set to 'Administrators, Remote Desktop Users' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeNetworkLogonRight`""
}
@{ 
    audit_name = "2.2.3 (L1) Ensure 'Act as part of the operating system' is set to 'No One' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeTcbPrivilege`""
}
@{ 
    audit_name = "2.2.4 (L1) Ensure 'Adjust memory quotas for a process' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeIncreaseQuotaPrivilege`""
}
@{ 
    audit_name = "2.2.5 (L1) Ensure 'Allow log on locally' is set to 'Administrators, Users' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeInteractiveLogonRight`""
}
@{ 
    audit_name = "2.2.6 (L1) Ensure 'Allow log on through Remote Desktop Services' is set to 'Administrators, Remote Desktop Users' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeRemoteInteractiveLogonRight`""
}
@{ 
    audit_name = "2.2.7 (L1) Ensure 'Back up files and directories' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeBackupPrivilege`""
}
@{ 
    audit_name = "2.2.8 (L1) Ensure 'Change the system time' is set to 'Administrators, LOCAL SERVICE' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeSystemTimePrivilege`""
}
@{ 
    audit_name = "2.2.9 (L1) Ensure 'Change the time zone' is set to 'Administrators, LOCAL SERVICE, Users' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeTimeZonePrivilege`""
}
@{ 
    audit_name = "2.2.10 (L1) Ensure 'Create a pagefile' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeCreatePagefilePrivilege`""
}
@{ 
    audit_name = "2.2.11 (L1) Ensure 'Create a token object' is set to 'No One' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeCreateTokenPrivilege`""
}
@{ 
    audit_name = "2.2.12 (L1) Ensure 'Create global objects' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeCreateGlobalPrivilege`""
}
@{ 
    audit_name = "2.2.13 (L1) Ensure 'Create permanent shared objects' is set to 'No One' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeCreatePermanentPrivilege`""
}
@{ 
    audit_name = "2.2.14 (L1) Configure 'Create symbolic links' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeCreateSymbolicLinkPrivilege`""
}
@{ 
    audit_name = "2.2.15 (L1) Ensure 'Debug programs' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeDebugPrivilege`""
}
@{ 
    audit_name = "2.2.16 (L1) Ensure 'Deny access to this computer from the network' to include 'Guests' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeDenyNetworkLogonRight`""
}
@{ 
    audit_name = "2.2.17 (L1) Ensure 'Deny log on as a batch job' to include 'Guests' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeDenyBatchLogonRight`""
}
@{ 
    audit_name = "2.2.18 (L1) Ensure 'Deny log on as a service' to include 'Guests' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeDenyServiceLogonRight`""
}
@{ 
    audit_name = "2.2.19 (L1) Ensure 'Deny log on locally' to include 'Guests' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeDenyInteractiveLogonRight`""
}
@{ 
    audit_name = "2.2.20 (L1) Ensure 'Deny log on through Remote Desktop Services' to include 'Guests' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeDenyRemoteInteractiveLogonRight`""
}
@{ 
    audit_name = "2.2.21 (L1) Ensure 'Enable computer and user accounts to be trusted for delegation' is set to 'No One' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeEnableDelegationPrivilege`""
}
@{ 
    audit_name = "2.2.22 (L1) Ensure 'Force shutdown from a remote system' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeRemoteShutdownPrivilege`""
}
@{ 
    audit_name = "2.2.23 (L1) Ensure 'Generate security audits' is set to 'LOCAL SERVICE, NETWORK SERVICE' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeAuditPrivilege`""
}
@{ 
    audit_name = "2.2.24 (L1) Ensure 'Impersonate a client after authentication' is set to 'Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeImpersonatePrivilege`""
}
@{ 
    audit_name = "2.2.25 (L1) Ensure 'Increase scheduling priority' is set to 'Administrators, Window Manager\Window Manager Group' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeIncreaseBasePriorityPrivilege`""
}
@{ 
    audit_name = "2.2.26 (L1) Ensure 'Load and unload device drivers' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeLoadDriverPrivilege`""
}
@{ 
    audit_name = "2.2.27 (L1) Ensure 'Lock pages in memory' is set to 'No One' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeLockMemoryPrivilege`""
}
@{ 
    audit_name = "2.2.28 (L2) Ensure 'Log on as a batch job' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeBatchLogonRight`""
}
@{ 
    audit_name = "2.2.29 (L2) Configure 'Log on as a service' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeServiceLogonRight`""
}
@{ 
    audit_name = "2.2.30 (L1) Ensure 'Manage auditing and security log' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeSecurityPrivilege`""
}
@{ 
    audit_name = "2.2.31 (L1) Ensure 'Modify an object label' is set to 'No One' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeDelegateSessionUserImpersonatePrivilege`""
}
@{ 
    audit_name = "2.2.32 (L1) Ensure 'Modify firmware environment values' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeSystemEnvironmentPrivilege`""
}
@{ 
    audit_name = "2.2.33 (L1) Ensure 'Perform volume maintenance tasks' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeManageVolumePrivilege`""
}
@{ 
    audit_name = "2.2.34 (L1) Ensure 'Profile single process' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeProfileSingleProcessPrivilege`""
}
@{ 
    audit_name = "2.2.35 (L1) Ensure 'Profile system performance' is set to 'Administrators, NT SERVICE\WdiServiceHost' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeSystemProfilePrivilege`""
}
@{ 
    audit_name = "2.2.36 (L1) Ensure 'Replace a process level token' is set to 'LOCAL SERVICE, NETWORK SERVICE' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeAssignPrimaryTokenPrivilege`""
}
@{ 
    audit_name = "2.2.37 (L1) Ensure 'Restore files and directories' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeRestorePrivilege`""
}
@{ 
    audit_name = "2.2.38 (L1) Ensure 'Shut down the system' is set to 'Administrators, Users' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeShutdownPrivilege`""
}
@{ 
    audit_name = "2.2.39 (L1) Ensure 'Take ownership of files or other objects' is set to 'Administrators' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"SeTakeOwnershipPrivilege`""
}
@{ 
    audit_name = "2.3.1.1 (L1) Ensure 'Accounts: Block Microsoft accounts' is set to 'Users can't add or log on with Microsoft accounts' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"NoConnectedUser`""
}
@{ 
    audit_name = "2.3.1.2 (L1) Ensure 'Accounts: Guest account status' is set to  'Disabled' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"Accounts_DisableGuestAccount`""
}
@{ 
    audit_name = "2.3.1.3 (L1) Ensure 'Accounts: Limit local account use of blank passwords to console logon only' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"LimitBlankPasswordUse`""
}
@{ 
    audit_name = "2.3.1.4 (L1) Configure 'Accounts: Rename administrator account' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"NewAdministratorName`""
}
@{ 
    audit_name = "2.3.1.5 (L1) Configure 'Accounts: Rename guest account' (Automated)"
    command = "Get-LocalPolicyEntry -SettingName `"NewGuestAccountName`""
}
@{ 
    audit_name = "2.3.2.1 (L1) Ensure 'Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"SCENoApplyLegacyAuditPolicy`""
}
@{ 
    audit_name = "2.3.2.2 (L1) Ensure 'Audit: Shut down system immediately if unable to log security audits' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"CrashOnAuditFail`""
}
@{ 
    audit_name = "2.3.4.1 (L2) Ensure 'Devices: Prevent users from installing printer drivers' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers`" -Name `"AddPrinterDrivers`""
}
@{ 
    audit_name = "2.3.7.1 (L1) Ensure 'Interactive logon: Do not require CTRL+ALT+DEL' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"DisableCAD`""
}
@{ 
    audit_name = "2.3.7.2 (L1) Ensure 'Interactive logon: Don't display last signed-in' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"DontDisplayLastUserName`""
}
@{ 
    audit_name = "2.3.7.3 (BL) Ensure 'Interactive logon: Machine account lockout threshold' is set to '10 or fewer invalid logon attempts, but not 0' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"MaxDevicePasswordFailedAttempts`""
}
@{ 
    audit_name = "2.3.7.4 (L1) Ensure 'Interactive logon: Machine inactivity limit' is set to '900 or fewer second(s), but not 0' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"InactivityTimeoutSecs`""
}
@{ 
    audit_name = "2.3.7.5 (L1) Configure 'Interactive logon: Message text for users attempting to log on' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"LegalNoticeText`""
}
@{ 
    audit_name = "2.3.7.6 (L1) Configure 'Interactive logon: Message title for users attempting to log on'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"LegalNoticeCaption`""
}
@{ 
    audit_name = "2.3.7.7 (L1) Ensure 'Interactive logon: Prompt user to change password before expiration' is set to 'between 5 and 14 days'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" -Name `"PasswordExpiryWarning`""
}
@{ 
    audit_name = "2.3.7.8 (L1) Ensure 'Interactive logon: Smart card removal behavior' is set to 'Lock Workstation' or higher (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" -Name `"ScRemoveOption`""
}
@{ 
    audit_name = "2.3.8.1 (L1) Ensure 'Microsoft network client: Digitally sign communications (always)' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters`" -Name `"RequireSecuritySignature`""
}
@{ 
    audit_name = "2.3.8.2 (L1) Ensure 'Microsoft network client: Digitally sign communications (if server agrees)' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters`" -Name `"EnableSecuritySignature`""
}
@{ 
    audit_name = "2.3.8.3 (L1) Ensure 'Microsoft network client: Send unencrypted password to third-party SMB servers' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters`" -Name `"EnablePlainTextPassword`""
}
@{ 
    audit_name = "2.3.9.1 (L1) Ensure 'Microsoft network server: Amount of idle time required before suspending session' is set to '15 or fewer minute(s)'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"AutoDisconnect`""
}
@{ 
    audit_name = "2.3.9.2 (L1) Ensure 'Microsoft network server: Digitally sign communications (always)' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"RequireSecuritySignature`""
}
@{ 
    audit_name = "2.3.9.3 (L1) Ensure 'Microsoft network server: Digitally sign communications (if client agrees)' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"EnableSecuritySignature`""
}
@{ 
    audit_name = "2.3.9.4 (L1) Ensure 'Microsoft network server: Disconnect clients when logon hours expire' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"enableforcedlogoff`""
}
@{ 
    audit_name = "2.3.9.5 (L1) Ensure 'Microsoft network server: Server SPN target name validation level' is set to 'Accept if provided by client' or higher"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"SMBServerNameHardeningLevel`""
}
@{ 
    audit_name = "2.3.10.1 (L1) Ensure 'Network access: Allow anonymous SID/Name translation' is set to 'Disabled'"
    command = "Get-LocalPolicyEntry -SettingName `"AllowAnonymousSIDNameTranslation`""
}
@{ 
    audit_name = "2.3.10.2 (L1) Ensure 'Network access: Do not allow anonymous enumeration of SAM accounts' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"RestrictAnonymousSAM`""
}
@{ 
    audit_name = "2.3.10.3 (L1) Ensure 'Network access: Do not allow anonymous enumeration of SAM accounts and shares' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"RestrictAnonymous`""
}
@{ 
    audit_name = "2.3.10.4 (L1) Ensure 'Network access: Do not allow storage of passwords and credentials for network authentication' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"DisableDomainCreds`""
}
@{ 
    audit_name = "2.3.10.5 (L1) Ensure 'Network access: Let Everyone permissions apply to anonymous users' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"EveryoneIncludesAnonymous`""
}
@{ 
    audit_name = "2.3.10.6 (L1) Ensure 'Network access: Named Pipes that can be accessed anonymously' is set to 'None'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"NullSessionPipes`""
}
@{ 
    audit_name = "2.3.10.7 (L1) Ensure 'Network access: Remotely accessible registry paths' is configured"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedExactPaths`" -Name `"Machine`""
}
@{ 
    audit_name = "2.3.10.8 (L1) Ensure 'Network access: Remotely accessible registry paths and sub-paths' is configured"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\Winreg\AllowedPaths`" -Name `"Machine`""
}
@{ 
    audit_name = "2.3.10.9 (L1) Ensure 'Network access: Restrict anonymous access to Named Pipes and Shares' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"RestrictNullSessAccess`""
}
@{ 
    audit_name = "2.3.10.10 (L1) Ensure 'Network access: Restrict clients allowed to make remote calls to SAM' is set to 'Administrators: Remote Access: Allow'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"restrictremotesam`""
}
@{ 
    audit_name = "2.3.10.11 (L1) Ensure 'Network access: Shares that can be accessed anonymously' is set to 'None'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters`" -Name `"NullSessionShares`""
}
@{ 
    audit_name = "2.3.10.12 (L1) Ensure 'Network access: Sharing and security model for local accounts' is set to 'Classic - local users authenticate as themselves'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"ForceGuest`""
}
@{ 
    audit_name = "2.3.11.1 (L1) Ensure 'Network security: Allow Local System to use computer identity for NTLM' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"UseMachineId`""
}
@{ 
    audit_name = "2.3.11.2 (L1) Ensure 'Network security: Allow LocalSystem NULL session fallback' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0`" -Name `"AllowNullSessionFallback`""
}
@{ 
    audit_name = "2.3.11.3 (L1) Ensure 'Network Security: Allow PKU2U authentication requests to this computer to use online identities' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\pku2u`" -Name `"AllowOnlineID`""
}
@{ 
    audit_name = "2.3.11.4 (L1) Ensure 'Network security: Configure encryption types allowed for Kerberos' is set to 'AES128_HMAC_SHA1, AES256_HMAC_SHA1, Future encryption types' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters`" -Name `"SupportedEncryptionTypes`""
}
@{ 
    audit_name = "2.3.11.5 (L1) Ensure 'Network security: Do not store LAN Manager hash value on next password change' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"NoLMHash`""
}
@{ 
    audit_name = "2.3.11.6 (L1) Ensure 'Network security: Force logoff when logon hours expire' is set to 'Enabled' (Manual)"
    command = "Get-LocalPolicyEntry -SettingName `"ForceLogoffWhenHourExpire`""
}
@{ 
    audit_name = "2.3.11.7 (L1) Ensure 'Network security: LAN Manager authentication level' is set to 'Send NTLMv2 response only. Refuse LM & NTLM' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"LmCompatibilityLevel`""
}
@{ 
    audit_name = "2.3.11.8 (L1) Ensure 'Network security: LDAP client signing requirements' is set to 'Negotiate signing' or higher (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LDAP`" -Name `"LDAPClientIntegrity`""
}
@{ 
    audit_name = "2.3.11.9 (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) clients' is set to 'Require NTLMv2 session security, Require 128-bit encryption' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0`" -Name `"NTLMMinClientSec`""
}
@{ 
    audit_name = "2.3.11.10 (L1) Ensure 'Network security: Minimum session security for NTLM SSP based (including secure RPC) servers' is set to 'Require NTLMv2 session security, Require 128-bit encryption' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0`" -Name `"NTLMMinServerSec`""
}
@{ 
    audit_name = "2.3.11.11 (L1) Ensure 'Network security: Restrict NTLM: Audit Incoming NTLM Traffic' is set to 'Enable auditing for all accounts' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0`" -Name `"AuditReceivingNTLMTraffic`""
}
@{ 
    audit_name = "2.3.11.12 (L1) Ensure 'Network security: Restrict NTLM: Outgoing NTLM traffic to remote servers' is set to 'Audit all' or higher (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0`" -Name `"RestrictSendingNTLMTraffic`""
}
@{ 
    audit_name = "2.3.14.1 (L2) Ensure 'System cryptography: Force strong key protection for user keys stored on the computer' is set to 'User is prompted when the key is first used' or higher (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Cryptography`" -Name `"ForceKeyProtection`""
}
@{ 
    audit_name = "2.3.15.1 (L1) Ensure 'System objects: Require case insensitivity for non-Windows subsystems' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel`" -Name `"ObCaseInsensitive`""
}
@{ 
    audit_name = "2.3.15.2 (L1) Ensure 'System objects: Strengthen default permissions of internal system objects (e.g. Symbolic Links)' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager`" -Name `"ProtectionMode`""
}
@{ 
    audit_name = "2.3.17.1 (L1) Ensure 'User Account Control: Admin Approval Mode for the Built-in Administrator account' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"FilterAdministratorToken`""
}
@{ 
    audit_name = "2.3.17.2 (L1) Ensure 'User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode' is set to 'Prompt for consent on the secure desktop' or higher (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"ConsentPromptBehaviorAdmin`""
}
@{ 
    audit_name = "2.3.17.3 (L1) Ensure 'User Account Control: Behavior of the elevation prompt for standard users' is set to 'Automatically deny elevation requests'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"ConsentPromptBehaviorUser`""
}
@{ 
    audit_name = "2.3.17.4 (L1) Ensure 'User Account Control: Detect application installations and prompt for elevation' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"EnableInstallerDetection`""
}
@{ 
    audit_name = "2.3.17.5 (L1) Ensure 'User Account Control: Only elevate UIAccess applications that are installed in secure locations' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"EnableSecureUIAPaths`""
}
@{ 
    audit_name = "2.3.17.6 (L1) Ensure 'User Account Control: Run all administrators in Admin Approval Mode' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"EnableLUA`""
}
@{ 
    audit_name = "2.3.17.7 (L1) Ensure 'User Account Control: Switch to the secure desktop when prompting for elevation' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"PromptOnSecureDesktop`""
}
@{ 
    audit_name = "2.3.17.8 (L1) Ensure 'User Account Control: Virtualize file and registry write failures to per-user locations' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"EnableVirtualization`""
}
@{ 
    audit_name = "5.1 (L2) Ensure 'Bluetooth Audio Gateway Service (BTAGService)' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\BTAGService`" -Name `"Start`""
}
@{ 
    audit_name = "5.2 (L2) Ensure 'Bluetooth Support Service (bthserv)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\bthserv`" -Name `"Start`""
}
@{ 
    audit_name = "5.3 (L1) Ensure 'Computer Browser (Browser)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Browser`" -Name `"Start`""
}
@{ 
    audit_name = "5.4 (L2) Ensure 'Downloaded Maps Manager (MapsBroker)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\MapsBroker`" -Name `"Start`""
}
@{ 
    audit_name = "5.5 (L2) Ensure 'Geolocation Service (lfsvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.6 (L1) Ensure 'IIS Admin Service (IISADMIN)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\IISADMIN`" -Name `"Start`""
}
@{ 
    audit_name = "5.7 (L1) Ensure 'Infrared monitor service (irmon)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\irmon`" -Name `"Start`""
}
@{ 
    audit_name = "5.8 (L1) Ensure 'Internet Connection Sharing (ICS) (SharedAccess)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess`" -Name `"Start`""
}
@{ 
    audit_name = "5.9 (L2) Ensure 'Link-Layer Topology Discovery Mapper (lltdsvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\lltdsvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.10 (L1) Ensure 'LxssManager (LxssManager)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LxssManager`" -Name `"Start`""
}
@{ 
    audit_name = "5.11 (L1) Ensure 'Microsoft FTP Service (FTPSVC)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\FTPSVC`" -Name `"Start`""
}
@{ 
    audit_name = "5.12 (L2) Ensure 'Microsoft iSCSI Initiator Service (MSiSCSI)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\MSiSCSI`" -Name `"Start`""
}
@{ 
    audit_name = "5.13 (L1) Ensure 'OpenSSH SSH Server (sshd)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\sshd`" -Name `"Start`""
}
@{ 
    audit_name = "5.14 (L2) Ensure 'Peer Name Resolution Protocol (PNRPsvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\PNRPsvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.15 (L2) Ensure 'Peer Networking Grouping (p2psvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\p2psvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.16 (L2) Ensure 'Peer Networking Identity Manager (p2pimsvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\p2pimsvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.17 (L2) Ensure 'PNRP Machine Name Publication Service (PNRPAutoReg)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\PNRPAutoReg`" -Name `"Start`""
}
@{ 
    audit_name = "5.18 (L2) Ensure 'Print Spooler (Spooler)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Spooler`" -Name `"Start`""
}
@{ 
    audit_name = "5.19 (L2) Ensure 'Problem Reports and Solutions Control Panel Support (wercplsupport)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\wercplsupport`" -Name `"Start`""
}
@{ 
    audit_name = "5.20 (L2) Ensure 'Remote Access Auto Connection Manager (RasAuto)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\RasAuto`" -Name `"Start`""
}
@{ 
    audit_name = "5.21 (L2) Ensure 'Remote Desktop Configuration (SessionEnv)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\SessionEnv`" -Name `"Start`""
}
@{ 
    audit_name = "5.22 (L2) Ensure 'Remote Desktop Services (TermService)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\TermService`" -Name `"Start`""
}
@{ 
    audit_name = "5.23 (L2) Ensure 'Remote Desktop Services UserMode Port Redirector (UmRdpService)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\UmRdpService`" -Name `"Start`""
}
@{ 
    audit_name = "5.24 (L1) Ensure 'Remote Procedure Call (RPC) Locator (RpcLocator)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\RpcLocator`" -Name `"Start`""
}
@{ 
    audit_name = "5.25 (L2) Ensure 'Remote Registry (RemoteRegistry)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\RemoteRegistry`" -Name `"Start`""
}
@{ 
    audit_name = "5.26 (L1) Ensure 'Routing and Remote Access (RemoteAccess)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess`" -Name `"Start`""
}
@{ 
    audit_name = "5.27 (L2) Ensure 'Server (LanmanServer)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer`" -Name `"Start`""
}
@{ 
    audit_name = "5.28 (L1) Ensure 'Simple TCP/IP Services (simptcp)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\simptcp`" -Name `"Start`""
}
@{ 
    audit_name = "5.29 (L2) Ensure 'SNMP Service (SNMP)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\SNMP`" -Name `"Start`""
}
@{ 
    audit_name = "5.30 (L1) Ensure 'Special Administration Console Helper (sacsvr)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\sacsvr`" -Name `"Start`""
}
@{ 
    audit_name = "5.31 (L1) Ensure 'SSDP Discovery (SSDPSRV)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\SSDPSRV`" -Name `"Start`""
}
@{ 
    audit_name = "5.32 (L1) Ensure 'UPnP Device Host (upnphost)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\upnphost`" -Name `"Start`""
}
@{ 
    audit_name = "5.33 (L1) Ensure 'Web Management Service (WMSvc)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\WMSvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.34 (L2) Ensure 'Windows Error Reporting Service (WerSvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\WerSvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.35 (L2) Ensure 'Windows Event Collector (Wecsvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Wecsvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.36 (L1) Ensure 'Windows Media Player Network Sharing Service (WMPNetworkSvc)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\WMPNetworkSvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.37 (L1) Ensure 'Windows Mobile Hotspot Service (icssvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\icssvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.38 (L2) Ensure 'Windows Push Notifications System Service (WpnService)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\WpnService`" -Name `"Start`""
}
@{ 
    audit_name = "5.39 (L2) Ensure 'Windows PushToInstall Service (PushToInstall)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\PushToInstall`" -Name `"Start`""
}
@{ 
    audit_name = "5.40 (L2) Ensure 'Windows Remote Management (WS Management) (WinRM)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\WinRM`" -Name `"Start`""
}
@{ 
    audit_name = "5.41 (L1) Ensure 'World Wide Web Publishing Service (W3SVC)' is set to 'Disabled' or 'Not Installed' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\W3SVC`" -Name `"Start`""
}
@{ 
    audit_name = "5.42 (L1) Ensure 'Xbox Accessory Management Service (XboxGipSvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\XboxGipSvc`" -Name `"Start`""
}
@{ 
    audit_name = "5.43 (L1) Ensure 'Xbox Live Auth Manager (XblAuthManager)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\XblAuthManager`" -Name `"Start`""
}
@{ 
    audit_name = "5.44 (L1) Ensure 'Xbox Live Game Save (XblGameSave)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\XblGameSave`" -Name `"Start`""
}
@{ 
    audit_name = "5.45 (L1) Ensure 'Xbox Live Networking Service (XboxNetApiSvc)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\XboxNetApiSvc`" -Name `"Start`""
}
@{ 
    audit_name = "9.2.1 (L1) Ensure 'Windows Firewall: Private: Firewall state' is set to 'On (recommended)'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile`" -Name `"EnableFirewall`""
}
@{ 
    audit_name = "9.2.2 (L1) Ensure 'Windows Firewall: Private: Inbound connections' is set to 'Block (default)'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile`" -Name `"DefaultInboundAction`""
}
@{ 
    audit_name = "9.2.3 (L1) Ensure 'Windows Firewall: Private: Settings: Display a notification' is set to 'No'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile`" -Name `"DisableNotifications`""
}
@{ 
    audit_name = "9.2.4 (L1) Ensure 'Windows Firewall: Private: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\privatefw.log'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging`" -Name `"LogFilePath`""
}
@{ 
    audit_name = "9.2.5 (L1) Ensure 'Windows Firewall: Private: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging`" -Name `"LogFileSize`""
}
@{ 
    audit_name = "9.2.6 (L1) Ensure 'Windows Firewall: Private: Logging: Log dropped packets' is set to 'Yes'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging`" -Name `"LogDroppedPackets`""
}
@{ 
    audit_name = "9.2.7 (L1) Ensure 'Windows Firewall: Private: Logging: Log successful connections' is set to 'Yes'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile\Logging`" -Name `"LogSuccessfulConnections`""
}
@{ 
    audit_name = "9.3.1 (L1) Ensure 'Windows Firewall: Public: Firewall state' is set to 'On (recommended)'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile`" -Name `"EnableFirewall`""
}
@{ 
    audit_name = "9.3.2 (L1) Ensure 'Windows Firewall: Public: Inbound connections' is set to 'Block (default)'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile`" -Name `"DefaultInboundAction`""
}
@{ 
    audit_name = "9.3.3 (L1) Ensure 'Windows Firewall: Public: Settings: Display a notification' is set to 'No'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile`" -Name `"DisableNotifications`""
}
@{ 
    audit_name = "9.3.4 (L1) Ensure 'Windows Firewall: Public: Settings: Apply local firewall rules' is set to 'No'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile`" -Name `"AllowLocalPolicyMerge`""
}
@{ 
    audit_name = "9.3.5 (L1) Ensure 'Windows Firewall: Public: Settings: Apply local connection security rules' is set to 'No'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile`" -Name `"AllowLocalIPsecPolicyMerge`""
}
@{ 
    audit_name = "9.3.6 (L1) Ensure 'Windows Firewall: Public: Logging: Name' is set to '%SystemRoot%\System32\logfiles\firewall\publicfw.log'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging`" -Name `"LogFilePath`""
}
@{ 
    audit_name = "9.3.7 (L1) Ensure 'Windows Firewall: Public: Logging: Size limit (KB)' is set to '16,384 KB or greater'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging`" -Name `"LogFileSize`""
}
@{ 
    audit_name = "9.3.8 (L1) Ensure 'Windows Firewall: Public: Logging: Log dropped packets' is set to 'Yes'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging`" -Name `"LogDroppedPackets`""
}
@{ 
    audit_name = "9.3.9 (L1) Ensure 'Windows Firewall: Public: Logging: Log successful connections' is set to 'Yes'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile\Logging`" -Name `"LogSuccessfulConnections`""
}
@{ 
    audit_name = "17.1.1 (L1) Ensure 'Audit Credential Validation' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Credential Validation`""
}
@{ 
    audit_name = "17.2.1 (L1) Ensure 'Audit Application Group Management' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Application Group Management`""
}
@{ 
    audit_name = "17.2.2 (L1) Ensure 'Audit Security Group Management' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Security Group Management`""
}
@{ 
    audit_name = "17.2.3 (L1) Ensure 'Audit User Account Management' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"User Account Management`""
}
@{ 
    audit_name = "17.3.1 (L1) Ensure 'Audit PNP Activity' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"PNP Activity`""
}
@{ 
    audit_name = "17.3.2 (L1) Ensure 'Audit Process Creation' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Process Creation`""
}
@{ 
    audit_name = "17.5.1 (L1) Ensure 'Audit Account Lockout' is set to include 'Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Account Lockout`""
}
@{ 
    audit_name = "17.5.2 (L1) Ensure 'Audit Group Membership' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Group Membership`""
}
@{ 
    audit_name = "17.5.3 (L1) Ensure 'Audit Logoff' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Logoff`""
}
@{ 
    audit_name = "17.5.4 (L1) Ensure 'Audit Logon' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Logon`""
}
@{ 
    audit_name = "17.5.5 (L1) Ensure 'Audit Other Logon/Logoff Events' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Other Logon/Logoff Events`""
}
@{ 
    audit_name = "17.5.6 (L1) Ensure 'Audit Special Logon' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Special Logon`""
}
@{ 
    audit_name = "17.6.1 (L1) Ensure 'Audit Detailed File Share' is set to include 'Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Detailed File Share`""
}
@{ 
    audit_name = "17.6.2 (L1) Ensure 'Audit File Share' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"File Share`""
}
@{ 
    audit_name = "17.6.3 (L1) Ensure 'Audit Other Object Access Events' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Audit Other Object Access Events`""
}
@{ 
    audit_name = "17.6.4 (L1) Ensure 'Audit Removable Storage' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Removable Storage`""
}
@{ 
    audit_name = "17.7.1 (L1) Ensure 'Audit Audit Policy Change' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Audit Policy Change`""
}
@{ 
    audit_name = "17.7.2 (L1) Ensure 'Audit Authentication Policy Change' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Authentication Policy Change`""
}
@{ 
    audit_name = "17.7.3 (L1) Ensure 'Audit Authorization Policy Change' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Authorization Policy Change`""
}
@{ 
    audit_name = "17.7.4 (L1) Ensure 'Audit MPSSVC Rule-Level Policy Change' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"MPSSVC Rule-Level Policy Change`""
}
@{ 
    audit_name = "17.7.5 (L1) Ensure 'Audit Other Policy Change Events' is set to include 'Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Other Policy Change Events`""
}
@{ 
    audit_name = "17.8.1 (L1) Ensure 'Audit Sensitive Privilege Use' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Sensitive Privilege Use`""
}
@{ 
    audit_name = "17.9.1 (L1) Ensure 'Audit IPsec Driver' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"IPsec Driver`""
}
@{ 
    audit_name = "17.9.2 (L1) Ensure 'Audit Other System Events' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Other System Events`""
}
@{ 
    audit_name = "17.9.3 (L1) Ensure 'Audit Security State Change' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Security State Change`""
}
@{ 
    audit_name = "17.9.4 (L1) Ensure 'Audit Security System Extension' is set to include 'Success' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"Security System Extension`""
}
@{ 
    audit_name = "17.9.5 (L1) Ensure 'Audit System Integrity' is set to 'Success and Failure' (Automated)"
    command = "Get-AuditPolicySetting -Subcategory `"System Integrity`""
}
@{ 
    audit_name = "18.1.1.1 (L1) Ensure 'Prevent enabling lock screen camera' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization`" -Name `"NoLockScreenCamera`""
}
@{ 
    audit_name = "18.1.1.2 (L1) Ensure 'Prevent enabling lock screen slide show' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization`" -Name `"NoLockScreenSlideshow`""
}
@{ 
    audit_name = "18.1.2.2 (L1) Ensure 'Allow users to enable online speech recognition services' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization`" -Name `"AllowInputPersonalization`""
}
@{ 
    audit_name = "18.1.3 (L2) Ensure 'Allow Online Tips' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"AllowOnlineTips`""
}
@{ 
    audit_name = "18.4.1 (L1) Ensure 'Configure RPC packet level privacy setting for incoming connections' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Print`" -Name `"RpcAuthnLevelPrivacyEnabled`""
}
@{ 
    audit_name = "18.4.2 (L1) Ensure 'Configure SMB v1 client driver' is set to 'Enabled: Disable driver (recommended)' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10`" -Name `"Start`""
}
@{ 
    audit_name = "18.4.3 (L1) Ensure 'Configure SMB v1 server' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters`" -Name `"SMB1`""
}
@{ 
    audit_name = "18.4.4 (L1) Ensure 'Enable Certificate Padding' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config`" -Name `"EnableCertPaddingCheck`""
}
@{ 
    audit_name = "18.4.5 (L1) Ensure 'Enable Structured Exception Handling Overwrite Protection (SEHOP)' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel`" -Name `"DisableExceptionChainValidation`""
}
@{ 
    audit_name = "18.4.6 (L1) Ensure 'LSA Protection' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"RunAsPPL`""
}
@{ 
    audit_name = "18.4.7 (L1) Ensure 'NetBT NodeType configuration' is set to 'Enabled: P-node (recommended)' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters`" -Name `"NodeType`""
}
@{ 
    audit_name = "18.4.8 (L1) Ensure 'WDigest Authentication' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest`" -Name `"UseLogonCredential`""
}
@{ 
    audit_name = "18.5.1 (L1) Ensure 'MSS: (AutoAdminLogon) Enable Automatic Logon' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" -Name `"AutoAdminLogon`""
}
@{ 
    audit_name = "18.5.2 (L1) Ensure 'MSS: (DisableIPSourceRouting IPv6) IP source routing protection level' is set to 'Enabled: Highest protection, source routing is completely disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters`" -Name `"DisableIPSourceRouting`""
}
@{ 
    audit_name = "18.5.3 (L1) Ensure 'MSS: (DisableIPSourceRouting) IP source routing protection level' is set to 'Enabled: Highest protection, source routing is completely disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`" -Name `"DisableIPSourceRouting`""
}
@{ 
    audit_name = "18.5.4 (L2) Ensure 'MSS: (DisableSavePassword) Prevent the dial-up password from being saved' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters`" -Name `"DisableSavePassword`""
}
@{ 
    audit_name = "18.5.5 (L1) Ensure 'MSS: (EnableICMPRedirect) Allow ICMP redirects to override OSPF generated routes' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`" -Name `"EnableICMPRedirect`""
}
@{ 
    audit_name = "18.5.6 (L2) Ensure 'MSS: (KeepAliveTime) How often keep-alive packets are sent in milliseconds' is set to 'Enabled: 300,000 or 5 minutes' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`" -Name `"KeepAliveTime`""
}
@{ 
    audit_name = "18.5.7 (L1) Ensure 'MSS: (NoNameReleaseOnDemand) Allow the computer to ignore NetBIOS name release requests except from WINS servers' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters`" -Name `"NoNameReleaseOnDemand`""
}
@{ 
    audit_name = "18.5.8 (L2) Ensure 'MSS: (PerformRouterDiscovery) Allow IRDP to detect and configure Default Gateway addresses' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`" -Name `"PerformRouterDiscovery`""
}
@{ 
    audit_name = "18.5.9 (L1) Ensure 'MSS: (SafeDllSearchMode) Enable Safe DLL search mode' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager`" -Name `"SafeDllSearchMode`""
}
@{ 
    audit_name = "18.5.10 (L1) Ensure 'MSS: (ScreenSaverGracePeriod) The time in seconds before the screen saver grace period expires' is set to 'Enabled: 5 or fewer seconds' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" -Name `"ScreenSaverGracePeriod`""
}
@{ 
    audit_name = "18.5.11 (L2) Ensure 'MSS: (TcpMaxDataRetransmissions IPv6) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters`" -Name `"TcpMaxDataRetransmissions`""
}
@{ 
    audit_name = "18.5.12 (L2) Ensure 'MSS: (TcpMaxDataRetransmissions) How many times unacknowledged data is retransmitted' is set to 'Enabled: 3' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`" -Name `"TcpMaxDataRetransmissions`""
}
@{ 
    audit_name = "18.5.13 (L1) Ensure 'MSS: (WarningLevel) Percentage threshold for the security event log at which the system will generate a warning' is set to 'Enabled: 90% or less' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Security`" -Name `"WarningLevel`""
}
@{ 
    audit_name = "18.6.5.1 (L2) Ensure 'Enable Font Providers' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"EnableFontProviders`""
}
@{ 
    audit_name = "18.6.8.1 (L1) Ensure 'Enable insecure guest logons' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation`" -Name `"AllowInsecureGuestAuth`""
}
@{ 
    audit_name = "18.6.9.1 (L2) Ensure 'Turn on Mapper I/O (LLTDIO) driver' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD`" -Name `"AllowLLTDIOOnDomain,AllowLLTDIOOnPublicNet,EnableLLTDIO,ProhibitLLTDIOOnPrivateNet`""
}
@{ 
    audit_name = "18.6.9.2 (L2) Ensure 'Turn on Responder (RSPNDR) driver' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD`" -Name `"AllowRspndrOnDomain,AllowRspndrOnPublicNet,EnableRspndr,ProhibitRspndrOnPrivateNet`""
}
@{ 
    audit_name = "18.6.10.2 (L2) Ensure 'Turn off Microsoft Peer-to-Peer Networking Services' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Peernet`" -Name `"Disabled`""
}
@{ 
    audit_name = "18.6.11.2 (L1) Ensure 'Prohibit installation and configuration of Network Bridge on your DNS domain network' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections`" -Name `"NC_AllowNetBridge_NLA`""
}
@{ 
    audit_name = "18.6.11.3 (L1) Ensure 'Prohibit use of Internet Connection Sharing on your DNS domain network' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections`" -Name `"NC_ShowSharedAccessUI`""
}
@{ 
    audit_name = "18.6.14.1 (L1) Ensure 'Hardened UNC Paths' is set to 'Enabled, with Require Mutual Authentication, Require Integrity, and Require Privacy for NETLOGON and SYSVOL'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths`" -Name `"`""
}
@{ 
    audit_name = "18.6.19.2.1 (L2) Disable IPv6 (Ensure TCPIP6 Parameter 'DisabledComponents' is set to '0xff (255)')"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters`" -Name `"DisabledComponents`""
}
@{ 
    audit_name = "18.6.20.1 (L2) Ensure 'Configuration of wireless settings using Windows Connect Now' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars`" -Name `"EnableRegistrars,DisableUPnPRegistrar,DisableInBand802DOT11Registrar,DisableFlashConfigRegistrar,DisableFlashConfigRegistrar,DisableWPDRegistrar`""
}
@{ 
    audit_name = "18.6.20.2 (L2) Ensure 'Prohibit access of the Windows Connect Now wizards' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\UI`" -Name `"DisableWcnUi`""
}
@{ 
    audit_name = "18.6.21.1 (L1) Ensure 'Minimize the number of simultaneous connections to the Internet or a Windows Domain' is set to 'Enabled: 3 = Prevent Wi-Fi when on Ethernet' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy`" -Name `"fMinimizeConnections`""
}
@{ 
    audit_name = "18.6.23.2.1 (L1) Ensure 'Allow Windows to automatically connect to suggested open hotspots, to networks shared by contacts, and to hotspots offering paid services' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config`" -Name `"AutoConnectAllowedOEM`""
}
@{ 
    audit_name = "18.7.1 (L1) Ensure 'Allow Print Spooler to accept client connections' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers`" -Name `"RegisterSpoolerRemoteRpcEndPoint`""
}
@{ 
    audit_name = "18.7.2 (L1) Ensure 'Configure Redirection Guard' is set to 'Enabled: Redirection Guard Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers`" -Name `"RedirectionguardPolicy`""
}
@{ 
    audit_name = "18.7.3 (L1) Ensure 'Configure RPC connection settings: Protocol to use for outgoing RPC connections' is set to 'Enabled: RPC over TCP' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC`" -Name `"RpcUseNamedPipeProtocol`""
}
@{ 
    audit_name = "18.7.4 (L1) Ensure 'Configure RPC connection settings: Use authentication for outgoing RPC connections' is set to 'Enabled: Default' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC`" -Name `"RpcAuthentication`""
}
@{ 
    audit_name = "18.7.5 (L1) Ensure 'Configure RPC listener settings: Protocols to allow for incoming RPC connections' is set to 'Enabled: RPC over TCP' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC`" -Name `"RpcProtocols`""
}
@{ 
    audit_name = "18.7.6 (L1) Ensure 'Configure RPC listener settings: Authentication protocol to use for incoming RPC connections:' is set to 'Enabled: Negotiate' or higher (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC`" -Name `"ForceKerberosForRpc`""
}
@{ 
    audit_name = "18.7.7 (L1) Ensure 'Configure RPC over TCP port' is set to 'Enabled: 0' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC`" -Name `"RpcTcpPort`""
}
@{ 
    audit_name = "18.7.8 (L1) Ensure 'Limits print driver installation to Administrators' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint`" -Name `"RestrictDriverInstallationToAdministrators`""
}
@{ 
    audit_name = "18.7.9 (L1) Ensure 'Manage processing of Queue-specific files' is set to 'Enabled: Limit Queue-specific files to Color profiles' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers`" -Name `"CopyFilesPolicy`""
}
@{ 
    audit_name = "18.7.10 (L1) Ensure 'Point and Print Restrictions: When installing drivers for a new connection' is set to 'Enabled: Show warning and elevation prompt' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint`" -Name `"NoWarningNoElevationOnInstall`""
}
@{ 
    audit_name = "18.7.11 (L1) Ensure 'Point and Print Restrictions: When updating drivers for an existing connection' is set to 'Enabled: Show warning and elevation prompt' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint`" -Name `"UpdatePromptSettings`""
}
@{ 
    audit_name = "18.8.1.1 (L2) Ensure 'Turn off notifications network usage' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications`" -Name `"NoCloudApplicationNotification`""
}
@{ 
    audit_name = "18.9.3.1 (L1) Ensure 'Include command line in process creation events' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit`" -Name `"ProcessCreationIncludeCmdLine_Enabled`""
}
@{ 
    audit_name = "18.9.4.1 (L1) Ensure 'Encryption Oracle Remediation' is set to 'Enabled: Force Updated Clients' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters`" -Name `"AllowEncryptionOracle`""
}
@{ 
    audit_name = "18.9.4.2 (L1) Ensure 'Remote host allows delegation of non-exportable credentials' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation`" -Name `"AllowProtectedCreds`""
}
@{ 
    audit_name = "18.9.5.1 (NG) Ensure 'Turn On Virtualization Based Security' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard`" -Name `"EnableVirtualizationBasedSecurity`""
}
@{ 
    audit_name = "18.9.5.2 (NG) Ensure 'Turn On Virtualization Based Security: Select Platform Security Level' is set to 'Secure Boot' or higher (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard`" -Name `"RequirePlatformSecurityFeatures`""
}
@{ 
    audit_name = "18.9.5.3 (NG) Ensure 'Turn On Virtualization Based Security: Virtualization Based Protection of Code Integrity' is set to 'Enabled with UEFI lock' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard`" -Name `"HypervisorEnforcedCodeIntegrity`""
}
@{ 
    audit_name = "18.9.5.4 (NG) Ensure 'Turn On Virtualization Based Security: Require UEFI Memory Attributes Table' is set to 'True (checked)' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard`" -Name `"HVCIMATRequired`""
}
@{ 
    audit_name = "18.9.5.5 (NG) Ensure 'Turn On Virtualization Based Security: Credential Guard Configuration' is set to 'Enabled with UEFI lock' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard`" -Name `"LsaCfgFlags`""
}
@{ 
    audit_name = "18.9.5.6 (NG) Ensure 'Turn On Virtualization Based Security: Secure Launch Configuration' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard`" -Name `"ConfigureSystemGuardLaunch`""
}
@{ 
    audit_name = "18.9.7.1.1 (BL) Ensure 'Prevent installation of devices that match any of these device IDs' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions`" -Name `"DenyDeviceIDs`""
}
@{ 
    audit_name = "18.9.7.1.2 (BL) Ensure 'Prevent installation of devices that match any of these device IDs' is set to 'PCI\\CC_0C0A' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceIDs`" -Name `"1`""
}
@{ 
    audit_name = "18.9.7.1.3 (BL) Ensure 'Prevent installation of devices that match any of these device IDs: Also apply to matching devices that are already installed.' is set to 'True' (checked) (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions`" -Name `"DenyDeviceIDsRetroactive`""
}
@{ 
    audit_name = "18.9.7.1.4 (BL) Ensure 'Prevent installation of devices using drivers that match these device setup classes' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions`" -Name `"DenyDeviceClasses`""
}
@{ 
    audit_name = "18.9.7.1.5 (BL) Ensure 'Prevent installation of devices using drivers that match these device setup classes' is set to 'IEEE 1394 device setup classes' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceClasses`" -Name `"1,2,3,4`""
}
@{ 
    audit_name = "18.9.7.1.6 (BL) Ensure 'Prevent installation of devices using drivers that match these device setup classes: Also apply to matching devices that are already installed.' is set to 'True' (checked) (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions`" -Name `"DenyDeviceClassesRetroactive`""
}
@{ 
    audit_name = "18.9.7.2 (L1) Ensure 'Prevent device metadata retrieval from the Internet' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata`" -Name `"PreventDeviceMetadataFromNetwork`""
}
@{ 
    audit_name = "18.9.13.1 (L1) Ensure 'Boot-Start Driver Initialization Policy' is set to 'Enabled: Good, unknown and bad but critical' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Policies\EarlyLaunch`" -Name `"DriverLoadPolicy`""
}
@{ 
    audit_name = "18.9.19.2 (L1) Ensure 'Continue experiences on this device' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"EnableCdp`""
}
@{ 
    audit_name = "18.9.20.1.1 (L2) Ensure 'Turn off access to the Store' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer`" -Name `"NoUseStoreOpenWith`""
}
@{ 
    audit_name = "18.9.20.1.2 (L1) Ensure 'Turn off downloading of print drivers over HTTP' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers`" -Name `"DisableWebPnPDownload`""
}
@{ 
    audit_name = "18.9.20.1.3 (L2) Ensure 'Turn off handwriting personalization data sharing' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC`" -Name `"PreventHandwritingDataSharing`""
}
@{ 
    audit_name = "18.9.20.1.4 (L2) Ensure 'Turn off handwriting recognition error reporting' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports`" -Name `"PreventHandwritingErrorReports`""
}
@{ 
    audit_name = "18.9.20.1.5 (L2) Ensure 'Turn off Internet Connection Wizard if URL connection is referring to Microsoft.com' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Internet Connection Wizard`" -Name `"ExitOnMSICW`""
}
@{ 
    audit_name = "18.9.20.1.6 (L1) Ensure 'Turn off Internet download for Web publishing and online ordering wizards' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoWebServices`""
}
@{ 
    audit_name = "18.9.20.1.7 (L2) Ensure 'Turn off printing over HTTP' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers`" -Name `"DisableHTTPPrinting`""
}
@{ 
    audit_name = "18.9.20.1.8 (L2) Ensure 'Turn off Registration if URL connection is referring to Microsoft.com' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Registration Wizard Control`" -Name `"NoRegistration`""
}
@{ 
    audit_name = "18.9.20.1.9 (L2) Ensure 'Turn off Search Companion content file updates' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\SearchCompanion`" -Name `"DisableContentFileUpdates`""
}
@{ 
    audit_name = "18.9.20.1.10 (L2) Ensure 'Turn off the \Order Prints\`" picture task' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoOnlinePrintsWizard`""
}
@{ 
    audit_name = "18.9.20.1.11 (L2) Ensure 'Turn off the \Publish to Web\`" task for files and folders' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoPublishingWizard`""
}
@{ 
    audit_name = "18.9.20.1.12 (L2) Ensure 'Turn off the Windows Messenger Customer Experience Improvement Program' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Messenger\Client`" -Name `"CEIP`""
}
@{ 
    audit_name = "18.9.20.1.13 (L2) Ensure 'Turn off Windows Customer Experience Improvement Program' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows`" -Name `"CEIPEnable`""
}
@{ 
    audit_name = "18.9.20.1.14 (L2) Ensure 'Turn off Windows Error Reporting' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting`" -Name `"Disabled`""
}
@{ 
    audit_name = "18.9.20.1.14 (L2) Ensure 'Turn off Windows Error Reporting' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting`" -Name `"DoReport`""
}
@{ 
    audit_name = "18.9.23.1 (L2) Ensure 'Support device authentication using certificate' is set to 'Enabled: Automatic' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\kerberos\parameters`" -Name `"DevicePKInitBehavior,DevicePKInitEnabled`""
}
@{ 
    audit_name = "18.9.24.1 (BL) Ensure 'Enumeration policy for external devices incompatible with Kernel DMA Protection' is set to 'Enabled: Block All' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Kernel DMA Protection`" -Name `"DeviceEnumerationPolicy`""
}
@{ 
    audit_name = "18.9.26.1 (L1) Ensure 'Allow Custom SSPs and APs to be loaded into LSASS' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"AllowCustomSSPsAPs`""
}
@{ 
    audit_name = "18.9.26.2 (NG) Ensure 'Configures LSASS to run as a protected process' is set to 'Enabled: Enabled with UEFI Lock' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SYSTEM\CurrentControlSet\Control\Lsa`" -Name `"RunAsPPL`""
}
@{ 
    audit_name = "18.9.27.1 (L2) Ensure 'Disallow copying of user input methods to the system account for sign-in' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Control Panel\International`" -Name `"BlockUserInputMethodsForSignIn`""
}
@{ 
    audit_name = "18.9.28.1 (L1) Ensure 'Block user from showing account details on sign-in' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"BlockUserFromShowingAccountDetailsOnSignin`""
}
@{ 
    audit_name = "18.9.28.2 (L1) Ensure 'Do not display network selection UI' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"DontDisplayNetworkSelectionUI`""
}
@{ 
    audit_name = "18.9.28.3 (L1) Ensure 'Turn off app notifications on the lock screen' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"DisableLockScreenAppNotifications`""
}
@{ 
    audit_name = "18.9.28.4 (L1) Ensure 'Turn on convenience PIN sign-in' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"AllowDomainPINLogon`""
}
@{ 
    audit_name = "18.9.31.1 (L2) Ensure 'Allow Clipboard synchronization across devices' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"AllowCrossDeviceClipboard`""
}
@{ 
    audit_name = "18.9.31.2 (L2) Ensure 'Allow upload of User Activities' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"UploadUserActivities`""
}
@{ 
    audit_name = "18.9.33.6.1 (L1) Ensure 'Allow network connectivity during connected-standby (on battery)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9`" -Name `"DCSettingIndex`""
}
@{ 
    audit_name = "18.9.33.6.2 (L1) Ensure 'Allow network connectivity during connected-standby (plugged in)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9`" -Name `"ACSettingIndex`""
}
@{ 
    audit_name = "18.9.33.6.3 (BL) Ensure 'Allow standby states (S1-S3) when sleeping (on battery)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\abfc2519-3608-4c2a-94ea-171b0ed546ab`" -Name `"DCSettingIndex`""
}
@{ 
    audit_name = "18.9.33.6.4 (BL) Ensure 'Allow standby states (S1-S3) when sleeping (plugged in)' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\abfc2519-3608-4c2a-94ea-171b0ed546ab`" -Name `"ACSettingIndex`""
}
@{ 
    audit_name = "18.9.33.6.5 (L1) Ensure 'Require a password when a computer wakes (on battery)' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51`" -Name `"DCSettingIndex`""
}
@{ 
    audit_name = "18.9.33.6.6 (L1) Ensure 'Require a password when a computer wakes (plugged in)' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51`" -Name `"ACSettingIndex`""
}
@{ 
    audit_name = "18.9.35.1 (L1) Ensure 'Configure Offer Remote Assistance' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fAllowUnsolicited`""
}
@{ 
    audit_name = "18.9.35.2 (L1) Ensure 'Configure Solicited Remote Assistance' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fAllowToGetHelp`""
}
@{ 
    audit_name = "18.9.36.1 (L1) Ensure 'Enable RPC Endpoint Mapper Client Authentication' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Rpc`" -Name `"EnableAuthEpResolution`""
}
@{ 
    audit_name = "18.9.36.2 (L1) Ensure 'Restrict Unauthenticated RPC clients' is set to 'Enabled: Authenticated' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Rpc`" -Name `"RestrictRemoteClients`""
}
@{ 
    audit_name = "18.9.47.5.1 (L2) Ensure 'Microsoft Support Diagnostic Tool: Turn on MSDT interactive communication with support provider' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\ScriptedDiagnosticsProvider\Policy`" -Name `"DisableQueryRemoteServer`""
}
@{ 
    audit_name = "18.9.47.11.1 (L2) Ensure 'Enable/Disable PerfTrack' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}`" -Name `"ScenarioExecutionEnabled`""
}
@{ 
    audit_name = "18.9.49.1 (L2) Ensure 'Turn off the advertising ID' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo`" -Name `"DisabledByGroupPolicy`""
}
@{ 
    audit_name = "18.9.51.1.1 (L1) Ensure 'Enable Windows NTP Client' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\W32Time\TimeProviders\NtpClient`" -Name `"Enabled`""
}
@{ 
    audit_name = "18.10.3.1 (L2) Ensure 'Allow a Windows app to share application data between users' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\AppModel\StateManager`" -Name `"AllowSharedLocalAppData`""
}
@{ 
    audit_name = "18.10.3.2 (L1) Ensure 'Prevent non-admin users from installing packaged Windows apps' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx`" -Name `"BlockNonAdminUserInstall`""
}
@{ 
    audit_name = "18.10.4.1 (L1) Ensure 'Let Windows apps activate with voice while the system is locked' is set to 'Enabled: Force Deny' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy`" -Name `"LetAppsActivateWithVoiceAboveLock`""
}
@{ 
    audit_name = "18.10.5.1 (L1) Ensure 'Allow Microsoft accounts to be optional' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"MSAOptional`""
}
@{ 
    audit_name = "18.10.5.2 (L2) Ensure 'Block launching Universal Windows apps with Windows Runtime API access from hosted content.' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"BlockHostedAppAccessWinRT`""
}
@{ 
    audit_name = "18.10.7.1 (L1) Ensure 'Disallow Autoplay for non-volume devices' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer`" -Name `"NoAutoplayfornonVolume`""
}
@{ 
    audit_name = "18.10.7.2 (L1) Ensure 'Set the default behavior for AutoRun' is set to 'Enabled: Do not execute any autorun commands' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoAutorun`""
}
@{ 
    audit_name = "18.10.7.3 (L1) Ensure 'Turn off Autoplay' is set to 'Enabled: All drives' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoDriveTypeAutoRun`""
}
@{ 
    audit_name = "18.10.8.1.1 (L1) Ensure 'Configure enhanced anti-spoofing' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Biometrics\FacialFeatures`" -Name `"EnhancedAntiSpoofing`""
}
@{ 
    audit_name = "18.10.9.1.1 (BL) Ensure 'Allow access to BitLocker-protected fixed data drives from earlier versions of Windows' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVDiscoveryVolumeType`""
}
@{ 
    audit_name = "18.10.9.1.2 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVRecovery`""
}
@{ 
    audit_name = "18.10.9.1.3 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered: Allow data recovery agent' is set to 'Enabled: True'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVManageDRA`""
}
@{ 
    audit_name = "18.10.9.1.4 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered: Recovery Password' is set to 'Enabled: Allow 48-digit recovery password' or higher"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVRecoveryPassword`""
}
@{ 
    audit_name = "18.10.9.1.5 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered: Recovery Key' is set to 'Enabled: Allow 256-bit recovery key' or 'Enabled: Require 256-bit recovery key'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVRecoveryKey`""
}
@{ 
    audit_name = "18.10.9.1.6 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered: Omit recovery options from the BitLocker setup wizard' is set to 'Enabled: True'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVHideRecoveryPage`""
}
@{ 
    audit_name = "18.10.9.1.7 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered: Save BitLocker recovery information to AD DS for fixed data drives' is set to 'Enabled: False'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVActiveDirectoryBackup`""
}
@{ 
    audit_name = "18.10.9.1.8 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered: Configure storage of BitLocker recovery information to AD DS' is set to 'Enabled: Backup recovery passwords and key packages'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVActiveDirectoryInfoToStore`""
}
@{ 
    audit_name = "18.10.9.1.9 (BL) Ensure 'Choose how BitLocker-protected fixed drives can be recovered: Do not enable BitLocker until recovery information is stored to AD DS for fixed data drives' is set to 'Enabled: False'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVRequireActiveDirectoryBackup`""
}
@{ 
    audit_name = "18.10.9.1.10 (BL) Ensure 'Configure use of hardware-based encryption for fixed data drives' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVHardwareEncryption`""
}
@{ 
    audit_name = "18.10.9.1.11 (BL) Ensure 'Configure use of passwords for fixed data drives' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVPassphrase`""
}
@{ 
    audit_name = "18.10.9.1.12 (BL) Ensure 'Configure use of smart cards on fixed data drives' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVAllowUserCert`""
}
@{ 
    audit_name = "18.10.9.1.13 (BL) Ensure 'Configure use of smart cards on fixed data drives: Require use of smart cards on fixed data drives' is set to 'Enabled: True' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"FDVEnforceUserCert`""
}
@{ 
    audit_name = "18.10.9.2.1 (BL) Ensure 'Allow enhanced PINs for startup' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"UseEnhancedPin`""
}
@{ 
    audit_name = "18.10.9.2.2 (BL) Ensure 'Allow Secure Boot for integrity validation' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSAllowSecureBootForIntegrity`""
}
@{ 
    audit_name = "18.10.9.2.3 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSRecovery`""
}
@{ 
    audit_name = "18.10.9.2.4 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered: Allow data recovery agent' is set to 'Enabled: False'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSManageDRA`""
}
@{ 
    audit_name = "18.10.9.2.5 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered: Recovery Password' is set to 'Enabled: Require 48-digit recovery password'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSRecoveryPassword`""
}
@{ 
    audit_name = "18.10.9.2.6 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered: Recovery Key' is set to 'Enabled: Do not allow 256-bit recovery key'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSRecoveryKey`""
}
@{ 
    audit_name = "18.10.9.2.7 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered: Omit recovery options from the BitLocker setup wizard' is set to 'Enabled: True'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSHideRecoveryPage`""
}
@{ 
    audit_name = "18.10.9.2.8 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered: Save BitLocker recovery information to AD DS for operating system drives' is set to 'Enabled: True'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSActiveDirectoryBackup`""
}
@{ 
    audit_name = "18.10.9.2.9 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered: Configure storage of BitLocker recovery information to AD DS:' is set to 'Enabled: Store recovery passwords and key packages'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSActiveDirectoryInfoToStore`""
}
@{ 
    audit_name = "18.10.9.2.10 (BL) Ensure 'Choose how BitLocker-protected operating system drives can be recovered: Do not enable BitLocker until recovery information is stored to AD DS for operating system drives' is set to 'Enabled: True'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSRequireActiveDirectoryBackup`""
}
@{ 
    audit_name = "18.10.9.2.11 (BL) Ensure 'Configure use of hardware-based encryption for operating system drives' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSHardwareEncryption`""
}
@{ 
    audit_name = "18.10.9.2.12 (BL) Ensure 'Configure use of passwords for operating system drives' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"OSPassphrase`""
}
@{ 
    audit_name = "18.10.9.2.13 (BL) Ensure 'Require additional authentication at startup' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"UseAdvancedStartup`""
}
@{ 
    audit_name = "18.10.9.2.14 (BL) Ensure 'Require additional authentication at startup: Allow BitLocker without a compatible TPM' is set to 'Enabled: False' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"EnableBDEWithNoTPM`""
}
@{ 
    audit_name = "18.10.9.3.1 (BL) Ensure 'Allow access to BitLocker-protected removable data drives from earlier versions of Windows' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVDiscoveryVolumeType`""
}
@{ 
    audit_name = "18.10.9.3.2 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVRecovery`""
}
@{ 
    audit_name = "18.10.9.3.3 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered: Allow data recovery agent' is set to 'Enabled: True' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVManageDRA`""
}
@{ 
    audit_name = "18.10.9.3.4 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered: Recovery Password' is set to 'Enabled: Do not allow 48-digit recovery password' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVRecoveryPassword`""
}
@{ 
    audit_name = "18.10.9.3.5 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered: Recovery Key' is set to 'Enabled: Do not allow 256-bit recovery key' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVRecoveryKey`""
}
@{ 
    audit_name = "18.10.9.3.6 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered: Omit recovery options from the BitLocker setup wizard' is set to 'Enabled: True' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVHideRecoveryPage`""
}
@{ 
    audit_name = "18.10.9.3.7 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered: Save BitLocker recovery information to AD DS for removable data drives' is set to 'Enabled: False' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVActiveDirectoryBackup`""
}
@{ 
    audit_name = "18.10.9.3.8 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered: Configure storage of BitLocker recovery information to AD DS:' is set to 'Enabled: Backup recovery passwords and key packages' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVActiveDirectoryInfoToStore`""
}
@{ 
    audit_name = "18.10.9.3.9 (BL) Ensure 'Choose how BitLocker-protected removable drives can be recovered: Do not enable BitLocker until recovery information is stored to AD DS for removable data drives' is set to 'Enabled: False' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVRequireActiveDirectoryBackup`""
}
@{ 
    audit_name = "18.10.9.3.10 (BL) Ensure 'Configure use of hardware-based encryption for removable data drives' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVHardwareEncryption`""
}
@{ 
    audit_name = "18.10.9.3.11 (BL) Ensure 'Configure use of passwords for removable data drives' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVPassphrase`""
}
@{ 
    audit_name = "18.10.9.3.12 (BL) Ensure 'Configure use of smart cards on removable data drives' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVAllowUserCert`""
}
@{ 
    audit_name = "18.10.9.3.13 (BL) Ensure 'Configure use of smart cards on removable data drives: Require use of smart cards on removable data drives' is set to 'Enabled: True' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVEnforceUserCert`""
}
@{ 
    audit_name = "18.10.9.3.14 (BL) Ensure 'Deny write access to removable drives not protected by BitLocker' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE`" -Name `"RDVDenyWriteAccess`""
}
@{ 
    audit_name = "18.10.9.3.15 (BL) Ensure 'Deny write access to removable drives not protected by BitLocker: Do not allow write access to devices configured in another organization' is set to 'Enabled: False' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"RDVDenyCrossOrg`""
}
@{ 
    audit_name = "18.10.9.4 (BL) Ensure 'Disable new DMA devices when this computer is locked' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\FVE`" -Name `"DisableExternalDMAUnderLock`""
}
@{ 
    audit_name = "18.10.10.1 (L2) Ensure 'Allow Use of Camera' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Camera`" -Name `"AllowCamera`""
}
@{ 
    audit_name = "18.10.12.1 (L1) Ensure 'Turn off cloud consumer account state content' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent`" -Name `"DisableConsumerAccountStateContent`""
}
@{ 
    audit_name = "18.10.12.2 (L2) Ensure 'Turn off cloud optimized content' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent`" -Name `"DisableCloudOptimizedContent`""
}
@{ 
    audit_name = "18.10.12.3 (L1) Ensure 'Turn off Microsoft consumer experiences' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent`" -Name `"DisableWindowsConsumerFeatures`""
}
@{ 
    audit_name = "18.10.13.1 (L1) Ensure 'Require pin for pairing' is set to 'Enabled: First Time' OR 'Enabled: Always' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Connect`" -Name `"RequirePinForPairing`""
}
@{ 
    audit_name = "18.10.14.1 (L1) Ensure 'Do not display the password reveal button' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\CredUI`" -Name `"DisablePasswordReveal`""
}
@{ 
    audit_name = "18.10.14.2 (L1) Ensure 'Enumerate administrator accounts on elevation' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI`" -Name `"EnumerateAdministrators`""
}
@{ 
    audit_name = "18.10.14.3 (L1) Ensure 'Prevent the use of security questions for local accounts' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"NoLocalPasswordResetQuestions`""
}
@{ 
    audit_name = "18.10.15.1 (L1) Ensure 'Allow Diagnostic Data' is set to 'Enabled: Diagnostic data off (not recommended)' or 'Enabled: Send required diagnostic data'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`" -Name `"AllowTelemetry`""
}
@{ 
    audit_name = "18.10.15.2 (L2) Ensure 'Configure Authenticated Proxy usage for the Connected User Experience and Telemetry service' is set to 'Enabled: Disable Authenticated Proxy usage'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`" -Name `"DisableEnterpriseAuthProxy`""
}
@{ 
    audit_name = "18.10.15.3 (L1) Ensure 'Disable OneSettings Downloads' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`" -Name `"DisableOneSettingsDownloads`""
}
@{ 
    audit_name = "18.10.15.4 (L1) Ensure 'Do not show feedback notifications' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`" -Name `"DoNotShowFeedbackNotifications`""
}
@{ 
    audit_name = "18.10.15.5 (L1) Ensure 'Enable OneSettings Auditing' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`" -Name `"EnableOneSettingsAuditing`""
}
@{ 
    audit_name = "18.10.15.6 (L1) Ensure 'Limit Diagnostic Log Collection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`" -Name `"LimitDiagnosticLogCollection`""
}
@{ 
    audit_name = "18.10.15.7 (L1) Ensure 'Limit Dump Collection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`" -Name `"LimitDumpCollection`""
}
@{ 
    audit_name = "18.10.15.8 (L1) Ensure 'Toggle user control over Insider builds' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds`" -Name `"AllowBuildPreview`""
}
@{ 
    audit_name = "18.10.16.1 (L1) Ensure 'Download Mode' is NOT set to 'Enabled: Internet (3)'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization`" -Name `"DODownloadMode`""
}
@{ 
    audit_name = "18.10.17.1 (L1) Ensure 'Enable App Installer' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller`" -Name `"EnableAppInstaller`""
}
@{ 
    audit_name = "18.10.17.2 (L1) Ensure 'Enable App Installer Experimental Features' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller`" -Name `"EnableExperimentalFeatures`""
}
@{ 
    audit_name = "18.10.17.3 (L1) Ensure 'Enable App Installer Hash Override' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller`" -Name `"EnableHashOverride`""
}
@{ 
    audit_name = "18.10.17.4 (L1) Ensure 'Enable App Installer ms-appinstaller protocol' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppInstaller`" -Name `"EnableMSAppInstallerProtocol`""
}
@{ 
    audit_name = "18.10.25.1.1 (L1) Ensure 'Application: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Application`" -Name `"Retention`""
}
@{ 
    audit_name = "18.10.25.1.2 (L1) Ensure 'Application: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Application`" -Name `"MaxSize`""
}
@{ 
    audit_name = "18.10.25.2.1 (L1) Ensure 'Security: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security`" -Name `"Retention`""
}
@{ 
    audit_name = "18.10.25.2.2 (L1) Ensure 'Security: Specify the maximum log file size (KB)' is set to 'Enabled: 196,608 or greater'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security`" -Name `"MaxSize`""
}
@{ 
    audit_name = "18.10.25.3.1 (L1) Ensure 'Setup: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Setup`" -Name `"Retention`""
}
@{ 
    audit_name = "18.10.25.3.2 (L1) Ensure 'Setup: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\Setup`" -Name `"MaxSize`""
}
@{ 
    audit_name = "18.10.25.4.1 (L1) Ensure 'System: Control Event Log behavior when the log file reaches its maximum size' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\System`" -Name `"Retention`""
}
@{ 
    audit_name = "18.10.25.4.2 (L1) Ensure 'System: Specify the maximum log file size (KB)' is set to 'Enabled: 32,768 or greater'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\System`" -Name `"MaxSize`""
}
@{ 
    audit_name = "18.10.28.2 (L1) Ensure 'Turn off Data Execution Prevention for Explorer' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer`" -Name `"NoDataExecutionPrevention`""
}
@{ 
    audit_name = "18.10.28.3 (L1) Ensure 'Turn off heap termination on corruption' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer`" -Name `"NoHeapTerminationOnCorruption`""
}
@{ 
    audit_name = "18.10.28.4 (L1) Ensure 'Turn off shell protocol protected mode' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"PreXPSP2ShellProtocolBehavior`""
}
@{ 
    audit_name = "18.10.34.1 (L1) Ensure 'Disable Internet Explorer 11 as a standalone browser' is set to 'Enabled: Always'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\InternetExplorer\Main`" -Name `"NotifyDisableIEOptions`""
}
@{ 
    audit_name = "18.10.36.1 (L2) Ensure 'Turn off location' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors`" -Name `"DisableLocation`""
}
@{ 
    audit_name = "18.10.40.1 (L2) Ensure 'Allow Message Service Cloud Sync' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging`" -Name `"AllowMessageSync`""
}
@{ 
    audit_name = "18.10.41.1 (L1) Ensure 'Block all consumer Microsoft account user authentication' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\MicrosoftAccount`" -Name `"DisableUserAuth`""
}
@{ 
    audit_name = "18.10.42.5.1 (L1) Ensure 'Configure local setting override for reporting to Microsoft MAPS' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet`" -Name `"LocalSettingOverrideSpynetReporting`""
}
@{ 
    audit_name = "18.10.42.5.2 (L2) Ensure 'Join Microsoft MAPS' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet`" -Name `"SpynetReporting`""
}
@{ 
    audit_name = "18.10.42.6.1.1 (L1) Ensure 'Configure Attack Surface Reduction rules' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR`" -Name `"ExploitGuard_ASR_Rules`""
}
@{ 
    audit_name = "18.10.42.6.1.2 (L1) Ensure 'Configure Attack Surface Reduction rules: Set the state for each ASR rule' is configured"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules`" -Name `"26190899-1602-49e8-8b27-eb1d0a1ce869, 3b576869-a4ec-4529-8536-b80a7769e899, 56a863a9-875e-4185-98a7-b882c64b5ce5, 5beb7efe-fd9a-4556-801d-275e5ffc04cc, 75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84, 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c, 92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b, 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2, b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4, be9ba2d9-53ea-4cdc-84e5-9b1eeee46550, d3e037e1-3eb8-44c8-a917-57927947596d, d4f940ab-401b-4efc-aadc-ad5f3c50688a, e6db77e5-3df2-4cf1-b95a-636979351e5b`""
}
@{ 
    audit_name = "18.10.42.6.3.1 (L1) Ensure 'Prevent users and apps from accessing dangerous websites' is set to 'Enabled: Block'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection`" -Name `"EnableNetworkProtection`""
}
@{ 
    audit_name = "18.10.42.7.1 (L1) Ensure 'Enable file hash computation feature' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine`" -Name `"EnableFileHashComputation`""
}
@{ 
    audit_name = "18.10.42.10.1 (L1) Ensure 'Scan all downloaded files and attachments' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection`" -Name `"DisableIOAVProtection`""
}
@{ 
    audit_name = "18.10.42.10.2 (L1) Ensure 'Turn off real-time protection' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection`" -Name `"DisableRealtimeMonitoring`""
}
@{ 
    audit_name = "18.10.42.10.3 (L1) Ensure 'Turn on behavior monitoring' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection`" -Name `"DisableBehaviorMonitoring`""
}
@{ 
    audit_name = "18.10.42.10.4 (L1) Ensure 'Turn on script scanning' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection`" -Name `"DisableScriptScanning`""
}
@{ 
    audit_name = "18.10.42.12.1 (L2) Ensure 'Configure Watson events' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting`" -Name `"DisableGenericRePorts`""
}
@{ 
    audit_name = "18.10.42.13.1 (L1) Ensure 'Scan packed executables' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan`" -Name `"DisablePackedExeScanning`""
}
@{ 
    audit_name = "18.10.42.13.2 (L1) Ensure 'Scan removable drives' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan`" -Name `"DisableRemovableDriveScanning`""
}
@{ 
    audit_name = "18.10.42.13.3 (L1) Ensure 'Turn on e-mail scanning' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan`" -Name `"DisableEmailScanning`""
}
@{ 
    audit_name = "18.10.42.16 (L1) Ensure 'Configure detection for potentially unwanted applications' is set to 'Enabled: Block'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender`" -Name `"PUAProtection`""
}
@{ 
    audit_name = "18.10.42.17 (L1) Ensure 'Turn off Microsoft Defender AntiVirus' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender`" -Name `"DisableAntiSpyware`""
}
@{ 
    audit_name = "18.10.43.1 (NG) Ensure 'Allow auditing events in Microsoft Defender Application Guard' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\AppHVSI`" -Name `"AuditApplicationGuard`""
}
@{ 
    audit_name = "18.10.43.2 (NG) Ensure 'Allow camera and microphone access in Microsoft Defender Application Guard' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\AppHVSI`" -Name `"AllowCameraMicrophoneRedirection`""
}
@{ 
    audit_name = "18.10.43.3 (NG) Ensure 'Allow data persistence for Microsoft Defender Application Guard' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\AppHVSI`" -Name `"AllowPersistence`""
}
@{ 
    audit_name = "18.10.43.4 (NG) Ensure 'Allow files to download and save to the host operating system from Microsoft Defender Application Guard' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\AppHVSI`" -Name `"SaveFilesToHost`""
}
@{ 
    audit_name = "18.10.43.5 (NG) Ensure 'Configure Microsoft Defender Application Guard clipboard settings: Clipboard behavior setting' is set to 'Enabled: Enable clipboard operation from an isolated session to the host'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\AppHVSI`" -Name `"AppHVSIClipboardSettings`""
}
@{ 
    audit_name = "18.10.43.6 (NG) Ensure 'Turn on Microsoft Defender Application Guard in Managed Mode' is set to 'Enabled: 1'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\AppHVSI`" -Name `"AllowAppHVSI_ProviderSet`""
}
@{ 
    audit_name = "18.10.49.1 (L2) Ensure 'Enable news and interests on the taskbar' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds`" -Name `"EnableFeeds`""
}
@{ 
    audit_name = "18.10.50.1 (L1) Ensure 'Prevent the usage of OneDrive for file storage' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive`" -Name `"DisableFileSyncNGSC`""
}
@{ 
    audit_name = "18.10.55.1 (L2) Ensure 'Turn off Push To Install service' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall`" -Name `"DisablePushToInstall`""
}
@{ 
    audit_name = "18.10.56.2.2 (L1) Ensure 'Do not allow passwords to be saved' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"DisablePasswordSaving`""
}
@{ 
    audit_name = "18.10.56.3.2.1 (L2) Ensure 'Allow users to connect remotely by using Remote Desktop Services' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fDenyTSConnections`""
}
@{ 
    audit_name = "18.10.56.3.3.1 (L2) Ensure 'Allow UI Automation redirection' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"EnableUiaRedirection`""
}
@{ 
    audit_name = "18.10.56.3.3.2 (L2) Ensure 'Do not allow COM port redirection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fDisableCcm`""
}
@{ 
    audit_name = "18.10.56.3.3.3 (L1) Ensure 'Do not allow drive redirection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fDisableCdm`""
}
@{ 
    audit_name = "18.10.56.3.3.4 (L2) Ensure 'Do not allow location redirection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fDisableLocationRedir`""
}
@{ 
    audit_name = "18.10.56.3.3.5 (L2) Ensure 'Do not allow LPT port redirection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fDisableLPT`""
}
@{ 
    audit_name = "18.10.56.3.3.6 (L2) Ensure 'Do not allow supported Plug and Play device redirection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fDisablePNPRedir`""
}
@{ 
    audit_name = "18.10.56.3.3.7 (L2) Ensure 'Do not allow WebAuthn redirection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fDisableWebAuthn`""
}
@{ 
    audit_name = "18.10.56.3.9.1 (L1) Ensure 'Always prompt for password upon connection' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fPromptForPassword`""
}
@{ 
    audit_name = "18.10.56.3.9.2 (L1) Ensure 'Require secure RPC communication' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"fEncryptRPCTraffic`""
}
@{ 
    audit_name = "18.10.56.3.9.3 (L1) Ensure 'Require use of specific security layer for remote (RDP) connections' is set to 'Enabled: SSL'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"SecurityLayer`""
}
@{ 
    audit_name = "18.10.56.3.9.4 (L1) Ensure 'Require user authentication for remote connections by using Network Level Authentication' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"UserAuthentication`""
}
@{ 
    audit_name = "18.10.56.3.9.5 (L1) Ensure 'Set client connection encryption level' is set to 'Enabled: High Level'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"MinEncryptionLevel`""
}
@{ 
    audit_name = "18.10.56.3.10.1 (L2) Ensure 'Set time limit for active but idle Remote Desktop Services sessions' is set to 'Enabled: 15 minutes or less, but not Never (0)'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"MaxIdleTime`""
}
@{ 
    audit_name = "18.10.56.3.10.2 (L2) Ensure 'Set time limit for disconnected sessions' is set to 'Enabled: 1 minute'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"MaxDisconnectionTime`""
}
@{ 
    audit_name = "18.10.56.3.11.1 (L1) Ensure 'Do not delete temp folders upon exit' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services`" -Name `"DeleteTempDirsOnExit`""
}
@{ 
    audit_name = "18.10.57.1 (L1) Ensure 'Prevent downloading of enclosures' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Feeds`" -Name `"DisableEnclosureDownload`""
}
@{ 
    audit_name = "18.10.58.2 (L2) Ensure 'Allow Cloud Search' is set to 'Enabled: Disable Cloud Search'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`" -Name `"AllowCloudSearch`""
}
@{ 
    audit_name = "18.10.58.3 (L1) Ensure 'Allow Cortana' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`" -Name `"AllowCortana`""
}
@{ 
    audit_name = "18.10.58.4 (L1) Ensure 'Allow Cortana above lock screen' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`" -Name `"AllowCortanaAboveLock`""
}
@{ 
    audit_name = "18.10.58.5 (L1) Ensure 'Allow indexing of encrypted files' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`" -Name `"AllowIndexingEncryptedStoresOrItems`""
}
@{ 
    audit_name = "18.10.58.6 (L1) Ensure 'Allow search and Cortana to use location' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`" -Name `"AllowSearchToUseLocation`""
}
@{ 
    audit_name = "18.10.58.7 (L2) Ensure 'Allow search highlights' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`" -Name `"EnableDynamicContentInWSB`""
}
@{ 
    audit_name = "18.10.62.1 (L2) Ensure 'Turn off KMS Client Online AVS Validation' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform`" -Name `"NoGenTicket`""
}
@{ 
    audit_name = "18.10.65.1 (L2) Ensure 'Disable all apps from Microsoft Store' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`" -Name `"DisableStoreApps`""
}
@{ 
    audit_name = "18.10.65.2 (L1) Ensure 'Only display the private store within the Microsoft Store' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`" -Name `"RequirePrivateStoreOnly`""
}
@{ 
    audit_name = "18.10.65.3 (L1) Ensure 'Turn off Automatic Download and Install of updates' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`" -Name `"AutoDownload`""
}
@{ 
    audit_name = "18.10.65.4 (L1) Ensure 'Turn off the offer to update to the latest version of Windows' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`" -Name `"DisableOSUpgrade`""
}
@{ 
    audit_name = "18.10.65.5 (L2) Ensure 'Turn off the Store application' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`" -Name `"RemoveWindowsStore`""
}
@{ 
    audit_name = "18.10.71.1 (L1) Ensure 'Allow widgets' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Dsh`" -Name `"AllowNewsAndInterests`""
}
@{ 
    audit_name = "18.10.75.2.1 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"EnableSmartScreen`""
}
@{ 
    audit_name = "18.10.75.2.1 (L1) Ensure 'Configure Windows Defender SmartScreen' is set to 'Enabled: Warn and prevent bypass'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`" -Name `"ShellSmartScreenLevel`""
}
@{ 
    audit_name = "18.10.77.1 (L1) Ensure 'Enables or disables Windows Game Recording and Broadcasting' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR`" -Name `"AllowGameDVR`""
}
@{ 
    audit_name = "18.10.79.1 (L2) Ensure 'Allow suggested apps in Windows Ink Workspace' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace`" -Name `"AllowSuggestedAppsInWindowsInkWorkspace`""
}
@{ 
    audit_name = "18.10.79.2 (L1) Ensure 'Allow Windows Ink Workspace' is set to 'Enabled: On, but disallow access above lock' OR 'Enabled: Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace`" -Name `"AllowWindowsInkWorkspace`""
}
@{ 
    audit_name = "18.10.80.1 (L1) Ensure 'Allow user control over installs' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer`" -Name `"EnableUserControl`""
}
@{ 
    audit_name = "18.10.80.2 (L1) Ensure 'Always install with elevated privileges' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer`" -Name `"AlwaysInstallElevated`""
}
@{ 
    audit_name = "18.10.80.3 (L2) Ensure 'Prevent Internet Explorer security prompt for Windows Installer scripts' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer`" -Name `"SafeForScripting`""
}
@{ 
    audit_name = "18.10.81.1 (L1) Ensure 'Enable MPR notifications for the system' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"EnableMPR`""
}
@{ 
    audit_name = "18.10.81.2 (L1) Ensure 'Sign-in and lock last interactive user automatically after a restart' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"DisableAutomaticRestartSignOn`""
}
@{ 
    audit_name = "18.10.86.1 (L2) Ensure 'Turn on PowerShell Script Block Logging' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging`" -Name `"EnableScriptBlockLogging`""
}
@{ 
    audit_name = "18.10.86.2 (L2) Ensure 'Turn on PowerShell Transcription' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription`" -Name `"EnableTranscripting`""
}
@{ 
    audit_name = "18.10.88.1.1 (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client`" -Name `"AllowBasic`""
}
@{ 
    audit_name = "18.10.88.1.2 (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client`" -Name `"AllowUnencryptedTraffic`""
}
@{ 
    audit_name = "18.10.88.1.3 (L1) Ensure 'Disallow Digest authentication' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client`" -Name `"AllowDigest`""
}
@{ 
    audit_name = "18.10.88.2.1 (L1) Ensure 'Allow Basic authentication' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service`" -Name `"AllowBasic`""
}
@{ 
    audit_name = "18.10.88.2.2 (L2) Ensure 'Allow remote server management through WinRM' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service`" -Name `"AllowAutoConfig`""
}
@{ 
    audit_name = "18.10.88.2.3 (L1) Ensure 'Allow unencrypted traffic' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service`" -Name `"AllowUnencryptedTraffic`""
}
@{ 
    audit_name = "18.10.88.2.4 (L1) Ensure 'Disallow WinRM from storing RunAs credentials' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service`" -Name `"DisableRunAs`""
}
@{ 
    audit_name = "18.10.89.1 (L2) Ensure 'Allow Remote Shell Access' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\WinRS`" -Name `"AllowRemoteShellAccess`""
}
@{ 
    audit_name = "18.10.90.1 (L1) Ensure 'Allow clipboard sharing with Windows Sandbox' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sandbox`" -Name `"AllowClipboardRedirection`""
}
@{ 
    audit_name = "18.10.90.2 (L1) Ensure 'Allow networking in Windows Sandbox' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sandbox`" -Name `"AllowNetworking`""
}
@{ 
    audit_name = "18.10.91.2.1 (L1) Ensure 'Prevent users from modifying settings' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection`" -Name `"DisallowExploitProtectionOverride`""
}
@{ 
    audit_name = "18.10.92.1.1 (L1) Ensure 'No auto-restart with logged on users for scheduled automatic updates installations' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`" -Name `"NoAutoRebootWithLoggedOnUsers`""
}
@{ 
    audit_name = "18.10.92.2.1 (L1) Ensure 'Configure Automatic Updates' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`" -Name `"NoAutoUpdate`""
}
@{ 
    audit_name = "18.10.92.2.2 (L1) Ensure 'Configure Automatic Updates: Scheduled install day' is set to '0 - Every day'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`" -Name `"ScheduledInstallDay`""
}
@{ 
    audit_name = "18.10.92.2.3 (L1) Ensure 'Remove access to “Pause updates” feature' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`" -Name `"SetDisablePauseUXAccess`""
}
@{ 
    audit_name = "18.10.92.4.1 (L1) Ensure 'Manage preview builds' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`" -Name `"ManagePreviewBuildsPolicyValue`""
}
@{ 
    audit_name = "18.10.92.4.2 (L1) Ensure 'Select when Preview Builds and Feature Updates are received' is set to 'Enabled: 180 or more days'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`" -Name `"DeferFeatureUpdates,DeferFeatureUpdatesPeriodInDays`""
}
@{ 
    audit_name = "18.10.92.4.3 (L1) Ensure 'Select when Quality Updates are received' is set to 'Enabled: 0 days'"
    command = "Get-RegistryValueWithFallback -Path `"HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`" -Name `"DeferQualityUpdates,DeferQualityUpdatesPeriodInDays`""
}
@{ 
    audit_name = "19.5.1.1 (L1) Ensure 'Turn off toast notifications on the lock screen' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications`" -Name `"NoToastApplicationNotificationOnLockScreen`""
}
@{ 
    audit_name = "19.6.6.1.1 (L2) Ensure 'Turn off Help Experience Improvement Program' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\Assistance\Client\1.0`" -Name `"NoImplicitFeedback`""
}
@{ 
    audit_name = "19.7.5.1 (L1) Ensure 'Do not preserve zone information in file attachments' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments`" -Name `"SaveZoneInformation`""
}
@{ 
    audit_name = "19.7.5.2 (L1) Ensure 'Notify antivirus programs when opening attachments' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments`" -Name `"ScanWithAntiVirus`""
}
@{ 
    audit_name = "19.7.8.1 (L1) Ensure 'Configure Windows spotlight on lock screen' is set to 'Disabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\Windows\CloudContent`" -Name `"ConfigureWindowsSpotlight`""
}
@{ 
    audit_name = "19.7.8.2 (L1) Ensure 'Do not suggest third-party content in Windows spotlight' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\Windows\CloudContent`" -Name `"DisableThirdPartySuggestions`""
}
@{ 
    audit_name = "19.7.8.3 (L2) Ensure 'Do not use diagnostic data for tailored experiences' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\Windows\CloudContent`" -Name `"DisableTailoredExperiencesWithDiagnosticData`""
}
@{ 
    audit_name = "19.7.8.4 (L2) Ensure 'Turn off all Windows spotlight features' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\Windows\CloudContent`" -Name `"DisableWindowsSpotlightFeatures`""
}
@{ 
    audit_name = "19.7.8.5 (L1) Ensure 'Turn off Spotlight collection on Desktop' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\SOFTWARE\Policies\Microsoft\Windows\CloudContent`" -Name `"DisableSpotlightCollectionOnDesktop`""
}
@{ 
    audit_name = "19.7.26.1 (L1) Ensure 'Prevent users from sharing files within their profile.' is set to 'Enabled'"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoInplaceSharing`""
}
@{ 
    audit_name = "19.7.42.1 (L1) Ensure 'Always install with elevated privileges' is set to 'Disabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\Windows\Installer`" -Name `"AlwaysInstallElevated`""
}
@{ 
    audit_name = "19.7.44.2.1 (L2) Ensure 'Prevent Codec Download' is set to 'Enabled' (Automated)"
    command = "Get-RegistryValueWithFallback -Path `"Registry::HKU\$currentUserSid\Software\Policies\Microsoft\WindowsMediaPlayer`" -Name `"PreventCodecDownload`""
}
)

$results = @()

foreach ($item in $queries) {
    try {
        $queryResult = Invoke-Expression $item.command
    } catch {
        $queryResult = @{ "Error" = $_.Exception.Message }
    }
    $results += [PSCustomObject]@{
        audit_name = $item.audit_name
        command    = $item.command
        result     = $queryResult
    }
}

# Convert results to JSON and save to file
$json = $results | ConvertTo-Json -Depth 5
$json = $json -replace '\u0027', "'"

$outputFullPath = [System.IO.Path]::GetFullPath("D:\DES\DSEC360-\backend\DSEC\startScan\Configuration_Audit\Windows\Output\Microsoft_Windows_11_Stand-alone_v3.0.0_output.json")
[System.IO.File]::WriteAllText($outputFullPath, $json, [System.Text.Encoding]::UTF8)

Write-Host "Output successfully written to: $outputFullPath"
