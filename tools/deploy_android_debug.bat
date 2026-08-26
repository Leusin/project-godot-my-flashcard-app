@echo off
rem Export the Android debug APK, install it on the connected phone, launch the app.
rem Paths follow README "Android 배포". Keep this file ASCII-only for cp949 consoles.
setlocal
set "GODOT=C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
set "APK=build\android\my-simple-flash-card-debug.apk"
set "PACKAGE=com.leusin.mysimpleflashcard"

pushd "%~dp0.."

if not exist "build\android" mkdir "build\android"

echo [1/3] export Android debug APK...
"%GODOT%" --headless --path . --export-debug "Android" "%APK%"
if errorlevel 1 goto :fail

echo [2/3] install on connected phone...
"%ADB%" install -r "%APK%"
if errorlevel 1 goto :fail

echo [3/3] launch app...
"%ADB%" shell monkey -p %PACKAGE% -c android.intent.category.LAUNCHER 1 >nul 2>nul

echo.
echo deploy done.
popd
exit /b 0

:fail
echo.
echo deploy FAILED - check the output above.
popd
pause
exit /b 1
