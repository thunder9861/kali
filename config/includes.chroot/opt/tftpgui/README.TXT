TFTPgui Version : 2.2
Date 20110908

This program is a TFTP server.

It is intended to run as a user initiated program, rather than a service daemon,
and displays a gui interface allowing the user to stop and start the tftp server.

It provides a simple tftp server for engineers to download and upload
configuration files from equipment such as routers and switches.


Installation

Download the tar file tftpgui_2_2.tar : Untar it into a directory of your
choice, and running "python tftpgui.py" will run the program.

Or if using Windows: download tftpgui_2_2.zip, unzip it and run
'python tftpgui.pyw'

The full command is run:

python tftpgui.py [options] <configuration-file>

The command line options are:

--nogui : in which case the tftp server is run, but no GUI is created.
--version : prints the version number and exits
--help : prints a usage message and exits

<configuration-file> : The optional location of a configuration file.

Windows users may need to replace the 'python' with the path to their Python
interpreter, i.e. C:\Python27\python tftpgui.pyw

It would also be possible to associate the .pyw extension with the python
interpreter, in which case merely double clicking on the tftpgui.pyw file
will run the program.

This version of tftpgui requires python 2.5 to 2.7 to be installed, and also the
python tk modules.

On Ubuntu/Debian this is package python-tk, on Widows it is built into
Python and does not need to be separately installed.

(A version 3 of TFTPgui exists which works with Python 3)


Usage

The program presents you with a graphical window, with start, stop,
setup and exit buttons.

Start - will start the server, which will then listen for file
        transfers from remote tftp clients.

Stop - will stop the server.

Setup - will open a window giving various options described below.

Exit - will close the program.


Setup Options

TFTP ROOT Folder: set the folder where files will be sent and received

TFTP LOGS Folder: During transmission, the program writes log entries,
these are held in this folder, which you can set.

Allow access from any remote IP Address, or just a specified subnet:

If any remote address is allowed, then any client can call this server.

If a subnet is specified, then you may input the subnet and mask, and
the server will only accept calls from clients within this subnet.
If you wish to limit remote access from a single device, set the subnet
to the remote device IP address, and the mask to 32.

PORT: The port which the tftp server listens on, as standard this is 69

It should be noted that on Linux, to set up a server listening on any
port below 1000 requires root permission, therefore you will need
to be root (or use sudo) to run this program on port 69.

APPLY - Save and implement the options.

CANCEL - Discard any option changes you have done.

DEFAULT - Set options to the initial defaults.


Configuration file

Under normal use, the hidden file .tftpgui.cfg is automatically created
in the users home directory (on Linux, or the equivalent per user
application directory on Windows).  This file is initially created
with default values and changed whenever the user sets changes on
the graphical interface. The file is subsequently read on startup,
so the users changes are persistent.

Most users need never look at, or edit the file, however a configuration
file location can be specified on the command line, which may be
useful if the program is to be started without a GUI.

Typical contents of configuration file:

---------------------------------------------------
[IPsetup]
clientmask = 16
listenport = 69
anyclient = 1
listenipaddress = 0.0.0.0
clientipaddress = 192.168.0.0

[Folders]
tftprootfolder = /home/bernie/tftpgui/tftproot
logfolder = /home/bernie/tftpgui/tftplogs
----------------------------------------------------

The value 'anyclient' is set to 1 to indicate any client can contact
the server, or zero if only a client with an ip address in the given
subnet will be accepted.

The folder locations will be set to appropriate locations on your
own PC the first time you run the program.

The configuration file has one option not set via the GUI. This
is 'listenipaddress' which is normally set to 0.0.0.0 - meaning
the server will listen on any ip address. If however you have a
machine with multiple IP addresses and you want the tftp service
to only listen on one, you can set the IP address here. 


version 2.2 changes:

Refactored, to make the code more flexible.
The configuration file now created in the users home as an hidden
file.


New in version 2:

Using the --nogui option on the command line allows the server to be
run without a graphical environment, in which case the configuration
file is the only form of controlling the server. In this case, a
configuration file location can be set on the command line.

