@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Evo KokoroTTS - Instalador

echo.
echo  ====================================================
echo        Evo KokoroTTS - Instalador Automatico
echo        Sintese de Voz com Inteligencia Artificial
echo  ====================================================
echo.
echo  Aguarde enquanto tudo e preparado automaticamente.
echo  Isso pode levar alguns minutos na primeira vez.
echo.

cd /d "%~dp0"
set "ESPEAK_RELEASES_URL=https://github.com/espeak-ng/espeak-ng/releases"
set "ESPEAK_API_URL=https://api.github.com/repos/espeak-ng/espeak-ng/releases/latest"
set "ESPEAK_PORTABLE_ROOT=%~dp0espeak-ng"
set "ESPEAK_PORTABLE_DIR=%~dp0espeak-ng\eSpeak NG"

:: ============================================================
:: 1. Python
:: ============================================================
echo  [1/6] Preparando Python...

if exist "python_embedded\python.exe" (
    echo         OK - Python ja esta pronto.
    set "PYTHON=%~dp0python_embedded\python.exe"
    goto :check_espeak
)

if exist "%~dp0python_embedded.zip" (
    echo         Extraindo Python da pasta do projeto...
    mkdir python_embedded 2>nul
    powershell -Command "Expand-Archive -Path 'python_embedded.zip' -DestinationPath 'python_embedded' -Force"
    if errorlevel 1 goto :fail_python_extract
    powershell -Command "(Get-Content 'python_embedded\python311._pth') -replace '#import site','import site' | Set-Content 'python_embedded\python311._pth'"
    echo         Configurando gerenciador de pacotes...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'python_embedded\get-pip.py' }"
    if errorlevel 1 goto :fail_pip
    python_embedded\python.exe python_embedded\get-pip.py >nul 2>&1
    if errorlevel 1 goto :fail_pip
    del python_embedded\get-pip.py 2>nul
    set "PYTHON=%~dp0python_embedded\python.exe"
    echo         OK - Python extraido e configurado.
    goto :check_espeak
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set pyver=%%i
    python -c "import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 11) and sys.version_info[:2] < (3, 13) else 1)" >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON=python"
        set "USE_SYSTEM_PYTHON=1"
        echo         OK - Usando Python do sistema.
    ) else (
        echo         Versao incompativel. Baixando Python compativel...
        call :download_python
        if errorlevel 1 goto :fail_end
    )
) else (
    echo         Baixando Python (cerca de 11 MB)...
    call :download_python
    if errorlevel 1 goto :fail_end
)

:: ============================================================
:: 2. espeak-ng
:: ============================================================
:check_espeak
echo.
echo  [2/6] Preparando sintetizador de voz (espeak-ng)...

where espeak-ng >nul 2>&1
if %errorlevel% equ 0 (
    echo         OK - espeak-ng ja esta instalado.
    goto :check_ffmpeg
)

if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" (
    echo         OK - espeak-ng encontrado.
    set "PATH=C:\Program Files\eSpeak NG;%PATH%"
    goto :check_ffmpeg
)

if exist "%~dp0espeak-ng\espeak-ng.exe" (
    echo         OK - espeak-ng encontrado.
    set "PATH=%~dp0espeak-ng;%PATH%"
    goto :check_ffmpeg
)

if exist "%~dp0espeak-ng\command_line\espeak-ng.exe" (
    echo         OK - espeak-ng encontrado.
    set "PATH=%~dp0espeak-ng\command_line;%PATH%"
    goto :check_ffmpeg
)

if exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" (
    echo         OK - espeak-ng encontrado.
    set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"
    goto :check_ffmpeg
)

if not exist "%~dp0espeak-ng-installer.msi" goto :espeak_download

echo.
echo  ----------------------------------------------------
echo   O espeak-ng precisa ser instalado.
echo   Uma janela de instalacao vai abrir agora.
echo   Basta clicar em "Next" ate finalizar.
echo  ----------------------------------------------------
echo.
msiexec /i "%~dp0espeak-ng-installer.msi"
echo.

if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" (
    echo         OK - espeak-ng instalado.
    set "PATH=C:\Program Files\eSpeak NG;%PATH%"
    goto :check_ffmpeg
)

echo         Tentando instalar automaticamente...
mkdir "%ESPEAK_PORTABLE_ROOT%" 2>nul
if exist "%ESPEAK_PORTABLE_DIR%" rd /s /q "%ESPEAK_PORTABLE_DIR%" 2>nul
msiexec /a "%~dp0espeak-ng-installer.msi" /qn TARGETDIR="%ESPEAK_PORTABLE_ROOT%"
if exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" (
    echo         OK - espeak-ng configurado.
    set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"
    goto :check_ffmpeg
)

echo.
echo  ====================================================
echo   NAO FOI POSSIVEL INSTALAR O ESPEAK-NG
echo.
echo   Tente instalar manualmente:
echo   1. Abra o arquivo espeak-ng-installer.msi
echo   2. Clique em Next ate finalizar
echo   3. Rode este instalador novamente
echo  ====================================================
echo.
pause
exit /b 1

:espeak_download
echo         Baixando espeak-ng (cerca de 13 MB)...
call :download_espeak
if errorlevel 1 (
    echo.
    echo  ====================================================
    echo   NAO FOI POSSIVEL BAIXAR O ESPEAK-NG
    echo.
    echo   Verifique sua conexao com a internet e tente
    echo   novamente. Se o problema persistir, baixe
    echo   manualmente em:
    echo   github.com/espeak-ng/espeak-ng/releases
    echo  ====================================================
    echo.
    pause
    exit /b 1
)
set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"

:: ============================================================
:: 3. ffmpeg
:: ============================================================
:check_ffmpeg
echo.
echo  [3/6] Preparando conversor de audio (ffmpeg)...

where ffmpeg >nul 2>&1
if %errorlevel% equ 0 (
    echo         OK - ffmpeg ja esta instalado.
    goto :setup_venv
)

if exist "%~dp0ffmpeg\ffmpeg.exe" (
    echo         OK - ffmpeg encontrado.
    set "PATH=%~dp0ffmpeg;%PATH%"
    goto :setup_venv
)

if exist "%~dp0ffmpeg\bin\ffmpeg.exe" (
    echo         OK - ffmpeg encontrado.
    set "PATH=%~dp0ffmpeg\bin;%PATH%"
    goto :setup_venv
)

if exist "%~dp0ffmpeg_bundled\ffmpeg.exe" (
    echo         Configurando ffmpeg da pasta do projeto...
    mkdir ffmpeg 2>nul
    copy /y "%~dp0ffmpeg_bundled\*.exe" ffmpeg\ >nul
    set "PATH=%~dp0ffmpeg;%PATH%"
    echo         OK - ffmpeg configurado.
    goto :setup_venv
)

echo         Baixando ffmpeg (pode levar alguns minutos)...
echo         Aguarde, o arquivo e grande (~200 MB)...
call :download_ffmpeg
if errorlevel 1 (
    echo.
    echo  ====================================================
    echo   NAO FOI POSSIVEL BAIXAR O FFMPEG
    echo.
    echo   O download pode ter falhado por conexao lenta.
    echo   Voce pode baixar manualmente:
    echo.
    echo   1. Acesse: github.com/BtbN/FFmpeg-Builds/releases
    echo   2. Baixe: ffmpeg-master-latest-win64-gpl-shared.zip
    echo   3. Extraia ffmpeg.exe e ffprobe.exe
    echo   4. Coloque na pasta ffmpeg_bundled\
    echo   5. Rode este instalador novamente
    echo  ====================================================
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: 4. Ambiente Python
:: ============================================================
:setup_venv
echo.
echo  [4/6] Configurando ambiente...

if defined USE_SYSTEM_PYTHON (
    if not exist "venv" (
        echo         Criando ambiente isolado...
        %PYTHON% -m venv venv
    )
    set "PYTHON=%~dp0venv\Scripts\python.exe"
    set "PIP=%~dp0venv\Scripts\pip.exe"
)

if not exist "%PYTHON%" (
    echo.
    echo  ====================================================
    echo   ERRO: Python nao foi encontrado.
    echo.
    echo   Tente apagar a pasta python_embedded e rodar
    echo   este instalador novamente.
    echo  ====================================================
    echo.
    pause
    exit /b 1
)

echo         OK - Ambiente pronto.

:: ============================================================
:: 5. Dependencias (PyTorch + pacotes)
:: ============================================================
echo.
echo  [5/6] Instalando componentes de IA...
echo         Isso pode levar varios minutos na primeira vez.
echo.

echo         Atualizando gerenciador de pacotes...
"%PYTHON%" -m pip install --upgrade pip "setuptools<82" wheel >nul 2>&1
if errorlevel 1 goto :fail_pip_upgrade

set "HAS_GPU=0"
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 goto :install_torch_gpu
goto :install_torch_cpu

:install_torch_gpu
set "HAS_GPU=1"
echo         Placa de video NVIDIA detectada!
echo         Instalando com aceleracao por GPU (mais rapido)...
echo.
"%PYTHON%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
if errorlevel 1 goto :fail_torch
goto :install_requirements

:install_torch_cpu
echo         Nenhuma placa de video NVIDIA encontrada.
echo         Instalando versao para processador (CPU)...
echo.
"%PYTHON%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
if errorlevel 1 goto :fail_torch

:install_requirements
echo.
echo         Instalando demais componentes...
"%PYTHON%" -m pip install -r requirements.txt
if errorlevel 1 goto :fail_requirements

:: ============================================================
:: 6. Verificacao final
:: ============================================================
echo.
echo  [6/6] Verificando se tudo esta funcionando...
echo.

"%PYTHON%" -c "import torch; cuda='SIM (GPU)' if torch.cuda.is_available() else 'NAO (usando CPU)'; print('         PyTorch: OK'); print('         Aceleracao GPU: ' + cuda)"
"%PYTHON%" -c "import kokoro; print('         Kokoro TTS: OK')" 2>nul || echo         Kokoro TTS: sera baixado no primeiro uso
"%PYTHON%" -c "import fastapi; print('         Servidor web: OK')"
"%PYTHON%" -c "import edge_tts; print('         Edge TTS: OK')"

echo.
echo  ====================================================
echo.
echo   INSTALACAO CONCLUIDA COM SUCESSO!
echo.
if defined EVO_SKIP_PAUSE (
echo   Iniciando o servidor automaticamente...
) else (
echo   Para usar, execute:  run-kokoro.bat
echo.
echo   O navegador abrira automaticamente com a
echo   interface em http://localhost:8880
)
echo.
echo  ====================================================
echo.
if not defined EVO_SKIP_PAUSE pause
exit /b 0

:: ============================================================
:: Mensagens de erro amigaveis
:: ============================================================
:fail_pip_upgrade
echo.
echo  ====================================================
echo   ERRO AO PREPARAR O AMBIENTE
echo.
echo   Nao foi possivel atualizar o gerenciador de pacotes.
echo   Verifique sua conexao com a internet e tente
echo   novamente.
echo  ====================================================
echo.
pause
exit /b 1

:fail_torch
echo.
echo  ====================================================
echo   ERRO AO INSTALAR COMPONENTE DE IA
echo.
echo   O PyTorch nao pode ser instalado.
echo   Verifique sua conexao com a internet e tente
echo   novamente. Este download e grande (~200 MB).
echo  ====================================================
echo.
pause
exit /b 1

:fail_requirements
echo.
echo  ====================================================
echo   ERRO AO INSTALAR DEPENDENCIAS
echo.
echo   Alguns componentes nao puderam ser instalados.
echo   Verifique sua conexao com a internet e tente
echo   novamente.
echo  ====================================================
echo.
pause
exit /b 1

:fail_python_extract
echo.
echo  ====================================================
echo   ERRO AO EXTRAIR PYTHON
echo.
echo   O arquivo python_embedded.zip pode estar corrompido.
echo   Tente baixar o projeto novamente do GitHub.
echo  ====================================================
echo.
pause
exit /b 1

:fail_pip
echo.
echo  ====================================================
echo   ERRO AO CONFIGURAR PYTHON
echo.
echo   E necessario conexao com a internet para esta etapa.
echo   Verifique sua conexao e tente novamente.
echo  ====================================================
echo.
pause
exit /b 1

:fail_end
echo.
echo  ====================================================
echo   A INSTALACAO FOI INTERROMPIDA
echo.
echo   Verifique os erros acima e tente novamente.
echo   Se o problema persistir, tente apagar as pastas
echo   python_embedded e venv, e rode novamente.
echo  ====================================================
echo.
pause
exit /b 1

:: ============================================================
:: FUNCAO: Baixar Python Embedded
:: ============================================================
:download_python
if exist "python_embedded\python.exe" (
    set "PYTHON=%~dp0python_embedded\python.exe"
    echo         OK - Python ja esta pronto.
    exit /b 0
)

echo         Baixando Python 3.11 (cerca de 11 MB)...
mkdir python_embedded 2>nul
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile 'python_embedded\python.zip' }"
if errorlevel 1 (
    echo         Falha ao baixar. Verifique sua conexao.
    exit /b 1
)
echo         Extraindo...
powershell -Command "Expand-Archive -Path 'python_embedded\python.zip' -DestinationPath 'python_embedded' -Force"
if errorlevel 1 (
    echo         Falha ao extrair.
    exit /b 1
)
del python_embedded\python.zip 2>nul

echo         Configurando gerenciador de pacotes...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'python_embedded\get-pip.py' }"
if errorlevel 1 (
    echo         Falha ao baixar configurador.
    exit /b 1
)

powershell -Command "(Get-Content 'python_embedded\python311._pth') -replace '#import site','import site' | Set-Content 'python_embedded\python311._pth'"

python_embedded\python.exe python_embedded\get-pip.py >nul 2>&1
if errorlevel 1 (
    echo         Falha ao configurar.
    exit /b 1
)
del python_embedded\get-pip.py 2>nul

set "PYTHON=%~dp0python_embedded\python.exe"
echo         OK - Python instalado.
exit /b 0

:: ============================================================
:: FUNCAO: Baixar ffmpeg
:: ============================================================
:download_ffmpeg
mkdir ffmpeg 2>nul
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg\ffmpeg.zip' }"
if errorlevel 1 (
    echo         Falha ao baixar.
    exit /b 1
)
echo         Extraindo...
powershell -Command "Expand-Archive -Path 'ffmpeg\ffmpeg.zip' -DestinationPath 'ffmpeg\temp' -Force"
if errorlevel 1 (
    echo         Falha ao extrair.
    exit /b 1
)
powershell -Command "Get-ChildItem 'ffmpeg\temp' -Recurse -Filter '*.exe' | Move-Item -Destination 'ffmpeg\' -Force"
if errorlevel 1 (
    echo         Falha ao preparar.
    exit /b 1
)
rd /s /q ffmpeg\temp 2>nul
del ffmpeg\ffmpeg.zip 2>nul
set "PATH=%~dp0ffmpeg;%PATH%"
echo         OK - ffmpeg instalado.
exit /b 0

:: ============================================================
:: FUNCAO: Baixar e extrair espeak-ng portable
:: ============================================================
:download_espeak
mkdir "%ESPEAK_PORTABLE_ROOT%" 2>nul
powershell -Command "$release = Invoke-RestMethod -Uri '%ESPEAK_API_URL%'; $asset = $release.assets | Where-Object { $_.name -eq 'espeak-ng.msi' } | Select-Object -First 1; if (-not $asset) { throw 'Asset espeak-ng.msi nao encontrado.' }; $asset.browser_download_url" > "%TEMP%\evo_espeak_url.txt"
if errorlevel 1 goto :download_espeak_fail

set /p ESPEAK_MSI_URL=<"%TEMP%\evo_espeak_url.txt"
del "%TEMP%\evo_espeak_url.txt" 2>nul
if not defined ESPEAK_MSI_URL goto :download_espeak_fail

powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ESPEAK_MSI_URL%' -OutFile '%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi' }"
if errorlevel 1 goto :download_espeak_fail

echo         Extraindo...
if exist "%ESPEAK_PORTABLE_DIR%" rd /s /q "%ESPEAK_PORTABLE_DIR%" 2>nul
msiexec /a "%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi" /qn TARGETDIR="%ESPEAK_PORTABLE_ROOT%"
if errorlevel 1 goto :download_espeak_fail

if not exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" goto :download_espeak_fail

del "%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi" 2>nul
echo         OK - espeak-ng instalado.
exit /b 0

:download_espeak_fail
echo         Falha ao baixar espeak-ng.
exit /b 1
