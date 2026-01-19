@echo off
:: ---------------------------------------------------------------------
:: TeamCity database maintenance script
:: ---------------------------------------------------------------------
:: Environment variables:
::
:: TEAMCITY_MAINTAINDB_MEM_OPTS   memory options (JVM options)
::
:: TEAMCITY_MAINTAINDB_OPTS       additional JVM options
::
:: TEAMCITY_APP_DIR    Path to TeamCity application directory (default is <TeamCity_home>\webapps\ROOT)
::
:: ---------------------------------------------------------------------

SET TEAMCITY_MAINTAIN_CURRENT_DIR=%CD%
cd /d %~dp0

IF defined TEAMCITY_APP_DIR goto app_dir_defined
if defined TEAMCITY_APP_DIR_ACTUAL goto app_dir_got
SET TEAMCITY_APP_DIR_ACTUAL=..\webapps\ROOT
goto app_dir_got

:app_dir_defined
SET TEAMCITY_APP_DIR_ACTUAL=%TEAMCITY_APP_DIR%

:app_dir_got
IF EXIST "%TEAMCITY_APP_DIR_ACTUAL%" goto app_dir_done

echo TeamCity web application directory must be specified to run TeamCity database maintenance tool.
echo TEAMCITY_APP_DIR environment variable not found.
SET /P APP_DIR_INPUT=Enter TeamCity web application directory path [%TEAMCITY_APP_DIR_ACTUAL%]:
if not "%APP_DIR_INPUT%"=="" SET TEAMCITY_APP_DIR_ACTUAL=%APP_DIR_INPUT%

:app_dir_done
SET TEAMCITY_LIB_DIR=%TEAMCITY_APP_DIR_ACTUAL%\WEB-INF\lib

IF NOT EXIST "%TEAMCITY_LIB_DIR%" goto no_lib_folder



:: Add all JARs from WEB-INF\lib to classpath
SET ACC=
SET SEPARATOR=;
rem FOR %%J in ("%TEAMCITY_LIB_DIR%\*.jar") DO call append.bat %%J
REM SET CP=%ACC%;%TEAMCITY_LIB_DIR%\..\classes

:: Alternative classpath: Add only necessary JARs
rem SET CP=
REM SET CP=%CP%;TEAMCITY_LIB_DIR%\..\classes

SET CP=%TEAMCITY_LIB_DIR%\..\classes
rem for %%f in (%TEAMCITY_LIB_DIR%\commons-cli-*.jar) do SET CP=%CP%;%%f
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\server.jar
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\openapi.jar
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\server-openapi.jar
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\common.jar
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\server-model.jar
rem for %%f in (%TEAMCITY_LIB_DIR%\log4j-core-*.jar) do SET CP=%CP%;%%f
rem for %%f in (%TEAMCITY_LIB_DIR%\log4j-api-*.jar) do SET CP=%CP%;%%f
rem for %%f in (%TEAMCITY_LIB_DIR%\log4j-1.2-api-*.jar) do SET CP=%CP%;%%f
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\jdom.jar
rem for %%f in (%TEAMCITY_LIB_DIR%\xstream-*.jar) do SET CP=%CP%;%%f
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\messages.jar
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\spring.jar
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\common-impl.jar
rem for %%f in (%TEAMCITY_LIB_DIR%\commons-compress-*.jar) do SET CP=%CP%;%%f
rem for %%f in (%TEAMCITY_LIB_DIR%\commons-dbcp2-*.jar) do SET CP=%CP%;%%f
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\commons-logging.jar
rem for %%f in (%TEAMCITY_LIB_DIR%\commons-pool2-*.jar) do SET CP=%CP%;%%f
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\db.jar
rem for %%f in (%TEAMCITY_LIB_DIR%\guava-*.jar) do SET CP=%CP%;%%f
rem for %%f in (%TEAMCITY_LIB_DIR%\jaxen-*.jar) do SET CP=%CP%;%%f
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\xercesImpl.jar
rem for %%f in (%TEAMCITY_LIB_DIR%\trove-*.jar) do SET CP=%CP%;%%f

:: Database drivers
rem SET CP=%CP%;%TEAMCITY_LIB_DIR%\hsqldb.jar
for %%f in (%TEAMCITY_LIB_DIR%\mysql-connector-java-*.jar) do SET CP=%CP%;%%f
for %%f in (%TEAMCITY_LIB_DIR%\postgresql-*.jar) do SET CP=%CP%;%%f
for %%f in (%TEAMCITY_LIB_DIR%\ojdbc*.jar) do SET CP=%CP%;%%f
for %%f in (%TEAMCITY_LIB_DIR%\jtds-*.jar) do SET CP=%CP%;%%f
:: End alternative classpath

if not "%TEAMCITY_MAINTAINDB_MEM_OPTS%" == "" goto mem_opts_set
rem Default options
SET TEAMCITY_MAINTAINDB_MEM_OPTS_ACTUAL=-Xmx1024m

goto mem_opts_done

:mem_opts_set
SET TEAMCITY_MAINTAINDB_MEM_OPTS_ACTUAL=%TEAMCITY_MAINTAINDB_MEM_OPTS%

:mem_opts_done

SET MIGRATION_JVM_OPTS=%TEAMCITY_MAINTAINDB_OPTS%
SET MIGRATION_JVM_OPTS=%MIGRATION_JVM_OPTS% %TEAMCITY_MAINTAINDB_MEM_OPTS_ACTUAL%
SET MIGRATION_JVM_OPTS=%MIGRATION_JVM_OPTS% -XX:+HeapDumpOnOutOfMemoryError -Dlog4j2.configurationFile=file:../conf/teamcity-maintenance-log4j.xml -Dteamcity_logs=../logs/

if exist ..\jre SET JRE_HOME=%cd%\..\jre
set FJ_MIN_UNSUPPORTED_JAVA_VERSION=22
CALL "%cd%\findJava.bat" "1.8" "%cd%\..\jre"
IF ERRORLEVEL 0 GOTO java_search_done
ECHO Java not found. Cannot start the tool. Please ensure JDK or JRE is installed and JAVA_HOME environment variable points to it.
GOTO migration_error

:java_search_done
"%FJ_JAVA_EXEC%" %MIGRATION_JVM_OPTS% -cp "%CP%" -jar db-maintenance.jar %*

:: Post-migration steps

if not %ERRORLEVEL%==0 goto migration_error
goto migration_ok

:migration_error
echo Critical error has occurred during command execution.
set EXIT_CODE=%ERRORLEVEL%
cd /d %TEAMCITY_MAINTAIN_CURRENT_DIR%
exit /B %EXIT_CODE%

goto done

:migration_ok
echo Done.

:done
goto end

:no_lib_folder
echo Critical error: No TeamCity installation found (%TEAMCITY_APP_DIR_ACTUAL%)
echo Set TEAMCITY_APP_DIR variable to the TeamCity web application directory before running the script.
goto end

:end
cd /d %TEAMCITY_MAINTAIN_CURRENT_DIR%
