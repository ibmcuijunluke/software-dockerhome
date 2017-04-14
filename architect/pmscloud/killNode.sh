#!/bin/bash
#author cuijun 2016-11-22
#kill nodejs  pid
#cd /var/lib/jenkins/workspace/cw-hms-web
#cnpm i &&
#nohup npm start &

set -x
echo "check the grabash .json.gz files,and delete that!!!"
cd /var/lib/jenkins/workspace/cw-hms-web
rm -rf *..json.gz

echo "starting check node service................."
ps -elf|grep node
#echo " the WORKSPACE is --->"$WORKSPACE
count=`ps -ef | grep node | grep -v "grep"| wc -l`
echo " the node process count is =======>"$count
#########################################################

if [ $count -gt 0 ]; then

    ps -elf|grep node
    #killall node
    #re-deploy war package to destin dir.
    sleep 1s
    
else
    echo "nodejs service have not exists!"
    ps -elf|grep node
fi

echo "kill 3000 node pid........."
pidnode=`netstat -anp|grep 3000|awk '{printf $7}'|cut -d/ -f1`
echo "the 3000 pid is ->"$pidnode
#kill -9 $pidnode
if [ "$pidnode" == "" ]; then

    echo "nodejs service have not exists!"
    ps -elf|grep node
    
else
    ps -elf|grep node
    kill -9 $pidnode
    #re-deploy war package to destin dir.
    sleep 1s

fi



echo " killall  nodejs has been started."
