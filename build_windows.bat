@echo off
echo ========================================
echo  Programming Card Host - Windows Build
echo ========================================
echo.

echo [1/4] Cleaning previous build...
call flutter clean
if errorlevel 1 (
    echo Error: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo [2/4] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo Error: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo [3/4] Building Windows Release...
call flutter build windows --release
if errorlevel 1 (
    echo Error: Flutter build failed
    pause
    exit /b 1
)

echo.
echo [4/4] Build completed successfully!
echo.
echo Output location:
echo   build\windows\x64\runner\Release\
echo.
echo Main executable:
echo   build\windows\x64\runner\Release\programming_card_host.exe
echo.
echo ========================================
echo  Next Steps:
echo ========================================
echo 1. Test the application
echo 2. Package the Release folder for distribution
echo 3. Create installer (optional)
echo.
pause
