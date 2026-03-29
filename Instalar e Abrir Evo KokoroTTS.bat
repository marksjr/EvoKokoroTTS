@echo off
chcp 65001 >nul 2>&1
title Evo KokoroTTS - Install and Start
cd /d "%~dp0"

echo.
echo  Evo KokoroTTS - Install and Start
echo.
echo  1. The installer will set up the environment.
echo  2. Then the server will start automatically.
echo.

set "EVO_SKIP_PAUSE=1"
call "%~dp0install.bat"
if errorlevel 1 exit /b 1

call "%~dp0start.bat"
