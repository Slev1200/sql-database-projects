@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM ------------------------------
REM Help flags
REM ------------------------------
IF /I "%~1"=="/?" GOTO :HELP
IF /I "%~1"=="/h" GOTO :HELP
IF /I "%~1"=="--help" GOTO :HELP

REM ------------------------------
REM Mode dispatch based on first arg
REM ------------------------------
IF /I "%~1"=="/r"      GOTO :REGISTER
IF /I "%~1"=="/cancel" GOTO :CANCEL

REM Otherwise default to VIEW mode
GOTO :VIEW


REM =================================================
REM VIEW MODE
REM Usage:
REM   memberships.bat FirstName LastName
REM Description:
REM   Shows what classes this member is enrolled in
REM   using memberships_script.sql
REM =================================================
:VIEW

REM Require exactly 2 args
IF "%~2"=="" (
    ECHO Error: Missing arguments.
    ECHO Usage: %~nx0 FirstName LastName
    EXIT /B 1
)

IF NOT "%~3"=="" (
    ECHO Error: Too many arguments.
    ECHO Usage: %~nx0 FirstName LastName
    EXIT /B 1
)

REM Basic sanity: must contain at least one letter
ECHO %~1 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputView
ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputView

REM Run SELECT script for memberships
sqlite3 gym.db ".headers on" ".mode box" ".param set :fn '%1'"  ".param set :ln '%2'" ".read sql_files/memberships_script.sql"

GOTO :EOF

:BadInputView
ECHO Error: Invalid name. Please provide first and last name as strings.
ECHO Example: %~nx0 Liam Johnson
EXIT /B 1


REM =================================================
REM REGISTER MODE (/r)
REM Usage:
REM   memberships.bat /r member_id membership_id
REM Example:
REM   memberships.bat /r 2 10
REM =================================================
:REGISTER

REM Need exactly 3 args total:
REM   %1 = /r
REM   %2 = member_id
REM   %3 = membership_id

REM Args: /r member_id membership_id
IF "%~3"=="" (
  ECHO Error: Missing arguments for /r.
  ECHO Usage: %~nx0 /r member_id membership_id
  EXIT /B 1
)
IF NOT "%~4"=="" (
  ECHO Error: Too many arguments for /r.
  ECHO Usage: %~nx0 /r member_id membership_id
  EXIT /B 1
)
REM
SET "MEMBER_ID=%~2"
SET "MEMBERSHIP_ID=%~3"
REM
REM Insert the history row (start_date = tomorrow)
sqlite3 gym.db "INSERT INTO member_membership_history (member_id, membership_id, start_date, end_date) VALUES (%MEMBER_ID%, %MEMBERSHIP_ID%, DATE('now','+1 day'), NULL);"

IF ERRORLEVEL 1 (
  ECHO Registration failed.
  EXIT /B 1
)

REM Pull friendly names and the exact start_date we just inserted

FOR /F "tokens=1-4 delims=|" %%A IN ('
  sqlite3 -noheader -separator "|" gym.db ".param clear" ".param set :mid %MEMBER_ID%" ".param set :msid %MEMBERSHIP_ID%" ".read sql_files/mmh_lookup.sql"
') DO (
  SET "FIRST_NAME=%%A"
  SET "LAST_NAME=%%B"
  SET "PLAN_NAME=%%C"
  SET "START_DATE=%%D"
)

ECHO Successfully added !PLAN_NAME! membership for !FIRST_NAME! !LAST_NAME! starting !START_DATE!.
GOTO :EOF

:HELP
ECHO.
ECHO Usage:
ECHO   %~nx0 FirstName LastName
ECHO   %~nx0 /r member_id membership_id
ECHO.
ECHO Examples:
ECHO   %~nx0 Emma Rodriguez
ECHO   %~nx0 /r 2 10
ECHO.
EXIT /B 0

GOTO :EOF

REM =================================================
REM HELP
REM =================================================
:HELP
ECHO.
ECHO View current enrollments:
ECHO   %~nx0 FirstName LastName
ECHO.
ECHO Register for a class:
ECHO   %~nx0 /r member_id membership_id
ECHO Example:
ECHO   %~nx0 /r 2 10
ECHO.
EXIT /B 0

