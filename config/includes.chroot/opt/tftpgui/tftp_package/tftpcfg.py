####### TFTPgui #######
#
# tftpcfg.py  - reads configuration file for TFTPgui
#
# Version : 2.2
# Date : 20110812
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
#    along with TFTPgui.  If not, see <http://www.gnu.org/licenses/>.
#

"""This module provides functions to parse and store
config information for the TFTPgui program

It stores setup values in the configfile, and
via function getconfig() it returns a dictionary of
the setup values, these being:

 tftprootfolder  - path to a folder
 logfolder       - path to a folder
 anyclient       - 1 if any client can call, 0 if only from a specific subnet
 clientipaddress - specific subnet ip address of the client
 clientmask      - specific subnet mask of the client
 listenport      - tftp port to listen on
 listenipaddress - address to listen on
"""

from __future__ import with_statement
import ConfigParser
import os
import sys

from tftp_package import ipv4

# Store configfile location as a global variable
CONFIGFILE = ""

# Store scriptdirectory location as a global variable
SCRIPTDIRECTORY = ""


class ConfigError(Exception):
    """The configuration has an error"""
    pass

def get_defaults():
    "Returns a dictionary of default values"
    cfgdict = { "anyclient": True,
                "clientipaddress": "192.168.0.0",
                "clientmask": 16,
                "listenport": 69,
                "listenipaddress": "0.0.0.0"  }
    if SCRIPTDIRECTORY:
        cfgdict["tftprootfolder"]=os.path.join(SCRIPTDIRECTORY,'tftproot')
        cfgdict["logfolder"]=os.path.join(SCRIPTDIRECTORY,'tftplogs')
    return cfgdict


def getconfigstrict(scriptdirectory, configfile):
    """Returns a dictionary of config values
       If any of the read values are missing or
       invalid, raise ConfigError"""

    global SCRIPTDIRECTORY, CONFIGFILE
    SCRIPTDIRECTORY = scriptdirectory
    CONFIGFILE = configfile
    cfgdict = {}

    if not os.path.isfile(configfile):
        CONFIGFILE = ""
        raise ConfigError, "The configuration file does not exist"

    # Now create a ConfigParser object, to read the config file
    cfg=ConfigParser.ConfigParser()
    try:
        cfg.read(configfile)
    except Exception:
        CONFIGFILE = ""
        raise ConfigError, "Unable to read the configuration file"

    # make sure cfg has the two sections Folders and IPsetup
    if not cfg.has_section("Folders"):
        raise ConfigError, "The configuration file has no Folders section"
    if not cfg.has_section("IPsetup"):
        raise ConfigError, "The configuration file has no IPsetup section"

    # Read each parameter in turn

    # tftprootfolder
    if cfg.has_option("Folders", "tftprootfolder"):
        cfgdict["tftprootfolder"]=os.path.abspath(cfg.get("Folders", "tftprootfolder"))
    else:
        raise ConfigError, "tftprootfolder missing from configuration file"

    # logfolder
    if cfg.has_option("Folders", "logfolder"):
        cfgdict["logfolder"]=os.path.abspath(cfg.get("Folders", "logfolder"))
    else:
        raise ConfigError, "logfolder missing from configuration file"

    # anyclient
    if cfg.has_option("IPsetup", "anyclient"):
        try:
            cfgdict["anyclient"]=bool(int(cfg.get("IPsetup", "anyclient")))
        except Exception:
            raise ConfigError, "Option anyclient in the config file is in error"
    else:
        raise ConfigError, "anyclient missing from configuration file"

    # clientipaddress
    if cfg.has_option("IPsetup", "clientipaddress"):
        cfgdict["clientipaddress"]=cfg.get("IPsetup", "clientipaddress")
    else:
        raise ConfigError, "clientipaddress missing from configuration file"

    # clientmask
    if cfg.has_option("IPsetup", "clientmask"):
        try:
            cfgdict["clientmask"]=int(cfg.get("IPsetup", "clientmask"))
        except Exception:
            raise ConfigError, "Option clientmask in the config file is in error"
    else:
        raise ConfigError, "clientmask missing from configuration file"

    # listenipaddress
    if cfg.has_option("IPsetup", "listenipaddress"):
        cfgdict["listenipaddress"]=cfg.get("IPsetup", "listenipaddress")
    else:
        raise ConfigError, "listenipaddress missing from configuration file"

    # listenport
    if cfg.has_option("IPsetup", "listenport"):
        try:
            cfgdict["listenport"]=int(cfg.get("IPsetup", "listenport"))
        except Exception:
            raise ConfigError, "Option listenport in the config file is in error"
    else:
        raise ConfigError, "listenport missing from configuration file"
    # cfgdict now filled, check it
    status, message = validate(cfgdict)
    if not status:
        raise ConfigError, message
    # All ok, so return cfgdict
    return cfgdict
    

def getconfig(scriptdirectory, configfile):
    """Returns a dictionary of config values
    
       Read the configfile, and if parts do not exist,
       substitute defaults instead.

       If config file does not exist, create a new one
       If any items are invalid, raise ConfigError"""

    global SCRIPTDIRECTORY, CONFIGFILE
    SCRIPTDIRECTORY = scriptdirectory
    CONFIGFILE = configfile

    # Set defaults
    cfgdict = get_defaults()

    # Flag used to test if a new config file has to be written
    # Note; the following is more complex than it needs to be, since
    # it is written to be compatable with older versions of TFTPgui
    write_new_config = False
    
    # Now create a ConfigParser object, to read and write
    # to the config file
    cfg=ConfigParser.ConfigParser()
    try:
        if os.path.isfile(configfile):
            cfg.read(configfile)
    except Exception:
        CONFIGFILE = ""
        raise ConfigError, "Unable to read the configuration file"

    # make sure cfg has the two sections Folders and IPsetup
    if not cfg.has_section("Folders"):
        cfg.add_section("Folders")
    if not cfg.has_section("IPsetup"):
        cfg.add_section("IPsetup")

    # Read each parameter in turn, and if it doesnt
    # exist, make sure the defaults are inserted into cfg instead

    # tftprootfolder
    if cfg.has_option("Folders", "tftprootfolder"):
        cfgdict["tftprootfolder"]=os.path.abspath(cfg.get("Folders", "tftprootfolder"))
    else:
        write_new_config = True
        cfg.set("Folders", "tftprootfolder", cfgdict["tftprootfolder"])

    # logfolder
    if cfg.has_option("Folders", "logfolder"):
        cfgdict["logfolder"]=os.path.abspath(cfg.get("Folders", "logfolder"))
    else:
        write_new_config = True
        cfg.set("Folders", "logfolder", cfgdict["logfolder"])

    # anyclient
    if cfg.has_option("IPsetup", "anyclient"):
        try:
            cfgdict["anyclient"]=bool(int(cfg.get("IPsetup", "anyclient")))
        except Exception:
            raise ConfigError, "Option anyclient in the config file is in error"
    else:
        write_new_config = True
        if cfg.has_option("IPsetup", "anysource"):
            try:
                cfgdict["anyclient"]=bool(int(cfg.get("IPsetup", "anysource")))
            except Exception:
                raise ConfigError, "Option anysource in the config file is in error"
            cfg.remove_option("IPsetup", "anysource")
        if cfgdict["anyclient"]:
            cfg.set("IPsetup", "anyclient", "1")
        else:
            cfg.set("IPsetup", "anyclient", "0")

    # clientipaddress
    if cfg.has_option("IPsetup", "clientipaddress"):
        cfgdict["clientipaddress"]=cfg.get("IPsetup", "clientipaddress")
    else:
        write_new_config = True
        if cfg.has_option("IPsetup", "ipaddress"):
            cfgdict["clientipaddress"]=cfg.get("IPsetup", "ipaddress")
            cfg.remove_option("IPsetup", "ipaddress")
        cfg.set("IPsetup", "clientipaddress", cfgdict["clientipaddress"])

    # clientmask
    if cfg.has_option("IPsetup", "clientmask"):
        try:
            cfgdict["clientmask"]=int(cfg.get("IPsetup", "clientmask"))
        except Exception:
            raise ConfigError, "Option clientmask in the config file is in error"
    else:
        write_new_config = True
        if cfg.has_option("IPsetup", "mask"):
            try:
                cfgdict["clientmask"]=int(cfg.get("IPsetup", "mask"))
            except Exception:
                raise ConfigError, "Option clientmask in the config file is in error"
            cfg.remove_option("IPsetup", "mask")
        cfg.set("IPsetup", "clientmask", str(cfgdict["clientmask"]))

    # listenipaddress
    if cfg.has_option("IPsetup", "listenipaddress"):
        cfgdict["listenipaddress"]=cfg.get("IPsetup", "listenipaddress")
    else:
        write_new_config = True
        cfg.set("IPsetup", "listenipaddress", cfgdict["listenipaddress"])

    # listenport
    if cfg.has_option("IPsetup", "listenport"):
        try:
            cfgdict["listenport"]=int(cfg.get("IPsetup", "listenport"))
        except Exception:
            raise ConfigError, "Option listenport in the config file is in error"
    else:
        write_new_config = True
        if cfg.has_option("IPsetup", "port"):
            try:
                cfgdict["listenport"]=int(cfg.get("IPsetup", "port"))
            except Exception:
                raise ConfigError, "Option port in the config file is in error"
            cfg.remove_option("IPsetup", "port")
        cfg.set("IPsetup", "listenport", str(cfgdict["listenport"]))

    # cfgdict now filled, check it
    status, message = validate(cfgdict)
    if not status:
        raise ConfigError, message
    # All ok, so return cfgdict

    # So cfg and dictionary cfgdict are now matched
    if write_new_config and CONFIGFILE:
        # changes have been made, so write out the config file
        try: 
            with open(configfile, "w") as fp:
                cfg.write(fp)
        except Exception:
            CONFIGFILE = ""
            raise ConfigError, "Unable to update the config file"

    return cfgdict


def setconfig(cfgdict):
    """Writes cfgdict to the configuration file, only
       writes if there are changes, returns True on success
       False on failure.
       """
    try:
        if not CONFIGFILE:
            return False
        # Flag used to test if a new config file has to be written
        write_new_config = False
        
        # Now create a ConfigParser object, to read and write
        # to the config file
        cfg=ConfigParser.ConfigParser()
        if os.path.exists(CONFIGFILE):
            # read it
            cfg.read(CONFIGFILE)

        # make sure cfg has the two sections Folders and IPsetup
        if not cfg.has_section("Folders"):
            cfg.add_section("Folders")
        if not cfg.has_section("IPsetup"):
            cfg.add_section("IPsetup")

        # Read each parameter in turn, and if it doesnt
        # exist, make sure the defaults are inserted into cfg instead

        # tftprootfolder
        if ("tftprootfolder" in cfgdict) and (not cfg.has_option("Folders", "tftprootfolder") or 
            cfgdict["tftprootfolder"] != cfg.get("Folders", "tftprootfolder")):
            write_new_config = True
            cfg.set("Folders", "tftprootfolder", cfgdict["tftprootfolder"])

        # logfolder
        if ("logfolder" in cfgdict) and (not cfg.has_option("Folders", "logfolder") or
            cfgdict["logfolder"] != cfg.get("Folders", "logfolder")):
            write_new_config = True
            cfg.set("Folders", "logfolder", cfgdict["logfolder"])

        # anyclient
        if "anyclient" in cfgdict:
            if cfgdict["anyclient"]:
                anyclient = "1"
            else:
                anyclient = "0"
            if (not cfg.has_option("IPsetup", "anyclient") or
                anyclient != cfg.get("IPsetup", "anyclient")):
                write_new_config = True
                cfg.set("IPsetup", "anyclient", anyclient)

        # clientipaddress
        if ("clientipaddress" in cfgdict) and (not cfg.has_option("IPsetup", "clientipaddress") or
            cfgdict["clientipaddress"] != cfg.get("IPsetup", "clientipaddress")):
            write_new_config = True
            cfg.set("IPsetup", "clientipaddress", cfgdict["clientipaddress"])

        # clientmask
        if "clientmask" in cfgdict:
            clientmask = str(cfgdict["clientmask"])
            if (not cfg.has_option("IPsetup", "clientmask") or
                clientmask != cfg.get("IPsetup", "clientmask")):
                write_new_config = True
                cfg.set("IPsetup", "clientmask", clientmask)

        # listenipaddress
        if "listenipaddress" in cfgdict:
            if not cfgdict["listenipaddress"]:
                lipa = "0.0.0.0"
            else:
                lipa = cfgdict["listenipaddress"]
            if (not cfg.has_option("IPsetup", "listenipaddress") or
                lipa != cfg.get("IPsetup", "listenipaddress")):
                write_new_config = True
                cfg.set("IPsetup", "listenipaddress", lipa)

        # listenport
        if "listenport" in cfgdict:
            listenport = str(cfgdict["listenport"])
            if (not cfg.has_option("IPsetup", "listenport") or
                listenport != cfg.get("IPsetup", "listenport")):
                write_new_config = True
                cfg.set("IPsetup", "listenport", listenport)

        # So cfg and dictionary cfgdict are now matched
        if write_new_config:
            # changes have been made, so write out the config file  
            with open(CONFIGFILE, "w") as fp:
                cfg.write(fp)
    except Exception:
        # Return False on failure
        return False
    return True


def validate(cfgdict):
    """Returns True, None if cfgdict ok
       or False, message if there is an error"""
    status,message = validate_tftprootfolder(cfgdict["tftprootfolder"])
    if not status:
        return status, message
    status,message = validate_logfolder(cfgdict["logfolder"])
    if not status:
        return status, message
    status,message = validate_listenport(cfgdict["listenport"])
    if not status:
        return status, message
    status,message = validate_clientmask(cfgdict["clientmask"])
    if not status:
        return status, message
    status,message = validate_client_ip_mask(cfgdict["clientipaddress"], cfgdict["clientmask"])
    if not status:
        return status, message
    status,message = validate_listenipaddress(cfgdict["listenipaddress"])
    if not status:
        return status, message
    return True, None


def validate_tftprootfolder(tftprootfolder):
    """Check tftprootfolder"""
    if not os.path.exists(tftprootfolder):
        # it doesn't exist
        return False, "The tftp root folder does not exist"
    if not os.path.isdir(tftprootfolder):
        return False, "The tftp root folder given is not a directory"
    if not os.access(tftprootfolder, os.R_OK | os.W_OK):
        return False, "Application does not have read-write\npermissions to the tftp root folder"
    return True, None


def validate_logfolder(logfolder):
    """Check logfolder"""
    if not os.path.exists(logfolder):
        # it doesn't exist
        return False, "The log folder does not exist"
    if not os.path.isdir(logfolder):
        return False, "The log folder given is not a directory"
    if not os.access(logfolder, os.W_OK):
        return False, "Application does not have write\npermissions to the log folder"
    return True, None

def validate_listenport(listenport):
    """Check listenport"""
    if listenport<0 or listenport>65535:
        return False, "Port must be between 0 and 65535"
    return True, None

def validate_clientmask(clientmask):
    """Check clientmask"""
    if clientmask<0 or clientmask>32:
        return False, "Subnet Mask must be between 0 and 32"
    return True, None

def validate_client_ip_mask(clientipaddress, clientmask):
    """Check clientipaddress and clientmask"""
    broadcast_address, network_address = ipv4.parse(clientipaddress, clientmask)
    if not broadcast_address:
        return False, "Client ip address and mask do not make a valid subnet"
    return True, None

def validate_listenipaddress(listenipaddress):
    """Check listenipaddress"""
    if not listenipaddress or listenipaddress == "0.0.0.0":
        return True, None
    broadcast_address, network_address = ipv4.parse(listenipaddress, 32)
    if not broadcast_address:
        return False, "Server listen ip address is not valid"
    return True, None

def make_subnet(clientipaddress, clientmask):
    "Returns a subnet string"
    if clientmask != "32":
        broadcast_address, network_address = ipv4.parse(clientipaddress, clientmask)
        return network_address
    else:
        return clientipaddress



