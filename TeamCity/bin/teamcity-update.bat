@echo off
:: This script is internal and should not be called directly, it's used during server auto update.

if [%1] == [] goto usage
if [%2] == [] goto usage

set CURRENT_DIR=%~1
set UPDATE_DIR=%~2

echo Starting the update process
"%JAVA_HOME%\bin\java.exe" -jar "%UPDATE_DIR%\bin\teamcity-server-update.jar" "%CURRENT_DIR%" "%UPDATE_DIR%" 2>&1
echo Update finished

goto completed

:usage
echo This script is internal and should not be called directly, it's used during server auto update.

:completed

