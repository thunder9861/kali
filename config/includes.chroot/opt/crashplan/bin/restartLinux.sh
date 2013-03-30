#!/bin/sh

# Restart for Linux

# source the install vars
. ../install.vars

logFile="restart.`date +'%Y-%m-%d_%H.%M.%S'`.log"

echo `date` : `pwd`/restart.sh > $logFile
echo `date` : APP_BASENAME=$APP_BASENAME >> $logFile
echo `date` : DIR_BASENAME=$DIR_BASENAME >> $logFile

ENGINE_SCRIPT=./${APP_BASENAME}Engine
	
echo `date` : Stopping using $ENGINE_SCRIPT... >> $logFile 2>&1
$ENGINE_SCRIPT stop >> $logFile 2>&1
echo `date` : Sleeping 10 seconds... >> $logFile 2>&1
sleep 10
echo `date` : Starting using $ENGINE_SCRIPT... >> $logFile 2>&1
$ENGINE_SCRIPT start >> $logFile 2>&1	


# Print the service process summary to the logfile
echo `date` : New Service Process below: >> $logFile
ps axw | grep 'app=${APP_BASENAME}Service' | grep -v grep >> $logFile 2>&1
echo `date` : Exiting restart script >> $logFile
sleep 1
exit