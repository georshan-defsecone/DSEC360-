import pandas as pd
import re
import os

def generate_powershell_script(excel_path, output_ps1_path, excluded_controls, audit_method):
    """
    Generates a PowerShell script based on user-selected IOC scripts from an Excel file.

    Parameters:
    excel_path (str): Path to the Excel file containing IOC scripts.
    output_ps1_path (str): Path where the generated PowerShell script will be saved.
    """
    # Load Excel
    df = pd.read_excel(excel_path)
    df.columns = df.columns.str.strip().str.lower()

    # Clean excluded query names (ensure they are all strings and lowercase)
    excluded_controls_cleaned = [str(q).strip().lower() for q in excluded_controls if q is not None]

    # Define a safe filtering function to handle NaN or non-string values in Excel
    def is_not_excluded(x):
        if pd.isnull(x):
            return False  # Skip NaN values
        return str(x).strip().lower() not in excluded_controls_cleaned

    # Filter the DataFrame to exclude unchecked items
    included_df = df[df['name'].apply(is_not_excluded)]
    print("Included queries: ", included_df['name'].tolist())


    print("Excluded Queries: ", excluded_controls_cleaned)
    print("Available Queries: ", df['name'].dropna().str.strip().str.lower().tolist())
    print("Excel names:", list(df['name'].dropna().str.strip().str.lower()))
    print("Excluded names:", excluded_controls_cleaned)

    if included_df.empty:
        raise ValueError("No scripts to include after exclusion.")

    output_json_name = "IOCoutput.json"
    output_json_path = os.path.join(os.path.dirname(output_ps1_path), output_json_name)

    # PowerShell Template
    ps_code = """\
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
"""

    # Add the remaining (included) scripts
    for index, row in included_df.iterrows():
        name = row['name']
        raw_script = row['script']
        script_code = str(raw_script).strip().replace('"', '\"')  # Safe casting to string
        ps_code += f'    @{{"Name"="{name}"; "Command"={{ {script_code} }} }}\n'

    ps_code += """
)

foreach ($check in $selectedChecks) {
    Run_Check -Name $check.Name -Command $check.Command
}

# Export Results to JSON
$outputPath = "IOCoutput.json"
$results | ConvertTo-Json -Depth 5 | Out-File $outputPath -Encoding UTF8

Write-Host "`nAll checks completed. Results saved to: $outputPath"
"""

    # Write PowerShell script to file
    with open(output_ps1_path, "w", encoding="utf-8") as f:
        f.write(ps_code)

    print(f"\nPowerShell script generated: {output_ps1_path}")
    if audit_method.lower() == 'agent':
        print(f"Results will be saved to: {output_json_path}")
