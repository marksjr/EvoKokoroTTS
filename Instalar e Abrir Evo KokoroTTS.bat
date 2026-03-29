@echo off
chcp 65001 >nul 2>&1
title Evo KokoroTTS - Instalar e Abrir
cd /d "%~dp0"

echo.
echo  ====================================================
echo        Evo KokoroTTS - Instalar e Abrir
echo.
echo        Tudo sera preparado automaticamente.
echo        Aguarde...
echo  ====================================================
echo.

set "EVO_SKIP_PAUSE=1"
call "%~dp0install.bat"
if errorlevel 1 exit /b 1

call "%~dp0run-kokoro.bat"
