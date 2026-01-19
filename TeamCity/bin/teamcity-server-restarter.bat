@echo off
:: This script should not be called directly, use teamcity-server.bat instead

:: Script to support TeamCity server auto restart
:: Environment variables that may affect script:
::   * CATALINA_HOME
::   * CATALINA_BASE
::   * CATALINA_OUT

:: Variables defined in this script:
::   * TEAMCITY_RESTART_LOCK_FILE_PATH  path to a file which will contain restarter lock, if file present server would automatically restart after exit

:: Auto restart notes upon server process exit:
:: If TEAMCITY_RESTART_LOCK_FILE_PATH is not preset server will not be restarted
if not defined TEAMCITY_SERVER_SCRIPT (
  echo This script should not be called directly, use teamcity-server.bat instead
  exit /b 2
)
setlocal

set RESTARTER_OLD_DIR=%CD%

cd /d %~dp0
set BIN=%CD%


:: Setup variables
set "TEAMCITY_SERVER_INTERNAL_SCRIPT=%BIN%\teamcity-server-internal.bat"

if not "%TEAMCITY_LOGS_PATH%" == "" goto logs_path_set
set "TEAMCITY_LOGS_PATH=%BIN%\..\logs"
:logs_path_set
set "LOG=%TEAMCITY_LOGS_PATH%\teamcity-wrapper.log"

::set to 'internal' property to avoid spoiling nested server (if any)
set "TEAMCITY_RESTARTER_SILENT_ACTUAL=%TEAMCITY_RESTARTER_SILENT%"
set "TEAMCITY_RESTARTER_SILENT="

set "TEAMCITY_RESTART_LOCK_FILE_PATH=%TEAMCITY_LOGS_PATH%\teamcity.lock"
set "TEAMCITY_RESTART_REQUESTED_FILE_PATH=%TEAMCITY_LOGS_PATH%\teamcity.restart"

if "%TEAMCITY_RESTART_LIMIT%" == "" (
  set TEAMCITY_RESTART_LIMIT_ACTUAL=3
) else (
  set "TEAMCITY_RESTART_LIMIT_ACTUAL=%TEAMCITY_RESTART_LIMIT%"
)

if not "%TEAMCITY_PID_FILE_PATH%" == "" goto teamcity_pid_file_path_set
set "TEAMCITY_PID_FILE_PATH=%TEAMCITY_LOGS_PATH%\teamcity.pid"
:teamcity_pid_file_path_set

:: Only set CATALINA_HOME if not already set
if "%CATALINA_HOME%"=="" for %%A in ("%CD%\..") do set CATALINA_HOME=%%~fA

:: Copy CATALINA_BASE from CATALINA_HOME if not already set
if "%CATALINA_BASE%"=="" set "CATALINA_BASE=%CATALINA_HOME%"
if "%CATALINA_OUT%"==""  set "CATALINA_OUT=%TEAMCITY_LOGS_PATH%\catalina.out"

set RESTARTER_TC_EXIT_CODE=0

:: start implemented in teamcity-server.bat
if ""%1"" == ""run"" goto run
if ""%1"" == ""stop"" goto stop
if ""%1"" == ""restart"" goto restart
goto default

:run
call:restarter_run %*
goto exit

:restart
copy /y nul "%TEAMCITY_RESTART_REQUESTED_FILE_PATH%" 1>nul
if ERRORLEVEL 0 (
  call:log "Successfully created restart marker file"
  call:do_default stop %2 %3
  goto exit
)
call:log "Failed to create restart mark file. Restart functionality is unavailable"
set RESTARTER_TC_EXIT_CODE=1
goto exit

:stop
if exist "%TEAMCITY_RESTART_LOCK_FILE_PATH%" (
  call:log "Removing lock file so server won't automatically restart"
  del "%TEAMCITY_RESTART_LOCK_FILE_PATH%"
)

:default
call:do_default %*

:exit
cd /d "%RESTARTER_OLD_DIR%"
exit /b %RESTARTER_TC_EXIT_CODE%

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:log
  echo %~1
  echo %date% %time% %~1 >> "%LOG%" 2>&1
goto:eof

:do_default
  call "%TEAMCITY_SERVER_INTERNAL_SCRIPT%" %*
goto:eof

:restarter_run
  if not exist "%TEAMCITY_LOGS_PATH%" mkdir "%TEAMCITY_LOGS_PATH%"
  if exist "%TEAMCITY_RESTART_LOCK_FILE_PATH%" (
    :: TODO: Check server not running
    call:log "Existing lock file found, will be removed"
    del "%TEAMCITY_RESTART_LOCK_FILE_PATH%"
  )

  set TEAMCITY_RESTART_COUNT=0

  :while

  call:log "Starting TeamCity server"
  if exist "%TEAMCITY_RESTART_LOCK_FILE_PATH%" del "%TEAMCITY_RESTART_LOCK_FILE_PATH%"
  copy /y nul "%TEAMCITY_RESTART_LOCK_FILE_PATH%" 1>nul
  if ERRORLEVEL 0 goto:lock_created
    call:log "Failed to create lock file. Auto restart and upgrade functionality is unavailable"
    set "TEAMCITY_RESTART_LOCK_FILE_PATH="
  :lock_created

  if "%TEAMCITY_RESTARTER_SILENT_ACTUAL%" == "" goto non_silent
  call:log "TeamCity server output redirected to %CATALINA_OUT%"
  call:roll "%CATALINA_OUT%" 2147483648
  call "%TEAMCITY_SERVER_INTERNAL_SCRIPT%" run %2 %3 %4 %5 %6 %7 %8 %9 >> "%CATALINA_OUT%" 2>&1
  set RESTARTER_TC_EXIT_CODE=%ERRORLEVEL%
  goto internal_finished
  :non_silent
  call "%TEAMCITY_SERVER_INTERNAL_SCRIPT%" run %2 %3 %4 %5 %6 %7 %8 %9 2>&1
  set RESTARTER_TC_EXIT_CODE=%ERRORLEVEL%
  :internal_finished

  :: In case of failed to create lock file we should not try to restart
  if "%TEAMCITY_RESTART_LOCK_FILE_PATH%" == "" goto end_while

  if not exist "%TEAMCITY_RESTART_LOCK_FILE_PATH%" (
    call:log "Server exited with code %RESTARTER_TC_EXIT_CODE%"
    goto end_while
  )

  set /a "TEAMCITY_RESTART_COUNT=%TEAMCITY_RESTART_COUNT%+1"
  :: Restart after abrupt exit or crash
  if %RESTARTER_TC_EXIT_CODE% EQU 0 (
    if exist "%TEAMCITY_RESTART_REQUESTED_FILE_PATH%" (
      del "%TEAMCITY_RESTART_REQUESTED_FILE_PATH%"
      set TEAMCITY_RESTART_COUNT=0
      call:log "Server exited with code %RESTARTER_TC_EXIT_CODE% and will be restarted: requested-restart marker file found"
      goto while
    )
  )

  if %TEAMCITY_RESTART_COUNT% LSS %TEAMCITY_RESTART_LIMIT_ACTUAL% (
    call:log "Server exited unexpectedly with code %RESTARTER_TC_EXIT_CODE% and will be restarted"
  ) else (
    call:log "Server exited unexpectedly with code %RESTARTER_TC_EXIT_CODE% and restart limit (%TEAMCITY_RESTART_LIMIT_ACTUAL%) is reached" 1>&2
    goto end_while
  )

  goto while

  :end_while
goto:eof

:roll
  if exist %1 call:roll_file_by_size %*
goto:eof

:roll_file_by_size
  set "new_log=%~d1%~p1%~n1.%date:~-4,4%-%date:~-7,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%%~x1"
  if %~z1 GEQ %2 move /Y %1 "%new_log%">nul
goto:eof
