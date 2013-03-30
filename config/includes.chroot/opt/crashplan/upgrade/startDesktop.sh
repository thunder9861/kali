#!/bin/sh

# Launch the desktop for Mac

appBaseName=`echo "$PWD" | sed -e 's/.*\/\(.*\)\.app\/.*/\1/'`
executableDir=`echo "$PWD" | sed -e 's/\(.*\.app\/Contents\/\).*/\1MacOS/'`

if [ -f "$executableDir/${appBaseName}" ]; then
	"$executableDir/${appBaseName}" &
else 
	"$executableDir/JavaApplicationStub" &
fi