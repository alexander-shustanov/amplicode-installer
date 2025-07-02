@echo off
setlocal enabledelayedexpansion

REM === Конфигурация ===
set "CACHE_DIR=%TEMP%\plugin-installer-cache"
mkdir "%CACHE_DIR%" >nul 2>&1


REM === Список поддерживаемых версий и URL плагинов ===
call :get_plugin_url "2025.1" url_2025_1
call :get_plugin_url "2024.3" url_2024_3
call :get_plugin_url "2024.2" url_2024_2
call :get_plugin_url "2024.1" url_2024_1
call :get_plugin_url "2023.2" url_2023_2

REM === Каталоги с настройками IDE ===
set "IDE_DIRS=%APPDATA%\JetBrains %APPDATA%\GIGAIDE"

echo Looking for installed IDEs...

for %%D in (%IDE_DIRS%) do (
    if exist "%%D" (
        for /d %%I in ("%%D\*") do (
            set "IDE_NAME=%%~nxI"
            echo.
            echo Found: !IDE_NAME!
            call :install_plugin "%%~nxI" "%%~fI"
        )
    )
)

echo.
echo Done.
exit /b


REM === Функция: установить плагин ===
:install_plugin
set "IDE_NAME=%~1"
set "IDE_PATH=%~2"

REM Извлечь версию из имени
for /f "tokens=1,2 delims=-" %%a in ("%IDE_NAME%") do (
    set "PART1=%%a"
    set "PART2=%%b"
)

set "VERSION="
for /f "tokens=*" %%v in ('echo %IDE_NAME% ^| findstr /r "[0-9][0-9][0-9][0-9]\.[0-9]"') do (
    set "VERSION=%%v"
)

if "%VERSION%"=="" (
    echo ❓ Could not determine version from %IDE_NAME%
    exit /b
)

REM Определить URL по версии
set "URL="
if "%VERSION%"=="2024.1" set "URL=%url_2024_1%"
if "%VERSION%"=="2024.2" set "URL=%url_2024_2%"
if "%VERSION%"=="2025.1" set "URL=%url_2025_1%"

if "%URL%"=="" (
    echo ⏭️  No plugin available for version %VERSION%
    exit /b
)

set "ZIP_NAME=plugin-%VERSION%.zip"
set "ZIP_PATH=%CACHE_DIR%\%ZIP_NAME%"

if exist "%ZIP_PATH%" (
    echo 📦 Using cached %ZIP_NAME%
) else (
    echo ⬇️  Downloading plugin for %IDE_NAME% (%VERSION%)...
    curl --silent --show-error --location "%URL%" --output "%ZIP_PATH%"
)

set "PLUGIN_DIR=%IDE_PATH%\plugins"
mkdir "%PLUGIN_DIR%" >nul 2>&1

echo 📦 Extracting into %PLUGIN_DIR%
tar -xf "%ZIP_PATH%" -C "%PLUGIN_DIR%" 2>nul

if errorlevel 1 (
    echo ⚠️  Extraction failed. Retrying download...
    del /f /q "%ZIP_PATH%"
    curl --silent --show-error --location "%URL%" --output "%ZIP_PATH%"
    tar -xf "%ZIP_PATH%" -C "%PLUGIN_DIR%" 2>nul
    if errorlevel 1 (
        echo ❌ Still failed. Skipping %IDE_NAME%
        exit /b
    ) else (
        echo ✅ Installed after retry
    )
) else (
    echo ✅ Installed successfully
)

exit /b

:get_plugin_url
set "VERSION=%~1"
set "VAR=%~2"

if "%VERSION%"=="2025.1" set "%VAR%=https://amplicode.ru/Amplicode/amplicode-2025.1.4-251.zip"
if "%VERSION%"=="2024.3" set "%VAR%=https://amplicode.ru/Amplicode/amplicode-2025.1.4-243.zip"
if "%VERSION%"=="2024.2" set "%VAR%=https://amplicode.ru/Amplicode/amplicode-2025.1.4-242.zip"
if "%VERSION%"=="2024.1" set "%VAR%=https://amplicode.ru/Amplicode/amplicode-2024.3.6-241-EAP.zip"
if "%VERSION%"=="2023.2" set "%VAR%=https://amplicode.ru/Amplicode/amplicode-2024.1.6-232-EAP.zip"

exit /b
