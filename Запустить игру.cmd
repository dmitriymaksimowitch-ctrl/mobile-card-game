@echo off
setlocal
set "GODOT_EXE=%~dp0..\..\work\tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
set "GAME_DIR=%~dp0"
set "GAME_DIR=%GAME_DIR:~0,-1%"

if not exist "%GODOT_EXE%" (
  echo Godot executable was not found:
  echo %GODOT_EXE%
  pause
  exit /b 1
)

if not exist "%GAME_DIR%\project.godot" (
  echo Project file was not found:
  echo %GAME_DIR%\project.godot
  pause
  exit /b 1
)

cd /d "%GAME_DIR%"
start "" "%GODOT_EXE%" --path "%GAME_DIR%"
exit /b 0
