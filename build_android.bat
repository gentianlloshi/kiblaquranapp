@echo off
echo ===================================
echo Building Kibla App for Android
echo ===================================
echo.

echo Step 1: Clean the project
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b %ERRORLEVEL%
)
echo Flutter clean completed successfully.
echo.

echo Step 2: Get dependencies
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b %ERRORLEVEL%
)
echo Dependencies updated successfully.
echo.

echo Step 3: Building the release APK
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed! Check the errors above.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================
echo Build completed successfully!
echo ===================================
echo.
echo The APK can be found at:
echo F:\kibla_app_project\kibla_app_new\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Done!
pause

