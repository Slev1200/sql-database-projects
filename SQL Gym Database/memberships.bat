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

@REM REM Args: /r member_id membership_id
@REM IF "%~3"=="" (
@REM   ECHO Error: Missing arguments for /r.
@REM   ECHO Usage: %~nx0 /r member_id membership_id
@REM   EXIT /B 1
@REM )
@REM IF NOT "%~4"=="" (
@REM   ECHO Error: Too many arguments for /r.
@REM   ECHO Usage: %~nx0 /r member_id membership_id
@REM   EXIT /B 1
@REM )
@REM REM
@REM SET "MEMBER_ID=%~2"
@REM SET "MEMBERSHIP_ID=%~3"
@REM REM
@REM REM Insert the history row (start_date = tomorrow)
@REM sqlite3 gym.db "INSERT INTO member_membership_history (member_id, membership_id, start_date, end_date) VALUES (SELECT member_id FROM members WHERE first_name = '%FIRST_NAME%' AND last_name = '%LAST_NAME%', %MEMBERSHIP_ID%, DATE('now','+1 day'), NULL);"

@REM IF ERRORLEVEL 1 (
@REM   ECHO Registration failed.
@REM   EXIT /B 1
@REM )

@REM REM Pull friendly names and the exact start_date we just inserted

@REM FOR /F "tokens=1-4 delims=|" %%A IN ('
@REM   sqlite3 -noheader -separator "|" gym.db ".param clear" ".param set :mid %MEMBER_ID%" ".param set :msid %MEMBERSHIP_ID%" ".read sql_files/mmh_lookup.sql"
@REM ') DO (
@REM   SET "FIRST_NAME=%%A"
@REM   SET "LAST_NAME=%%B"
@REM   SET "PLAN_NAME=%%C"
@REM   SET "START_DATE=%%D"
@REM )

@REM ECHO Successfully added !PLAN_NAME! membership for !FIRST_NAME! !LAST_NAME! starting !START_DATE!.
@REM GOTO :EOF


@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM ------------------------------
REM Help flags
REM ------------------------------
IF /I "%~1"=="/?" GOTO :HELP
IF /I "%~1"=="/h" GOTO :HELP
IF /I "%~1"=="--help" GOTO :HELP

REM ------------------------------
REM Mode dispatch
REM ------------------------------
IF /I "%~1"=="/r" GOTO :REGISTER

GOTO :VIEW


REM =================================================
REM VIEW MODE
REM Usage:
REM   usrenr.bat FirstName LastName
REM Description:
REM   Shows this member's memberships
REM =================================================
:VIEW
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

SET "FIRST_NAME=%~1"
SET "LAST_NAME=%~2"

sqlite3 -cmd ".headers on" -cmd ".mode box" -cmd ".param clear" -cmd ".param set :fn %FIRST_NAME%" -cmd ".param set :ln %LAST_NAME%" gym.db ^
"SELECT m.first_name, m.last_name, ms.plan_name AS membership, mmh.start_date, mmh.end_date
   FROM members m
   JOIN member_membership_history mmh ON mmh.member_id = m.member_id
   JOIN memberships ms ON ms.membership_id = mmh.membership_id
  WHERE m.first_name = :fn AND m.last_name = :ln
  ORDER BY mmh.start_date DESC;"

EXIT /B %ERRORLEVEL%


REM =================================================
REM REGISTER MODE
REM Usage:
REM   usrenr.bat /r FirstName LastName Plan   [Start]
REM Examples:
REM   usrenr.bat /r Emma Rodriguez "Basic Monthly"
REM   usrenr.bat /r Emma Rodriguez 2
REM   usrenr.bat /r Emma Rodriguez "Basic Monthly" 2025-11-10
REM   usrenr.bat /r Emma Rodriguez "Basic Monthly" +2 days
REM =================================================
:REGISTER
IF "%~4"=="" (
  ECHO Error: Missing arguments.
  ECHO Usage: %~nx0 /r FirstName LastName Plan [StartDateOrOffset]
  EXIT /B 1
)

SET "FIRST_NAME=%~2"
SET "LAST_NAME=%~3"
SET "PLAN_INPUT=%~4"

REM Optional start date (default = tomorrow)
IF "%~5"=="" (
  SET "START_EXPR=DATE('now','+1 day')"
) ELSE (
  SET "START_RAW=%~5"
  REM If it starts with + treat as relative offset; otherwise literal date
  ECHO %START_RAW% | FINDSTR /R "^[+]" >NUL
  IF NOT ERRORLEVEL 1 (
    SET "START_EXPR=DATE('now','%START_RAW%')"
  ) ELSE (
    SET "START_EXPR='%START_RAW%'"
  )
)

REM Detect if PLAN_INPUT is an integer id
ECHO %PLAN_INPUT% | FINDSTR /R "^[0-9][0-9]*$" >NUL
IF ERRORLEVEL 1 (
  SET "PLAN_ID=-1"
  SET "PLAN_NAME=%PLAN_INPUT%"
) ELSE (
  SET "PLAN_ID=%PLAN_INPUT%"
  SET "PLAN_NAME="
)

REM Perform insert via name-or-id lookup; avoid overlapping active rows
sqlite3 -noheader -separator "|" ^
  -cmd ".param clear" ^
  -cmd ".param set :fn %FIRST_NAME%" ^
  -cmd ".param set :ln %LAST_NAME%" ^
  -cmd ".param set :plan_id %PLAN_ID%" ^
  -cmd ".param set :plan_name %PLAN_NAME%" ^
  gym.db ^
"WITH target_member AS (
     SELECT member_id, first_name, last_name
       FROM members
      WHERE first_name = :fn AND last_name = :ln
  ),
  target_plan AS (
     SELECT membership_id, plan_name
       FROM memberships
      WHERE membership_id = :plan_id AND :plan_id > 0
     UNION
     SELECT membership_id, plan_name
       FROM memberships
      WHERE :plan_id <= 0 AND LOWER(plan_name) = LOWER(:plan_name)
     LIMIT 1
  ),
  ins AS (
     INSERT INTO member_membership_history (member_id, membership_id, start_date, end_date)
     SELECT m.member_id, p.membership_id, %START_EXPR%, NULL
       FROM target_member m, target_plan p
      WHERE NOT EXISTS (
             SELECT 1
               FROM member_membership_history x
              WHERE x.member_id = m.member_id
                AND x.membership_id = p.membership_id
                AND (x.end_date IS NULL OR x.end_date >= %START_EXPR%)
           )
     RETURNING member_id, membership_id, start_date
  )
  SELECT m.first_name, m.last_name, pl.plan_name, ins.start_date
    FROM ins
    JOIN members m    ON m.member_id = ins.member_id
    JOIN memberships pl ON pl.membership_id = ins.membership_id;" ^
  > "%TEMP%\_mmh_out.txt"

IF ERRORLEVEL 1 (
  ECHO Registration failed.
  EXIT /B 1
)

FOR /F "usebackq tokens=1-4 delims=|" %%A IN ("%TEMP%\_mmh_out.txt") DO (
  SET "OUT_F=%%~A"
  SET "OUT_L=%%~B"
  SET "OUT_P=%%~C"
  SET "OUT_S=%%~D"
)

@REM IF NOT DEFINED OUT_F (
@REM   ECHO No row inserted. Possible reasons:
@REM   ECHO  - Name not found, plan not found, or an active/overlapping membership already exists for that plan and start date.
@REM   EXIT /B 2
@REM )

ECHO Successfully added !OUT_P! membership for !OUT_F! !OUT_L! starting !OUT_S!.
DEL "%TEMP%\_mmh_out.txt" >NUL 2>&1
EXIT /B 0


:HELP
ECHO.
ECHO Usage:
ECHO   %~nx0 FirstName LastName
ECHO   %~nx0 /r FirstName LastName Plan [StartDateOrOffset]
ECHO.
ECHO Examples:
ECHO   %~nx0 Emma Rodriguez
ECHO   %~nx0 /r Emma Rodriguez "Basic Monthly"
ECHO   %~nx0 /r Emma Rodriguez 2
ECHO   %~nx0 /r Emma Rodriguez "Basic Monthly" 2025-11-10
ECHO   %~nx0 /r Emma Rodriguez "Basic Monthly" +2 days
ECHO.
EXIT /B 0


@REM IF "%~3"=="" (
@REM     ECHO Error: Missing arguments for /r.
@REM     ECHO Usage: %~nx0 /r member_id membership_id
@REM     EXIT /B 1
@REM )

@REM IF NOT "%~4"=="" (
@REM     ECHO Error: Too many arguments for /r.
@REM     ECHO Usage: %~nx0 /r member_id membership_id
@REM     EXIT /B 1
@REM )

@REM REM Validate names contain letters
@REM @REM ECHO %MEMBER_ID% | FINDSTR /R "^[0-9][0-9]*$" >NUL || GOTO :BadInput
@REM @REM ECHO %MEMBERSHIP_ID% | FINDSTR /R "^[0-9][0-9]*$" >NUL || GOTO :BadInput

@REM SET "MEMBER_ID=%~2"
@REM SET "MEMBERSHIP_ID=%~3"
@REM @REM SET "START_DATE=%~4"

@REM sqlite3 gym.db ^
@REM     "INSERT INTO member_membership_history (member_id, membership_id, start_date, end_date) VALUES (%MEMBER_ID%, %MEMBERSHIP_ID%, DATE('now', '+1 day'), NULL);"

@REM IF ERRORLEVEL 1 (
@REM     ECHO Registration failed.
@REM     EXIT /B 1
@REM )

@REM REM Retrieve and display the friendly names
@REM FOR /F "tokens=1,2 delims=|" %%A IN ('sqlite3 -noheader -separator ^| gym.db "SELECT first_name, last_name FROM members WHERE member_id=%MEMBER_ID%;"') DO (
@REM     SET "FIRST_NAME=%%A"
@REM     SET "LAST_NAME=%%B"
@REM )

@REM FOR /F "tokens=* delims=" %%C IN ('sqlite3 -noheader gym.db "SELECT membership_type FROM memberships WHERE membership_id=%MEMBERSHIP_ID%;"') DO (
@REM     SET "PLAN_NAME=%%C"
@REM )

@REM ECHO Successfully added %PLAN_NAME% membership for %FIRST_NAME% %LAST_NAME% starting %DATE%.
@REM GOTO :EOF



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

