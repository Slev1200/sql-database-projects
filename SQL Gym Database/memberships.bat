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
REM REGISTER MODE
REM Usage:
REM   usrenr.bat /r FirstName LastName Plan   [Start]
REM Examples:
REM   usrenr.bat /r Emma Rodriguez "Basic Monthly"
REM   usrenr.bat /r Emma Rodriguez 2
REM =================================================
:REGISTER
REM Usage: memberships.bat /r FirstName LastName Plan [StartDateOrOffset]
REM Plan can be numeric membership_id (e.g., 2) OR plan name (e.g., "Basic Monthly")

@REM IF "%~4"=="" (
@REM   ECHO Error: Missing arguments.
@REM   ECHO Usage: %~nx0 /r FirstName LastName Plan [StartDateOrOffset]
@REM   EXIT /B 1
@REM )

@REM SET "FIRST_NAME=%~2"
@REM SET "LAST_NAME=%~3"
@REM SET "PLAN_INPUT=%~4"

@REM REM Optional start date (default = tomorrow)
@REM IF "%~5"=="" (
@REM   SET "START_EXPR=DATE('now','+1 day')"
@REM ) ELSE (
@REM   SET "START_RAW=%~5"
@REM   ECHO %START_RAW% | FINDSTR /R "^[+]" >NUL
@REM   IF NOT ERRORLEVEL 1 (
@REM     SET "START_EXPR=DATE('now','%START_RAW%')"
@REM   ) ELSE (
@REM     REM literal date 'YYYY-MM-DD'
@REM     SET "START_EXPR='%START_RAW%'"
@REM   )
@REM )

@REM REM Detect if PLAN_INPUT is an integer id
@REM ECHO %PLAN_INPUT% | FINDSTR /R "^[0-9][0-9]*$" >NUL
@REM IF ERRORLEVEL 1 (
@REM   SET "PLAN_ID=-1"
@REM   SET "PLAN_NAME=%PLAN_INPUT%"
@REM ) ELSE (
@REM   SET "PLAN_ID=%PLAN_INPUT%"
@REM   SET "PLAN_NAME="
@REM )

@REM REM ---------- Build temp SQL to INSERT (no RETURNING) ----------
@REM SET "TMP_INS=%TEMP%\mmh_insert_%RANDOM%.sql"
@REM > "%TMP_INS%" (
@REM   ECHO WITH target_member AS (
@REM   ECHO   SELECT member_id FROM members WHERE first_name = :fn AND last_name = :ln),
@REM   ECHO target_plan AS (
@REM   ECHO   SELECT membership_id FROM memberships
@REM   ECHO    WHERE membership_id = :plan_id AND :plan_id > 0
@REM   ECHO   UNION
@REM   ECHO   SELECT membership_id FROM memberships
@REM   ECHO    WHERE :plan_id <= 0 AND LOWER(membership_type) = LOWER(:plan_name)
@REM   ECHO   LIMIT 1)
@REM   ECHO INSERT INTO member_membership_history (member_id, membership_id, start_date, end_date)
@REM   ECHO SELECT m.member_id, p.membership_id, %START_EXPR%, NULL
@REM   ECHO FROM target_member m, target_plan p
@REM   ECHO WHERE NOT EXISTS (
@REM   ECHO   SELECT 1
@REM   ECHO   FROM member_membership_history x
@REM   ECHO   WHERE x.member_id = m.member_id
@REM   ECHO     AND x.membership_id = p.membership_id
@REM   ECHO     AND (x.end_date IS NULL OR x.end_date >= %START_EXPR%));
@REM )

@REM REM Run the INSERT (single line; no carets)
@REM sqlite3 -batch gym.db ^
@REM   ".param clear" ".param set :fn %FIRST_NAME%" ".param set :ln %LAST_NAME%" ^
@REM   ".param set :plan_id %PLAN_ID%" ".param set :plan_name %PLAN_NAME%" ^
@REM   ".read %TMP_INS%"

@REM IF ERRORLEVEL 1 (
@REM   ECHO Registration failed.
@REM   DEL "%TMP_INS%" >NUL 2>&1
@REM   EXIT /B 1
@REM )
@REM DEL "%TMP_INS%" >NUL 2>&1

@REM REM ---------- Build temp SQL to SELECT confirmation ----------
@REM SET "TMP_OUT=%TEMP%\mmh_select_%RANDOM%.sql"
@REM > "%TMP_OUT%" (
@REM   ECHO SELECT m.first_name, m.last_name, ms.membership_type, h.start_date
@REM   ECHO FROM member_membership_history h
@REM   ECHO JOIN members m      ON m.member_id = h.member_id
@REM   ECHO JOIN memberships ms ON ms.membership_id = h.membership_id
@REM   ECHO WHERE m.first_name = :fn AND m.last_name = :ln
@REM   ECHO ORDER BY h.history_id DESC
@REM   ECHO LIMIT 1;
@REM )

@REM REM Capture the row into a temp file, parse with FOR /F
@REM sqlite3 -batch -noheader -separator "|" gym.db ^
@REM   ".param clear" ".param set :fn %FIRST_NAME%" ".param set :ln %LAST_NAME%" ^
@REM   ".read %TMP_OUT%" > "%TEMP%\_mmh_out.txt"

@REM DEL "%TMP_OUT%" >NUL 2>&1

@REM FOR /F "usebackq tokens=1-4 delims=|" %%A IN ("%TEMP%\_mmh_out.txt") DO (
@REM   SET "OUT_F=%%~A"
@REM   SET "OUT_L=%%~B"
@REM   SET "OUT_P=%%~C"
@REM   SET "OUT_S=%%~D"
@REM )

@REM DEL "%TEMP%\_mmh_out.txt" >NUL 2>&1

@REM IF NOT DEFINED OUT_F (
@REM   ECHO Insert may have succeeded but lookup found no row.
@REM   ECHO - Name not found, plan not found, or an overlapping active row already exists.
@REM   EXIT /B 2
@REM )

@REM ECHO Successfully added !OUT_P! membership for !OUT_F! !OUT_L! starting !OUT_S!.
@REM EXIT /B 0



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
ECHO   %~nx0 /r FirstName LastName Plan [StartDateOrOffset]
ECHO.
ECHO Examples:
ECHO   %~nx0 Emma Rodriguez
ECHO   %~nx0 /r Emma Rodriguez "Basic Monthly"
ECHO   %~nx0 /r Emma Rodriguez 2
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
ECHO   %~nx0 /r 1 10
ECHO.
ECHO Cancel a registration:
ECHO   %~nx0 /cancel FirstName LastName "Class Name" DayOfWeek StartTime
ECHO Example:
ECHO   %~nx0 /cancel Liam Johnson HIIT Wednesday 07:00
ECHO.
EXIT /B 0

