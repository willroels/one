@echo off
setlocal EnableDelayedExpansion
goto :main

:power n a power
    set %~3=1
    for /L %%i in (1, 1, %~2) do (
        set /a %~3=!%~3! * %~1
    )
goto :eof

:sum_of_scales n sum
setlocal
    set /a exp=%~1+1
    call :power 2 %exp% pow
endlocal & set /a %~2=%pow%-1
goto :eof

:get_numeric_args
    for %%a in (%*) do (
        set arg_string=%%~a
        set /a !arg_string! + 0
    )
goto :eof

:perlin_like_2d noise_array octave_count output_array
    set /a max_octave=%~2-1
    set sum_scale=0
    set curr_max=0
    set curr_min=0
    call :sum_of_scales %max_octave% sum_scales
    for /L %%y in (0, 1, !%~1.max_y!) do (
        for /L %%x in (0, 1, !%~1.max_x!) do (
            set noise=0
            call :power 2 %max_octave% scale
            for /L %%o in (0, 1, !max_octave!) do (
                call :power 2 %%o result
                set /a pitch_x=!%~1.count_x!/!result!
                set /a pitch_y=!%~1.count_y!/!result!
                if !pitch_x!==0 ( set pitch_x=1)
                if !pitch_y!==0 ( set pitch_y=1)

                set /a first_sample_x=%%x/!pitch_x!*!pitch_x!
                set /a "second_sample_x = (!first_sample_x!+!pitch_x!) %% !%~1.count_x!"

                set /a first_sample_y=%%y/!pitch_y!*!pitch_y!
                set /a "second_sample_y = (!first_sample_y!+!pitch_y!) %% !%~1.count_y!"

                set /a blend_x=%%x-!first_sample_x!
                set /a blend_y=%%y-!first_sample_y!

                set sample1=%~1[!first_sample_x!][!first_sample_y!]
                set sample2=%~1[!second_sample_x!][!first_sample_y!]
                set sample3=%~1[!first_sample_x!][!second_sample_y!]
                set sample4=%~1[!second_sample_x!][!second_sample_y!]
                for /F "tokens=1,2,3,4 delims=," %%a in ("!sample1!,!sample2!,!sample3!,!sample4!") do (
                    set /a "sampleT = ((!pitch_x! - !blend_x!) * !%%a! + !blend_x! * !%%b!) * !scale! / !pitch_x!"
                    set /a "sampleB = ((!pitch_x! - !blend_x!) * !%%c! + !blend_x! * !%%d!) * !scale! / !pitch_x!"
                )

                set /a "noise = (!blend_y! * (!sampleB! - !sampleT!) + !sampleT!) / !pitch_y!"
                set /a "%~3[%%x][%%y] = !%~3[%%x][%%y]! + !noise!"


                set /a "sum_scale = !sum_scale! + !scale!"
                set /a "scale = !scale! * 65 / 100"
            )
            set /a "%~3[%%x][%%y] = !%~3[%%x][%%y]! / !sum_scale!"

            if !%~3[%%x][%%y]! GTR !curr_max! (set curr_max=!%~3[%%x][%%y]!)
            if !%~3[%%x][%%y]! LSS !curr_min! (set curr_min=!%~3[%%x][%%y]!)

            set sum_scale=0
        )
    )

    set /a "%~3.min=!curr_min!"
    set /a "%~3.max=!curr_max!"

goto :eof

:main

    call :get_numeric_args %*

    if "%width%"=="" set width=80
    if "%height%"=="" set height=20
    if "%octaves%"=="" set octaves=3
    if "%walkable_threshold%"=="" set walkable_threshold=105
    if "%level%"=="" set level=1

    set /a noise_2d.max_x=%width%-1
    set /a noise_2d.max_y=%height%-1
    set /a noise_2d.count_x=%noise_2d.max_x%+1
    set /a noise_2d.count_y=%noise_2d.max_y%+1

    for /L %%i in (0, 1, %noise_2d.max_x%) do (
        for /L %%j in (0, 1, %noise_2d.max_y%) do (
               set noise_2d[%%i][%%j]=!random!
        )
    )

    call :perlin_like_2d noise_2d %octaves% output_2d

    for /L %%y in (%noise_2d.max_y%, -1, 0) do (
        for /L %%x in (0, 1, %noise_2d.max_x%) do (
            set /a "noise_value = (!output_2d[%%x][%%y]! - !output_2d.min!) * 255 / (!output_2d.max! - !output_2d.min!)"
            if !noise_value! GTR %walkable_threshold% (
                set world[%%y]=!world[%%y]! 
                set walkable[%%y]=!walkable[%%y]!1
            ) else (
                set world[%%y]=!world[%%y]!a
                set walkable[%%y]=!walkable[%%y]!0
            )
        )
        @echo.!world[%%y]!>>level!level!_rendered.txt
        @echo.!walkable[%%y]!>>level!level!_walkable.txt
    )

endlocal
