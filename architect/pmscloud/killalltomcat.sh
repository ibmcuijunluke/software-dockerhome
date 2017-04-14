#!/bin/sh  
#TOM_HOME=$(cd `dirname $0`;cd ..;pwd)  
TOM_HOME=tomcat
ps -ef|grep $TOM_HOME|grep -v grep|grep -v kill  
if [ $? -eq 0 ];then  
    kill -9 `ps -ef|grep $TOM_HOME|grep -v grep|grep -v kill|awk '{print $2}'`  
else  
    echo $TOM_HOME' No Found Process'  
fi
