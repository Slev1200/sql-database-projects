@REM @ECHO OFF
@REM SETLOCAL ENABLEDELAYEDEXPANSION

@REM REM --- Help flags ---
@REM IF /I "%~1"=="/?" GOTO :HELP
@REM IF /I "%~1"=="/h" GOTO :HELP
@REM IF /I "%~1"=="--help" GOTO :HELP

@REM REM --- Check argument count ---
@REM IF "%~2"=="" (
@REM     ECHO Error: You must provide both first and last name.
@REM     ECHO Usage: %~nx0 first_name last_name
@REM     EXIT /B 1
@REM )

@REM IF NOT "%~3"=="" (
@REM     ECHO Error: Too many arguments. Only first and last name allowed.
@REM     EXIT /B 1
@REM )

@REM REM --- Check each argument contains at least one letter ---
@REM ECHO %~1 | FINDSTR /R "[A-Za-z]" >NUL
@REM IF ERRORLEVEL 1 GOTO :BadInput

@REM ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL
@REM IF ERRORLEVEL 1 GOTO :BadInput

@REM REM --- Main script logic ---
@REM sqlite3 gym.db ".headers on" ".mode box" ".param set :fn '%1'"  ".param set :ln '%2'" ".read sql_files/memberships_script.sql"

@REM GOTO :EOF


@REM :BadInput
@REM ECHO Error: Invalid input detected. Both first and last name must be strings.
@REM ECHO Example: %~nx0 John Lennon
@REM EXIT /B 1


@REM :HELP
@REM ECHO.
@REM ECHO Usage: %~nx0 first_name last_name
@REM ECHO Example: %~nx0 John Lennon
@REM ECHO.
@REM ECHO Description:
@REM ECHO   This batch file queries membership data for the specified member.
@REM ECHO   You must provide exactly two string arguments.
@REM ECHO.
@REM EXIT /B 0

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
REM   usrenr.bat FirstName LastName
REM Description:
REM   Shows what classes this member is enrolled in
REM   using enrollments_script.sql
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

REM Run SELECT script for enrollments
sqlite3 gym.db ".headers on" ".mode box" ".param set :fn '%1'"  ".param set :ln '%2'" ".read sql_files/memberships_script.sql"

GOTO :EOF

:BadInputView
ECHO Error: Invalid name. Please provide first and last name as strings.
ECHO Example: %~nx0 Samuel Lenin
EXIT /B 1


REM =================================================
REM REGISTER MODE (/r)
REM Usage:
REM   usrenr.bat /r FirstName LastName "Class Name" DayOfWeek StartTime
REM Example:
REM   usrenr.bat /r Emma Rodriguez "Yoga Basics" Wednesday 07:00
REM Action:
REM   INSERT INTO register_request (... status='enrolled')
REM =================================================
:REGISTER

REM Need exactly 6 args total:
REM   %1 = /r
REM   %2 = FirstName
REM   %3 = LastName
REM   %4 = ClassName (quote if spaced)
REM   %5 = DayOfWeek
REM   %6 = StartTime
IF "%~3"=="" (
    ECHO Error: Missing arguments for /r.
    ECHO Usage: %~nx0 /r member_id membership_id
    EXIT /B 1
)

IF NOT "%~7"=="" (
    ECHO Error: Too many arguments for /r.
    ECHO Usage: %~nx0 /r member_id membership_id
    EXIT /B 1
)

REM Validate names contain letters
@REM ECHO %MEMBER_ID% | FINDSTR /R "^[0-9][0-9]*$" >NUL || GOTO :BadInput
@REM ECHO %MEMBERSHIP_ID% | FINDSTR /R "^[0-9][0-9]*$" >NUL || GOTO :BadInput

SET "MEMBER_ID=%~2"
SET "MEMBERSHIP_ID=%~3"
@REM SET "START_DATE=%~4"

sqlite3 gym.db ^
    "INSERT INTO member_membership_history (member_id, membership_id, start_date, end_date) VALUES (%MEMBER_ID%, %MEMBERSHIP_ID%, DATE('now', '+1 day'), NULL);"

IF ERRORLEVEL 1 (
    ECHO Registration failed.
    EXIT /B 1
)

REM Retrieve and display the friendly names
FOR /F "tokens=1,2 delims=|" %%A IN ('sqlite3 -noheader -separator ^| gym.db "SELECT first_name, last_name FROM members WHERE member_id=%MEMBER_ID%;"') DO (
    SET "FIRST_NAME=%%A"
    SET "LAST_NAME=%%B"
)

FOR /F "tokens=* delims=" %%C IN ('sqlite3 -noheader gym.db "SELECT membership_type FROM memberships WHERE membership_id=%MEMBERSHIP_ID%;"') DO (
    SET "PLAN_NAME=%%C"
)

ECHO Successfully added %PLAN_NAME% membership for %FIRST_NAME% %LAST_NAME% starting %DATE%.
GOTO :EOF

@REM ELSE (
@REM     ECHO Successfully added membership %MEMBERSHIP_ID% for member %MEMBER_ID% starting %START_DATE%.
)

GOTO :EOF

:BadInputReg
ECHO Error: Invalid name for /r.
ECHO Usage: %~nx0 /r FirstName LastName "Class Name" DayOfWeek StartTime
EXIT /B 1


REM =================================================
REM CANCEL MODE (/cancel)
REM Usage:
REM   usrenr.bat /cancel FirstName LastName "Class Name" DayOfWeek StartTime
REM Example:
REM   usrenr.bat /cancel Liam Johnson HIIT Wednesday 07:00
REM   usrenr.bat /cancel Liam Johnson "Yoga Basics" Wednesday 07:00
REM Action:
REM   DELETE FROM register_request WHERE ...;
REM =================================================
:CANCEL

REM Need exactly 6 args total:
REM   %1 = /cancel
REM   %2 = FirstName
REM   %3 = LastName
REM   %4 = ClassName (quote if spaced)
REM   %5 = DayOfWeek
REM   %6 = StartTime
IF "%~6"=="" (
    ECHO Error: Missing arguments for /cancel.
    ECHO Usage: %~nx0 /cancel FirstName LastName "Class Name" DayOfWeek StartTime
    EXIT /B 1
)

IF NOT "%~7"=="" (
    ECHO Error: Too many arguments for /cancel.
    ECHO Usage: %~nx0 /cancel FirstName LastName "Class Name" DayOfWeek StartTime
    EXIT /B 1
)

REM Validate names
@REM ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel
@REM ECHO %~3 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel

SET "FIRST_NAME=%~2"
SET "LAST_NAME=%~3"
SET "CLASS_NAME=%~4"
SET "DAY_OF_WEEK=%~5"
SET "START_TIME=%~6"

sqlite3 gym.db ^
    "DELETE FROM class_registrations WHERE first_name='%FIRST_NAME%' AND last_name='%LAST_NAME%' AND class_name='%CLASS_NAME%' AND day_of_week='%DAY_OF_WEEK%' AND start_time='%START_TIME%';"

IF ERRORLEVEL 1 (
    ECHO Cancellation failed.
    EXIT /B 1
) ELSE (
    ECHO Cancelled registration for %FIRST_NAME% %LAST_NAME% in "%CLASS_NAME%" on %DAY_OF_WEEK% at %START_TIME%.
)

GOTO :EOF

:BadInputCancel
ECHO Error: Invalid name in /cancel.
ECHO Usage: %~nx0 /cancel FirstName LastName "Class Name" DayOfWeek StartTime
EXIT /B 1


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
ECHO   %~nx0 /r 1 10
ECHO.
ECHO Cancel a registration:
ECHO   %~nx0 /cancel FirstName LastName "Class Name" DayOfWeek StartTime
ECHO Example:
ECHO   %~nx0 /cancel Liam Johnson HIIT Wednesday 07:00
ECHO.
EXIT /B 0

