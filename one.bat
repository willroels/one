@echo off
REM An attempt to hack batch scripts into something that can run a game
REM The purpose of this project is to have fun

MODE CON LINES=24 COLS=80

echo. >> log.txt

setlocal EnableDelayedExpansion
    title one
    set debug=true

    set border=////////////////////////////////////////////////////////////////////////////////

    set "space=                                                                                "
REM Enable virtual terminal sequences
    call binutils\set_console_mode.exe

REM Saves the ESC character value (hex 0x1B) to the variable ESC
REM To be used later to construct VT commands using 'echo'
    for /f "tokens=2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"

REM aliases for the VT sequences to disable the cursor,
REM and enable again when the game exits as part of cleanup
    set show_cursor=%ESC%[?25h
    set hide_cursor=%ESC%[?25l

    set disable_blink=%ESC%[?12h
    set  enable_blink=%ESC%[?12l

REM Global variables and settings have been intialized, go to main function
goto :main

:csv_get_header_index file column_header index
setlocal
    for /F "delims=, tokens=*" %%l in (%~1) do (
        set line=%%l
        set line_step2=!line:,= !
        for %%a in (!line_step2!) do (
            set /a idx=!idx!+1
            if "%~2"=="%%a" (
                goto :return
            )
        )
        endlocal & set %~3=-1
        exit /b
    )
:return
endlocal & set %~3=%idx%
exit /b

:set_random value min max
setlocal
    set /a diff=%~3-%~2+1
    set /a rnd=!random! %% %diff%
endlocal & set /a %~1=%~2 + %rnd%
exit /b

:: Pulled from ss64.com/nt/syntax-strlen.html
:strlen  StrVar  [RtnVar]
  setlocal EnableDelayedExpansion
  set "s=#!%~1!"
  set "len=0"
  for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
    if "!s:~%%N,1!" neq "" (
      set /a "len+=%%N"
      set "s=!s:~%%N!"
    )
  )
  endlocal&if "%~2" neq "" (set %~2=%len%) else echo %len%
exit /b

:strip_outer str
    setlocal EnableDelayedExpansion
    call :strlen %~1 _length
    set str=!%~1!
    set /a _length=%_length%-2
    set str=!str:~1,%_length%!
    endlocal & set %~1=%str%
exit /b

:collision_check attacker target
setlocal EnableDelayedExpansion
    set directions=north east south west
    set    north.x=!%~1.x!
    set /a north.y=!%~1.y!+1
    set /a east.x=!%~1.x!+1
    set    east.y=!%~1.y!
    set    south.x=!%~1.x!
    set /a south.y=!%~1.y!-1
    set /a west.x=!%~1.x!-1
    set    west.y=!%~1.y!

    for %%e in (%entities:,= %) do (
        for %%d in (%directions%) do (
            if !%%e.x!==!%%d.x! (
                if !%%e.y!==!%%d.y! (
                    endlocal & set %~2=%%e
                    exit /b
                )
            )
        )
    )
endlocal & set %~2=
exit /b

:absolute_value val |val|
setlocal EnableDelayedExpansion
    if !%~1! LSS 0 (
        endlocal & set /a %~2=0-!%~1!
        exit /b
    )
    endlocal & set %~2=!%~1!
exit /b

:set_entity_attributes entities_csv
    for /F %%l in (%~1) do (
        set entitity_attributes=%%l
        set entitity_attributes=!entitity_attributes:entity_name,=!
        goto :break
    )
:break

    set temp=!entitity_attributes:,= !
    set index=0
    for %%e in (%temp%) do (
        set entity_attribute[!index!]=%%e
        set /a index=!index!+1
    )

    for /F "skip=1 tokens=1,* delims=," %%e in (%~1) do (
        set temporary=%%f
        set string="!temporary:,= !"
        call :strip_outer string
        set index=0
        for %%b in (!string!) do (
            for %%v in (entity_attribute[!index!]) do (
                set %%e.!%%v!=%%b
            )
            set /a index=!index!+1
        )
    )
exit /b

:load_level
    set level_render_y=19
    for /F "tokens=*" %%a in (levels\level%curr_level%_rendered.txt) do (
        set "current_level[!level_render_y!]=%%a"
        set /a level_render_y=!level_render_y!-1
    )

    set level_render_y=19
    for /F %%a in (levels\level%curr_level%_walkable.txt) do (
        set is_walkable[!level_render_y!]=%%a
        set /a level_render_y=!level_render_y!-1
    )

goto :eof

:spawn_in_walkable_location spawnable_coord
setlocal
    call :set_random y_val 0 19
    call :set_random x_val 0 79

    set /a "y_iter_max = %y_val% + 19"
    for /L %%y in (%y_val%, 1, %y_iter_max%) do (
        set /a "check_y = %%y %% 20"
        for %%c in ("is_walkable[!check_y!]") do (
            if "!%%~c:~%x_val%,1!" EQU "1" goto :spawn_return
        )
    )
    
:spawn_return
endlocal & set %~1="%x_val%,%check_y%"
goto :eof

:main
    
    set curr_level=1
    if exist levels\level%curr_level%* (
        call :load_level %curr_level%
    ) else (
        start /b cmd /c perlin-like-2d.bat "width = 80" "height = 20" "octaves = 3" "level = 1" "walkable_threshold = 125"
    )


    set preferred_language=%~1
    if "%preferred_language%"=="" (
        set preferred_language=EN
    )

    call :csv_get_header_index config\messages.csv %preferred_language% csv_index
    for /F "skip=1 tokens=1,%csv_index% delims=," %%m in (config\messages.csv) do (
        set %%m=%%n
    )

    call :set_entity_attributes config\entities.csv

    set update_field=%ESC%[24;1H%ESC%[80X%ESC%[37m
    set min_x=-1
    set min_y=-1
    set max_x=80
    set max_y=20


REM this is the render loop
    for /L %%y in (19, -1, 0) do (
        set "line=!current_level[%%y]:~0,80!"
        @echo.!line!
    )

    echo %hide_cursor%%disable_blink%

    echo|set /p=%update_field%[h]=!left! [j]=!down! [k]=!up! [l]=!right! [e]=!exit!
    if "%debug%"=="true" (
        set DEBUG=
    ) else (
        set DEBUG=
    )

REM 'key' variable to store the value of the user input
    set key=

    set entities=player,goblin,mage,trader

    set npcs=goblin,mage,trader
    
    for %%e in (%entities%) do (
        call :spawn_in_walkable_location walkable_coord

        for /F "tokens=1,2 delims=," %%x in (!walkable_coord!) do (
            set %%e.x=%%x
            set %%e.y=%%y
        )

        set %%e.x_vel=0
        set %%e.y_vel=0

        set %%e.health=!%%e.basehealth!
        
        set /a %%e.console_x=!%%e.x! + 1
        set /a %%e.console_y=20 - !%%e.y!
        if !%%e.sprite_modifier! NEQ """""" (
            echo %ESC%[!%%e.console_y!;!%%e.console_x!H%ESC%!%%e.sprite_modifier!!%%e.entity_sprite!
        )else (
            echo %ESC%[!%%e.console_y!;!%%e.console_x!H%ESC%[37m!%%e.entity_sprite!
        )
    )

:event_loop
    echo.Starting the event loop >> log.txt
REM this is the user input logic
    for /f %%a in ('binutils\key.exe') do (
        set key=%%a
    )

    if %key%==e (
        echo.Exiting the game >> log.txt
        goto game_exit
    )

:: Update player
    if %key%==h (
        echo.Move left >> log.txt
        set /a player.x_vel=-1
    )
    if %key%==j (
        echo.move down >> log.txt
        set /a player.y_vel=-1
    )
    if %key%==k (
        echo.move up >> log.txt
        set /a player.y_vel=1
    )
    if %key%==l (
        echo.move right >> log.txt
        set /a player.x_vel=1
    )
    if %key%==a (
        echo.attacking, looking for collision up >> log.txt
        call :collision_check player entity_hit
        for %%e in (!entity_hit!) do (
            echo.entity %%e has been hit >> log.txt
            set /a %%e.health=!%%e.health!-!player.strength!
            set health_remaining=!%%e.health!
            for %%z in (!health_remaining!) do (
                if %%z LSS 0 (
                    echo.entity %%e has been killed >> log.txt
                    set update_message=!enemyHit:xx=%%e!. !enemyDefeated:xx=%%e! 
                )
            )
        )
    )

    for %%e in (%npcs:,= %) do (
        if !%%e.health! GTR 0 (
            call :set_random %%e.x_vel -1 1
            if !%%e.x_vel!==0 (
                call :set_random %%e.y_vel -1 1
            )
        ) else (
            echo.Erasing entity %%e at [!%%e.x!,!%%e.y!] >> log.txt
            set /a %%e.console_x=!%%e.x! + 1
            set /a "%%e.console_y=20 - !%%e.y!"
            echo.%ESC%[!%%e.console_y!;!%%e.console_x!H 
            set npcs=!npcs:%%e=!
            set entities=!entities:%%e=!
        )
    )

    for %%e in (%entities:,= %) do (
        if "!%%e.affinity!"=="hostile" (
            set /a dist_x=!player.x!-!%%e.x!
            set /a dist_y=!player.y!-!%%e.y!

            call :absolute_value dist_x dist_x_magnitude
            call :absolute_value dist_y dist_y_magnitude

            set /a distance=!dist_x_magnitude!+!dist_y_magnitude!
            if "!distance!"=="0" (
                set %%e.x_vel=0
                set %%e.y_vel=0
            ) else (
                if !distance! LSS 5 (
                    echo "distance less than 5" >> log.txt
                    if !dist_y_magnitude! LSS !dist_x_magnitude! (
                        set /a direction=!dist_x!/!dist_x_magnitude!
                        set %%e.y_vel=0
                        set %%e.x_vel=!direction!
                    ) else (
                        set /a direction=!dist_y!/!dist_y_magnitude!
                        set %%e.x_vel=0
                        set %%e.y_vel=!direction!
                    )
                )
            )

            set entity_hit=
            call :collision_check %%e entity_hit
            if "!entity_hit!" NEQ "" (
                for %%v in (!entity_hit!) do (
                    set /a %%v.health=!%%v.health!-!%%e.strength!
                    for %%h in (!%%v.health!) do (
                        set update_message=!npcAttack:xx=%%e!. !retaliation:xx=%%h!
                    )
                )
            ) else (
                set update_message=
            )
        )

    )

    for %%e in (%entities:,= %) do (
:: Clear sprite & render at new location
        set /a new_x=!%%e.x! + !%%e.x_vel!
        set /a new_y=!%%e.y! + !%%e.y_vel!

        for /F "tokens=1,2 delims=," %%x in ("!new_x!,!new_y!") do (
            if "!is_walkable[%%y]:~%%x,1!"=="1" (
                REM x and y have to be positive
                if %%x GTR -1 (
                    set %%e.x=%%x
                )

                if %%y GTR -1 (
                    set %%e.y=%%y
                )
            )
        )

        echo %ESC%[!%%e.console_y!;!%%e.console_x!H%ESC%[37m.
        set /a %%e.console_x=!%%e.x! + 1
        set /a "%%e.console_y=20 - !%%e.y!"
        if !%%e.sprite_modifier! NEQ """""" (
            echo %ESC%[!%%e.console_y!;!%%e.console_x!H%ESC%!%%e.sprite_modifier!!%%e.entity_sprite!
        )else (
            echo %ESC%[!%%e.console_y!;!%%e.console_x!H%ESC%[37m!%%e.entity_sprite!
        )

        set %%e.x_vel=0
        set %%e.y_vel=0
    )

    echo|set /p=%update_field%!update_message!
    set update_message=

    if !player.health!==0 (
        goto :game_over
    )

goto event_loop

:game_over
echo.%ESC%[5;1H%ESC%[37m
type game_over.txt

:game_exit
    echo %show_cursor%%enable_blink%
    title Command Prompt
    echo %ESC%[37m%ESC%[23;1H%ESC%[2M%goodbye_message%

endlocal

