SET TEXTSIZE 2147483647;
DECLARE @results TABLE (
    Name NVARCHAR(255),
    Result NVARCHAR(MAX)
);

INSERT INTO @results (Name, Result)
SELECT '2.1 Ensure ''Ad Hoc Distributed Queries'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Ad Hoc Distributed Queries'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.2 Ensure ''CLR Enabled'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'clr enabled'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.3 Ensure ''Cross DB Ownership Chaining'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'cross db ownership chaining'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.4 Ensure ''Database Mail XPs'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Database Mail XPs'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.5 Ensure ''Ole Automation Procedures'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'Ole Automation Procedures'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.6 Ensure ''Remote Access'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'remote access'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.7 Ensure ''Remote Admin Connections'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'remote admin connections' AND SERVERPROPERTY('IsClustered') = 0
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.8 Ensure ''Scan For Startup Procs'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'scan for startup procs'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.9 Ensure ''Trustworthy'' Database Property is set to ''Off'' (Automated)', (
    SELECT * FROM (
        SELECT name FROM sys.databases WHERE is_trustworthy_on = 1 AND name != 'msdb'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.11 Ensure SQL Server is configured to use non-standard ports (Automated)', (
    SELECT * FROM (
        SELECT COUNT(*) AS Count FROM sys.dm_server_registry WHERE value_name like '%Tcp%' and value_data='1433'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.13 Ensure the ''sa'' Login Account is set to ''Disabled'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(is_disabled AS INT) AS is_disabled FROM sys.server_principals WHERE sid = 0x01 AND is_disabled = 0
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.15 Ensure ''xp_cmdshell'' Server Configuration Option is set to ''0'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'xp_cmdshell'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.16 Ensure ''AUTO_CLOSE'' is set to ''OFF'' on contained databases (Automated)', (
    SELECT * FROM (
        SELECT name, containment, containment_desc, CAST(is_auto_close_on AS INT) AS is_auto_close_on FROM sys.databases WHERE containment <> 0 and is_auto_close_on = 1
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.17 Ensure no login exists with the name ''sa'' (Automated)', (
    SELECT * FROM (
        SELECT principal_id, name FROM sys.server_principals WHERE name = 'sa'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '2.18 Ensure ''clr strict security'' Server Configuration Option is set to ''1'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'clr strict security'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '3.1 Ensure ''Server Authentication'' Property is set to ''Windows Authentication Mode'' (Automated)', (
    SELECT * FROM (
        SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') as [login_mode]
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '3.4 Ensure SQL Authentication is not used in contained databases (Automated)', (
    SELECT * FROM (
        SELECT name AS DBUser FROM sys.database_principals WHERE name NOT IN ('dbo','Information_Schema','sys','guest') AND type IN ('U','S','G') AND authentication_type = 2
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '3.8 Ensure only the default permissions specified by Microsoft are granted to the public server role (Automated)', (
    SELECT * FROM (
        SELECT * FROM master.sys.server_permissions WHERE (grantee_principal_id = SUSER_SID(N'public') and state_desc LIKE 'GRANT%') AND NOT (state_desc = 'GRANT' and [permission_name] = 'VIEW ANY DATABASE' and class_desc = 'SERVER') AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 2) AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 3) AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 4) AND NOT (state_desc = 'GRANT' and [permission_name] = 'CONNECT' and class_desc = 'ENDPOINT' and major_id = 5)
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '4.3 Ensure ''CHECK_POLICY'' Option is set to ''ON'' for All SQL Authenticated Logins (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(is_disabled AS INT) AS is_disabled FROM sys.sql_logins WHERE is_policy_checked = 0
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '5.2 Ensure ''Default Trace Enabled'' Server Configuration Option is set to ''1'' (Automated)', (
    SELECT * FROM (
        SELECT name, CAST(value as int) as value_configured, CAST(value_in_use as int) as value_in_use FROM sys.configurations WHERE name = 'default trace enabled'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '7.3 Ensure Database Backups are Encrypted (Automated)', (
    SELECT * FROM (
        SELECT b.key_algorithm, b.encryptor_type, CAST(d.is_encrypted AS INT) AS is_encrypted, b.database_name, b.server_name FROM msdb.dbo.backupset b inner join sys.databases d on b.database_name = d.name where b.key_algorithm IS NULL AND b.encryptor_type IS NULL AND d.is_encrypted = 0
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

INSERT INTO @results (Name, Result)
SELECT '7.5 Ensure Databases are Encrypted with TDE (Automated)', (
    SELECT * FROM (
        select database_id, name, CAST(is_encrypted AS INT) AS is_encrypted from sys.databases where database_id > 4 and is_encrypted != 1
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

USE [master];
INSERT INTO @results (Name, Result)
SELECT '3.10 Ensure Windows local groups are not SQL Logins (Automated)', (
    SELECT * FROM (
        SELECT pr.[name] AS LocalGroupName, pe.[permission_name], pe.[state_desc] FROM sys.server_principals pr JOIN sys.server_permissions pe ON pr.[principal_id] = pe.[grantee_principal_id] WHERE pr.[type_desc] = 'WINDOWS_GROUP' AND pr.[name] like CAST(SERVERPROPERTY('MachineName') AS nvarchar) + '%'
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

USE [msdb];
INSERT INTO @results (Name, Result)
SELECT '3.11 Ensure the public role in the msdb database is not granted access to SQL Agent proxies (Automated)', (
    SELECT * FROM (
        SELECT sp.name AS proxyname FROM dbo.sysproxylogin spl JOIN sys.database_principals dp ON dp.sid = spl.sid JOIN sysproxies sp ON sp.proxy_id = spl.proxy_id WHERE principal_id = USER_ID('public')
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

DECLARE @getValue INT;
EXEC master.sys.xp_instance_regread @rootkey = N'HKEY_LOCAL_MACHINE', @key = N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib', @value_name = N'HideInstance', @value = @getValue OUTPUT;
INSERT INTO @results (Name, Result)
SELECT '2.12 Ensure ''Hide Instance'' option is set to ''Yes'' for Production SQL Server instances (Automated)', (
    SELECT * FROM (
        SELECT @getValue as hideinstance
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

DECLARE @NumErrorLogs int;
EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', @NumErrorLogs OUTPUT;
INSERT INTO @results (Name, Result)
SELECT '5.1 Ensure ''Maximum number of error log files'' is set to greater than or equal to ''12'' (Automated)', (
    SELECT * FROM (
        SELECT ISNULL(@NumErrorLogs, -1) AS [NumberOfLogFiles]
    ) AS src FOR JSON PATH, INCLUDE_NULL_VALUES
);

SELECT Name, ISNULL(JSON_QUERY(Result), 'null') AS Result FROM @results FOR JSON PATH;
