@echo off
setlocal

REM Used to clean up the project folder and create compressed folders that are easy to download

set one_home=%cd%

if exist *~ (
    del *~
)

if exist *.zip (
    del *.zip
)

if exist *.tar.gz (
    del *.tar.gz
)

if exist log.txt (
    del log.txt
)

cd ..
tar --exclude-vcs -caf one-release.zip one
tar --exclude-vcs -czvf one-release.tar.gz one
@move one-release* one
cd %one_home%


endlocal
