if not defined ACC goto emptyacc
if "%SEPARATOR%" == "" goto noseparator
set ACC=%ACC%%SEPARATOR%%*
goto end

:noseparator
set ACC=%ACC% %*
goto end

:emptyacc
set ACC=%*
goto end

:end