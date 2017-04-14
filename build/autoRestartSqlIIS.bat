@echo off     
:begin automation excute sql and reset iis
::author jun.cui
::date 20170119
color 0e
::sqlip is your sqlserver address, sqldbname is sqlserver database name,sqlusername is sqlserver uname,
::sqlpasword is sqlservber passwd, initsqlscript is init sql scripts
set sqlip=192.168.10.96
set sqldbname=HYfrontce
set sqlusername=sa
set sqlpasword=masterkey
set initsqlscript=E:\清库脚本风险很大注意备份（慧云系统切换系统的数据清理脚本20151230V2.0).sql

osql -S %sqlip% -d %sqldbname% -U %sqlusername% -P %sqlpasword% -i %initsqlscript%

::osql -S 192.168.10.96  gdjlc -d HYfrontce TestDB -U sa -P masterkey 1 -i E:\清库脚本风险很大注意备份（慧云系统切换系统的数据清理脚本20151230V2.0).sql

::setting your delete all dir
::set m=F:\CshisNet\CshisNetWs
::buildDir is your dev build ftp dir, targetDir is your iis server target dir
set buildDir=c:\test
set targetDir=F:\CshisNet\CshisNetWs
:delete your target build file
del "%targetDir%\*" /f /s /q /a
for /f "delims=" %%i in ('dir /ad /w /b "%targetDir%"') do (
rd /s /q "%targetDir%\%%i"
)

:xcopy newest build to target dir
::delete F:\CshisNet\CshisNetWs
::copy target files
xcopy %buildDir% %targetDir% /s /e /r

::reset your iis server
:reset IIS Server
net stop iisadmin /yes
net start iisadmin
net start w3svc

pause
:exit
