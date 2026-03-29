@echo off
chcp 65001 >nul 2>&1
title Evo KokoroTTS - Server
cd /d "%~dp0"

echo.
echo  Evo KokoroTTS - Starting...
echo.

:: Add local tools to PATH if they exist
if exist "%~dp0ffmpeg\ffmpeg.exe" set "PATH=%~dp0ffmpeg;%PATH%"
if exist "%~dp0ffmpeg\bin\ffmpeg.exe" set "PATH=%~dp0ffmpeg\bin;%PATH%"
if exist "%~dp0espeak-ng\espeak-ng.exe" set "PATH=%~dp0espeak-ng;%PATH%"
if exist "%~dp0espeak-ng\command_line\espeak-ng.exe" set "PATH=%~dp0espeak-ng\command_line;%PATH%"
if exist "%~dp0espeak-ng\eSpeak NG\espeak-ng.exe" set "PATH=%~dp0espeak-ng\eSpeak NG;%PATH%"
if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" set "PATH=C:\Program Files\eSpeak NG;%PATH%"

set "PYTHON_CMD="

:: Detect which Python to use
call :resolve_python
if not defined PYTHON_CMD (
    where python >nul 2>&1
    if errorlevel 1 (
        echo  First run detected. Starting installation...
        echo.
        set "EVO_SKIP_PAUSE=1"
        call "%~dp0install.bat"
        if errorlevel 1 exit /b 1
        call :resolve_python
    ) else (
        set "PYTHON_CMD=python"
    )
)

if not defined PYTHON_CMD (
    echo.
    echo  Python was not found.
    echo  Run the installer: install.bat
    echo.
    pause
    exit /b 1
)

"%PYTHON_CMD%" -c "import uvicorn, fastapi, torch, kokoro" >nul 2>&1
if errorlevel 1 (
    echo  Missing components. Repairing automatically...
    echo.
    set "EVO_SKIP_PAUSE=1"
    call "%~dp0install.bat"
    if errorlevel 1 exit /b 1
    call :resolve_python
)

"%PYTHON_CMD%" -c "import uvicorn, fastapi, torch, kokoro" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  Installation is not complete.
    echo  Run the installer: install.bat
    echo.
    pause
    exit /b 1
)

echo  Server starting...
echo  The browser will open automatically.
echo.
echo  To stop, close this window or press Ctrl+C.
echo.

start "" powershell -WindowStyle Hidden -Command "Start-Sleep 4; Start-Process 'http://localhost:8880'"
"%PYTHON_CMD%" start.py
echo.
echo  Server stopped.
pause
goto :eof

:resolve_python
set "PYTHON_CMD="
if exist "%~dp0python_embedded\python.exe" (
    set "PYTHON_CMD=%~dp0python_embedded\python.exe"
) else if exist "%~dp0venv\Scripts\python.exe" (
    set "PYTHON_CMD=%~dp0venv\Scripts\python.exe"
)
goto :eof
