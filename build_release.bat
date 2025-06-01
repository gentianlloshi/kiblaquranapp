@echo off
echo Cleaning Flutter project...
flutter clean
echo.
echo Building Release APK...
flutter build apk --release --split-debug-info=build/release/symbols
echo.
echo If successful, the APK can be found at:
echo F:\kibla_app_project\kibla_app_new\build\app\outputs\flutter-apk\app-release.apk
pause

