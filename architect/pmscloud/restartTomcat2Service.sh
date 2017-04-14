#!/bin/bash
#author cuijun 2016-11-22
#kill tomcat pid and copy new war deploy to target tomcat server and restart it.
#pidcontrlllist=`ps -ef|grep apache-tomcat-7-controller|grep -v "grep"|awk '{print $2}'`
echo "##################################################################################"
echo "##############staring deplpy apache-tomcat-8.0.41 project....................."
echo "##################################################################################"
pidTomcatlist=`ps -ef|grep apache-tomcat-8.0.41-RP|grep -v "grep"|awk '{print $2}'`
echo "@@@@@@@@@@the tomcat process is>>>>>>>>>>>>> --->$pidTomcatlist"

#echo "the tomcat process is --->$pidservicelist"
#if [ "$pidcontrlllist" = "" ]
#   then
#       echo "no tomcat pid alive!"
#else
#  echo "tomcat Id list :$pidcontrlllist"
#  kill -9 $pidcontrlllist
#  #killall tomcat
#  echo "service stop success"
#fi

if [ "$pidTomcatlist" = "" ]
   then
       echo " the linux server has no tomcat pid alive!"
else
  echo "@@@@@@@@@@@tomcat Id list>>>>>>>>>>>>>>>> :$pidTomcatlist"
  kill -9 $pidTomcatlist
  #killall tomcat
  echo " the tomcat RA service stop success"
fi

cd /var/lib/jenkins/workspace/cw-hms-source
ls -ll
#cd 3160001RA/target
#cp 3160001RA-1.0.0-SNAPSHOT.war /opt/javawars/
#sleep 1s
#cd ../..
cd 3171001R/target 
cp 3171001R-1.0.0-SNAPSHOT.war /opt/javawars/
sleep 1s
cd /opt/javawars/
chmod 777 *
ls -ll

echo "delete all wars for tomcat server...."
cd /opt/apache-tomcat-8.0.41-RP
cd webapps
#rm -rf 3160001RA-1.0.0-SNAPSHOT
rm -rf 3171001R-1.0.0-SNAPSHOT
rm -rf *.war
pwd
cp /opt/javawars/3171001R-1.0.0-SNAPSHOT.war .

echo "starting cw-source controller  tomcat services............."
#cd /opt/apache-tomcat-7-controller/bin
#./startup.sh &
cd /opt/apache-tomcat-8.0.41-RP/bin
ls -ll startup.sh
#nohup startup.sh &
nohup ./startup.sh &

echo "##################################################################################"
echo "##############staring deplpy apache-tomcat-8.0.41-RA project....................."
echo "##################################################################################"
pidTomcatlistRA=`ps -ef|grep apache-tomcat-8.0.41-RA|grep -v "grep"|awk '{print $2}'`
echo "@@@@@@@@@@the tomcat process is>>>>>>>>>>>>> --->$pidTomcatlistRA"


if [ "$pidTomcatlistRA" = "" ]
   then
       echo " the linux server has no tomcat pid alive!"
else
  echo "@@@@@@@@@@@tomcat Id list>>>>>>>>>>>>>>>> :$pidTomcatlistRA"
  kill -9 $pidTomcatlistRA
  #killall tomcat
  echo " the tomcat RA service stop success"
fi

cd /var/lib/jenkins/workspace/cw-hms-source
ls -ll
cd 3160001RA/target
cp 3160001RA-1.0.0-SNAPSHOT.war /opt/javawars/
sleep 1s
#cd ../..
#cd 3171001R/target 
#cp 3171001R-1.0.0-SNAPSHOT.war /opt/javawars/
sleep 1s
cd /opt/javawars/
chmod 777 *
ls -ll

echo "delete all wars for tomcat server...."
cd /opt/apache-tomcat-8.0.41-RA
cd webapps
rm -rf 3160001RA-1.0.0-SNAPSHOT
#rm -rf 3171001R-1.0.0-SNAPSHOT
rm -rf *.war
pwd
cp /opt/javawars/3160001RA-1.0.0-SNAPSHOT.war .

echo "starting cw-source controller  tomcat services............."
#cd /opt/apache-tomcat-7-controller/bin
#./startup.sh &
cd /opt/apache-tomcat-8.0.41-RA/bin
ls -ll startup.sh
#nohup startup.sh &
nohup ./startup.sh &


echo " The all cw-source tomcat has been started."
