@echo off
REM Exline Programming Language Installer for Windows
REM Version: 0.2.0
REM Compatible with: Windows 7, 8, 10, 11

setlocal enabledelayedexpansion

REM Configuration
set EXLINE_VERSION=0.2.0
set BINARY_NAME=exline.exe
set SOURCE_BINARY=.\target\release\exline.exe
set INSTALL_DIR=%ProgramFiles%\Exline
set USER_INSTALL_DIR=%LOCALAPPDATA%\Exline

REM Check for command line arguments
if "%1"=="--help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--version" goto :show_version
if "%1"=="-v" goto :show_version
if "%1"=="--uninstall" goto :uninstall
if "%1"=="--user" set USER_INSTALL=1

REM Main installation
echo ==================================
echo   Exline Programming Language
echo   Windows Installation Script v%EXLINE_VERSION%
echo ==================================
echo.

echo [INFO] Starting installation process...

REM Check if binary exists
if not exist "%SOURCE_BINARY%" (
    echo [ERROR] Exline binary not found at %SOURCE_BINARY%
    echo [ERROR] Please build the project first using: cargo build --release
    pause
    exit /b 1
)

REM Check for admin privileges or user installation
if defined USER_INSTALL (
    set TARGET_DIR=%USER_INSTALL_DIR%
    echo [INFO] Installing to user directory: !TARGET_DIR!
) else (
    REM Try to determine if we have admin privileges
    net session >nul 2>&1
    if !errorlevel! == 0 (
        set TARGET_DIR=%INSTALL_DIR%
        echo [INFO] Installing to system directory: !TARGET_DIR!
    ) else (
        echo [WARNING] Administrator privileges not detected.
        echo [INFO] Installing to user directory: %USER_INSTALL_DIR%
        set TARGET_DIR=%USER_INSTALL_DIR%
    )
)

REM Create installation directory
if not exist "!TARGET_DIR!" (
    echo [INFO] Creating installation directory...
    mkdir "!TARGET_DIR!" 2>nul
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to create directory: !TARGET_DIR!
        echo [ERROR] Please run as administrator or use --user flag
        pause
        exit /b 1
    )
)

REM Backup existing installation
if exist "!TARGET_DIR!\%BINARY_NAME%" (
    echo [WARNING] Existing Exline installation found. Creating backup...
    set BACKUP_NAME=exline_backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.exe
    set BACKUP_NAME=!BACKUP_NAME: =0!
    copy "!TARGET_DIR!\%BINARY_NAME%" "!TARGET_DIR!\!BACKUP_NAME!" >nul
    echo [INFO] Backup created: !BACKUP_NAME!
)

REM Copy the binary
echo [INFO] Installing Exline binary...
copy "%SOURCE_BINARY%" "!TARGET_DIR!\%BINARY_NAME%" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Failed to copy binary to !TARGET_DIR!
    pause
    exit /b 1
)

echo [SUCCESS] Exline binary installed successfully!

REM Add to PATH if not already there
echo [INFO] Checking PATH configuration...
echo !PATH! | findstr /i "!TARGET_DIR!" >nul
if !errorlevel! neq 0 (
    echo [INFO] Adding Exline to PATH...

    if defined USER_INSTALL (
        REM Add to user PATH
        for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set USER_PATH=%%b
        if "!USER_PATH!"=="" (
            set NEW_PATH=!TARGET_DIR!
        ) else (
            set NEW_PATH=!USER_PATH!;!TARGET_DIR!
        )
        reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
        echo [SUCCESS] Added to user PATH. Please restart your command prompt.
    ) else (
        REM Add to system PATH (requires admin)
        for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set SYSTEM_PATH=%%b
        set NEW_PATH=!SYSTEM_PATH!;!TARGET_DIR!
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul 2>&1
        if !errorlevel! == 0 (
            echo [SUCCESS] Added to system PATH. Please restart your command prompt.
        ) else (
            echo [WARNING] Could not add to system PATH automatically.
            echo [INFO] Please manually add !TARGET_DIR! to your PATH environment variable.
        )
    )
) else (
    echo [INFO] Exline directory already in PATH.
)

REM Create examples
set /p CREATE_EXAMPLES="Would you like to install example Exline programs? (Y/n): "
if /i "!CREATE_EXAMPLES!"=="n" goto :skip_examples

set EXAMPLE_DIR=%USERPROFILE%\.exline\examples
echo [INFO] Creating example directory: !EXAMPLE_DIR!
if not exist "!EXAMPLE_DIR!" mkdir "!EXAMPLE_DIR!" 2>nul

REM Create hello world example
echo # Simple Hello World in Exline > "!EXAMPLE_DIR!\hello.exl"
echo def greet(name: String) -^> String >> "!EXAMPLE_DIR!\hello.exl"
echo     "Hello, #{name}!" >> "!EXAMPLE_DIR!\hello.exl"
echo end >> "!EXAMPLE_DIR!\hello.exl"
echo. >> "!EXAMPLE_DIR!\hello.exl"
echo print(greet("World")) >> "!EXAMPLE_DIR!\hello.exl"

REM Create OOP example
echo # Object-Oriented Programming Example in Exline > "!EXAMPLE_DIR!\person.exl"
echo. >> "!EXAMPLE_DIR!\person.exl"
echo class Person >> "!EXAMPLE_DIR!\person.exl"
echo     String name >> "!EXAMPLE_DIR!\person.exl"
echo     Int age >> "!EXAMPLE_DIR!\person.exl"
echo. >> "!EXAMPLE_DIR!\person.exl"
echo     def greet() -^> void >> "!EXAMPLE_DIR!\person.exl"
echo         print("Hello, I'm #{name} and I'm #{age} years old!") >> "!EXAMPLE_DIR!\person.exl"
echo     end >> "!EXAMPLE_DIR!\person.exl"
echo. >> "!EXAMPLE_DIR!\person.exl"
echo     def set_name(new_name: String) -^> void >> "!EXAMPLE_DIR!\person.exl"
echo         name = new_name >> "!EXAMPLE_DIR!\person.exl"
echo     end >> "!EXAMPLE_DIR!\person.exl"
echo. >> "!EXAMPLE_DIR!\person.exl"
echo     def set_age(new_age: Int) -^> void >> "!EXAMPLE_DIR!\person.exl"
echo         age = new_age >> "!EXAMPLE_DIR!\person.exl"
echo     end >> "!EXAMPLE_DIR!\person.exl"
echo end >> "!EXAMPLE_DIR!\person.exl"
echo. >> "!EXAMPLE_DIR!\person.exl"
echo # Create and use a Person object >> "!EXAMPLE_DIR!\person.exl"
echo p = Person.new() >> "!EXAMPLE_DIR!\person.exl"
echo p.set_name("Alice") >> "!EXAMPLE_DIR!\person.exl"
echo p.set_age(30) >> "!EXAMPLE_DIR!\person.exl"
echo p.greet() >> "!EXAMPLE_DIR!\person.exl"

echo [SUCCESS] Example files created in !EXAMPLE_DIR!

:skip_examples

REM Show post-installation information
echo.
echo [SUCCESS] Exline Programming Language v%EXLINE_VERSION% installed successfully!
echo.
echo [INFO] Quick Start:
echo [INFO]   1. Open a new command prompt or PowerShell window
echo [INFO]   2. Create a new .exl file with your Exline code
echo [INFO]   3. Run it with: exline your_file.exl
echo.
echo [INFO] Installation location: !TARGET_DIR!
if exist "!EXAMPLE_DIR!" (
    echo [INFO] Example files: !EXAMPLE_DIR!
    echo [INFO] Try running: exline "!EXAMPLE_DIR!\hello.exl"
)
echo.
echo [INFO] Documentation: https://github.com/msxavi/exline
echo [INFO] Need help? Visit: https://github.com/msxavi/exline/issues
echo.
echo [SUCCESS] Installation completed!
pause
exit /b 0

:show_help
echo Exline Programming Language Windows Installer
echo.
echo Usage: %0 [OPTIONS]
echo.
echo Options:
echo   --help, -h      Show this help message
echo   --version, -v   Show version information
echo   --user          Install to user directory instead of system
echo   --uninstall     Uninstall Exline
echo.
echo Default behavior: Install Exline to system directory (requires admin)
pause
exit /b 0

:show_version
echo Exline Windows Installer v%EXLINE_VERSION%
pause
exit /b 0

:uninstall
echo [INFO] Starting Exline uninstallation...

REM Check both possible installation locations
set FOUND_INSTALL=0
if exist "%INSTALL_DIR%\%BINARY_NAME%" (
    echo [INFO] Found system installation: %INSTALL_DIR%
    del "%INSTALL_DIR%\%BINARY_NAME%" 2>nul
    if !errorlevel! == 0 (
        echo [SUCCESS] Removed system installation.
        set FOUND_INSTALL=1
    ) else (
        echo [ERROR] Failed to remove system installation. Run as administrator.
    )
)

if exist "%USER_INSTALL_DIR%\%BINARY_NAME%" (
    echo [INFO] Found user installation: %USER_INSTALL_DIR%
    del "%USER_INSTALL_DIR%\%BINARY_NAME%" 2>nul
    if !errorlevel! == 0 (
        echo [SUCCESS] Removed user installation.
        set FOUND_INSTALL=1
    ) else (
        echo [ERROR] Failed to remove user installation.
    )
)

if !FOUND_INSTALL! == 0 (
    echo [ERROR] No Exline installation found.
    pause
    exit /b 1
)

REM Optionally remove examples
if exist "%USERPROFILE%\.exline" (
    set /p REMOVE_EXAMPLES="Remove example files from %USERPROFILE%\.exline? (y/N): "
    if /i "!REMOVE_EXAMPLES!"=="y" (
        rmdir /s /q "%USERPROFILE%\.exline" 2>nul
        echo [SUCCESS] Example files removed.
    )
)

echo [SUCCESS] Exline has been uninstalled.
echo [INFO] You may need to restart your command prompt for PATH changes to take effect.
pause
exit /b 0