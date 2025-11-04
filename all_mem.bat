@ECHO OFF
IF /I "%~1" == "/?" GOTO :HELP
IF /I "%~1" == "/h" GOTO :HELP
IF /I "%~1" == "--help" GOTO :HELP

REM Your main script logic starts here
sqlite3 gym.db ".headers on" ".mode box" ".param set :num_members %1" ".read sql_files/members_rows_script.sql"

GOTO :EOF

:HELP
ECHO.
ECHO Usage: pass one arguments: num_members e.g. all_mem.bat 5
ECHO.
ECHO Options:
ECHO   /?         Display this help message.
ECHO   /h         Display this help message.
ECHO   --help     Display this help message.
ECHO.
ECHO Description:
ECHO   This batch file provides a list of members in the club.
ECHO.
ECHO Helpful Info:
ECHO   /?         Display this help message.
ECHO   /h         Display this help message.
ECHO   --help     Display this help message.
GOTO :EOF