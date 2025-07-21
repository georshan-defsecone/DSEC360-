-- Generated SQL script with JSON output for MariaDB/MySQL

SELECT JSON_ARRAYAGG(JSON_OBJECT('Name', Name, 'Result', Result)) AS AllResults
FROM (
SELECT '2_1_5_Point_in_Time_Recovery_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE, 'Note', Note)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE, 'BINLOG - Log Expiration' as Note  FROM information_schema.global_variables where variable_name = 'binlog_expire_logs_seconds') t
  ) AS Result
UNION ALL
SELECT '2_9_Ensure_MariaDB_is_Bound_to_an_IP_Address_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'bind_address') t
  ) AS Result
UNION ALL
SELECT '2_10_Limit_Accepted_Transport_Layer_Security_TLS_Versions_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('value', value)) FROM (select @@tls_version AS value) t
  ) AS Result
UNION ALL
SELECT '2_11_Require_Client_Side_Certificates_X_509_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('user', user, 'host', host, 'ssl_type', ssl_type)) FROM (select user, host, ssl_type from mysql.user where user not in ('mysql', 'root', 'mariadb.sys')) t
  ) AS Result
UNION ALL
SELECT '2_12_Ensure_Only_Approved_Ciphers_are_Used_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'ssl_cipher') t
  ) AS Result
UNION ALL
SELECT '4_6_Ensure_Symbolic_Links_are_Disabled_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE 'have_symlink') t
  ) AS Result
UNION ALL
SELECT '4_7_Ensure_the_secure_file_priv_is_Configured_Correctly_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'secure_file_priv') t
  ) AS Result
UNION ALL
SELECT '4_8_Ensure_sql_mode_Contains_STRICT_ALL_TABLES_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE 'sql_mode') t
  ) AS Result
UNION ALL
SELECT '6_1_Ensure_log_error_is_configured_correctly_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE 'log_error') t
  ) AS Result
UNION ALL
SELECT '6_2_Ensure_Log_Files_are_Stored_on_a_Non_System_Partition_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('value', value)) FROM (SELECT @@global.log_bin_basename AS value) t
  ) AS Result
UNION ALL
SELECT '6_3_Ensure_log_warnings_is_Set_to_2_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE 'log_warnings') t
  ) AS Result
UNION ALL
SELECT '6_4_Ensure_Audit_Logging_Is_Enabled_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE '%audit%') t
  ) AS Result
UNION ALL
SELECT '6_5_Ensure_the_Audit_Plugin_Can_t_be_Unloaded_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('LOAD_OPTION', LOAD_OPTION)) FROM (SELECT LOAD_OPTION FROM information_schema.plugins WHERE PLUGIN_NAME='SERVER_AUDIT') t
  ) AS Result
UNION ALL
SELECT '6_6_Ensure_Binary_and_Relay_Logs_are_Encrypted_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE, 'Note', Note)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE, 'BINLOG - At Rest Encryption' as Note FROM information_schema.global_variables where variable_name like '%ENCRYPT_LOG%') t
  ) AS Result
UNION ALL
SELECT '7_3_Ensure_strong_authentication_is_utilized_for_all_accounts_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('User', User, 'host', host)) FROM (SELECT User,host FROM mysql.user WHERE (plugin IN('mysql_native_password', 'mysql_old_password','') AND NOT (User = 'root' AND authentication_string = 'invalid') AND NOT (User = 'mysql' and authentication_string = 'invalid'))) t
  ) AS Result
UNION ALL
SELECT '7_5_Ensure_No_Users_Have_Wildcard_Hostnames_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('user', user, 'host', host)) FROM (SELECT user, host FROM mysql.user WHERE host = '%') t
  ) AS Result
UNION ALL
SELECT '7_6_Ensure_No_Anonymous_Accounts_Exist_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('user', user, 'host', host)) FROM (SELECT user,host FROM mysql.user WHERE user = '') t
  ) AS Result
UNION ALL
SELECT '8_2_Ensure_ssl_type_is_Set_to_ANY_X509_or_SPECIFIED_for_All_Remote_Users_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('user', user, 'host', host, 'ssl_type', ssl_type)) FROM (SELECT user, host, ssl_type FROM mysql.user WHERE NOT HOST IN ('::1', '127.0.0.1', 'localhost')) t
  ) AS Result
UNION ALL
SELECT '4_4_Harden_Usage_for_local_infile_on_MariaDB_Clients_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE 'version'
UNION ALL
SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'local_infile') t
  ) AS Result
UNION ALL
SELECT '4_9_Enable_data_at_rest_encryption_in_MariaDB_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables where variable_name like '%ENCRYPT%'
UNION ALL
SELECT SPACE,NAME FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION) t
  ) AS Result
UNION ALL
SELECT '7_1_Disable_use_of_the_mysql_old_password_plugin_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'old_passwords'
UNION ALL
SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'secure_auth') t
  ) AS Result
UNION ALL
SELECT '7_4_Ensure_Password_Complexity_Policies_are_in_Place_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('PLUGIN_NAME', PLUGIN_NAME, 'PLUGIN_STATUS', PLUGIN_STATUS)) FROM (SELECT PLUGIN_NAME, PLUGIN_STATUS FROM information_schema.plugins WHERE PLUGIN_NAME IN ('simple_password_check', 'cracklib_password_check')
UNION ALL
SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME LIKE '%pass%') t
  ) AS Result
UNION ALL
SELECT '8_1_Ensure_require_secure_transport_is_Set_to_ON_and_have_ssl_is_Set_to_YES_Automated_' AS Name,
  (
    SELECT JSON_ARRAYAGG(JSON_OBJECT('VARIABLE_NAME', VARIABLE_NAME, 'VARIABLE_VALUE', VARIABLE_VALUE)) FROM (SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'require_secure_transport'
UNION ALL
SELECT VARIABLE_NAME, VARIABLE_VALUE FROM information_schema.global_variables WHERE VARIABLE_NAME = 'have_ssl') t
  ) AS Result
) results;
