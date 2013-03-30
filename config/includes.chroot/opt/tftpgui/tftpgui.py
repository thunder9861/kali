#!/usr/bin/env python

####### TFTPgui #######
#
# tftpgui.py  - a TFTP server
#
# Version : 2.2
# Date : 20110908
#
# Author : Bernard Czenkusz
# Email  : bernie@skipole.co.uk
#
#
# Copyright (c) 2007,2008,2009,2010,2011 Bernard Czenkusz
#
# This file is part of TFTPgui.
#
#    TFTPgui is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    TFTPgui is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with VATStuff.  If not, see <http://www.gnu.org/licenses/>.
#

"""
tftpgui.py  - a TFTP server.

This script parses command line options, reads the configuration file
and starts a GUI loop in the main thread and the tftp service in a
second thread. It is intended to be run with the simplest installation;
by placing the files in a directory and running the script from there.

The program is run with:

python tftpgui.py [options] <configuration-file>

The command line options are:

--nogui : in which case the tftp server is run, but no GUI is created.
--version : prints the version number and exits
--help : prints a usage message and exits

<configuration-file> : The optional location of a configuration file.

Normally a hidden file .tftpgui.cfg in the users home directory will
be created with default values.

The configuration file holds the options available via the GUI 'Setup'
button and as these are changed in the GUI, they are changed in the
config file.

With one exception:  The config file also has the option 'listenipaddress'
which by default is set to '0.0.0.0' - meaning listen on any address.

If 'listenipaddress' is set to a specific IP address of the computer
(only applicable for a computer with multiple ip addresses), then it will
only listen on the address given.

If run with the --nogui option then the program has no dependencies other
than standard Python (versions 2.5 to 2.7).  If run with a GUI then the
script imports the Tkinter module, and some Gnu/Linux distributions may
require this installing (package python-tk in Debian).

Note: If set to listen on port 69 (the default tftp server port), then
under Gnu/Linux the program must be run with administrator pivileges
(ie using sudo) - as the OS requires this.
"""

import os, sys, thread, time

from optparse import OptionParser

from tftp_package import tftpcfg, tftp_engine

# Check the python version
if not sys.version_info[0] == 2 and sys.version_info[1] >= 5:
    print("Sorry, your python version is not compatable")
    print("This program requires python 2.5, 2.6 or 2.7")
    print("Program exiting")
    sys.exit(1)

usage = """usage: %prog [options] <configuration-file>

Without any options the program runs with a GUI.
If no configuration file is specified, the program
will search for one in:

The script directory as 'tftpgui.cfg'
Linux: The users home directory as '.tftpgui.cfg'
Windows: The per-user applications data directory
as 'tftpgui.cfg'

If the configuration file cannot be found, one will
be created with default values in the users home,
or per-user application data directory"""

parser = OptionParser(usage=usage, version="2.2")
parser.add_option("-n", "--nogui", action="store_true", dest="nogui", default=False,
                  help="program runs without GUI, serving immediately")
(options, args) = parser.parse_args()

# get the directory this script is in
scriptdirectory=os.path.abspath(os.path.dirname(sys.argv[0]))

# set the default location of the config file
# in the scriptdirectory, or, if no file exists in
# the script directory, set it as a hidden file
# in users home directory
default_configfile=os.path.join(scriptdirectory, 'tftpgui.cfg')
if not os.path.isfile(default_configfile):
    if os.name == "nt":
        # where data is stored for windows systems
        configdirectory = os.getenv("APPDATA", scriptdirectory)
        default_configfile = os.path.join(configdirectory, 'tftpgui.cfg')
    else:
        # The users home directory - where data is stored for Linux systems
        configdirectory = os.getenv("HOME", os.getenv("HOMEPATH", scriptdirectory))
        default_configfile = os.path.join(configdirectory, '.tftpgui.cfg')

# However if a config file is given on command line, this overrides
if args:
    configfile = args[0]
else:
    configfile = default_configfile

# read configuration values
error_text = ""

if (not options.nogui) and configfile == default_configfile:
    # Gui option and default config, if the config file
    # does not exist, or sections are missing, re-create it
    try:
        cfgdict = tftpcfg.getconfig(scriptdirectory, configfile)
    except tftpcfg.ConfigError, e:
        # On error fall back to defaults, but warn the user
        cfgdict = tftpcfg.get_defaults()
        error_text = "Error in config file:\n" + str(e) + "\nso using defaults"
else:
    # No gui, or not the default config file,
    # therefore read it with more rigour and exit if any errors
    try:
        cfgdict = tftpcfg.getconfigstrict(scriptdirectory, configfile)
    except tftpcfg.ConfigError, e:
        print "Error in config file:"
        print e
        sys.exit(1)

######## Create the server ######################
# this makes a server object.
# It is run in a loop, either using
# tftp_engine.loop_nogui(server)
# or
# tftp_engine.loop(server)
##################################################

server = tftp_engine.ServerState(**cfgdict)


if options.nogui:
    # Run the server from the command line without a gui
    if server.listenipaddress :
        print "TFTP server listening on %s:%s\nSee logs at:\n%s" % (server.listenipaddress,
                                                                    server.listenport,
                                                                    server.logfolder)
    else:
        print "TFTP server listening on port %s\nSee logs at:\n%s" % (server.listenport,server.logfolder)
    print "Press CTRL-c to stop"
    # loop_nogui runs the server loop,
    # which exits if the the server cannot listen on the port given
    # otherwise it exits on a CTRL-C keyboard interrupt
    # returns 0 if terminated with CTRL-c
    # or 1 if an error occurs
    result = tftp_engine.loop_nogui(server)
    sys.exit(result)


# Run the server with a gui
try:
    # Check Tkinter can be imported
    import Tkinter
except Exception:
    print """\
Failed to import Tkinter - required to run the GUI.
Check the TKinter Python module has been installed on this machine.
Alternatively, run with the --nogui option to operate without a GUI"""
    sys.exit(1)

# If an error occurred reading the config file, show it
if error_text:
    server.text = error_text +"\n\nPress Start to enable the tftp server"

# create a thread which runs the loop
thread.start_new_thread(tftp_engine.loop, (server,))

# create the gui
from tftp_package import gui_stuff
gui_stuff.create_gui(server)

# gui stopped, so stop the loop
server.break_loop = True

# give a moment for server thread to stop
time.sleep(0.5)

sys.exit(0)


