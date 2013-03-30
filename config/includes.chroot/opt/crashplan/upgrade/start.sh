#!/bin/sh

# Runs the Mac UpgradeUI in it's own JVM.

java -XstartOnFirstThread -classpath .:./com.backup42.desktop.jar com.backup42.desktop.UpgradeUI $* >> start.log 2>&1 &
