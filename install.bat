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

:: ============================================================
:: 1. Verificar se Python ja existe (sistema ou embedded)
:: ============================================================
echo [1/6] Verificando Python...

if exist "python_embedded\python.exe" (
    echo   Python embedded ja instalado.
    set "PYTHON=%~dp0python_embedded\python.exe"
    goto :check_espeak
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set pyver=%%i
    echo   Encontrado: !pyver!
    set "PYTHON=python"
    set "USE_SYSTEM_PYTHON=1"
) else (
    echo   Python nao encontrado. Baixando Python Embedded...
    call :download_python
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

echo.
echo  ************************************************************
echo  *  ATENCAO: espeak-ng NAO encontrado!                      *
echo  *                                                           *
echo  *  O espeak-ng e necessario para a sintese de voz.          *
echo  *  Baixe e instale de:                                      *
echo  *  https://github.com/espeak-ng/espeak-ng/releases          *
echo  *                                                           *
echo  *  Baixe o arquivo .msi, instale, e marque a opcao          *
echo  *  de adicionar ao PATH do sistema.                         *
echo  *  Alternativa portable: extraia o espeak-ng em             *
echo  *  .\espeak-ng\ ou .\espeak-ng\command_line\                *
echo  ************************************************************
echo.
echo  Apos instalar o espeak-ng, execute este instalador novamente.
echo.
pause
exit /b 1

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

echo   ffmpeg nao encontrado. Baixando...
call :download_ffmpeg

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

if not exist "%PYTHON%" call :fail "Python configurado, mas o executavel nao foi encontrado."

:: ============================================================
:: 5. Detectar GPU e instalar PyTorch
:: ============================================================
echo.
echo [5/6] Detectando hardware e instalando dependencias...

echo   Atualizando pip...
"%PYTHON%" -m pip install --upgrade pip setuptools wheel
if errorlevel 1 call :fail "Falha ao atualizar pip/setuptools/wheel."

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
    if errorlevel 1 call :fail "Falha ao instalar PyTorch com CUDA."
) else (
    echo.
    echo   Nenhuma GPU NVIDIA detectada. Usando CPU.
    echo   Instalando PyTorch versao CPU (mais leve)...
    echo.
    "%PYTHON%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    if errorlevel 1 call :fail "Falha ao instalar PyTorch para CPU."
)

echo.
echo   Instalando dependencias do projeto...
"%PYTHON%" -m pip install -r requirements.txt
if errorlevel 1 call :fail "Falha ao instalar as dependencias do projeto."

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

:fail
echo.
echo  ERRO: %~1
echo.
pause
exit /b 1

:: ============================================================
:: FUNCAO: Baixar Python Embedded
:: ============================================================
:download_python
echo   Baixando Python 3.11 Embedded...
mkdir python_embedded 2>nul
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile 'python_embedded\python.zip' }"
if errorlevel 1 call :fail "Falha ao baixar o Python Embedded."
powershell -Command "Expand-Archive -Path 'python_embedded\python.zip' -DestinationPath 'python_embedded' -Force"
if errorlevel 1 call :fail "Falha ao extrair o Python Embedded."
del python_embedded\python.zip 2>nul

:: Habilitar pip no embedded Python
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'python_embedded\get-pip.py' }"
if errorlevel 1 call :fail "Falha ao baixar o instalador do pip."

:: Descomentar import site no python311._pth
powershell -Command "(Get-Content 'python_embedded\python311._pth') -replace '#import site','import site' | Set-Content 'python_embedded\python311._pth'"

python_embedded\python.exe python_embedded\get-pip.py >nul 2>&1
if errorlevel 1 call :fail "Falha ao instalar o pip no Python Embedded."
del python_embedded\get-pip.py 2>nul

set "PYTHON=%~dp0python_embedded\python.exe"
echo   Python 3.11 Embedded instalado com sucesso.
goto :eof

:: ============================================================
:: FUNCAO: Baixar ffmpeg
:: ============================================================
:download_ffmpeg
echo   Baixando ffmpeg...
mkdir ffmpeg 2>nul
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg\ffmpeg.zip' }"
if errorlevel 1 call :fail "Falha ao baixar o ffmpeg."
powershell -Command "Expand-Archive -Path 'ffmpeg\ffmpeg.zip' -DestinationPath 'ffmpeg\temp' -Force"
if errorlevel 1 call :fail "Falha ao extrair o ffmpeg."
:: Mover executaveis para pasta ffmpeg
powershell -Command "Get-ChildItem 'ffmpeg\temp' -Recurse -Filter '*.exe' | Move-Item -Destination 'ffmpeg\' -Force"
if errorlevel 1 call :fail "Falha ao preparar os executaveis do ffmpeg."
rd /s /q ffmpeg\temp 2>nul
del ffmpeg\ffmpeg.zip 2>nul
set "PATH=%~dp0ffmpeg;%PATH%"
echo   ffmpeg instalado com sucesso.
goto :eof
