@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Help flags ---
IF /I "%~1"=="/?" GOTO :HELP
IF /I "%~1"=="/h" GOTO :HELP
IF /I "%~1"=="--help" GOTO :HELP

REM --- Check argument count ---
IF "%~2"=="" (
    ECHO Error: You must provide both first and last name.
    ECHO Usage: %~nx0 first_name last_name
    EXIT /B 1
)

IF NOT "%~3"=="" (
    ECHO Error: Too many arguments. Only first and last name allowed.
    EXIT /B 1
)

REM --- Check each argument contains at least one letter ---
ECHO %~1 | FINDSTR /R "[A-Za-z]" >NUL
IF ERRORLEVEL 1 GOTO :BadInput

ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL
IF ERRORLEVEL 1 GOTO :BadInput

REM --- Main script logic ---
sqlite3 gym.db ".headers on" ".mode box" ".param set :fn '%1'"  ".param set :ln '%2'" ".read sql_files/payments_script.sql"

GOTO :EOF


:BadInput
ECHO Error: Invalid input detected. Both first and last name must be strings.
ECHO Example: %~nx0 John Lennon
EXIT /B 1


:HELP
ECHO.
ECHO Usage: %~nx0 first_name last_name
ECHO Example: %~nx0 John Lennon
ECHO.
ECHO Description:
ECHO   This batch file queries all payments for the specified member.
ECHO   You must provide exactly two string arguments.
ECHO.
EXIT /B 0