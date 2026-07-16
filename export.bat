@echo off
title The Cube - Export
set GODOT="C:\Users\Simon\Desktop\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"
set PROJECT="C:\Users\Simon\Cube"

if not exist %GODOT% (
    echo Hittar inte Godot. Uppdatera sokvagen i export.bat
    pause
    exit /b 1
)

if not exist %PROJECT%\build mkdir %PROJECT%\build

echo Exporterar The Cube till build\TheCube.exe ...
%GODOT% --headless --path %PROJECT% --export-release "Windows Desktop" %PROJECT%\build\TheCube.exe

if %ERRORLEVEL%==0 (
    echo.
    echo Klart! Kor spelet fran:
    echo %PROJECT%\build\TheCube.exe
) else (
    echo.
    echo Export misslyckades. Oppna Godot och ladda ner Export Templates:
    echo Editor - Manage Export Templates
)

pause