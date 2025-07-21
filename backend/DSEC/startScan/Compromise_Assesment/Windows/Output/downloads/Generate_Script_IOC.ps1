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
    @{"Name"="Schedule Task"; "Command"={ # --- Scheduled_Tasks_Info (EXE-based scheduled tasks, paths, status, permissions, hash) ---

$taskList = @()

# Retrieve all scheduled tasks
$tasks = Get-ScheduledTask

foreach ($task in $tasks) {
    try {
        # Get task status info
        $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath

        # Filter to include only EXE-based actions
        $actions = $task.Actions | Where-Object { $_.Execute -match "\.exe$" }

        foreach ($action in $actions) {
            $exePath = $action.Execute
            $resolvedPath = $exePath

            # Attempt to resolve relative paths (e.g., just "cmd.exe" to full path)
            if (-not (Test-Path $resolvedPath)) {
                $resolvedPath = (Get-Command $exePath -ErrorAction SilentlyContinue)?.Source
            }

            # Initialize default values
            $fileHash = "N/A"
            $permissions = "N/A"

            # Get SHA256 hash
            if ($resolvedPath -and (Test-Path $resolvedPath)) {
                try {
                    $fileHash = (Get-FileHash -Path $resolvedPath -Algorithm SHA256).Hash
                } catch {
                    $fileHash = "Hash Error"
                }

                # Get permissions
                try {
                    $acl = Get-Acl -Path $resolvedPath
                    $permissions = ($acl.Access | ForEach-Object {
                        "$($_.IdentityReference):$($_.FileSystemRights)"
                    }) -join "; "
                } catch {
                    $permissions = "Permission Error"
                }
            }

            # Add to results
            $taskList += [PSCustomObject]@{
                TaskName    = $task.TaskName
                TaskPath    = $task.TaskPath
                Execute     = $exePath
                Arguments   = $action.Arguments
                WorkingDir  = $action.WorkingDirectory
                LastRunTime = $taskInfo.LastRunTime
                NextRunTime = $taskInfo.NextRunTime
                Status      = $taskInfo.State
                Hash        = $fileHash
                Permissions = $permissions
            }
        }
    } catch {
        Write-Warning "⚠️ Failed to retrieve info for task: $($task.TaskName)"
    }
}

# Return array; Run_Check wrapper stores it in $results["Scheduled_Tasks_Info"]
$taskList } }

)

foreach ($check in $selectedChecks) {
    Run_Check -Name $check.Name -Command $check.Command
}

# Export Results to JSON
$outputPath = "IOCoutput.json"
$results | ConvertTo-Json -Depth 5 | Out-File $outputPath -Encoding UTF8

Write-Host "`nAll checks completed. Results saved to: $outputPath"
