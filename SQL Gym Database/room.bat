@ECHO OFF
IF /I "%~1" == "/?" GOTO :HELP
IF /I "%~1" == "/h" GOTO :HELP
IF /I "%~1" == "--help" GOTO :HELP

REM Your main script logic starts here
sqlite3 gym.db ".headers on" ".mode box" ".param set :room_id %1" ".read sql_files/room_script.sql"

GOTO :EOF

:HELP
ECHO.
ECHO Usage: pass one arguments: room_id e.g. room.bat 17
ECHO.
ECHO Description:
ECHO   This batch file lists the room that the class you registered for is happening in.
ECHO.
GOTO :EOF