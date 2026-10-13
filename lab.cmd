@echo off
setlocal
set "LAB_ACTION=%~1"
if not defined LAB_ACTION set "LAB_ACTION=status"
set "LAB_SCRIPT="
set "LAB_ARG="
if "%LAB_ACTION%"=="install" set "LAB_SCRIPT=install.sh"
if "%LAB_ACTION%"=="start" set "LAB_SCRIPT=start-lab.sh"
if "%LAB_ACTION%"=="stop" set "LAB_SCRIPT=stop-lab.sh"
if "%LAB_ACTION%"=="test" set "LAB_SCRIPT=test-lab.sh"
if "%LAB_ACTION%"=="capture" set "LAB_SCRIPT=test-capture.sh"
if "%LAB_ACTION%"=="revoke" set "LAB_SCRIPT=revoke-br2.sh"
if "%LAB_ACTION%"=="restore" set "LAB_SCRIPT=restore-br2.sh"
for %%A in (erp mgmt branch deny status wan tunnel log) do if "%LAB_ACTION%"=="%%A" (
  set "LAB_SCRIPT=demo.sh"
  set "LAB_ARG=%%A"
)
if not defined LAB_SCRIPT (
  echo Usage: lab.cmd install^|start^|stop^|test^|capture^|erp^|mgmt^|branch^|deny^|status^|wan^|tunnel^|log^|revoke^|restore
  exit /b 1
)
for /f "usebackq delims=" %%P in (`wsl.exe -d Ubuntu-24.04 -- wslpath -a "%~dp0."`) do set "LAB_PATH=%%P"
if not defined LAB_PATH exit /b 1
wsl.exe -d Ubuntu-24.04 -u root -- bash "%LAB_PATH%/scripts/%LAB_SCRIPT%" %LAB_ARG%
exit /b %ERRORLEVEL%
