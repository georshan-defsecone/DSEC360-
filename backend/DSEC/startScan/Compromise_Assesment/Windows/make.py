import pandas as pd
import re

def generate_powershell_script(excel_path, output_ps1_path, excluded_controls):
    """
    Generates a PowerShell script based on user-selected IOC scripts from an Excel file.

    Parameters:
    excel_path (str): Path to the Excel file containing IOC scripts.
    output_ps1_path (str): Path where the generated PowerShell script will be saved.
    """
    # Load Excel
    df = pd.read_excel(excel_path)
    df.columns = df.columns.str.strip().str.lower()
    # Clean excluded query names (trim whitespace and lowercase for comparison)
    excluded_controls_cleaned = [q.strip().lower() for q in excluded_controls]
    

    # Filter the DataFrame to exclude selected scripts
    included_df = df[df['name'].apply(lambda x: x.strip().lower() not in excluded_controls_cleaned)]

    print("Excluded Queries: ", excluded_controls_cleaned)
    print("Available Queries: ", df['name'].str.strip().str.lower().tolist())
    print("Excel names:", list(df['name'].str.strip().str.lower()))
    print("Excluded names:", excluded_controls_cleaned)


    if included_df.empty:
        raise ValueError("No scripts to include after exclusion.")
    
    # PowerShell Template
    ps_code = """\
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
"""

    # Add the remaining (included) scripts
    for index, row in included_df.iterrows():
        name = row['name']
        raw_script = row['script']
        script_code = raw_script.strip().replace('"', '\"')
        ps_code += f'    @{{"Name"="{name}"; "Command"={{ {script_code} }} }}\n'

    ps_code += """
)

foreach ($check in $selectedChecks) {
    Run_Check -Name $check.Name -Command $check.Command
}

# Export Results to JSON
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = "results_$timestamp.json"
$results | ConvertTo-Json -Depth 3 | Out-File $outputPath -Encoding UTF8

Write-Host "`nAll checks completed. Results saved to: $outputPath"
"""

    # Write PowerShell script to file
    with open(output_ps1_path, "w", encoding="utf-8") as f:
        f.write(ps_code)

    print(f"\nPowerShell script generated: {output_ps1_path}")