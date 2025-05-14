param (
    [string]$pgVersion = "16.3",       # PostgreSQL version to install
    [string]$pgUser = "dsec360",
    [string]$pgPassword = "dsec360@123",
    [string]$pgDb = "dsec360",
    [string]$postgresPassword = "dsec360@123"  # superuser password for postgres
)

# Derived values
$majorVersion = $pgVersion.Split(".")[0]
$installerUrl = "https://get.enterprisedb.com/postgresql/postgresql-$pgVersion-1-windows-x64.exe"
$installerPath = "$env:TEMP\postgres_installer.exe"
$pgInstallDir = "C:\Program Files\PostgreSQL\$majorVersion"
$pgDataDir = "$pgInstallDir\data"
$psqlPath = "$pgInstallDir\bin\psql.exe"

# Check if psql exists
if (-Not (Test-Path $psqlPath)) {
    Write-Host "PostgreSQL $pgVersion not found. Downloading installer..."

    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

    Write-Host "Installing PostgreSQL silently..."
    Start-Process -FilePath $installerPath -ArgumentList `
        "--mode unattended",
        "--superpassword $postgresPassword",
        "--servicename postgresql-$majorVersion",
        "--serviceaccountpassword $postgresPassword",
        "--prefix `"$pgInstallDir`"" -Wait

    Write-Host "PostgreSQL installation complete."
} else {
    Write-Host "PostgreSQL is already installed."
}

# Wait for service to start
Start-Sleep -Seconds 5
$env:Path += ";$pgInstallDir\bin"

# Create user and database SQL
$sql = @"
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$pgUser') THEN
        CREATE ROLE $pgUser WITH LOGIN PASSWORD '$pgPassword';
    END IF;
END
\$\$;

CREATE DATABASE $pgDb OWNER $pgUser;
GRANT ALL PRIVILEGES ON DATABASE $pgDb TO $pgUser;
ALTER ROLE $pgUser CREATEDB;
"@

$sqlFile = "$env:TEMP\init_pg.sql"
$sql | Out-File -FilePath $sqlFile -Encoding UTF8

& "$psqlPath" -U postgres -d postgres -f $sqlFile -v ON_ERROR_STOP=1 --username=postgres --no-password

# Modify pg_hba.conf to use md5
$pgHbaPath = "$pgDataDir\pg_hba.conf"

(Get-Content $pgHbaPath) -replace '^(host\s+all\s+all\s+127\.0\.0\.1/32\s+)\w+', '${1}md5' |
    Set-Content $pgHbaPath
(Get-Content $pgHbaPath) -replace '^(host\s+all\s+all\s+::1/128\s+)\w+', '${1}md5' |
    Set-Content $pgHbaPath

# Restart PostgreSQL service
Write-Host "Restarting PostgreSQL service..."
Restart-Service -Name "postgresql-$majorVersion"

Write-Host "✅ PostgreSQL setup complete!"
Write-Host "You can connect using:"
Write-Host "`"$psqlPath -U $pgUser -d $pgDb`""
