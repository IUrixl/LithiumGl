@echo off
setlocal EnableDelayedExpansion

rem Code by (c) IURIXL 2025, 3d rendering library for Batch. Do not sell it without permission. All rights reserved.

For /F %%e in ('echo prompt $E^|cmd')Do set "esc=%%e"

chcp 65001>nul

rem G stands for graphic

set "g_w=75"
set "g_h=75"
set/a g_map=!g_h!*!g_w!
set "g_buffer="
set "g_frame=0"
set "g_fps"

goto fontSwap
rem goto fastSwap

:precalcBuffer
	for /L %%i in (1 1 !g_map!) do (
		set "g_buffer=!g_buffer! "
	)
	
	goto :eof

:Setup
    rem if not exist core\ (
    rem    echo Core folder missing, reinstall Lithiums
    rem    pause>nul
	rem    exit/b
    rem )

    start /b core\timer.bat

    echo %esc%[?25l
    if "%1"=="" (
        echo Lithium model not provided
        pause>nul
        exit/b
    )

    set "model=%1"
    set "buffer3D="
    set "buffer2D="

    goto Engine

:fastSwap
	mode con: cols=!g_w! lines=!g_h!

	call :precalcBuffer
	goto Setup

:fontSwap
    reg query HKCU\Console\Lithium

    IF %errorlevel%==1 (
        >nul reg add HKCU\Console\Lithium /v FaceName /t reg_sz /d "Terminal" /f
        >nul reg add HKCU\Console\Lithium /v FontSize /t reg_dword /d 524296
        >nul reg add HKCU\Console\Lithium /v FontFamily /t reg_dword /d 48
        start "Lithium" "%~0" %1
        exit
    ) else ( 
        mode con: cols=!g_w! lines=!g_h!
        >nul reg delete HKCU\Console\Lithium /f 
    )

    echo Powered by LithiumGL, (C) 2025 IUrixl
	ping -n 2 localhost > nul

    call :precalcBuffer

    goto Setup

:Engine
	cls
	goto Update	

	:Throwback
		echo Unexpected error, quitting.
		pause
		exit

	:Update
		rem Save internal fps
		if not exist core\fps.data set "g_fps=0"
		echo !g_fps!>core\fps.data

		rem Get calculated fps
		set/p g_dfps=<core\cFps.data
	
		set "verticesMap="
		set "coordsMap="

		rem Readmodel code outside a call to optmize the code!
			rem Read the file and save values into the 3d buffer
			set "buffer3D="
			set "buffer3D.len=0"

    		rem lm stands for loadModel variables, lm_write indicates if the line should be written on the buffer
    		rem lm_token = current line of the file, lm_index = index of the token

    		rem lmM stands for loadModel Metadata
    		rem lmC stands for loadModel Chunk

    		set "lm_index=0"
    		for /f "tokens=* eol= " %%A in (!model!) do (
    			set /a lm_index+=1
    			set "lm_write=true"
    			set "lm_token=%%A"

    			rem Check if the line is metadata constructor and get their info
    			if "!lm_token:~0,1!"=="?" (
    				set "lm_write=false"
    				set/a lm_index-=1

    				for %%m in (!lm_token!) do (
    					set "lmM_token=%%m"

    					if "!lmM_token:~0,2!"=="x|" set "originX=!lmM_token:~2!"
    					if "!lmM_token:~0,2!"=="y|" set "originY=!lmM_token:~2!"
    				)
    			)

    			rem Load the chunk into the buffer
    			set "lmC_index=0"
    			
    			set "v_c="
    			for %%d in (!lm_token!) do (
    				set /a lmC_index+=1
    				set "lmC_token=%%d"

    				if !lmC_index!==1 set "v_x=!lmC_token!" 
    				if !lmC_index!==2 set "v_y=!lmC_token!"
    				if !lmC_index!==3 set "v_z=!lmC_token!"
    				
    				if !lmC_index! geq 4 set "v_c=!v_c! !lmC_token!"
    			)

    			if "!lm_write!"=="true" (
    				rem Calculate the vertex offset
    				set/a v_x+=!originX!
    				set/a v_y+=!originY!

    				rem Calculate vertex position using the z
    				set/a v_x=!v_x!/!v_z!
    				set/a v_y=!v_y!/!v_z! 

    				rem Save on the global buffer and individual one for referenced access!
    				set "buffer3D=!buffer3D! !v_x! !v_y! !v_z! !v_c! #"
    				set "posX[!lm_index!]=!v_x!"
    				set "posY[!lm_index!]=!v_y!"

    				set/a buffer_offset=!v_y!*!g_w!+!v_x!
    				rem echo !buffer_offset!

    				set "verticesMap=!verticesMap! !buffer_offset!"
    			)
    		)

    		rem Render lines and connections, bf stands for buffer, ma for main, or origin, co connection

    		set "bf_i=0"
    		set "bf_v=1"
    		for %%c in (!buffer3D!) do (
    			set/a bf_i+=1

    			rem Check if its the end of the vertice, if not get the the coords and stablish connections
   				if "%%c"=="#" (
    				set "bf_i=0"
    				set/a bf_v+=1
    			) else (
    				if !bf_i!==1 set "ma_x=%%c"
    				if !bf_i!==2 set "ma_y=%%c"
    				if !bf_i!==3 set "ma_z=%%c"
    				
    				rem Connect vertices
 					if !bf_i! geq 4 (
 						rem Set main info
 						set "or_x=!ma_x!"
 						set "or_y=!ma_y!"

    					rem Get connection info
    					set "co_x=!posX[%%c]!"
    					set "co_y=!posY[%%c]!"

    					rem check for input flip and sx sy
    					if !or_x! gtr !co_x! (
    						set "bh_swap=!co_x!"
    						set "co_x=!or_x!"
    						set "or_x=!bh_swap!"

    						set "bh_swap=!co_y!"
    						set "co_y=!or_y!"
    						set "or_y=!bh_swap!"
    					)

    					if !or_y! gtr !co_y! (
    						set "bh_sy=-1"

    						set "bh_swap=!co_x!"
    						set "co_x=!or_x!"
    						set "or_x=!bh_swap!"

    						set "bh_swap=!co_y!"
    						set "co_y=!or_y!"
    						set "or_y=!bh_swap!"
    					)

    					rem check Direction
    					if !or_y! lss !co_y! ( set "bh_sy=1 ") else ( set "bh_sy=-1" )
    					if !or_x! lss !co_x! ( set "bh_sx=1 ") else ( set "bh_sx=-1" )

    					rem echo Connecting !bf_v! : %%c !or_x! !or_y! !co_x! !co_y!

    					set /a bh_dx=!co_x!-!or_x!
    					set /a bh_dy=!co_y!-!or_y!

    					set "bh_dx=!bh_dx:-=!"
    					set "bh_dy=!bh_dy:-=!"
    					set/a bh_dy=-!bh_dy!

    					set "bh_ody=!bh_dy:-=!"

    					set /a bh_error=!bh_dy!+!bh_dx!
    					set "bh_y=!or_y!"
    					set "bh_x=!or_x!"

    					set "bh_run=true"
    					set "bh_stud=1"

    					if !bh_dx! geq !bh_ody! ( set "bh_size=!bh_dx!" ) else ( set "bh_size=!bh_ody!" )

    					if !bh_dx!==0 (
    						set/a bh_y-=1
    						 for /L %%y in (!or_y!, 1, !co_y!) do (  
    						 	set/a bh_y+=!bh_stud!
								set/a buffer_offset=!bh_y!*!g_w!+!bh_x!

			    				set "coordsMap=!coordsMap! !buffer_offset!"
                            )
    					) else (
	    					for /l %%k in (1 1 !bh_size!) do (
	    						if "!bh_run!"=="true" (
	    							if !bh_x!==!co_x! if !bh_y!==!co_y! set "bh_run=false"

	    							rem Plot
									set/a buffer_offset=!bh_y!*!g_w!+!bh_x!

			    					set "coordsMap=!coordsMap! !buffer_offset!"

	    							rem Calculus
	    							set/a bh_2e=2*!bh_error!

	    							if !bh_2e! geq !bh_dy! (
	    								if !bh_x!==!co_x! set "bh_run=false"
	    								set/a bh_error+=!bh_dy!
	    								set/a bh_x+=!bh_sx!
	    							)

	    							if !bh_2e! leq !bh_dx! (
	    								if !bh_y!==!co_y! set "bh_run=false"
	    								set/a bh_error+=!bh_dx!
	    								set/a bh_y+=!bh_sy!
	    							)
	    						)
	    					)
    					)
    				)
    			)
    		)

    		rem echo Model origin:!originX!, !originY!
    	rem end of the readModel call

		set "buffer2D=!g_buffer!"

		title LithiumGL ^| Frame: !g_frame! ^| Fps: !g_dfps!

		rem echo Update: %taskTime% - %time%>>logs.tmp
		goto Render

		:plotCoord
			goto :eof

	:Render
		set/a g_frame+=1
		set/a g_fps+=1

		rem _plotCoords call
			for %%o in (!coordsMap!) do (
				set "preBuf=!buffer2D:~0, %%o!"
			 	set "buffer2D=!preBuf:~0,-1!█!buffer2D:~%%o!"
			)

		rem end of the _plotCoords call

		rem _plotVertices call
			set/a "r_v=0"
			for %%o in (!verticesMap!) do (
				set/a r_v+=1

				set "preBuf=!buffer2D:~0, %%o!"
			 	set "buffer2D=!preBuf:~0,-1!!r_v!!buffer2D:~%%o!"
			)
		rem end of the _plotVertices call

		echo %esc%[2J%esc%[H!buffer2D!

		rem echo Render: %taskTime% - %time%>>logs.tmp
		goto Update