-- Generated Oracle SQL script with JSON output and dynamic SQL error handling

SET SERVEROUTPUT ON SIZE UNLIMITED;


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'#  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_1_Ensure_AUDIT_SYS_OPERATIONS_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT('value' VALUE value))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME) = 'AUDIT_SYS_OPERATIONS'
        )
      #';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_1_Ensure_AUDIT_SYS_OPERATIONS_Is_Set_to_TRUE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_2_Ensure_AUDIT_TRAIL_Is_Set_to_DB_XML_OS_DB_EXTENDED_or_XML_EXTENDED_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='AUDIT_TRAIL'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_2_Ensure_AUDIT_TRAIL_Is_Set_to_DB_XML_OS_DB_EXTENDED_or_XML_EXTENDED_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_3_Ensure_GLOBAL_NAMES_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT UPPER(V.VALUE) AS value, DECODE(V.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE V.CON_ID = B.CON_ID)) AS db_name FROM V$SYSTEM_PARAMETER V WHERE UPPER(NAME) = 'GLOBAL_NAMES'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_3_Ensure_GLOBAL_NAMES_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='GLOBAL_NAMES'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_3_Ensure_GLOBAL_NAMES_Is_Set_to_TRUE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_4_Ensure_O7_DICTIONARY_ACCESSIBILITY_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT UPPER(V.VALUE) AS value, DECODE(V.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE V.CON_ID = B.CON_ID)) AS db_name FROM V$SYSTEM_PARAMETER V WHERE UPPER(NAME) = 'O7_DICTIONARY_ACCESSIBILITY'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_4_Ensure_O7_DICTIONARY_ACCESSIBILITY_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='O7_DICTIONARY_ACCESSIBILITY'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_4_Ensure_O7_DICTIONARY_ACCESSIBILITY_Is_Set_to_FALSE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_5_Ensure_OS_ROLES_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT UPPER(V.VALUE) AS value, DECODE(V.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE V.CON_ID = B.CON_ID)) AS db_name FROM V$SYSTEM_PARAMETER V WHERE UPPER(NAME) = 'OS_ROLES'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_5_Ensure_OS_ROLES_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='OS_ROLES'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_5_Ensure_OS_ROLES_Is_Set_to_FALSE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_6_Ensure_REMOTE_LISTENER_Is_Empty_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT UPPER(V.VALUE) AS value, DECODE(V.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE V.CON_ID = B.CON_ID)) AS db_name FROM V$SYSTEM_PARAMETER V WHERE UPPER(NAME) = 'REMOTE_LISTENER'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_6_Ensure_REMOTE_LISTENER_Is_Empty_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='REMOTE_LISTENER'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_6_Ensure_REMOTE_LISTENER_Is_Empty_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_7_Ensure_REMOTE_LOGIN_PASSWORDFILE_Is_Set_to_NONE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='REMOTE_LOGIN_PASSWORDFILE'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_7_Ensure_REMOTE_LOGIN_PASSWORDFILE_Is_Set_to_NONE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_8_Ensure_REMOTE_OS_AUTHENT_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='REMOTE_OS_AUTHENT'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_8_Ensure_REMOTE_OS_AUTHENT_Is_Set_to_FALSE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_9_Ensure_REMOTE_OS_ROLES_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='REMOTE_OS_ROLES'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_9_Ensure_REMOTE_OS_ROLES_Is_Set_to_FALSE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_10_Ensure_UTL_FILE_DIR_Is_Empty_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT VALUE FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='UTL_FILE_DIR'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_10_Ensure_UTL_FILE_DIR_Is_Empty_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_11_Ensure_SEC_CASE_SENSITIVE_LOGON_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='SEC_CASE_SENSITIVE_LOGON'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_11_Ensure_SEC_CASE_SENSITIVE_LOGON_Is_Set_to_TRUE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_12_Ensure_SEC_MAX_FAILED_LOGIN_ATTEMPTS_Is_3_or_Less_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='SEC_MAX_FAILED_LOGIN_ATTEMPTS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_12_Ensure_SEC_MAX_FAILED_LOGIN_ATTEMPTS_Is_3_or_Less_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_13_Ensure_SEC_PROTOCOL_ERROR_FURTHER_ACTION_Is_Set_to_DROP_3_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='SEC_PROTOCOL_ERROR_FURTHER_ACTION'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_13_Ensure_SEC_PROTOCOL_ERROR_FURTHER_ACTION_Is_Set_to_DROP_3_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_14_Ensure_SEC_PROTOCOL_ERROR_TRACE_ACTION_Is_Set_to_LOG_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='SEC_PROTOCOL_ERROR_TRACE_ACTION'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_14_Ensure_SEC_PROTOCOL_ERROR_TRACE_ACTION_Is_Set_to_LOG_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_15_Ensure_SEC_RETURN_SERVER_RELEASE_BANNER_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='SEC_RETURN_SERVER_RELEASE_BANNER'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_15_Ensure_SEC_RETURN_SERVER_RELEASE_BANNER_Is_Set_to_FALSE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_16_Ensure_SQL92_SECURITY_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT UPPER(V.VALUE) AS value, DECODE(V.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE V.CON_ID = B.CON_ID)) AS db_name FROM V$SYSTEM_PARAMETER V WHERE UPPER(NAME) = 'SQL92_SECURITY'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_16_Ensure_SQL92_SECURITY_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='SQL92_SECURITY'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_16_Ensure_SQL92_SECURITY_Is_Set_to_TRUE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_17_Ensure__trace_files_public_Is_Set_to_FALSE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT A.KSPPINM, B.KSPPSTVL FROM SYS.X_$KSPPI a, SYS.X_$KSPPCV b WHERE A.INDX=B.INDX AND A.KSPPINM LIKE '\_%trace_files_public' escape '\'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_17_Ensure__trace_files_public_Is_Set_to_FALSE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_18_Ensure_RESOURCE_LIMIT_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT UPPER(V.VALUE) AS value, DECODE(V.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE V.CON_ID = B.CON_ID)) AS db_name FROM V$SYSTEM_PARAMETER V WHERE UPPER(NAME) = 'RESOURCE_LIMIT'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '2_2_18_Ensure_RESOURCE_LIMIT_Is_Set_to_TRUE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT UPPER(VALUE) AS value FROM V$SYSTEM_PARAMETER WHERE UPPER(NAME)='RESOURCE_LIMIT'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '2_2_18_Ensure_RESOURCE_LIMIT_Is_Set_to_TRUE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_1_Ensure_FAILED_LOGIN_ATTEMPTS_Is_Less_than_or_Equal_to_5_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_LOCK_TIME' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) < 1 AND P.RESOURCE_NAME = 'PASSWORD_LOCK_TIME' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_1_Ensure_FAILED_LOGIN_ATTEMPTS_Is_Less_than_or_Equal_to_5_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_LOCK_TIME'),'UNLIMITED','9999',P.LIMIT)) < 1 AND P.RESOURCE_NAME = 'PASSWORD_LOCK_TIME' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_1_Ensure_FAILED_LOGIN_ATTEMPTS_Is_Less_than_or_Equal_to_5_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_2_Ensure_PASSWORD_LOCK_TIME_Is_Greater_than_or_Equal_to_1_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_LOCK_TIME' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) < 1 AND P.RESOURCE_NAME = 'PASSWORD_LOCK_TIME' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_2_Ensure_PASSWORD_LOCK_TIME_Is_Greater_than_or_Equal_to_1_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_LOCK_TIME'),'UNLIMITED','9999',P.LIMIT)) < 1 AND P.RESOURCE_NAME = 'PASSWORD_LOCK_TIME' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_2_Ensure_PASSWORD_LOCK_TIME_Is_Greater_than_or_Equal_to_1_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_3_Ensure_PASSWORD_LIFE_TIME_Is_Less_than_or_Equal_to_90_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_LIFE_TIME' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) > 90 AND P.RESOURCE_NAME = 'PASSWORD_LIFE_TIME' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_3_Ensure_PASSWORD_LIFE_TIME_Is_Less_than_or_Equal_to_90_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_LIFE_TIME'),'UNLIMITED','9999',P.LIMIT)) > 90 AND P.RESOURCE_NAME = 'PASSWORD_LIFE_TIME' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_3_Ensure_PASSWORD_LIFE_TIME_Is_Less_than_or_Equal_to_90_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_4_Ensure_PASSWORD_REUSE_MAX_Is_Greater_than_or_Equal_to_20_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_REUSE_MAX' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) < 20 AND P.RESOURCE_NAME = 'PASSWORD_REUSE_MAX' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_4_Ensure_PASSWORD_REUSE_MAX_Is_Greater_than_or_Equal_to_20_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT, 'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_REUSE_MAX'), 'UNLIMITED','9999',P.LIMIT)) < 20 AND P.RESOURCE_NAME = 'PASSWORD_REUSE_MAX' AND EXISTS ( SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE )
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_4_Ensure_PASSWORD_REUSE_MAX_Is_Greater_than_or_Equal_to_20_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_5_Ensure_PASSWORD_REUSE_TIME_Is_Greater_than_or_Equal_to_365_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_REUSE_TIME' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) < 365 AND P.RESOURCE_NAME = 'PASSWORD_REUSE_TIME' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_5_Ensure_PASSWORD_REUSE_TIME_Is_Greater_than_or_Equal_to_365_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_REUSE_TIME'),'UNLIMITED','9999',P.LIMIT)) < 365 AND P.RESOURCE_NAME = 'PASSWORD_REUSE_TIME' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_5_Ensure_PASSWORD_REUSE_TIME_Is_Greater_than_or_Equal_to_365_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_6_Ensure_PASSWORD_GRACE_TIME_Is_Less_than_or_Equal_to_5_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_GRACE_TIME' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) > 5 AND P.RESOURCE_NAME = 'PASSWORD_GRACE_TIME' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_6_Ensure_PASSWORD_GRACE_TIME_Is_Less_than_or_Equal_to_5_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='PASSWORD_GRACE_TIME'),'UNLIMITED','9999',P.LIMIT)) > 5 AND P.RESOURCE_NAME = 'PASSWORD_GRACE_TIME' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_6_Ensure_PASSWORD_GRACE_TIME_Is_Less_than_or_Equal_to_5_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_7_Ensure_PASSWORD_VERIFY_FUNCTION_Is_Set_for_All_Profiles_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE DECODE(P.LIMIT,'DEFAULT',(SELECT LIMIT FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME = P.RESOURCE_NAME AND CON_ID = P.CON_ID),LIMIT) = 'NULL' AND P.RESOURCE_NAME = 'PASSWORD_VERIFY_FUNCTION' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_7_Ensure_PASSWORD_VERIFY_FUNCTION_Is_Set_for_All_Profiles_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE DECODE(P.LIMIT,'DEFAULT',(SELECT LIMIT FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME = P.RESOURCE_NAME),LIMIT) = 'NULL' AND P.RESOURCE_NAME = 'PASSWORD_VERIFY_FUNCTION' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_7_Ensure_PASSWORD_VERIFY_FUNCTION_Is_Set_for_All_Profiles_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_8_Ensure_SESSIONS_PER_USER_Is_Less_than_or_Equal_to_10_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='SESSIONS_PER_USER' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) > 10 AND P.RESOURCE_NAME = 'SESSIONS_PER_USER' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE) ORDER BY CON_ID, PROFILE, RESOURCE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_8_Ensure_SESSIONS_PER_USER_Is_Less_than_or_Equal_to_10_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='SESSIONS_PER_USER'),'UNLIMITED','9999',P.LIMIT)) > 10 AND P.RESOURCE_NAME = 'SESSIONS_PER_USER' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_8_Ensure_SESSIONS_PER_USER_Is_Less_than_or_Equal_to_10_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_9_Ensure_INACTIVE_ACCOUNT_TIME_Is_Less_than_or_Equal_to_120_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT P.PROFILE, P.RESOURCE_NAME, P.LIMIT, DECODE(P.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE P.CON_ID = B.CON_ID)) DATABASE FROM CDB_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM CDB_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='INACTIVE_ACCOUNT_TIME' AND CON_ID = P.CON_ID),'UNLIMITED','9999',P.LIMIT)) > 120 AND P.RESOURCE_NAME = 'INACTIVE_ACCOUNT_TIME' AND EXISTS (SELECT 'X' FROM CDB_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '3_9_Ensure_INACTIVE_ACCOUNT_TIME_Is_Less_than_or_Equal_to_120_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT P.PROFILE, P.RESOURCE_NAME, P.LIMIT FROM DBA_PROFILES P WHERE TO_NUMBER(DECODE(P.LIMIT,'DEFAULT',(SELECT DISTINCT DECODE(LIMIT,'UNLIMITED',9999,LIMIT) FROM DBA_PROFILES WHERE PROFILE='DEFAULT' AND RESOURCE_NAME='INACTIVE_ACCOUNT_TIME'),'UNLIMITED','9999',P.LIMIT)) > 120 AND P.RESOURCE_NAME = 'INACTIVE_ACCOUNT_TIME' AND EXISTS (SELECT 'X' FROM DBA_USERS U WHERE U.PROFILE = P.PROFILE)
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '3_9_Ensure_INACTIVE_ACCOUNT_TIME_Is_Less_than_or_Equal_to_120_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_1_Ensure_All_Default_Passwords_Are_Changed_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT A.USERNAME, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_USERS_WITH_DEFPWD A, CDB_USERS C WHERE A.USERNAME = C.USERNAME AND C.ACCOUNT_STATUS = 'OPEN'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_1_Ensure_All_Default_Passwords_Are_Changed_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT A.USERNAME FROM DBA_USERS_WITH_DEFPWD A, DBA_USERS B WHERE A.USERNAME = B.USERNAME AND B.ACCOUNT_STATUS = 'OPEN'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '4_1_Ensure_All_Default_Passwords_Are_Changed_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_2_Ensure_All_Sample_Data_And_Users_Have_Been_Removed_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DISTINCT A.USERNAME, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_USERS A WHERE A.USERNAME IN ('BI','HR','IX','OE','PM','SCOTT','SH')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_2_Ensure_All_Sample_Data_And_Users_Have_Been_Removed_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT USERNAME FROM DBA_USERS WHERE USERNAME IN ('BI','HR','IX','OE','PM','SCOTT','SH')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '4_2_Ensure_All_Sample_Data_And_Users_Have_Been_Removed_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_3_Ensure_DBA_USERS_AUTHENTICATION_TYPE_Is_Not_Set_to_EXTERNAL_for_Any_User_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT A.USERNAME, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_USERS A WHERE AUTHENTICATION_TYPE = 'EXTERNAL'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_3_Ensure_DBA_USERS_AUTHENTICATION_TYPE_Is_Not_Set_to_EXTERNAL_for_Any_User_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT USERNAME FROM DBA_USERS WHERE AUTHENTICATION_TYPE = 'EXTERNAL'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '4_3_Ensure_DBA_USERS_AUTHENTICATION_TYPE_Is_Not_Set_to_EXTERNAL_for_Any_User_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_4_Ensure_No_Users_Are_Assigned_the_DEFAULT_Profile_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT A.USERNAME, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_USERS A WHERE A.PROFILE='DEFAULT' AND A.ACCOUNT_STATUS='OPEN' AND A.ORACLE_MAINTAINED='N'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_4_Ensure_No_Users_Are_Assigned_the_DEFAULT_Profile_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT USERNAME FROM DBA_USERS WHERE PROFILE='DEFAULT' AND ACCOUNT_STATUS='OPEN' AND ORACLE_MAINTAINED='N'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '4_4_Ensure_No_Users_Are_Assigned_the_DEFAULT_Profile_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_5_Ensure_SYS_USER_MIG_Has_Been_Dropped_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT OWNER, TABLE_NAME, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TABLES A WHERE TABLE_NAME='USER$MIG' AND OWNER='SYS'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_5_Ensure_SYS_USER_MIG_Has_Been_Dropped_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT OWNER, TABLE_NAME FROM DBA_TABLES WHERE TABLE_NAME='USER$MIG' AND OWNER='SYS'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '4_5_Ensure_SYS_USER_MIG_Has_Been_Dropped_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_6_Ensure_No_Public_Database_Links_Exist_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DB_LINK, HOST, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_DB_LINKS A WHERE OWNER = 'PUBLIC'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '4_6_Ensure_No_Public_Database_Links_Exist_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT DB_LINK, HOST FROM DBA_DB_LINKS WHERE OWNER = 'PUBLIC'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '4_6_Ensure_No_Public_Database_Links_Exist_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_1_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Network_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_LDAP','UTL_INADDR','UTL_TCP','UTL_MAIL','UTL_SMTP','UTL_DBWS','UTL_ORAMTS','UTL_HTTP','HTTPURITYPE') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_1_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Network_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_LDAP','UTL_INADDR','UTL_TCP','UTL_MAIL','UTL_SMTP','UTL_DBWS','UTL_ORAMTS','UTL_HTTP','HTTPURITYPE')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_1_1_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Network_Packages_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_2_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_File_System_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_ADVISOR','DBMS_LOB','UTL_FILE') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_2_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_File_System_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_ADVISOR','DBMS_LOB','UTL_FILE')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_1_2_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_File_System_Packages_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_3_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Encryption_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_CRYPTO','DBMS_OBFUSCATION_TOOLKIT','DBMS_RANDOM') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_3_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Encryption_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_CRYPTO','DBMS_OBFUSCATION_TOOLKIT','DBMS_RANDOM')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_1_3_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Encryption_Packages_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_4_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Java_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS DATABASE FROM CDB_TAB_PRIVS A WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_JAVA','DBMS_JAVA_TEST') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_4_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Java_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_JAVA','DBMS_JAVA_TEST')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_1_4_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Java_Packages_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_5_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Job_Scheduler_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_SCHEDULER','DBMS_JOB') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_5_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Job_Scheduler_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_SCHEDULER','DBMS_JOB')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_1_5_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_Job_Scheduler_Packages_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_6_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_SQL_Injection_Helper_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_SQL','DBMS_XMLGEN','DBMS_XMLQUERY','DBMS_XMLSTORE','DBMS_XMLSAVE','DBMS_AW','OWA_UTIL','DBMS_REDACT') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_1_6_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_SQL_Injection_Helper_Packages_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_SQL','DBMS_XMLGEN','DBMS_XMLQUERY','DBMS_XMLSTORE','DBMS_XMLSAVE','DBMS_AW','OWA_UTIL','DBMS_REDACT')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_1_6_Ensure_EXECUTE_is_revoked_from_PUBLIC_on_SQL_Injection_Helper_Packages_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_2_Non_Default_Privileges',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_BACKUP_RESTORE','DBMS_FILE_TRANSFER','DBMS_SYS_SQL','DBMS_AQADM_SYSCALLS','DBMS_REPCAT_SQL_UTL','INITJVMAUX','DBMS_STREAMS_ADM_UTL','DBMS_AQADM_SYS','DBMS_STREAMS_RPC','DBMS_PRVTAQIM','LTADM','WWV_DBMS_SQL','WWV_EXECUTE_IMMEDIATE','DBMS_IJOB','DBMS_PDB_EXEC_SQL') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_2_Non_Default_Privileges',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE='PUBLIC' AND PRIVILEGE='EXECUTE' AND TABLE_NAME IN ('DBMS_BACKUP_RESTORE','DBMS_FILE_TRANSFER','DBMS_SYS_SQL','DBMS_AQADM_SYSCALLS','DBMS_REPCAT_SQL_UTL','INITJVMAUX','DBMS_STREAMS_ADM_UTL','DBMS_AQADM_SYS','DBMS_STREAMS_RPC','DBMS_PRVTAQIM','LTADM','WWV_DBMS_SQL','WWV_EXECUTE_IMMEDIATE','DBMS_IJOB','DBMS_PDB_EXEC_SQL')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_2_Non_Default_Privileges',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_3_1_Ensure_ALL_Is_Revoked_from_Unauthorized_GRANTEE_on_AUD_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE TABLE_NAME='AUD$' AND OWNER = 'SYS'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_3_1_Ensure_ALL_Is_Revoked_from_Unauthorized_GRANTEE_on_AUD_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_TAB_PRIVS WHERE TABLE_NAME='AUD$' AND OWNER = 'SYS'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_3_1_Ensure_ALL_Is_Revoked_from_Unauthorized_GRANTEE_on_AUD_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_3_2_Ensure_ALL_Is_Revoked_from_Unauthorized_GRANTEE_on_DBA__Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE,TABLE_NAME, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_TAB_PRIVS A WHERE TABLE_NAME LIKE 'DBA_%' AND OWNER = 'SYS' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_3_2_Ensure_ALL_Is_Revoked_from_Unauthorized_GRANTEE_on_DBA__Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, TABLE_NAME FROM DBA_TAB_PRIVS WHERE TABLE_NAME LIKE 'DBA_%' AND OWNER = 'SYS' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED = 'Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED = 'Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_3_2_Ensure_ALL_Is_Revoked_from_Unauthorized_GRANTEE_on_DBA__Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_3_3_Ensure_ALL_Is_Revoked_on_Sensitive_Tables_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT TABLE_NAME, PRIVILEGE, GRANTEE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) DATABASE FROM CDB_TAB_PRIVS A WHERE TABLE_NAME IN ('CDB_LOCAL_ADMINAUTH$','DEFAULT_PWD$','ENC$','HISTGRM$','HIST_HEAD$','LINK$','PDB_SYNC$','SCHEDULER$_CREDENTIAL','USER$','USER_HISTORY$','XS$VERIFIERS') AND OWNER = 'SYS' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED = 'Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED = 'Y') ORDER BY CON_ID, TABLE_NAME
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_1_3_3_Ensure_ALL_Is_Revoked_on_Sensitive_Tables_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, TABLE_NAME FROM DBA_TAB_PRIVS WHERE TABLE_NAME IN ('CDB_LOCAL_ADMINAUTH$','DEFAULT_PWD$','ENC$','HISTGRM$','HIST_HEAD$','LINK$','PDB_SYNC$','SCHEDULER$_CREDENTIAL','USER$','USER_HISTORY$','XS$VERIFIERS') AND OWNER = 'SYS' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_1_3_3_Ensure_ALL_Is_Revoked_on_Sensitive_Tables_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_1_Ensure_ANY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE LIKE '%ANY%' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED = 'Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED = 'Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_1_Ensure_ANY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE LIKE '%ANY%' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_1_Ensure_ANY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_2_Ensure_DBA_SYS_PRIVS_Is_Revoked_from_Unauthorized_GRANTEE_with_ADMIN_OPTION_Set_to_YES_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE ADMIN_OPTION='YES' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_2_Ensure_DBA_SYS_PRIVS_Is_Revoked_from_Unauthorized_GRANTEE_with_ADMIN_OPTION_Set_to_YES_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE ADMIN_OPTION='YES' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_2_Ensure_DBA_SYS_PRIVS_Is_Revoked_from_Unauthorized_GRANTEE_with_ADMIN_OPTION_Set_to_YES_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_3_Ensure_EXECUTE_ANY_PROCEDURE_Is_Revoked_from_OUTLN_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='EXECUTE ANY PROCEDURE' AND GRANTEE='OUTLN'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_3_Ensure_EXECUTE_ANY_PROCEDURE_Is_Revoked_from_OUTLN_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='EXECUTE ANY PROCEDURE' AND GRANTEE='OUTLN'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_3_Ensure_EXECUTE_ANY_PROCEDURE_Is_Revoked_from_OUTLN_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_4_Ensure_EXECUTE_ANY_PROCEDURE_Is_Revoked_from_DBSNMP_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='EXECUTE ANY PROCEDURE' AND GRANTEE='DBSNMP'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_4_Ensure_EXECUTE_ANY_PROCEDURE_Is_Revoked_from_DBSNMP_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='EXECUTE ANY PROCEDURE' AND GRANTEE='DBSNMP'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_4_Ensure_EXECUTE_ANY_PROCEDURE_Is_Revoked_from_DBSNMP_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_5_Ensure_SELECT_ANY_DICTIONARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='SELECT ANY DICTIONARY' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_5_Ensure_SELECT_ANY_DICTIONARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='SELECT ANY DICTIONARY' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_5_Ensure_SELECT_ANY_DICTIONARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_6_Ensure_SELECT_ANY_TABLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='SELECT ANY TABLE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_6_Ensure_SELECT_ANY_TABLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='SELECT ANY TABLE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_6_Ensure_SELECT_ANY_TABLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_7_Ensure_AUDIT_SYSTEM_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='AUDIT SYSTEM' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_7_Ensure_AUDIT_SYSTEM_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='AUDIT SYSTEM' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_7_Ensure_AUDIT_SYSTEM_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_8_Ensure_EXEMPT_ACCESS_POLICY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='EXEMPT ACCESS POLICY' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_8_Ensure_EXEMPT_ACCESS_POLICY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='EXEMPT ACCESS POLICY' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_8_Ensure_EXEMPT_ACCESS_POLICY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_9_Ensure_BECOME_USER_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='BECOME USER' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_9_Ensure_BECOME_USER_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='BECOME USER' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_9_Ensure_BECOME_USER_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_10_Ensure_CREATE_PROCEDURE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='CREATE PROCEDURE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_10_Ensure_CREATE_PROCEDURE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='CREATE PROCEDURE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_10_Ensure_CREATE_PROCEDURE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_11_Ensure_ALTER_SYSTEM_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='ALTER SYSTEM' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_11_Ensure_ALTER_SYSTEM_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='ALTER SYSTEM' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_11_Ensure_ALTER_SYSTEM_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_12_Ensure_CREATE_ANY_LIBRARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='CREATE ANY LIBRARY' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_12_Ensure_CREATE_ANY_LIBRARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='CREATE ANY LIBRARY' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_12_Ensure_CREATE_ANY_LIBRARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_13_Ensure_CREATE_LIBRARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='CREATE LIBRARY' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_13_Ensure_CREATE_LIBRARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='CREATE LIBRARY' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_13_Ensure_CREATE_LIBRARY_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_14_Ensure_GRANT_ANY_OBJECT_PRIVILEGE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='GRANT ANY OBJECT PRIVILEGE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_14_Ensure_GRANT_ANY_OBJECT_PRIVILEGE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='GRANT ANY OBJECT PRIVILEGE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_14_Ensure_GRANT_ANY_OBJECT_PRIVILEGE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_15_Ensure_GRANT_ANY_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='GRANT ANY ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_15_Ensure_GRANT_ANY_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='GRANT ANY ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_15_Ensure_GRANT_ANY_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_16_Ensure_GRANT_ANY_PRIVILEGE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_SYS_PRIVS A WHERE PRIVILEGE='GRANT ANY PRIVILEGE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_2_16_Ensure_GRANT_ANY_PRIVILEGE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE PRIVILEGE='GRANT ANY PRIVILEGE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_2_16_Ensure_GRANT_ANY_PRIVILEGE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_1_Ensure_DELETE_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, GRANTED_ROLE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_ROLE_PRIVS A WHERE GRANTED_ROLE='DELETE_CATALOG_ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_1_Ensure_DELETE_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE='DELETE_CATALOG_ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_3_1_Ensure_DELETE_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_2_Ensure_SELECT_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, GRANTED_ROLE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_ROLE_PRIVS A WHERE GRANTED_ROLE='SELECT_CATALOG_ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_2_Ensure_SELECT_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE='SELECT_CATALOG_ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_3_2_Ensure_SELECT_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_3_Ensure_EXECUTE_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, GRANTED_ROLE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_ROLE_PRIVS A WHERE GRANTED_ROLE='EXECUTE_CATALOG_ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM CDB_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM CDB_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_3_Ensure_EXECUTE_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE='EXECUTE_CATALOG_ROLE' AND GRANTEE NOT IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='Y') AND GRANTEE NOT IN (SELECT ROLE FROM DBA_ROLES WHERE ORACLE_MAINTAINED='Y')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_3_3_Ensure_EXECUTE_CATALOG_ROLE_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_4_Ensure_DBA_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT 'GRANT' AS PATH, GRANTEE, GRANTED_ROLE, DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) CON FROM CDB_ROLE_PRIVS A WHERE GRANTED_ROLE='DBA' AND GRANTEE NOT IN ('SYS', 'SYSTEM') UNION SELECT 'PROXY', PROXY || '-' || CLIENT, 'DBA', DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) CON FROM CDB_PROXIES A WHERE CLIENT IN (SELECT GRANTEE FROM CDB_ROLE_PRIVS B WHERE GRANTED_ROLE='DBA' AND A.CON_ID = B.CON_ID)
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '5_3_4_Ensure_DBA_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT 'GRANT' AS PATH, GRANTEE, GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE = 'DBA' AND GRANTEE NOT IN ('SYS', 'SYSTEM') UNION SELECT 'PROXY', PROXY || '-' || CLIENT, 'DBA' FROM DBA_PROXIES WHERE CLIENT IN (SELECT GRANTEE FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE = 'DBA')
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '5_3_4_Ensure_DBA_Is_Revoked_from_Unauthorized_GRANTEE_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_1_Ensure_the_USER_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='USER'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_1_Ensure_the_USER_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='USER'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_1_Ensure_the_USER_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_2_Ensure_the_ROLE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION, SUCCESS, FAILURE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='ROLE'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_2_Ensure_the_ROLE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='ROLE'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_2_Ensure_the_ROLE_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_3_Ensure_the_SYSTEM_GRANT_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='SYSTEM GRANT'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_3_Ensure_the_SYSTEM_GRANT_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='SYSTEM GRANT'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_3_Ensure_the_SYSTEM_GRANT_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_4_Ensure_the_PROFILE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='PROFILE'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_4_Ensure_the_PROFILE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='PROFILE'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_4_Ensure_the_PROFILE_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_5_Ensure_the_DATABASE_LINK_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='DATABASE LINK'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_5_Ensure_the_DATABASE_LINK_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='DATABASE LINK'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_5_Ensure_the_DATABASE_LINK_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_6_Ensure_the_PUBLIC_DATABASE_LINK_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION, SUCCESS, FAILURE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION = 'PUBLIC DATABASE LINK'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_6_Ensure_the_PUBLIC_DATABASE_LINK_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='PUBLIC DATABASE LINK'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_6_Ensure_the_PUBLIC_DATABASE_LINK_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_7_Ensure_the_PUBLIC_SYNONYM_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='PUBLIC SYNONYM'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_7_Ensure_the_PUBLIC_SYNONYM_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='PUBLIC SYNONYM'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_7_Ensure_the_PUBLIC_SYNONYM_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_8_Ensure_the_SYNONYM_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION, SUCCESS, FAILURE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION = 'SYNONYM'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_8_Ensure_the_SYNONYM_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='SYNONYM'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_8_Ensure_the_SYNONYM_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_9_Ensure_the_DIRECTORY_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='DIRECTORY'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_9_Ensure_the_DIRECTORY_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='DIRECTORY'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_9_Ensure_the_DIRECTORY_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_10_Ensure_the_SELECT_ANY_DICTIONARY_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='SELECT ANY DICTIONARY'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_10_Ensure_the_SELECT_ANY_DICTIONARY_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='SELECT ANY DICTIONARY'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_10_Ensure_the_SELECT_ANY_DICTIONARY_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_11_Ensure_the_GRANT_ANY_OBJECT_PRIVILEGE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='GRANT ANY OBJECT PRIVILEGE'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_11_Ensure_the_GRANT_ANY_OBJECT_PRIVILEGE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='GRANT ANY OBJECT PRIVILEGE'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_11_Ensure_the_GRANT_ANY_OBJECT_PRIVILEGE_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_12_Ensure_the_GRANT_ANY_PRIVILEGE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='GRANT ANY PRIVILEGE'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_12_Ensure_the_GRANT_ANY_PRIVILEGE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='GRANT ANY PRIVILEGE'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_12_Ensure_the_GRANT_ANY_PRIVILEGE_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_13_Ensure_the_DROP_ANY_PROCEDURE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE, DECODE(A.CON_ID, 0,(SELECT NAME FROM V$DATABASE), 1,(SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='DROP ANY PROCEDURE'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_13_Ensure_the_DROP_ANY_PROCEDURE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='DROP ANY PROCEDURE'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_13_Ensure_the_DROP_ANY_PROCEDURE_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_14_Ensure_the_ALL_Audit_Option_on_SYS_AUD_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT * FROM CDB_OBJ_AUDIT_OPTS WHERE OBJECT_NAME='AUD$' AND ALT='A/A' AND AUD='A/A' AND COM='A/A' AND DEL='A/A' AND GRA='A/A' AND IND='A/A' AND INS='A/A' AND LOC='A/A' AND REN='A/A' AND SEL='A/A' AND UPD='A/A' AND FBK='A/A'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_14_Ensure_the_ALL_Audit_Option_on_SYS_AUD_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_15_Ensure_the_PROCEDURE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION, SUCCESS, FAILURE, DECODE(A.CON_ID, 0, (SELECT NAME FROM V$DATABASE), 1, (SELECT NAME FROM V$DATABASE), (SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION = 'PROCEDURE'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_15_Ensure_the_PROCEDURE_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='PROCEDURE'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_15_Ensure_the_PROCEDURE_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_16_Ensure_the_ALTER_SYSTEM_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE,DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='ALTER SYSTEM'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_16_Ensure_the_ALTER_SYSTEM_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='ALTER SYSTEM'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_16_Ensure_the_ALTER_SYSTEM_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_17_Ensure_the_TRIGGER_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE,DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='TRIGGER'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_17_Ensure_the_TRIGGER_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='TRIGGER'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_17_Ensure_the_TRIGGER_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    IF v_line = 'YES' THEN
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_18_Ensure_the_CREATE_SESSION_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE,DECODE(A.CON_ID,0,(SELECT NAME FROM V$DATABASE),1,(SELECT NAME FROM V$DATABASE),(SELECT NAME FROM V$PDBS B WHERE A.CON_ID = B.CON_ID)) AS db_name FROM CDB_STMT_AUDIT_OPTS A WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='CREATE SESSION'
        )
      ]';
    ELSE
      v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_1_18_Ensure_the_CREATE_SESSION_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUDIT_OPTION,SUCCESS,FAILURE FROM DBA_STMT_AUDIT_OPTS WHERE USER_NAME IS NULL AND PROXY_NAME IS NULL AND SUCCESS = 'BY ACCESS' AND FAILURE = 'BY ACCESS' AND AUDIT_OPTION='CREATE SESSION'
        )
      ]';
    END IF;

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_1_18_Ensure_the_CREATE_SESSION_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_1_Ensure_the_CREATE_USER_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'CREATE USER' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_1_Ensure_the_CREATE_USER_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_2_Ensure_the_ALTER_USER_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALTER USER' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_2_Ensure_the_ALTER_USER_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_3_Ensure_the_DROP_USER_Audit_Option_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'DROP USER' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_3_Ensure_the_DROP_USER_Audit_Option_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_4_Ensure_the_CREATE_ROLE_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'CREATE ROLE' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_4_Ensure_the_CREATE_ROLE_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_5_Ensure_the_ALTER_ROLE_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALTER ROLE' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_5_Ensure_the_ALTER_ROLE_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_6_Ensure_the_DROP_ROLE_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'DROP ROLE' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_6_Ensure_the_DROP_ROLE_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_7_Ensure_the_GRANT_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'GRANT' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_7_Ensure_the_GRANT_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_8_Ensure_the_REVOKE_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'REVOKE' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_8_Ensure_the_REVOKE_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_9_Ensure_the_CREATE_PROFILE_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'CREATE PROFILE' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_9_Ensure_the_CREATE_PROFILE_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_10_Ensure_the_ALTER_PROFILE_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALTER PROFILE' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_10_Ensure_the_ALTER_PROFILE_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_11_Ensure_the_DROP_PROFILE_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'DROP PROFILE' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_11_Ensure_the_DROP_PROFILE_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_12_Ensure_the_CREATE_DATABASE_LINK_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'CREATE DATABASE LINK' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_12_Ensure_the_CREATE_DATABASE_LINK_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_13_Ensure_the_ALTER_DATABASE_LINK_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALTER DATABASE LINK' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_13_Ensure_the_ALTER_DATABASE_LINK_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_14_Ensure_the_DROP_DATABASE_LINK_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'DROP DATABASE LINK' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_14_Ensure_the_DROP_DATABASE_LINK_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_15_Ensure_the_CREATE_SYNONYM_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'CREATE SYNONYM' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_15_Ensure_the_CREATE_SYNONYM_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_16_Ensure_the_ALTER_SYNONYM_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALTER SYNONYM' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_16_Ensure_the_ALTER_SYNONYM_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_17_Ensure_the_DROP_SYNONYM_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'DROP SYNONYM' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_17_Ensure_the_DROP_SYNONYM_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_18_Ensure_the_SELECT_ANY_DICTIONARY_Privilege_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'SELECT ANY DICTIONARY' AND AUD.AUDIT_OPTION_TYPE = 'SYSTEM PRIVILEGE' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_18_Ensure_the_SELECT_ANY_DICTIONARY_Privilege_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_19_Ensure_the_AUDSYS_AUD_UNIFIED_Access_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALL' AND AUD.AUDIT_OPTION_TYPE = 'OBJECT ACTION' AND (AUD.OBJECT_SCHEMA = 'SYS' OR AUD.OBJECT_SCHEMA = 'AUDSYS') AND AUD.OBJECT_NAME = 'AUD$UNIFIED' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_19_Ensure_the_AUDSYS_AUD_UNIFIED_Access_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_20_Ensure_the_CREATE_PROCEDURE_FUNCTION_PACKAGE_PACKAGE_BODY_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT ENABLED.POLICY_NAME FROM AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS' AND ( SELECT COUNT(*) FROM AUDIT_UNIFIED_POLICIES AUD WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION IN ('CREATE PROCEDURE', 'CREATE FUNCTION', 'CREATE PACKAGE', 'CREATE PACKAGE BODY') AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION') = 4
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_20_Ensure_the_CREATE_PROCEDURE_FUNCTION_PACKAGE_PACKAGE_BODY_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_21_Ensure_the_ALTER_PROCEDURE_FUNCTION_PACKAGE_PACKAGE_BODY_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT enabled.policy_name FROM AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY USER' AND ENABLED.USER_NAME = 'ALL USERS' AND ( SELECT COUNT(*) FROM AUDIT_UNIFIED_POLICIES AUD WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION IN ('ALTER PROCEDURE', 'ALTER FUNCTION', 'ALTER PACKAGE', 'ALTER PACKAGE BODY') AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION') = 4
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_21_Ensure_the_ALTER_PROCEDURE_FUNCTION_PACKAGE_PACKAGE_BODY_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_22_Ensure_the_DROP_PROCEDURE_FUNCTION_PACKAGE_PACKAGE_BODY_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT enabled.policy_name FROM AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY USER' AND ENABLED.USER_NAME = 'ALL USERS' AND ( SELECT COUNT(*) FROM AUDIT_UNIFIED_POLICIES AUD WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION IN ('DROP PROCEDURE', 'DROP FUNCTION', 'DROP PACKAGE', 'DROP PACKAGE BODY') AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION') = 4
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_22_Ensure_the_DROP_PROCEDURE_FUNCTION_PACKAGE_PACKAGE_BODY_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_23_Ensure_the_ALTER_SYSTEM_Privilege_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALTER SYSTEM' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_23_Ensure_the_ALTER_SYSTEM_Privilege_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_24_Ensure_the_CREATE_TRIGGER_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'CREATE TRIGGER' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_24_Ensure_the_CREATE_TRIGGER_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_25_Ensure_the_ALTER_TRIGGER_Action_Audit_IS_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'ALTER TRIGGER' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_25_Ensure_the_ALTER_TRIGGER_Action_Audit_IS_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_26_Ensure_the_DROP_TRIGGER_Action_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT AUD.POLICY_NAME, AUD.AUDIT_OPTION, AUD.AUDIT_OPTION_TYPE FROM AUDIT_UNIFIED_POLICIES AUD, AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION = 'DROP TRIGGER' AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION' AND ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY' AND ENABLED.USER_NAME = 'ALL USERS'
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_26_Ensure_the_DROP_TRIGGER_Action_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/


DECLARE
  v_json CLOB;
  v_sql  CLOB;
  v_cursor SYS_REFCURSOR;
  v_line   VARCHAR2(32767);
BEGIN
  SELECT cdb INTO v_line FROM v$database;

  BEGIN
    v_sql := q'[  
        SELECT JSON_OBJECT(
                 'name' VALUE '6_2_27_Ensure_the_LOGON_AND_LOGOFF_Actions_Audit_Is_Enabled_Scored_',
                 'results' VALUE JSON_ARRAYAGG(JSON_OBJECT(*))
               )
        FROM (
          SELECT ENABLED.POLICY_NAME FROM AUDIT_UNIFIED_ENABLED_POLICIES ENABLED WHERE ENABLED.SUCCESS = 'YES' AND ENABLED.FAILURE = 'YES' AND ENABLED.ENABLED_OPT = 'BY USER' AND ENABLED.USER_NAME = 'ALL USERS' AND ( SELECT COUNT(*) FROM AUDIT_UNIFIED_POLICIES AUD WHERE AUD.POLICY_NAME = ENABLED.POLICY_NAME AND AUD.AUDIT_OPTION IN ('LOGOFF', 'LOGON') AND AUD.AUDIT_OPTION_TYPE = 'STANDARD ACTION') = 2
        )
      ]';

    OPEN v_cursor FOR v_sql;
    FETCH v_cursor INTO v_json;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE(v_json);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE(
        JSON_OBJECT(
          'name' VALUE '6_2_27_Ensure_the_LOGON_AND_LOGOFF_Actions_Audit_Is_Enabled_Scored_',
          'results' VALUE 'ERROR: ' || SQLERRM
        )
      );
  END;
END;
/

