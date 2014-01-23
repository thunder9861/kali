#!/bin/sh
#
# ------------------------------------------------------
# RubyMine offline inspection script.
# ------------------------------------------------------
#

export DEFAULT_PROJECT_PATH="$(pwd)"

IDE_BIN_HOME="${0%/*}"
exec "$IDE_BIN_HOME/rubymine.sh" rinspect "$@"
