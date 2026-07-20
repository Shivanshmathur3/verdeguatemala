@echo off
REM Divya Stones Control Tower — one-click launcher for Windows
cd /d "%~dp0"
echo Installing dependencies (first run only)...
python -m pip install -r requirements.txt >nul 2>&1
echo.
echo Starting Control Tower...
python server.py
pause
