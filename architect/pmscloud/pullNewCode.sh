#!/bin/bash
#author cuijun 20170119
declare remotebranch="origin/develop"
declare localbranch="develop"

echo "starting pull all dev branch for jw-source project..."
#sleep 1s
echo $localbranch
echo $remotebranch
echo " the localbranch->$localbranch the remotebranch->$remotebranch"
echo "start pull jw-source-pmscode now ->cw-hms-web"
cd cw-hms-web &&
git checkout $localbranch &&
#git fetch --all &&
git fetch --all  &&
git reset --hard $remotebranch &&
git pull &&
git branch -a

sleep 1s

cd ..

echo "start pull jw-source-pmscode now ->cw-hms-source"
cd cw-hms-source &&
git checkout $localbranch &&
git fetch --all  &&
git reset --hard $remotebranch &&
git pull &&
git branch -a
#git fetch --all &&
#git checkout develop
sleep 1s
#git pull



echo "start pull jw-source-basecode now ->jw-source"
cd ..
cd jw-source  &&
git checkout $localbranch &&
git fetch --all  &&
git reset --hard $remotebranch &&
git pull &&
git branch -a
#git pull
#git fetch --all &&
#sleep 1s
cd ..
#git checkout master
echo "pull all dev branch source code has been done"