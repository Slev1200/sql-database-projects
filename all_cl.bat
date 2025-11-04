@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Help flags ---
IF /I "%~1"=="/?" GOTO :HELP
IF /I "%~1"=="/h" GOTO :HELP
IF /I "%~1"=="--help" GOTO :HELP

REM --- Check argument count ---
IF "%~1"=="" (
    ECHO Error: You must provide the number of classes you want to see.
    ECHO Usage: %~nx0 num_rows
    EXIT /B 1
)

IF NOT "%~2"=="" (
    ECHO Error: Too many arguments. Only one number allowed.
    EXIT /B 1
)

REM --- Check argument is a number (digits only) ---
SET "ARG=%~1"
FOR /F "delims=0123456789" %%A IN ("%ARG%") DO (
    ECHO Error: Argument must be a number.
    EXIT /B 1
)

IF ERRORLEVEL 1 GOTO :BadInput

REM --- Main script logic ---
REM sqlite3 gym.db ".param set :num_rows %1" ".read sql_files/all_classes_script.sql"

sqlite3 gym.db ".headers on" ".mode box" ".param set :num_rows %1" ".read sql_files/all_classes_script.sql"

GOTO :EOF


:BadInput
ECHO Error: Invalid input detected. Argument must be a number.
ECHO Example: %~nx0 10
EXIT /B 1


:HELP
ECHO.
ECHO Usage: %~nx0 num_rows
ECHO Example: %~nx0 10
ECHO.
ECHO Description:
ECHO   This batch file lists the top N classes from the database.
ECHO   You must provide exactly one numeric argument.
ECHO.
EXIT /B 0
