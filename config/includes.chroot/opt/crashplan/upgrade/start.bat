@echo off

..\..\jre\bin\java -classpath .;.\com.backup42.desktop.jar com.backup42.desktop.UpgradeUI %* >> start.log 2>&1

exit