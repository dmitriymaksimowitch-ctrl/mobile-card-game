@echo off
setlocal
set "GODOT_EXE=%~dp0..\..\work\tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
set "GAME_DIR=%~dp0"
set "GAME_DIR=%GAME_DIR:~0,-1%"
cd /d "%GAME_DIR%"
start "" "%GODOT_EXE%" --editor --path "%GAME_DIR%"
exit /b 0
