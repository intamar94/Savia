@echo off
setlocal

REM ============================================================
REM SAVIA - Blender Live Development Launcher
REM Works with Blender 5.2 LTS / common Windows installs
REM ============================================================

set "ROOT=%~dp0..\.."
set "BRIDGE=%~dp0live_bridge.py"

REM Common Blender 5.2 install locations.
set "BLENDER="

if exist "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
if not defined BLENDER if exist "C:\Program Files\Blender Foundation\Blender\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender\blender.exe"

REM If Blender is on PATH, use it.
if not defined BLENDER where blender.exe >nul 2>nul
if not defined BLENDER if %errorlevel%==0 set "BLENDER=blender.exe"

if not defined BLENDER (
    echo.
    echo [SAVIA] No se encontro blender.exe automaticamente.
    echo.
    echo Abre PowerShell y ejecuta:
    echo   where.exe blender
    echo.
    echo Si no devuelve una ruta, abre Blender ^> Help ^> About
    echo o revisa la carpeta de instalacion.
    echo.
    echo Despues pega aqui la ruta de blender.exe en la variable BLENDER.
    echo.
    pause
    exit /b 1
)

cd /d "%ROOT%"

echo.
echo ============================================================
echo SAVIA - BLENDER LIVE MODE
echo ============================================================
echo Blender:    %BLENDER%
echo Repository: %ROOT%
echo Bridge:     %BRIDGE%
echo.
echo Se abrira Blender normalmente.
echo El asset se construira dentro del viewport.
echo Guardar el .py provocara una reconstruccion automatica.
echo ============================================================
echo.

"%BLENDER%" --python "%BRIDGE%"

endlocal
