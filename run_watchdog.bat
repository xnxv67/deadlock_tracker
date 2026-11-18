@echo off
setlocal
cd /d "%~dp0"

echo [watchdog launcher] Starting OpenCode with network watchdog...
echo [watchdog launcher] Project: %CD%
echo.

where python >nul 2>nul
if %ERRORLEVEL%==0 (
  python tools\network_watchdog.py --shell-cmd "opencode"
) else (
  where py >nul 2>nul
  if %ERRORLEVEL%==0 (
    py -3 tools\network_watchdog.py --shell-cmd "opencode"
  ) else (
    echo [watchdog launcher] ERROR: Python was not found in PATH.
    echo Install Python 3 and try again.
    pause
    exit /b 1
  )
)

echo.
echo [watchdog launcher] Watchdog exited with code %ERRORLEVEL%.
pause
