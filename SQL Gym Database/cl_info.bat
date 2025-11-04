@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Help flags ---
IF /I "%~1"=="/?" GOTO :HELP
IF /I "%~1"=="/h" GOTO :HELP
IF /I "%~1"=="--help" GOTO :HELP

REM --- Check argument count ---
IF "%~1"=="" (
    ECHO Error: You must provide a class name.
    ECHO Usage: %~nx0 class_name
    EXIT /B 1
)

IF NOT "%~2"=="" (
    ECHO Error: Too many arguments. Only one class_name allowed.
    EXIT /B 1
)

REM --- Check each argument contains at least one letter ---
ECHO %~1 | FINDSTR /R "[A-Za-z]" >NUL
IF ERRORLEVEL 1 GOTO :BadInput

REM --- Main script logic ---
sqlite3 gym.db ".headers on" ".mode box" ".param set :cn '%1'" ".read sql_files/specific_class_script.sql"

GOTO :EOF


:BadInput
ECHO Error: Invalid input detected. Class name must be a string.
ECHO Example: %~nx0 Bootcamp
EXIT /B 1


:HELP
ECHO.
ECHO Usage: %~nx0 Bootcamp
ECHO Example: %~nx0 Bootcamp
ECHO.
ECHO Description:
ECHO   This batch file retrieves info for any specific class you want.
ECHO   You must provide exactly one string argument.
ECHO.
EXIT /B 0