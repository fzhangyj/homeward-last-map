@echo off
setlocal
set "GAME_ENGINE=%~dp0..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GAME_ENGINE%" (
  echo Godot was not found. Open project.godot in Godot 4.3 or newer and press F5.
  pause
  exit /b 1
)
start "" "%GAME_ENGINE%" --path "%~dp0."
