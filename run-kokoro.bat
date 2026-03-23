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
if exist "%~dp0espeak-ng\espeak-ng.exe" set "PATH=%~dp0espeak-ng;%PATH%"
if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" set "PATH=C:\Program Files\eSpeak NG;%PATH%"

:: Detectar qual Python usar
if exist "%~dp0python_embedded\python.exe" (
    "%~dp0python_embedded\python.exe" start.py
) else if exist "%~dp0venv\Scripts\python.exe" (
    "%~dp0venv\Scripts\python.exe" start.py
) else (
    python start.py
)

pause
