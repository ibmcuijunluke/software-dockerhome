#jwbase_interface_test_report

#BUILD_ID=cw-hms-web-buildnumber
BUILD_ID=DONTKILLME0
ls -ll
#killall node
#echo " kill all nodejs process on linux server the WORKSPACE is --->"$WORKSPACE
cd /opt
./killNode.sh
#cnpm i &&
#npm start
ps -elf|grep node



BUILD_ID=cw-hms-web-buildnumber
#BUILD_ID=DONTKILLME
ls -ll
#killall node
cd $WORKSPACE
rm -rf *.json.gz
#delete all .json.gz files on cw-web

cd  src
mv CONFIG.js CONFIG.js.bak
cp /opt/CONFIG.js .
cat CONFIG.js

#change web project rounter rules,system will change no-rountlinks acess.
cd utils
sed -i '1 s/\/\///g' router_helper.js
sed -i '2 s/^/\/\//g' router_helper.js
sed -i 's/^[ \t]*//g' router_helper.js
cat router_helper.js

cd ../..
pwd


npm install -g cnpm --registry=https://registry.npm.taobao.org &&
cnpm i &&
npm run build &&

#su - root
#cnpm i &&
#npm run build &&
#nohup babel-node ./server.js
#cnpm i &&
#npm run build &&
#npm run build &&
#nohup npm run server &
#nohup babel-node ./server.js &
#pm2 start pm2test.json &&
#pm2 start server.js --name 'cw-web-server'
#pm2 list
#echo " restart  all nodejs process on linux server  the WORKSPACE is --->"$WORKSPACE
cd /opt
#chmod 777 restartNode.sh
#ls -ll restartNode.sh
./restartNode.sh
whoami
#sudo su - root
#cd $WORKSPACE
#cnpm i &&
#npm run build &&
#nohup npm run server &
#cnpm i &&
#npm start

ps -elf|grep node

cd $WORKSPACE
pm2 start pm2test.json
ps -elf|grep node

cd $WORKSPACE
rm -rf *.json.gz
#delete all .json.gz files on cw-web
ls

pm2 list
#pm2 logs
