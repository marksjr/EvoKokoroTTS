@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Evo KokoroTTS - Installer

echo.
echo  Evo KokoroTTS - Automatic Installer
echo  AI-powered Text-to-Speech
echo.
echo  Please wait while everything is set up automatically.
echo  This may take a few minutes on the first run.
echo.

cd /d "%~dp0"
set "ESPEAK_RELEASES_URL=https://github.com/espeak-ng/espeak-ng/releases"
set "ESPEAK_API_URL=https://api.github.com/repos/espeak-ng/espeak-ng/releases/latest"
set "ESPEAK_PORTABLE_ROOT=%~dp0espeak-ng"
set "ESPEAK_PORTABLE_DIR=%~dp0espeak-ng\eSpeak NG"

:: 1. Python
echo  [1/6] Setting up Python...

:: Check embedded Python already extracted
if exist "python_embedded\python.exe" (
    echo         OK - Python is ready.
    set "PYTHON=%~dp0python_embedded\python.exe"
    goto :check_espeak
)

:: Check system Python
where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set pyver=%%i
    python -c "import sys; raise SystemExit(0 if sys.version_info[:2] >= (3, 11) and sys.version_info[:2] < (3, 13) else 1)" >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON=python"
        set "USE_SYSTEM_PYTHON=1"
        echo         OK - Using system Python.
        goto :check_espeak
    )
)

:: Extract bundled zip if available
if exist "%~dp0python_embedded.zip" (
    echo         Extracting bundled Python...
    mkdir python_embedded 2>nul
    powershell -Command "Expand-Archive -Path 'python_embedded.zip' -DestinationPath 'python_embedded' -Force"
    if errorlevel 1 goto :fail_python_extract
    powershell -Command "(Get-Content 'python_embedded\python311._pth') -replace '#import site','import site' | Set-Content 'python_embedded\python311._pth'"
    echo         Setting up package manager...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'python_embedded\get-pip.py' }"
    if errorlevel 1 goto :fail_pip
    python_embedded\python.exe python_embedded\get-pip.py >nul 2>&1
    if errorlevel 1 goto :fail_pip
    del python_embedded\get-pip.py 2>nul
    set "PYTHON=%~dp0python_embedded\python.exe"
    echo         OK - Python extracted and configured.
    goto :check_espeak
)

:: Download as last resort
echo         Downloading Python (about 11 MB)...
call :download_python
if errorlevel 1 goto :fail_end

:: 2. espeak-ng
:check_espeak
echo.
echo  [2/6] Setting up speech engine (espeak-ng)...

where espeak-ng >nul 2>&1
if %errorlevel% equ 0 (
    echo         OK - espeak-ng is installed.
    goto :check_ffmpeg
)

if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" (
    echo         OK - espeak-ng found.
    set "PATH=C:\Program Files\eSpeak NG;%PATH%"
    goto :check_ffmpeg
)

if exist "%~dp0espeak-ng\espeak-ng.exe" (
    echo         OK - espeak-ng found.
    set "PATH=%~dp0espeak-ng;%PATH%"
    goto :check_ffmpeg
)

if exist "%~dp0espeak-ng\command_line\espeak-ng.exe" (
    echo         OK - espeak-ng found.
    set "PATH=%~dp0espeak-ng\command_line;%PATH%"
    goto :check_ffmpeg
)

if exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" (
    echo         OK - espeak-ng found.
    set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"
    goto :check_ffmpeg
)

if not exist "%~dp0espeak-ng-installer.msi" goto :espeak_download

echo.
echo  espeak-ng needs to be installed.
echo  An installer window will open now.
echo  Just click "Next" until it finishes.
echo.
msiexec /i "%~dp0espeak-ng-installer.msi"
echo.

if exist "C:\Program Files\eSpeak NG\espeak-ng.exe" (
    echo         OK - espeak-ng installed.
    set "PATH=C:\Program Files\eSpeak NG;%PATH%"
    goto :check_ffmpeg
)

echo         Trying automatic install...
mkdir "%ESPEAK_PORTABLE_ROOT%" 2>nul
if exist "%ESPEAK_PORTABLE_DIR%" rd /s /q "%ESPEAK_PORTABLE_DIR%" 2>nul
msiexec /a "%~dp0espeak-ng-installer.msi" /qn TARGETDIR="%ESPEAK_PORTABLE_ROOT%"
if exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" (
    echo         OK - espeak-ng configured.
    set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"
    goto :check_ffmpeg
)

echo.
echo  COULD NOT INSTALL ESPEAK-NG
echo.
echo  Try installing manually:
echo  1. Open the file espeak-ng-installer.msi
echo  2. Click Next until it finishes
echo  3. Run this installer again
echo.
pause
exit /b 1

:espeak_download
echo         Downloading espeak-ng (about 13 MB)...
call :download_espeak
if errorlevel 1 (
    echo.
    echo  COULD NOT DOWNLOAD ESPEAK-NG
    echo.
    echo  Check your internet connection and try again.
    echo  If the problem persists, download manually from:
    echo  github.com/espeak-ng/espeak-ng/releases
    echo.
    pause
    exit /b 1
)
set "PATH=%ESPEAK_PORTABLE_DIR%;%PATH%"

:: 3. ffmpeg
:check_ffmpeg
echo.
echo  [3/6] Setting up audio converter (ffmpeg)...

where ffmpeg >nul 2>&1
if %errorlevel% equ 0 (
    echo         OK - ffmpeg is installed.
    goto :setup_venv
)

if exist "%~dp0ffmpeg\ffmpeg.exe" (
    echo         OK - ffmpeg found.
    set "PATH=%~dp0ffmpeg;%PATH%"
    goto :setup_venv
)

if exist "%~dp0ffmpeg\bin\ffmpeg.exe" (
    echo         OK - ffmpeg found.
    set "PATH=%~dp0ffmpeg\bin;%PATH%"
    goto :setup_venv
)

echo         ffmpeg not found. Downloading (~90 MB)...
call :download_ffmpeg
if errorlevel 1 goto :ffmpeg_browser_fallback
goto :setup_venv

:ffmpeg_browser_fallback
echo.
echo  Automatic download failed. Opening browser for manual download...
echo.
echo  INSTRUCTIONS:
echo  1. Your browser will open with the download link.
echo  2. Save the ZIP file anywhere on your computer.
echo  3. Extract ffmpeg.exe and ffprobe.exe from the ZIP.
echo  4. Place them in the ffmpeg folder:
echo     %~dp0ffmpeg\
echo  5. Run this installer again.
echo.
start "" "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
pause
exit /b 1

:: 4. Python environment
:setup_venv
echo.
echo  [4/6] Configuring environment...

if defined USE_SYSTEM_PYTHON (
    if not exist "venv" (
        echo         Creating isolated environment...
        %PYTHON% -m venv venv
    )
    set "PYTHON=%~dp0venv\Scripts\python.exe"
    set "PIP=%~dp0venv\Scripts\pip.exe"
)

if not exist "%PYTHON%" (
    echo.
    echo  ERROR: Python was not found.
    echo.
    echo  Try deleting the python_embedded folder
    echo  and running this installer again.
    echo.
    pause
    exit /b 1
)

echo         OK - Environment ready.

:: 5. Dependencies (PyTorch + packages)
echo.
echo  [5/6] Installing AI components...
echo         This may take several minutes on the first run.
echo.

echo         Updating package manager...
"%PYTHON%" -m pip install --upgrade pip "setuptools<82" wheel >nul 2>&1
if errorlevel 1 goto :fail_pip_upgrade

set "HAS_GPU=0"
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 goto :install_torch_gpu
goto :install_torch_cpu

:install_torch_gpu
set "HAS_GPU=1"
echo         NVIDIA graphics card detected!
echo         Installing with GPU acceleration (faster)...
echo.
"%PYTHON%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
if errorlevel 1 goto :fail_torch
goto :install_requirements

:install_torch_cpu
echo         No NVIDIA graphics card found.
echo         Installing CPU version...
echo.
"%PYTHON%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
if errorlevel 1 goto :fail_torch

:install_requirements
echo.
echo         Installing remaining components...
"%PYTHON%" -m pip install -r requirements.txt
if errorlevel 1 goto :fail_requirements

:: 6. Verification
echo.
echo  [6/6] Verifying installation...
echo.

"%PYTHON%" -c "import torch; cuda='YES (GPU)' if torch.cuda.is_available() else 'NO (using CPU)'; print('         PyTorch: OK'); print('         GPU Acceleration: ' + cuda)"
"%PYTHON%" -c "import kokoro; print('         Kokoro TTS: OK')" 2>nul || echo         Kokoro TTS: will download on first use
"%PYTHON%" -c "import fastapi; print('         Web Server: OK')"
"%PYTHON%" -c "import edge_tts; print('         Edge TTS: OK')"

echo.
if defined EVO_SKIP_PAUSE (
echo  INSTALLATION COMPLETE - Starting server...
) else (
echo  INSTALLATION COMPLETE
echo.
echo  To start, run:  start.bat
)
echo.
if not defined EVO_SKIP_PAUSE pause
exit /b 0

:: Error messages
:fail_pip_upgrade
echo.
echo  ERROR: Could not update package manager.
echo  Check your internet connection and try again.
echo.
pause
exit /b 1

:fail_torch
echo.
echo  ERROR: Could not install AI component.
echo  Check your internet connection and try again.
echo  This download is large (~200 MB).
echo.
pause
exit /b 1

:fail_requirements
echo.
echo  ERROR: Could not install dependencies.
echo  Check your internet connection and try again.
echo.
pause
exit /b 1

:fail_python_extract
echo.
echo  ERROR: Could not extract Python.
echo  The python_embedded.zip file may be corrupted.
echo  Try downloading the project again from GitHub.
echo.
pause
exit /b 1

:fail_pip
echo.
echo  ERROR: Could not configure Python.
echo  Internet connection is required for this step.
echo  Check your connection and try again.
echo.
pause
exit /b 1

:fail_end
echo.
echo  INSTALLATION WAS INTERRUPTED
echo.
echo  Check the errors above and try again.
echo  If the problem persists, try deleting the
echo  python_embedded and venv folders, then run again.
echo.
pause
exit /b 1

:: FUNCTION: Download Python Embedded
:download_python
if exist "python_embedded\python.exe" (
    set "PYTHON=%~dp0python_embedded\python.exe"
    echo         OK - Python is ready.
    exit /b 0
)

echo         Downloading Python 3.11 (about 11 MB)...
mkdir python_embedded 2>nul
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile 'python_embedded\python.zip' }"
if errorlevel 1 (
    echo         Download failed. Check your connection.
    exit /b 1
)
echo         Extracting...
powershell -Command "Expand-Archive -Path 'python_embedded\python.zip' -DestinationPath 'python_embedded' -Force"
if errorlevel 1 (
    echo         Extraction failed.
    exit /b 1
)
del python_embedded\python.zip 2>nul

echo         Setting up package manager...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'python_embedded\get-pip.py' }"
if errorlevel 1 (
    echo         Download failed.
    exit /b 1
)

powershell -Command "(Get-Content 'python_embedded\python311._pth') -replace '#import site','import site' | Set-Content 'python_embedded\python311._pth'"

python_embedded\python.exe python_embedded\get-pip.py >nul 2>&1
if errorlevel 1 (
    echo         Setup failed.
    exit /b 1
)
del python_embedded\get-pip.py 2>nul

set "PYTHON=%~dp0python_embedded\python.exe"
echo         OK - Python installed.
exit /b 0

:: FUNCTION: Download ffmpeg
:download_ffmpeg
set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
mkdir ffmpeg 2>nul

:: Try curl.exe first (built into Windows 10/11, much faster)
where curl.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo         Downloading with curl...
    curl.exe -L -o "ffmpeg\ffmpeg.zip" "%FFMPEG_URL%"
    if errorlevel 1 goto :ffmpeg_download_fail
    goto :ffmpeg_extract
)

:: Fallback to PowerShell
echo         Downloading with PowerShell (may be slower)...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%FFMPEG_URL%' -OutFile 'ffmpeg\ffmpeg.zip' }"
if errorlevel 1 goto :ffmpeg_download_fail

:ffmpeg_extract
echo         Extracting...
powershell -Command "Expand-Archive -Path 'ffmpeg\ffmpeg.zip' -DestinationPath 'ffmpeg\temp' -Force"
if errorlevel 1 goto :ffmpeg_download_fail
powershell -Command "Get-ChildItem 'ffmpeg\temp' -Recurse -Filter '*.exe' | Move-Item -Destination 'ffmpeg\' -Force"
if errorlevel 1 goto :ffmpeg_download_fail
rd /s /q ffmpeg\temp 2>nul
del ffmpeg\ffmpeg.zip 2>nul
set "PATH=%~dp0ffmpeg;%PATH%"
echo         OK - ffmpeg installed.
exit /b 0

:ffmpeg_download_fail
rd /s /q ffmpeg\temp 2>nul
del ffmpeg\ffmpeg.zip 2>nul
exit /b 1

:: FUNCTION: Download espeak-ng portable
:download_espeak
mkdir "%ESPEAK_PORTABLE_ROOT%" 2>nul
powershell -Command "$release = Invoke-RestMethod -Uri '%ESPEAK_API_URL%'; $asset = $release.assets | Where-Object { $_.name -eq 'espeak-ng.msi' } | Select-Object -First 1; if (-not $asset) { throw 'Asset espeak-ng.msi nao encontrado.' }; $asset.browser_download_url" > "%TEMP%\evo_espeak_url.txt"
if errorlevel 1 goto :download_espeak_fail

set /p ESPEAK_MSI_URL=<"%TEMP%\evo_espeak_url.txt"
del "%TEMP%\evo_espeak_url.txt" 2>nul
if not defined ESPEAK_MSI_URL goto :download_espeak_fail

powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ESPEAK_MSI_URL%' -OutFile '%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi' }"
if errorlevel 1 goto :download_espeak_fail

echo         Extracting...
if exist "%ESPEAK_PORTABLE_DIR%" rd /s /q "%ESPEAK_PORTABLE_DIR%" 2>nul
msiexec /a "%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi" /qn TARGETDIR="%ESPEAK_PORTABLE_ROOT%"
if errorlevel 1 goto :download_espeak_fail

if not exist "%ESPEAK_PORTABLE_DIR%\espeak-ng.exe" goto :download_espeak_fail

del "%ESPEAK_PORTABLE_ROOT%\espeak-ng.msi" 2>nul
echo         OK - espeak-ng installed.
exit /b 0

:download_espeak_fail
echo         Failed to download espeak-ng.
exit /b 1
