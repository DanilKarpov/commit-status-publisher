@echo off
:: ---------------------------------------------------------------------
:: TeamCity server start/stop script
:: ---------------------------------------------------------------------
:: Environment variables:
::
:: TEAMCITY_SERVER_MEM_OPTS   server memory options (JVM options)
::
:: TEAMCITY_SERVER_OPTS       additional server JVM options
::
:: TEAMCITY_DATA_PATH         path to TeamCity data directory
::
:: TEAMCITY_LOGS_PATH         path to TeamCity logs directory
::
:: TEAMCITY_PREPARE_SCRIPT    name of a script to execute before start/stop
::
:: TEAMCITY_PID_FILE_PATH     path to a file which will contain TeamCity process ID (if not specified file with name "teamcity.pid" will be created under logs directory)
::
:: TEAMCITY_RESTART_LIMIT     number of restart attempts on unexpected server exit (e.g. JVM crash), default is 3
::
:: ---------------------------------------------------------------------
setlocal

set OLD_DIR=%CD%

cd /d %~dp0
set BIN=%CD%

:: If restarter was spawned in separate window clear the flag to close the console after server stop
set EXIT_FLAG=/b

if not "%TEAMCITY_SERVER_SCRIPT%" == "" goto teamcity_server_script_set
  set "TEAMCITY_SERVER_SCRIPT=%BIN%\teamcity-server.bat"
:teamcity_server_script_set
if not "%TEAMCITY_BIN_DIRECTORY%" == "" goto teamcity_bin_dir_set
  set "TEAMCITY_BIN_DIRECTORY=%BIN%"
:teamcity_bin_dir_set
set "TEAMCITY_SERVER_RESTARTER_SCRIPT=%BIN%\teamcity-server-restarter.bat"

set EXIT_CODE=0

if ""%1"" == ""start"" goto start
if ""%1"" == ""run"" goto run
if ""%1"" == ""start_internal"" goto start_internal
if ""%1"" == ""service"" goto service
goto default


:start_internal
set TEAMCITY_START_COMMAND=start
set TEAMCITY_RESTARTER_SILENT=1
:: close window on server shutdown
set EXIT_FLAG=
call:do_cycle %*
goto:exit

:run
set TEAMCITY_START_COMMAND=run
call:do_cycle %*
goto:exit

:start
call:spawn_self %*
goto:exit

:service
if not "%TEAMCITY_LOGS_PATH%" == "" goto service_logs_path_set
set "TEAMCITY_LOGS_PATH=%BIN%\..\logs"

:service_logs_path_set
set "TEAMCITY_SERVICE_LOGS_PATH=%TEAMCITY_LOGS_PATH%"
if exist "%TEAMCITY_SERVICE_LOGS_PATH%" goto service_logs_done
mkdir "%TEAMCITY_SERVICE_LOGS_PATH%"

:service_logs_done
shift
SET TEAMCITY_SERVICE_COMMAND=%1
IF NOT "%1"=="install" IF NOT "%1"=="delete" goto service_usage_error
shift
TeamCityService.exe %TEAMCITY_SERVICE_COMMAND% /settings=..\conf\teamcity-server-service.xml "/logfile=%TEAMCITY_SERVICE_LOGS_PATH%\teamcity-winservice.log" %*
IF NOT ERRORLEVEL 1 GOTO service_succeeded
:: service failed to complete here
IF "%TEAMCITY_SERVICE_COMMAND%" == "install" ECHO Call teamcity-server.bat usage for usage details
IF "%TEAMCITY_SERVICE_COMMAND%" == "install" ECHO Service logs are in %TEAMCITY_SERVICE_LOGS_PATH%\teamcity-winservice.log
SET TEAMCITY_SERVICE_COMMAND=
set EXIT_CODE=1
goto:exit

:: service command call succeeded
:service_succeeded
IF "%TEAMCITY_SERVICE_COMMAND%" == "install" ECHO Service logs are in %TEAMCITY_SERVICE_LOGS_PATH%\teamcity-winservice.log
SET TEAMCITY_SERVICE_COMMAND=
set EXIT_CODE=0
goto:exit

:service_usage_error
echo.
echo Supported "service" command invocations:
echo service install /runAsSystem
echo   Installs the TeamCity server as a Windows service and uses the LOCAL_SYSTEM account.
echo service install /user=^<username^> [/domain=^<domain^>] /password=^<password^>
echo   Installs the TeamCity server as a Windows service under the specified user account.
echo service delete
echo   Removes a previously installed TeamCity server service.
echo.
set EXIT_CODE=1
goto:exit

:default
call "%TEAMCITY_SERVER_RESTARTER_SCRIPT%" %*
goto:exit

:exit
:: Ensure 'run' we won't spoil any further invocations
set "TEAMCITY_RESTARTER_SILENT="
set "TEAMCITY_SERVER_SCRIPT="
cd /d "%OLD_DIR%"
exit %EXIT_FLAG% %EXIT_CODE%

::::::::::::::::::::::::::::::::::::::::::::::::::
:spawn_self
  echo Starting TeamCity in a separate window...
  start "TeamCity Server" "%~f0" start_internal %2 %3 %4 %5 %6 %7 %8 %9 >nul 2>nul
goto:eof

:do_cycle
  :do_cycle_while
    if not exist "%TEAMCITY_SERVER_RESTARTER_SCRIPT%.new" goto do_cycle_call
    move "%TEAMCITY_SERVER_RESTARTER_SCRIPT%" "%TEAMCITY_SERVER_RESTARTER_SCRIPT%.old" >nul
    move "%TEAMCITY_SERVER_RESTARTER_SCRIPT%.new" "%TEAMCITY_SERVER_RESTARTER_SCRIPT%" >nul
    :do_cycle_call
    call "%TEAMCITY_SERVER_RESTARTER_SCRIPT%" run %2 %3 %4 %5 %6 %7 %8 %9
    if not exist "%TEAMCITY_SERVER_RESTARTER_SCRIPT%.new" goto do_cycle_end
  goto do_cycle_while
  :do_cycle_end
goto:eof
