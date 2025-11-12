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
IF /I "%~1"=="/reactivate" GOTO :REACTIVATE


REM Otherwise default to VIEW mode
GOTO :VIEW

:VIEW
REM expects: FirstName LastName
IF "%~2"=="" (
  ECHO Error: You must provide both first and last name.
  ECHO Usage: %~nx0 FirstName LastName
  EXIT /B 1
)

REM Basic sanity: must contain at least one letter
ECHO %~1 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputView
ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputView

sqlite3 gym.db ".headers on" ".mode box" ".param set :fn '%~1'" ".param set :ln '%~2'" ".read sql_files/find_member_script.sql"

GOTO :EOF

:BadInputView
ECHO Error: Invalid name. Please provide first and last name as strings.
ECHO Example: %~nx0 Liam Johnson
EXIT /B 1

REM =================================================
REM REGISTER MODE (/r)
REM Usage:
REM   member.bat /r FirstName LastName DOB Gender Email Phone "Address"
REM Example:
REM   member.bat /r Liam Johnson 1988-09-22 M liam.j@example.com 6175551002 "77 Main St, Cambridge, MA"
REM =================================================
:REGISTER
REM expects: FirstName LastName DOB Gender Email Phone "Address" Payment
IF "%~8"=="" (
  ECHO Error: Missing arguments for /r.
  ECHO Usage: %~nx0 /r FirstName LastName DOB Gender Email Phone "Address"
  EXIT /B 1
)
IF NOT "%~9"=="" (
  ECHO Error: Too many arguments for /r.
  EXIT /B 1
)

REM Validate names contain letters
ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputReg
ECHO %~3 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputReg

SET "FIRST_NAME=%~2"
SET "LAST_NAME=%~3"
SET "DATE_OF_BIRTH=%~4"
SET "GENDER=%~5"
SET "EMAIL=%~6"
SET "PHONE_NUMBER=%~7"
SET "ADDRESS=%~8"

sqlite3 gym.db ^
  "INSERT INTO members (first_name,last_name,date_of_birth,gender,email,phone_number,address,current_payment_type) VALUES ('%FIRST_NAME%','%LAST_NAME%', '%DATE_OF_BIRTH%','%GENDER%','%EMAIL%','%PHONE_NUMBER%','%ADDRESS%', 'Card');"

IF ERRORLEVEL 1 (
  ECHO Registration failed.
  EXIT /B 1
) ELSE (
  ECHO Successfully registered %FIRST_NAME% %LAST_NAME% to the gym.
)
GOTO :EOF

:BadInputReg
ECHO Error: Invalid name for /r.
ECHO Usage: %~nx0 /r FirstName LastName DOB Gender Email Phone "Address"
EXIT /B 1


REM =================================================
REM CANCEL MODE (/cancel)
REM Usage:
REM   member.bat /cancel FirstName LastName DOB
REM Example:
REM   member.bat /cancel Liam Johnson 1988-09-22
REM Action:
REM   Updates member status to show cancelled
REM =================================================
:CANCEL

REM Need exactly 4 args total:
REM   %1 = /cancel
REM   %2 = FirstName
REM   %3 = LastName
REM   %4 = DOB

IF "%~4"=="" (
    ECHO Error: Missing arguments for /cancel.
    ECHO Usage: %~nx0 /cancel FirstName LastName DOB
    EXIT /B 1
)

IF NOT "%~5"=="" (
    ECHO Error: Too many arguments for /cancel.
    ECHO Usage: %~nx0 /cancel FirstName LastName DOB
    EXIT /B 1
)

REM Validate names
ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel
ECHO %~3 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel

SET "FIRST_NAME=%~2"
SET "LAST_NAME=%~3"
SET "DATE_OF_BIRTH=%~4"

sqlite3 gym.db "UPDATE members SET status='cancelled' WHERE first_name='%FIRST_NAME%' AND last_name='%LAST_NAME%' AND (date_of_birth = '%DATE_OF_BIRTH%' OR date_of_birth IS NULL OR date_of_birth = '');"

IF ERRORLEVEL 1 (
    ECHO Cancellation failed.
    EXIT /B 1
) ELSE (
    ECHO Cancelled registration for %FIRST_NAME% %LAST_NAME%
)

GOTO :EOF

:BadInputCancel
ECHO Error: Invalid name in /cancel.
ECHO Usage: %~nx0 /cancel FirstName LastName DOB
EXIT /B 1


REM =================================================
REM HELP
REM =================================================
:HELP
ECHO Usage:
ECHO   %~nx0 FirstName LastName
ECHO   %~nx0 /r FirstName LastName DOB Gender Email Phone "Address"
ECHO.
ECHO Deactivate member info from the gym:
ECHO   %~nx0 /cancel FirstName LastName DOB
ECHO.
ECHO Example:
ECHO   %~nx0 /cancel Liam Johnson 1988-09-22
ECHO.
EXIT /B 0


REM =================================================
REM REACTIVATION MODE (/reactivate)
REM Usage:
REM   member.bat /reactivate FirstName LastName DOB
REM Example:
REM   member.bat /reactivate Liam Johnson 1988-09-22

REM =================================================
:REACTIVATE

REM Need exactly 4 args total:
REM   %1 = /reactivate
REM   %2 = FirstName
REM   %3 = LastName
REM   %4 = DOB

IF "%~4"=="" (
    ECHO Error: Missing arguments for /cancel.
    ECHO Usage: %~nx0 /cancel FirstName LastName DOB
    EXIT /B 1
)

IF NOT "%~5"=="" (
    ECHO Error: Too many arguments for /cancel.
    ECHO Usage: %~nx0 /cancel FirstName LastName DOB
    EXIT /B 1
)

REM Validate names
ECHO %~2 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel
ECHO %~3 | FINDSTR /R "[A-Za-z]" >NUL || GOTO :BadInputCancel


SET "FIRST_NAME=%~2"
SET "LAST_NAME=%~3"
SET "DATE_OF_BIRTH=%~4"

sqlite3 gym.db "UPDATE members SET status='active' WHERE first_name='%FIRST_NAME%' AND last_name='%LAST_NAME%' AND (date_of_birth = '%DATE_OF_BIRTH%' OR date_of_birth IS NULL OR date_of_birth = '');"

IF ERRORLEVEL 1 (
    ECHO Reactivating failed.
    EXIT /B 1
) ELSE (
    ECHO Reactivated registration for %FIRST_NAME% %LAST_NAME%
)

GOTO :EOF

:BadInputCancel
ECHO Error: Invalid name in /reactivate.
ECHO Usage: %~nx0 /reactivate FirstName LastName DOB
EXIT /B 1


REM =================================================
REM HELP
REM =================================================
:HELP
ECHO Usage:
ECHO   %~nx0 FirstName LastName
ECHO   %~nx0 /r FirstName LastName DOB Gender Email Phone "Address"
ECHO.
ECHO Deactivating member from the gym:
ECHO   %~nx0 /cancel FirstName LastName DOB
ECHO.
ECHO Example:
ECHO   %~nx0 /cancel Liam Johnson 1988-09-22
ECHO.
ECHO Reactivating member to the gym:
ECHO   %~nx0 /reactivate FirstName LastName DOB
ECHO.
ECHO Example:
ECHO   %~nx0 /reactivate Liam Johnson 1988-09-22
EXIT /B 0
