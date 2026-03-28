@echo off
chcp 65001 >nul 2>&1
title Evo KokoroTTS - Servidor
cd /d "%~dp0"

echo.
echo  Evo KokoroTTS - Iniciando servidor...
echo  Interface web: http://localhost:8880
echo  Pressione Ctrl+C para encerrar.
echo.

:: Adicionar ferramentas locais ao PATH se existirem
if exist "%~dp0ffmpeg\ffmpeg.exe" set "PATH=%~dp0ffmpeg;%PATH%"
if exist "%~dp0ffmpeg\bin\ffmpeg.exe" set "PATH=%~dp0ffmpeg\bin;%PATH%"
if exist "%~dp0espeak-ng\espeak-ng.exe" set "PATH=%~dp0espeak-ng;%PATH%"
if exist "%~dp0espeak-ng\command_line\espeak-ng.exe" set "PATH=%~dp0espeak-ng\command_line;%PATH%"
if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" set "PATH=C:\Program Files\eSpeak NG;%PATH%"

set "PYTHON_CMD="

:: Detectar qual Python usar
call :resolve_python
if not defined PYTHON_CMD (
    where python >nul 2>&1
    if errorlevel 1 (
        echo.
        echo  Nenhum Python configurado foi encontrado.
        echo  O instalador sera aberto para preparar o ambiente.
        echo.
        call "%~dp0install.bat"
        if errorlevel 1 exit /b 1
        call :resolve_python
    ) else (
        set "PYTHON_CMD=python"
    )
)

if not defined PYTHON_CMD (
    echo.
    echo  O Python ainda nao foi configurado corretamente.
    echo.
    pause
    exit /b 1
)

"%PYTHON_CMD%" -c "import uvicorn, fastapi, torch, kokoro" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  Dependencias ausentes ou instalacao incompleta detectada.
    echo  Iniciando reparo automatico...
    echo.
    call "%~dp0install.bat"
    if errorlevel 1 exit /b 1
    call :resolve_python
)

"%PYTHON_CMD%" -c "import uvicorn, fastapi, torch, kokoro" >nul 2>&1
if errorlevel 1 (
    echo.
    echo  A instalacao nao foi concluida corretamente.
    echo  Execute install.bat manualmente e tente novamente.
    echo.
    pause
    exit /b 1
)

"%PYTHON_CMD%" start.py
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
