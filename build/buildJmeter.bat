@echo off
::author jun.cui
::date 20170119
:begin starting my jmeter ineterface programs
set jmeterhome=E:\apache-jmeter-2.13
set antbuildscript=build_cloudwisdom.xml
set date1=%time:~0,8%
echo starting time is:%date1%
cd %jmeterhome%
ant -buildfile %antbuildscript%

set date2=%time:~0,8%
echo the ending time is:%date2%    
>%tmp%\tmp_datediff.vbs echo wscript.echo DateDiff^("s","%date1%","%date2%"^)
for /f "delims=" %%a in ('cscript //nologo %tmp%\tmp_datediff.vbs') do set diff=%%a
echo Elapsed Time   %diff%    s
del %tmp%\tmp_datediff.vbs

echo " the jmeter running has been done!" 
::echo. & pause
pause
:exit