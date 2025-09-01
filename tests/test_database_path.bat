@echo off
echo Testing DewaruciCpp Database Path Configuration
echo.

echo Building test executable...
cd /d "c:\Pranala\Projects\DewaruciCpp"

:: Build test executable
cmake -S . -B build-test -DCMakeList_FILE=CMakeListsTest.txt
if %ERRORLEVEL% neq 0 (
    echo Failed to configure test build
    pause
    exit /b 1
)

cmake --build build-test --config Debug
if %ERRORLEVEL% neq 0 (
    echo Failed to build test executable
    pause
    exit /b 1
)

echo.
echo Running database path test...
echo.

:: Run test
build-test\Debug\testDatabasePath.exe

echo.
echo Test completed. Check output above for results.
echo Database should be created in your home directory under:
echo %USERPROFILE%\DewaruciCpp\app\dewarucidb\dewaruci.db
echo.

pause
