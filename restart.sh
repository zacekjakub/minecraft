#! /bin/bash

#description     :Manages MC restarts after time and on demand
#author		 :zacekjakub
#date            :20150401
#version         :0.1
#usage		 :Just set variables and add this script to crontab.
#notes           :You need mcrcon for announcements
#bash_version    :4.1.0


# Here set all variables

mc_directory="/opt/minecraft/"
xms="1024"              # like 1042M
xmx="2048"              # like 2048M
mc_file=
path_to_java=
lockfile=
whenrestart=



#================================================================

#Functions

#start
function start_mc() {
screen -dmS mc_screen $path_to_java -Xms$xms -Xmx$xmx -jar $mc_file nogui
}


#running or not
function isrunning() {
if [ -f $lockfile ] ; then
 echo 'Script lock detected, going to recheck'
 thisscriptname=`basename $0`
 countinstances=`ps aux | grep -i $thisscriptname | grep -v "grep" | wc -l`
  if [ "$countinstances" -lt "2" ]
   rm -f $lockfile
   echo "Because of fail-saved lockfile: lockfile removed"
  fi
 exit 0;
else
  echo 1 > $lockfile
  echo 'This is first instance of this script running, lock saved'
fi
}




#Code


#If already running, do nothing; if needed, remove lock
isrunning


javapid=$(pgrep java)
howlongruns=$(ps -eo pid,etime | grep $javapid | awk -F' ' '{print $2}')


hours=$(echo $howlongruns | awk -F':' '{print $1}')
echo $hours
inhours=$(grep -o ":" <<<"$howlongruns" | wc -l)

if [ $inhours -gt 1 ]; then
if [ $hours -gt $whenrestart ]; then
echo "seems session runs longer than 3 hours, setting restart"
echo "restart=true">/var/www/html/default/service/serverinfo.php
fi
fi
isscreenalreadyrunning=$(screen -ls|grep mc_screen|wc -l)

if [ $isscreenalreadyrunning -eq 0 ]; then
echo "screen is not running, starting new session with MC"
screen -dmS mc_screen /usr/lib/jvm/jre-1.8.0-openjdk-1.8.0.31-1.b13.el6_6.x86_64/bin/java -Xms1024M -Xmx2048M -jar forge-1.7.10-10.13.2.1291-universal.jar nogui
else
echo "screen is already running, everything seems to be ok"
fi


source /var/www/html/default/service/serverinfo.php

if [[ $restart = "true" ]]
then
echo "Restart request detected, starting restart"
echo "Announcing restart after 10 mins. and waiting"
./mcrcon -c -H 127.0.0.1 -P 25575 -p 2504 "say Omlouvame se, server bude do 10. minut restartovan."
sleep 5m
./mcrcon -c -H 127.0.0.1 -P 25575 -p 2504 "say Omlouvame se, server bude do 5. minut restartovan."
sleep 4m
./mcrcon -c -H 127.0.0.1 -P 25575 -p 2504 "say Omlouvame se, server bude za minutu restartovan."
sleep 1m
echo  "restarting after 10 mins."
./mcrcon -c -H 127.0.0.1 -P 25575 -p 2504 "say Omlouvame se, probiha planovany restart, server bude za chvilku opet dostupny."
sleep 5
screen -S mc_screen -X stuff "/save-all
"
sleep 5
screen -S mc_screen -X stuff "stop
"
echo "mc stopped, waiting 5s"
sleep 5
screen -X -S mc_screen quit
echo "destroyed screen for sure"
echo "restart=false">/var/www/html/default/service/serverinfo.php
echo "serverinfo set to standard"
screen -dmS mc_screen /usr/lib/jvm/jre-1.8.0-openjdk-1.8.0.31-1.b13.el6_6.x86_64/bin/java -Xms1024M -Xmx2048M -jar forge-1.7.10-10.13.2.1291-universal.jar nogui
echo "mc started again in new screen"
fi
rm -f /tmp/mylockFile
echo 'Lock removed'
