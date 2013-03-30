#!/bin/sh

logFile=startFirst.log
/bin/chmod ug+x $1 >> $logFile 2>&1
$* & >> $logFile
