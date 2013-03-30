#!/bin/bash
#
# Resolve the location of the SmartGit/Hg installation.
# This includes resolving any symlinks.
PRG=$0
while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
    if expr "$link" : '^/' 2> /dev/null >/dev/null; then
        PRG="$link"
    else
        PRG="`dirname "$PRG"`/$link"
    fi
done

SMARTGIT_BIN=`dirname "$PRG"`

# absolutize dir
oldpwd=`pwd`
cd "${SMARTGIT_BIN}"; SMARTGIT_BIN=`pwd`
cd "${oldpwd}"; unset oldpwd

ICON_NAME=syntevo-smartgithg
DESKTOP_FILE=syntevo-smartgithg.desktop
cat << EOF > $DESKTOP_FILE
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=SmartGit/Hg 4
GenericName=SmartGit/Hg - Git&Hg-Client + SVN-support
Type=Application
Categories=Development;RevisionControl
Terminal=false
StartupNotify=true
Exec="$SMARTGIT_BIN/smartgithg.sh"
Icon=$ICON_NAME.png
EOF

xdg-desktop-menu install $DESKTOP_FILE
xdg-icon-resource install --size  32 smartgithg-32.png  $ICON_NAME
xdg-icon-resource install --size  48 smartgithg-48.png  $ICON_NAME
xdg-icon-resource install --size  64 smartgithg-64.png  $ICON_NAME
xdg-icon-resource install --size 128 smartgithg-128.png $ICON_NAME
