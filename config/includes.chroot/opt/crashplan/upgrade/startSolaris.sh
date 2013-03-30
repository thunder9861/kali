#!/bin/sh

# Runs the Solaris UpgradeUI in it's own JVM.

# source the install vars
. ../../install.vars

$JAVACOMMON -classpath .:./com.backup42.desktop.jar com.backup42.desktop.UpgradeUI $* >> start.log 2>&1 &

