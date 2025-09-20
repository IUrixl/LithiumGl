@echo off
setLocal enableDelayedExpansion

:_timeLoop
	ping -n 2 localhost > nul
	set/p currentFps=<core\fps.data
	del core\fps.data
	echo !currentFps!>core\cFps.data
	goto :_timeLoop