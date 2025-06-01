@echo off
echo Building debug APK...
cd android
call .\gradlew assembleDebug --info
echo.
echo If build is successful, the APK can be found at:
echo F:\kibla_app_project\kibla_app_new\build\app\outputs\apk\debug\app-debug.apk
pause

