@echo off
echo Cleaning Flutter project...
flutter clean
echo.
echo Building Flutter APK with --split-debug-info...
flutter build apk --debug --split-debug-info=build/debug/symbols
echo.
echo If successful, the APK can be found at:
echo "F:\kibla_app_project\kibla_app_new\build\app\outputs\flutter-apk\app-debug.apk"
pause

