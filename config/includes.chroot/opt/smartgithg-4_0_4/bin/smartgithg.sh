#!/bin/bash
#
# Normally, editing this script should not be required.
#
# To specify an alternative Java Runtime Environment, set the environment variable SMARTGITHG_JAVA_HOME

if [ "$SMARTGITHG_JAVA_HOME" = "" ] ; then
	SMARTGITHG_JAVA_HOME=$SMARTGIT_JAVA_HOME
fi
if [ "$SMARTGITHG_JAVA_HOME" = "" ] ; then
	SMARTGITHG_JAVA_HOME=$JAVA_HOME
fi

if [ "$SMARTGITHG_MAX_HEAP_SIZE" = "" ] ; then
	SMARTGITHG_MAX_HEAP_SIZE=$SMARTGIT_MAX_HEAP_SIZE
fi
if [ "$SMARTGITHG_MAX_HEAP_SIZE" = "" ] ; then
	SMARTGITHG_MAX_HEAP_SIZE=256m
fi

# this seems necessary for Solaris to find the Cairo-library
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib/gnome-private/lib

_JAVA_EXEC="java"
if [ "$SMARTGITHG_JAVA_HOME" != "" ] ; then
    _TMP="$SMARTGITHG_JAVA_HOME/bin/java"
    if [ -f "$_TMP" ] ; then
        if [ -x "$_TMP" ] ; then
            _JAVA_EXEC="$_TMP"
        else
            echo "Warning: $_TMP is not executable"
        fi
    else
        echo "Warning: $_TMP does not exist"
    fi
fi

if ! which "$_JAVA_EXEC" >/dev/null ; then
    echo "Error: No java environment found"
    exit 1
fi

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

SMARTGIT_HOME=`dirname "$SMARTGIT_BIN"`

_VM_PROPERTIES="-Dsun.io.useCanonCaches=false"

# Uncomment the following line to change the location where SmartGit/Hg should store
# settings (the given example path will make SmartGit/Hg portable by storing the settings
# in the installation directory):
#_VM_PROPERTIES="$_VM_PROPERTIES -Dsmartgit.settings=\${smartgit.installation}/.smartgit"

while :
do
  $_JAVA_EXEC $_VM_PROPERTIES -Xmx${SMARTGITHG_MAX_HEAP_SIZE} -Xverify:none -Dsmartgit.vm-xmx=${SMARTGITHG_MAX_HEAP_SIZE} -Dmain-class=SmartGit -jar "$SMARTGIT_HOME/lib/bootloader.jar" "$@"
  if [ "$?" -ne 88 ]
  then
    break;
  fi

  echo "restarting ..."
done
