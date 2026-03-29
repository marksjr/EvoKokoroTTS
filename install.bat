@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Evo KokoroTTS - Instalador

echo.
echo  ====================================================
echo        Evo KokoroTTS - Instalador Automatico
echo        Sintese de Voz pt-BR com IA
echo  ====================================================
echo.
echo  Este instalador prepara tudo automaticamente.
echo  Depois dele, basta executar run-kokoro.bat.
echo.

cd /d "%~dp0"
set "ESPEAK_RELEASES_URL=https://github.com/espeak-ng/espeak-ng/releases"
set "ESPEAK_API_URL=https://api.github.com/repos/espeak-ng/espeak-ng/releases/latest"
set "ESPEAK_PORTABLE_ROOT=%~dp0espeak-ng"
set "ESPEAK_PORTABLE_DIR=%~dp0espeak-ng\eSpeak NG"

:: ============================================================
:: 1. Verificar se Python ja existe (sistema ou embedded)
:: ============================================================
echo [1/6] Verificando Python...

if exist "python_embedded\python.exe" (
    echo   Python embedded ja instalado.
    set "PYTHON=%~dp0python_embedded\python.exe"
    goto :check_espeak
)

:: Verificar se existe o zip bundled do Python na pasta do projeto
if exist "%~dp0python_embedded.zip" (
    echo   Encontrado python_embedded.zip bundled. Extraindo...
    mkdir python_embedded 2>nul
    powershell -Command "Expand-Archive -Path 'python_embedded.zip' -DestinationPath 'python_embedded' -Force"
    if errorlevel 1 goto :fail_python_extract
    :: Habilitar pip no embedded Python
    powershell -Command "(Get-Content 'python_embedded\python311._pth') -replace '#import site','import site' | Set-Content 'python_embedded\python311._pth'"
    :: Instalar pip
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'python_embedded\get-pip.py' }"
    if errorlevel 1 goto :fail_pip
    python_embedded\python.exe python_embedded\get-pip.py >nul 2>&1
    if errorlevel 1 goto :fail_pip
    del python_embedded\get-pip.py 2>nul
    set "PYTHON=%~dp0python_embedded\python.exe"
    echo   Python 3.11 Embedded extraido e configurado com sucesso.
    goto :check_espeak
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set pyver=%%i
    echo   Encontrado: !pyver!
    python -c "import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 11) and sys.version_info[:2] < (3, 13) else 1)" >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON=python"
        set "USE_SYSTEM_PYTHON=1"
        echo   Versao compativel detectada. Usando Python do sistema.
    ) else (
        echo   A versao encontrada nao e compativel.
        echo   O instalador vai usar Python 3.11 embedded para evitar erros.
        call :download_python
        if errorlevel 1 goto :fail_end
    )
) else (
    echo   Python nao encontrado. Baixando Python Embedded...
    call :download_python
    if errorlevel 1 goto :fail_end
)

:: ============================================================
:: 2. Verificar espeak-ng
:: ============================================================
:check_espeak
echo.
echo [2/6] Verificando espeak-ng...

where espeak-ng >nul 2>&1
if %errorlevel% equ 0 (
    echo   espeak-ng encontrado no PATH.
    goto :check_ffmpeg
)

if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" (
    echo   espeak-ng encontrado em Program Files.
    set "PATH=C:\Program Files\eSpeak NG;%PATH%"
    goto :check_ffmpeg
)

if exist "%~dp0espeak-ng\espeak-ng.exe" (
    echo   espeak-ng encontrado localmente.
    set "PATH=%~dp0espeak-ng;%PATH%"
    goto :check_ffmpeg
)

if exist "%~dp0espeak-ng\command_line\espeak-ng.exe" (
    echo   espeak-ng encontrado localmente.
    set "PATH=%~dp0espeak-ng\command_line;%PATH%"
    goto :check_ffmpeg
)

if exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" (
    echo   espeak-ng portable encontrado localmente.
    set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"
    goto :check_ffmpeg
)

echo.
echo   espeak-ng nao encontrado.
echo.
if not exist "%~dp0espeak-ng-installer.msi" goto :espeak_download

echo   Instalador espeak-ng encontrado na pasta do projeto.
echo   Abrindo o instalador... Clique em "Next" para instalar.
echo.
msiexec /i "%~dp0espeak-ng-installer.msi"
echo.

:: Verificar se a instalacao via wizard foi bem sucedida
if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" (
    echo   espeak-ng instalado com sucesso!
    set "PATH=C:\Program Files\eSpeak NG;%PATH%"
    goto :check_ffmpeg
)

:: Tentar extrair portable como fallback
echo   Tentando extrair portable como alternativa...
mkdir "%ESPEAK_PORTABLE_ROOT%" 2>nul
if exist "%ESPEAK_PORTABLE_DIR%" rd /s /q "%ESPEAK_PORTABLE_DIR%" 2>nul
msiexec /a "%~dp0espeak-ng-installer.msi" /qn TARGETDIR="%ESPEAK_PORTABLE_ROOT%"
if exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" (
    echo   espeak-ng portable extraido com sucesso!
    set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"
    goto :check_ffmpeg
)

echo.
echo  ERRO: Falha ao instalar espeak-ng.
echo.
pause
exit /b 1

:espeak_download
echo   Baixando e extraindo copia portable local...
echo.
call :download_espeak
if errorlevel 1 (
    echo.
    echo  Nao foi possivel preparar o espeak-ng automaticamente.
    echo  A pagina oficial sera aberta para instalacao manual.
    echo.
    start "" "%ESPEAK_RELEASES_URL%"
    pause
    exit /b 1
)
set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"

:: ============================================================
:: 3. Verificar ffmpeg
:: ============================================================
:check_ffmpeg
echo.
echo [3/6] Verificando ffmpeg...

where ffmpeg >nul 2>&1
if %errorlevel% equ 0 (
    echo   ffmpeg encontrado.
    goto :setup_venv
)

if exist "%~dp0ffmpeg\ffmpeg.exe" (
    echo   ffmpeg encontrado localmente.
    set "PATH=%~dp0ffmpeg;%PATH%"
    goto :setup_venv
)

if exist "%~dp0ffmpeg\bin\ffmpeg.exe" (
    echo   ffmpeg encontrado localmente.
    set "PATH=%~dp0ffmpeg\bin;%PATH%"
    goto :setup_venv
)

if exist "%~dp0ffmpeg_bundled\ffmpeg.exe" (
    echo   Copiando ffmpeg da pasta bundled...
    mkdir ffmpeg 2>nul
    copy /y "%~dp0ffmpeg_bundled\*.exe" ffmpeg\ >nul
    set "PATH=%~dp0ffmpeg;%PATH%"
    echo   ffmpeg configurado com sucesso.
    goto :setup_venv
)

echo   ffmpeg nao encontrado. Baixando (isso pode levar alguns minutos)...
call :download_ffmpeg
if errorlevel 1 (
    echo.
    echo  ERRO: Falha ao baixar o ffmpeg.
    echo  Baixe manualmente de: https://github.com/BtbN/FFmpeg-Builds/releases
    echo  Extraia ffmpeg.exe e ffprobe.exe na pasta ffmpeg_bundled\
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: 4. Criar venv e instalar dependencias
:: ============================================================
:setup_venv
echo.
echo [4/6] Configurando ambiente Python...

if defined USE_SYSTEM_PYTHON (
    if not exist "venv" (
        echo   Criando ambiente virtual...
        %PYTHON% -m venv venv
    )
    set "PYTHON=%~dp0venv\Scripts\python.exe"
    set "PIP=%~dp0venv\Scripts\pip.exe"
)

if not exist "%PYTHON%" (
    echo.
    echo  ERRO: Python configurado, mas o executavel nao foi encontrado.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: 5. Detectar GPU e instalar PyTorch
:: ============================================================
echo.
echo [5/6] Detectando hardware e instalando dependencias...

echo   Atualizando pip...
"%PYTHON%" -m pip install --upgrade pip setuptools wheel
if errorlevel 1 (
    echo.
    echo  ERRO: Falha ao atualizar pip/setuptools/wheel.
    echo.
    pause
    exit /b 1
)

:: Verificar se NVIDIA GPU esta presente
set "HAS_GPU=0"
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    set "HAS_GPU=1"
    echo.
    echo   *** GPU NVIDIA detectada! ***
    echo   Instalando PyTorch com suporte CUDA...
    echo.
    "%PYTHON%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
    if errorlevel 1 (
        echo.
        echo  ERRO: Falha ao instalar PyTorch com CUDA.
        echo.
        pause
        exit /b 1
    )
) else (
    echo.
    echo   Nenhuma GPU NVIDIA detectada. Usando CPU.
    echo   Instalando PyTorch versao CPU (mais leve)...
    echo.
    "%PYTHON%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    if errorlevel 1 (
        echo.
        echo  ERRO: Falha ao instalar PyTorch para CPU.
        echo.
        pause
        exit /b 1
    )
)

echo.
echo   Instalando dependencias do projeto...
"%PYTHON%" -m pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo  ERRO: Falha ao instalar as dependencias do projeto.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: 6. Verificar instalacao
:: ============================================================
echo.
echo [6/6] Verificando instalacao...

"%PYTHON%" -c "import torch; cuda='SIM - GPU sera usada!' if torch.cuda.is_available() else 'NAO - usando CPU'; print(f'  PyTorch: {torch.__version__}'); print(f'  CUDA: {cuda}')"
"%PYTHON%" -c "import kokoro; print('  Kokoro: OK')" 2>nul || echo   Kokoro: sera baixado no primeiro uso
"%PYTHON%" -c "import fastapi; print('  FastAPI: OK')"
"%PYTHON%" -c "import edge_tts; print('  Edge TTS: OK')"

echo.
echo  ====================================================
echo   Evo KokoroTTS - INSTALACAO CONCLUIDA!
echo.
echo   Agora o usuario so precisa abrir:
echo     run-kokoro.bat
echo.
echo   A interface web abrira automaticamente
echo   no navegador em http://localhost:8880
echo  ====================================================
echo.
pause
exit /b 0

:fail_python_extract
echo.
echo  ERRO: Falha ao extrair o Python Embedded do zip bundled.
echo.
pause
exit /b 1

:fail_pip
echo.
echo  ERRO: Falha ao configurar pip no Python Embedded.
echo  Verifique sua conexao com a internet (necessario para baixar pip).
echo.
pause
exit /b 1

:fail_end
echo.
echo  A instalacao foi interrompida devido a um erro.
echo.
pause
exit /b 1

:: ============================================================
:: FUNCAO: Baixar Python Embedded
:: ============================================================
:download_python
if exist "python_embedded\python.exe" (
    set "PYTHON=%~dp0python_embedded\python.exe"
    echo   Python 3.11 Embedded ja esta pronto.
    exit /b 0
)

echo   Baixando Python 3.11 Embedded...
mkdir python_embedded 2>nul
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile 'python_embedded\python.zip' }"
if errorlevel 1 (
    echo   ERRO: Falha ao baixar o Python Embedded.
    exit /b 1
)
powershell -Command "Expand-Archive -Path 'python_embedded\python.zip' -DestinationPath 'python_embedded' -Force"
if errorlevel 1 (
    echo   ERRO: Falha ao extrair o Python Embedded.
    exit /b 1
)
del python_embedded\python.zip 2>nul

:: Habilitar pip no embedded Python
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'python_embedded\get-pip.py' }"
if errorlevel 1 (
    echo   ERRO: Falha ao baixar o instalador do pip.
    exit /b 1
)

:: Descomentar import site no python311._pth
powershell -Command "(Get-Content 'python_embedded\python311._pth') -replace '#import site','import site' | Set-Content 'python_embedded\python311._pth'"

python_embedded\python.exe python_embedded\get-pip.py >nul 2>&1
if errorlevel 1 (
    echo   ERRO: Falha ao instalar o pip no Python Embedded.
    exit /b 1
)
del python_embedded\get-pip.py 2>nul

set "PYTHON=%~dp0python_embedded\python.exe"
echo   Python 3.11 Embedded instalado com sucesso.
exit /b 0

:: ============================================================
:: FUNCAO: Baixar ffmpeg
:: ============================================================
:download_ffmpeg
echo   Baixando ffmpeg...
mkdir ffmpeg 2>nul
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg\ffmpeg.zip' }"
if errorlevel 1 (
    echo   ERRO: Falha ao baixar o ffmpeg.
    exit /b 1
)
powershell -Command "Expand-Archive -Path 'ffmpeg\ffmpeg.zip' -DestinationPath 'ffmpeg\temp' -Force"
if errorlevel 1 (
    echo   ERRO: Falha ao extrair o ffmpeg.
    exit /b 1
)
:: Mover executaveis para pasta ffmpeg
powershell -Command "Get-ChildItem 'ffmpeg\temp' -Recurse -Filter '*.exe' | Move-Item -Destination 'ffmpeg\' -Force"
if errorlevel 1 (
    echo   ERRO: Falha ao preparar os executaveis do ffmpeg.
    exit /b 1
)
rd /s /q ffmpeg\temp 2>nul
del ffmpeg\ffmpeg.zip 2>nul
set "PATH=%~dp0ffmpeg;%PATH%"
echo   ffmpeg instalado com sucesso.
exit /b 0

:: ============================================================
:: FUNCAO: Baixar e extrair espeak-ng portable
:: ============================================================
:download_espeak
echo   Consultando release oficial do espeak-ng...
mkdir "%ESPEAK_PORTABLE_ROOT%" 2>nul
powershell -Command "$release = Invoke-RestMethod -Uri '%ESPEAK_API_URL%'; $asset = $release.assets | Where-Object { $_.name -eq 'espeak-ng.msi' } | Select-Object -First 1; if (-not $asset) { throw 'Asset espeak-ng.msi nao encontrado.' }; $asset.browser_download_url" > "%TEMP%\evo_espeak_url.txt"
if errorlevel 1 goto :download_espeak_fail

set /p ESPEAK_MSI_URL=<"%TEMP%\evo_espeak_url.txt"
del "%TEMP%\evo_espeak_url.txt" 2>nul
if not defined ESPEAK_MSI_URL goto :download_espeak_fail

echo   Baixando espeak-ng portable...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ESPEAK_MSI_URL%' -OutFile '%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi' }"
if errorlevel 1 goto :download_espeak_fail

echo   Extraindo espeak-ng para a pasta local...
if exist "%ESPEAK_PORTABLE_DIR%" rd /s /q "%ESPEAK_PORTABLE_DIR%" 2>nul
msiexec /a "%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi" /qn TARGETDIR="%ESPEAK_PORTABLE_ROOT%"
if errorlevel 1 goto :download_espeak_fail

if not exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" goto :download_espeak_fail

del "%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi" 2>nul
echo   espeak-ng portable preparado com sucesso.
exit /b 0

:download_espeak_fail
echo   Falha ao preparar o espeak-ng portable.
exit /b 1
