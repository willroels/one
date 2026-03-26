@echo off

REM Used to build the executables 'key' and 'set_console_mode' from the C source files in c-source directory
REM If you wish to build the executables yourself, configure the variable cc below to whatever C compiler you use

if "%~1" NEQ "" (
    goto :%~1
)

goto :all

:clean
    if exist *~ (
        del /s /q *~
    )
    if exist binutils\* (
        del /q binutils\*
    )
exit /b

:all
setlocal
    set cc=mingw32-gcc

    if not exist binutils (
        mkdir binutils
    )

    for /f "tokens=1 delims=." %%c in ('dir /b c-source\*') do (
        echo.Building module %%c
        %cc% c-source\%%c.c -o binutils\%%c.exe
    )

endlocal
