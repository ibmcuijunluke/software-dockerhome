BUILD_ID=cw-hms-tomcat-buildnumber
ls -ll
cd /opt

./restartTomcat2Service.sh
#./restartTomcatServer.sh
sleep 1s

#./deployWar.sh/opt/apache-tomcat-8.0.41-RA/webapps
#cd /opt/apache-tomcat-8.0.41-RA/bin
#./startup.sh &
ps -elf|grep tomcat
