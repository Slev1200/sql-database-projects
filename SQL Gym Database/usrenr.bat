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
sqlite3 gym.db ".headers on" ".mode box" ".param set :fn '%1'"  ".param set :ln '%2'" ".read sql_files/enrollments_script.sql"


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
IF "%~6"=="" (
    ECHO Error: Missing arguments for /r.
    ECHO Usage: %~nx0 /r FirstName LastName "Class Name" DayOfWeek StartTime
    EXIT /B 1
)

IF NOT "%~7"=="" (
    ECHO Error: Too many arguments for /r.
    ECHO Usage: %~nx0 /r FirstName LastName "Class Name" DayOfWeek StartTime
    EXIT /B 1
)

REM Validate names contain letters
ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputReg
ECHO %~3 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputReg

SET "FIRST_NAME=%~2"
SET "LAST_NAME=%~3"
SET "CLASS_NAME=%~4"
SET "DAY_OF_WEEK=%~5"
SET "START_TIME=%~6"

sqlite3 gym.db ^
    "INSERT INTO register_request (first_name, last_name, class_name, day_of_week, start_time, status) VALUES ('%FIRST_NAME%','%LAST_NAME%','%CLASS_NAME%','%DAY_OF_WEEK%','%START_TIME%','enrolled');"

IF ERRORLEVEL 1 (
    ECHO Registration failed.
    EXIT /B 1
) ELSE (
    ECHO Successfully enrolled %FIRST_NAME% %LAST_NAME% in "%CLASS_NAME%" on %DAY_OF_WEEK% at %START_TIME%.
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
REM   DELETE FROM class_registrations WHERE ...;
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
ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel
ECHO %~3 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel

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
ECHO   %~nx0 /r FirstName LastName "Class Name" DayOfWeek StartTime
ECHO Example:
ECHO   %~nx0 /r Emma Rodriguez "Yoga Basics" Wednesday 07:00
ECHO.
ECHO Cancel a registration:
ECHO   %~nx0 /cancel FirstName LastName "Class Name" DayOfWeek StartTime
ECHO Example:
ECHO   %~nx0 /cancel Liam Johnson HIIT Wednesday 07:00
ECHO.
EXIT /B 0



