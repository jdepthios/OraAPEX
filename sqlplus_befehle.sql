--------------------------------------------------------------------------------
-- Oracle version
--------------------------------------------------------------------------------
SQL> select * from v$version;

BANNER
--------------------------------------------------------------------------------
Oracle Database 11g Enterprise Edition Release 11.2.0.1.0 - 64bit Production
PL/SQL Release 11.2.0.1.0 - Production
CORE    11.2.0.1.0      Production
TNS for 64-bit Windows: Version 11.2.0.1.0 - Production
NLSRTL Version 11.2.0.1.0 - Production

5 rows selected.

--------------------------------------------------------------------------------
-- get oracle home pfad
--------------------------------------------------------------------------------

SQL> var oracle_home clob;
SQL> exec dbms_system.get_env('ORACLE_HOME', :oracle_home);

PL/SQL procedure successfully completed.

SQL> print oracle_home;

ORACLE_HOME
--------------------------------------------------------------------------------
E:\app\Administrator\product\11.2.0\dbhome_1

SQL>
