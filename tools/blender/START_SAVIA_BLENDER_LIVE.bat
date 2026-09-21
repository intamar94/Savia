@echo off
setlocal

REM ============================================================
REM SAVIA - Blender Live Development Launcher
REM ============================================================

set "ROOT=%~dp0..\.."
set "BRIDGE=%~dp0live_bridge.py"

REM Default Blender 5.2 LTS installation path.
set "BLENDER=C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"

if not exist "%BLENDER%" (
    echo [SAVIA] Blender 5.2 LTS was not found at:
    echo %BLENDER%
    echo.
    echo Edit this BAT file and set BLENDER to your blender.exe path.
    pause
    exit /b 1
)

cd /d "%ROOT%"

echo.
echo ============================================================
echo SAVIA - BLENDER LIVE MODE
echo ============================================================
echo Repository: %ROOT%
echo Bridge:     %BRIDGE%
echo.
echo Blender will open normally.
echo The SAVIA station will build inside the viewport.
echo Saving savia_field_research_station_v01.py will rebuild it.
echo ============================================================
echo.

"%BLENDER%" --python "%BRIDGE%"

endlocal
