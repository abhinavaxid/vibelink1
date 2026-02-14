@echo off
REM VibeLink Complete Automation Script (Batch Wrapper)
REM Usage: run-complete-test.bat

echo.
echo ╔═════════════════════════════════════════════╗
echo ║  VibeLink Complete Automation Test Suite   ║
echo ╚═════════════════════════════════════════════╝
echo.

REM Check if PowerShell is available
powershell -Command "if(!$?) {exit 1}" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ PowerShell is required. Please install it.
    exit /b 1
)

REM Run the PowerShell script
echo Running automated tests...
echo.

powershell -ExecutionPolicy Bypass -File run-complete-test.ps1 %*

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Automation script failed
    exit /b 1
)

echo.
echo ✅ Automation script completed
