####### TFTPgui #######
#
# tftp_engine.py  - runs the tftp server for TFTPgui
#
# Version : 2.2
# Date : 20110813
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


"""
tftp_engine.py - runs the TFTP server for TFTPgui

Normally imported by tftpgui.py which creates an instance
of the ServerState class defined here, the instance holds
the ip address and port to bind to.

tftpgui.py then calls either:
loop_nogui(server)
or
loop(server)

Both create a loop, calling the poll() method of the ServerState
instance 'server', however loop_nogui exits if unable to bind to
the port whereas loop(server) is intended to run with a gui in
another thread, and keeps the loop working, so the user has the
option to change port parameters.
"""

import os, time, asyncore, socket, logging, logging.handlers, string

from tftp_package import ipv4


def create_logger(logfolder):
    "Create logger, return rootLogger on success, None on failure"
    if not logfolder:
        return None
    try:
        rootLogger = logging.getLogger('')
        rootLogger.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
        logfile=os.path.join(logfolder,"tftplog")
        loghandler = logging.handlers.RotatingFileHandler(logfile,
                                                maxBytes=20000, backupCount=5)
        loghandler.setFormatter(formatter)
        rootLogger.addHandler(loghandler)
    except Exception:
        return None
    return rootLogger

class DropPacket(Exception):
    """Raised to flag the packet should be dropped"""
    pass


class ServerState(object):
    """Defines a class which records the current server state
       and produces logs, and a text attribute for a gui"""

    def __init__(self, **cfgdict):
        """Creates a class which defines the state of the server
           cfgdict is a dictionary read from the config file
             tftprootfolder  - path to a folder
             logfolder       - path to a folder
             anyclient       - 1 if any client can call, 0 if only from a specific subnet
             clientipaddress - specific subnet ip address of the client
             clientmask      - specific subnet mask of the client
             listenport      - tftp port to listen on
             listenipaddress - address to listen on"""

        # self.serving is a settable/readable attribute
        # and instructs the class to serve or not when poll()
        # is called
        # self_serving is a flag that gives this actual status
        self.serving = False
        self._serving = False
        self.tftp_server = None
        self._engine_available = True
        self.logging_enabled = False

        # break_loop attribute is available, but not used by this class
        # it can be used by another thread to flag the loop should be brocken
        self.break_loop = False

        # set attributes from the dictionary, use assert to ensure
        # all attributes are present
        assert self.set_from_config_dict(cfgdict)

        # self._connections is a dictionary of current connections
        # the keys are address tuples, the values are connection objects
        # start off with an empty dictionary 
        self._connections = {}

        # The attribute self.text is read by the gui at regular intervals
        # and displayed to give server status messages
        self.text = """TFTPgui - a free tftp Server

Version\t:  TFTPgui 2.2
Author\t:  Bernard Czenkusz
Web site\t:  www.skipole.co.uk
License\t:  GPLv3

Press Start to enable the tftp server
"""

    def log_exception(self, e):
        "Used to log exceptions"
        if self.logging_enabled:
            try:
                logging.exception(e)
            except Exception:
                self.logging_enabled = False

    def add_text(self, text_line, clear=False):
        """Adds text_line to the log, and also to self.text,
           which is used by the gui interface - adds the line to
           the text, keeping a maximum of 12 lines.
           If clear is True, deletes previous lines, making text
           equal to this text_line only"""

        if len(text_line)>100:
            # limit to 100 characters
            text_line = text_line[:100]
        # strip non-printable characters, as this is to be displayed on screen
        text_line = ''.join([char for char in text_line if char in string.printable])

        if self.logging_enabled:
            try:
                logging.info(text_line)
            except Exception:
                self.logging_enabled = False

        if clear:
            self.text = text_line
            return
        text_list = self.text.splitlines()
        if not text_list:
            self.text = text_line
            return
        if len(text_list) > 12:
            # remove first line
            text_list.pop(0)
        text_list.append(text_line)
        self.text = "\n".join(text_list)

    def __len__(self):
        "Returns the number of connections"
        return len(self._connections)

    def __getitem__(self, rx_addr):
        "Returns the connection with the given rx_addr"
        if rx_addr not in self._connections: raise IndexError
        return self._connections[rx_addr]

    def __contains__(self, rx_addr):
        "Retrurns True if the rx_addr is associated with a connection"
        if rx_addr in self._connections:
            return True
        else:
            return None

    def del_connection(self, connection):
        """Deletes the given connection from the _connections dictionary"""
        if connection.rx_addr not in self._connections:
            return
        del self._connections[connection.rx_addr]


    def clear_all_connections(self):
        "Clears all connections from the connection list"
        connections_list = self.get_connections_list()
        for connection in connections_list:
            connection.shutdown()
        self._connections = {}

    def get_connections_list(self):
        """Returns a list of current connection objects"""
        return list(self._connections.values())


    def create_connection(self, rx_data, rx_addr):
        """Creates either a ReceiveData or SendData connection object
           and adds it to dictionary"""
        if rx_addr in self._connections:
            # connection already in the _connections dictionary
            raise DropPacket
        # check first two bytes of rx_data
        # should be 0001 or 0002
        if rx_data[0] != "\x00":
            raise DropPacket
        if rx_data[1] == "\x01":
            # Client is reading a file from the server
            # create a SendData connection object
            connection = SendData(self, rx_data, rx_addr)
        elif rx_data[1] == "\x02":
            # Client is sending a file to the server
            # create a ReceiveData connection object
            connection = ReceiveData(self, rx_data, rx_addr)
        else:
            # connection not recognised, just drop it
            raise DropPacket
        # Add it to dictionary
        self._connections[rx_addr] = connection


    def get_config_dict(self):
        "Returns a dictionary of the config attributes"
        cfgdict = { "tftprootfolder":self.tftprootfolder,
                    "logfolder":self.logfolder,
                    "anyclient":self.anyclient,
                    "clientipaddress":self.clientipaddress,
                    "clientmask":self.clientmask,
                    "listenport":self.listenport,
                    "listenipaddress":self.listenipaddress}
        return cfgdict

    def set_from_config_dict(self, cfgdict):
        """Sets attributes from a given dictionary
           Returns True if all attributes supplied, or False if not"""
        # attributes can only be changed while not serving
        assert not self._serving
        assert not self.serving
        all_attributes = True
        if "logfolder" in cfgdict:
            self.logfolder = cfgdict["logfolder"]
        else:
            all_attributes = False
        if "tftprootfolder" in cfgdict:
            self.tftprootfolder = cfgdict["tftprootfolder"]
        else:
            all_attributes = False
        if "anyclient" in cfgdict:
            self.anyclient = cfgdict["anyclient"]
        else:
            all_attributes = False
        if "clientipaddress" in cfgdict:
            self.clientipaddress = cfgdict["clientipaddress"]
        else:
            all_attributes = False
        if "clientmask" in cfgdict:
            self.clientmask = cfgdict["clientmask"]
        else:
            all_attributes = False
        if "listenport" in cfgdict:
            self.listenport = cfgdict["listenport"]
        if "listenipaddress" in cfgdict:
            if cfgdict["listenipaddress"] == "0.0.0.0":
                self.listenipaddress = ""
            else:
                self.listenipaddress = cfgdict["listenipaddress"]
        else:
            all_attributes = False
        return all_attributes

    def shutdown(self):
        "Shuts down the server"
        if not self._engine_available:
            return
        self.stop_serving()
        self.add_text("TFTPgui application stopped")
        self._engine_available = False

    def start_serving(self):
        "Starts the server serving"
        if not self._engine_available:
            return
        if self._serving:
            self.serving = True
            return
        try:
            self.tftp_server = TFTPserver(self)
        except Exception:
            self.stop_serving()
            # re-raise the exception
            raise
        # the server is now bound to the ip address and port
        self._serving = True
        self.serving = True
        if self.listenipaddress:
            self.add_text(("Listenning on %s:%s" % (self.listenipaddress, self.listenport)), clear=True)
        else:
            self.add_text(("Listenning on port %s" % self.listenport), clear=True)

    def stop_serving(self):
        "Stops the server serving"
        # server no longer running, stop listening
        if self.tftp_server != None:
            self.tftp_server.close()
            self.tftp_server = None
            self.add_text("Server stopped")
        # remove all connections
        self.clear_all_connections()
        self._serving = False
        self.serving = False


    def poll(self):
        """Polls asyncore if serving,
           checks the attribute self.serving, turning on listenning
           if True, or off if false"""
        if not self._engine_available:
            return
        if self._serving:
            # The server is listenning
            if not self.serving:
                # A request has been made to turn off the server
                self.stop_serving()
                return
            # poll asyncore and the connections
            asyncore.poll()
            # Poll each connection to run timers
            connection_list = self.get_connections_list()
            for connection in connection_list:
                connection.poll()
                asyncore.poll()
            return
        # self._serving must be False, but maybe self.serving has been set
        if self.serving:
            # The server is not serving, but the attribute
            # self.serving is True, so a request
            # has been made to turn on the server
            self.start_serving()

    def get_engine_available(self):
        """returns the value af self._engine_available"""
        return self._engine_available

    engine_available = property(get_engine_available)


class STOPWATCH_ERROR(Exception):
    """time_it should only be called if start has been called first."""
    pass

class Stopwatch(object):
    """stopwatch class calculates the TTL - the time to live in seconds
    
    The start() method should be called, each time a packet is transmitted
    which expects a reply, and then the time_it() method should be called
    periodically while waiting for the reply.
    If  time_it() returns True, then the time is still within the TTL - 
    so carry on waiting.
    If time_it() returns False, then the TTL has expired and the calling
    program needs to do something about it.
    When a packet is received, the calling program should call the
    stop() method - this then calculates the average round trip
    time (aveRTT), and a TTL of three times the aveRTT.
    TTL is  a minimum of 0.5 secs, and a maximum of 5 seconds.
    Methods: 
      start() to start  the stopwatch
      stop() to stop the stopwatch, and update aveRTT and TTL
      time_it() return True if the time between start and time_it is less than TTL
      return False if it is greater
    Exceptions:
        STOPWATCH_ERROR is raised by time_it() if is called without
        start() being called first - as the stopwatch must be running
        for the time_it measurement to have any validity
      """
      
    def __init__(self):
        # initial starting values
        self.RTTcount=1
        self.TotalRTT=0.5
        self.aveRTT=0.5
        self.TTL=1.5
        self.rightnow=0.0
        self.started=False
       
    def start(self):
        self.rightnow=time.time()
        self.started=True
        
    def stop(self):
        if not self.started: return
        # Calculate Round Trip Time (RTT)            
        RTT=time.time()-self.rightnow
        if RTT == 0.0 :
            # Perhaps the time() function on this platform is not
            # working, or only times to whole seconds. If this is the case
            # assume an RTT of 0.5 seconds
            RTT=0.5
        # Avoid extreme values
        RTT=min(3.0, RTT)
        RTT=max(0.01, RTT)
        # Calculate average Round Trip time
        self.TotalRTT += RTT
        self.RTTcount += 1
        self.aveRTT=self.TotalRTT/self.RTTcount
        # Don't let TotalRTT and RTTcount increase indefinetly
        # after twenty measurements, reset TotalRTT to five times
        # the aveRTT
        if self.RTTcount > 20:
            self.TotalRTT = 5.0*self.aveRTT
            self.RTTcount=5
        # Also limit aveRTT from increasing too much 
        if self.aveRTT>2.0:
            self.TotalRTT=10.0
            self.RTTcount=5
            self.aveRTT=2.0
        # And make Time To Live (TTL) = 3 * average RTT
        # with a maximum of 5 seconds, and a minimum of 0.5 seconds
        self.TTL=3.0*self.aveRTT
        self.TTL=min(5.0, self.TTL)
        self.TTL=max(0.5, self.TTL)
        # and finally flag that the stopwatch has been stopped
        self.started=False
    
    def time_it(self):
        """Called to check time is within TTL, if it is, return True
           If not, started attribute is set to False, and returns False"""
        if not self.started: raise STOPWATCH_ERROR
        deltatime=time.time()-self.rightnow
        if deltatime<=self.TTL :
            return True
        # increase the TTL in case the timeout was due to
        # excessive network delay
        self.aveRTT += 0.5
        self.aveRTT=min(2.0, self.aveRTT)
        self.TotalRTT = 5.0*self.aveRTT
        self.RTTcount=5
        self.TTL=3.0*self.aveRTT
        self.TTL=min(5.0, self.TTL)
        self.TTL=max(0.5, self.TTL)
        # Also a timeout will stop the stopwatch
        self.started=False
        return False


class NoService(Exception):
    """Raised to flag the service is unavailable"""
    pass

class TFTPserver(asyncore.dispatcher):
    """Class for binding the tftp listenning socket
       asyncore.poll will call the handle_read method whenever data is
       available to be read, and handle_write to see if data is to be transmitted"""
    def __init__(self, server):
        """Bind the tftp listener to the address given in server.listenipaddress
           and port given in server.listenport"""
        asyncore.dispatcher.__init__(self)
        self.server = server
        self.create_socket(socket.AF_INET, socket.SOCK_DGRAM)
        # list of connections to test for sending data
        self.connection_list = []
        # current connection sending data
        self.connection = None
        try:
            self.bind((server.listenipaddress, server.listenport))
        except Exception, e:
            server.log_exception(e)
            if server.listenipaddress:
                server.text = """Failed to bind to %s : %s
Possible reasons:
Check this IP address exists on this server.
(Try with 0.0.0.0 set as the 'listenipaddress'
in the configuration file which binds to any
server address.)"""  % (server.listenipaddress, server.listenport)
            else:
                server.text = "Failed to bind to port %s." % server.listenport
            
            server.text += """
Check you do not have another service listenning on
this port (you may have a tftp daemon already running).
Also check your user permissions allow you to open a
socket on this port."""
            if os.name == "posix" and server.listenport<1000 and os.geteuid() != 0:
                server.text += "\n(Ports below 1000 may need root or administrator privileges.)"
            server.text += "\nFurther error details will be given in the logs file."
            raise NoService, "Unable to bind to given address and port"

    def handle_read(self):
        """Handle incoming data - Checks if this is an existing connection,
           if not, creates a new connection object and adds it to server
           _connections dictionary.
           If it is, then calls the connection object incoming_data method
           for that object to handle it"""
        # buffer size of 4100 is given, when negotiating block size, only sizes
        # less than 4100 will be accepted
        rx_data, rx_addr = self.recvfrom(4100)
        if len(rx_data)>4100:
            raise DropPacket
        try:
            if rx_addr not in self.server:
                # This is not an existing connection, so must be
                # a new first packet from a client.
                self.server.create_connection(rx_data, rx_addr)
            else:
                # This is an existing connection
                # let the appropriate connection class handle it
                # via its incoming_data method
                self.server[rx_addr].incoming_data(rx_data)
        except DropPacket:
            # packet invalid in some way, drop it
            pass


    def writable(self):
        "If data available to write, return True"
        # self.connection is the current connection sending data
        # self.connection_list is a list of the connections,
        # test each in turn, popping the connection from the list
        # until none are left, then renew self.connection_list from
        # self.server.get_connections_list() - this is done to ensure
        # each connection is handled in turn
        if self.connection:
            if (not self.connection.expired) and self.connection.tx_data:
                # there is a current connection, and it has data to send
                return True
            else:
                # the current connection has no data to send
                # go to next connection on the list
                self.connection = None
        # there is no current connection, check if one is available
        # get the next connection in the list
        if not self.connection_list:
            # but if no list, renew it now
            if not len(self.server):
                # No connections available
                return False
            self.connection_list = self.server.get_connections_list()
        # so one or more connections exist in the list
        # get a connection, and remove it from the list
        self.connection = self.connection_list.pop()
        if self.connection.tx_data:
            return True
        else:
            return False

    def handle_write(self):
        """Send any data on the current connection"""
        if not self.connection:
            # no connection current
            return
        # so send any data on the current connection
        self.connection.send_data(self.sendto)
        if self.connection.expired or not self.connection.tx_data:
            # the current connection has no data to send
            # go to next connection on the list
            self.connection = None

    def handle_connect(self):
        pass
        
    def handle_error(self):
        pass


# opcode   operation
# 1         Read request           (RRQ)
# 2         Write request          (WRQ)
# 3         Data                   (DATA)
# 4         Acknowledgement        (ACK)
# 5         Error                  (ERROR)
# 6         Option Acknowledgement (OACK)

class Connection(object):
    """Stores details of a connection, acts as a parent to
       SendData and ReceiveData classes"""

    def __init__(self, server, rx_data, rx_addr):
        "New connection, check header"
        # check if the caller is from an allowed address
        if not server.anyclient :
            if not ipv4.address_in_subnet(rx_addr[0],
                                          server.clientipaddress,
                                          server.clientmask):
                # The caller ip address is not within the subnet as defined by the
                # clientipaddress and clientmask
                raise DropPacket
        if len(rx_data)>512:
            raise DropPacket
        # Check header
        if rx_data[0] != "\x00":
            raise DropPacket
        if (rx_data[1] != "\x01") and (rx_data[1] != "\x02"):
            raise DropPacket
        ### parse the filename received from the client ###
        # split the remaining rx_data into filename and mode
        parts=rx_data[2:].split("\x00")
        if len(parts) < 2:
            raise DropPacket
        self.filename=parts[0]
        self.mode=parts[1].lower()
        # mode must be "netascii" or "octet"
        if ((self.mode != "netascii") and (self.mode != "octet")):
            raise DropPacket
        # filename must be at least one character, and at most 256 characters long
        if (len(self.filename) < 1) or (len(self.filename)>256):
            raise DropPacket
         # filename must not start with a . character
        if self.filename[0] == ".":
            raise DropPacket
        # if filename starts with a \ or a / - strip it off
        if self.filename[0] == "\\" or self.filename[0] == "/":
            if len(self.filename) == 1:
                raise DropPacket
            self.filename=self.filename[1:]
        # filename must not start with a . character
        if self.filename[0] == ".":
            raise DropPacket    
        # The filename should only contain the printable characters, A-Z a-z 0-9 -_ or .
        # Temporarily replace any instances of the ._- characters with "x"
        temp_filename=self.filename.replace(".", "x")
        temp_filename=temp_filename.replace("-", "x")
        temp_filename=temp_filename.replace("_", "x")
        # Check all characters are alphanumeric
        if not temp_filename.isalnum():
            raise DropPacket
        # Check this filename is not being altered by a ReceiveData connection
        for conn in server.get_connections_list():
            if self.filename == conn.filename and isinstance(conn, ReceiveData):
                raise DropPacket
        # so self.filename is the file to be acted upon, set the filepath
        self.filepath=os.path.join(server.tftprootfolder,self.filename)

        # check header for options
        self.request_options = {}
        self.options = {}
        self.tx_data = None

        # Set block size
        self.blksize = 512

        try:
            # Get any tftp options
            if not parts[-1]:
                # last of parts will be an empty string, remove it
                parts.pop(-1)
            if len(parts)>3 and not (len(parts) % 2):
                # options exist, and the number of parts is even
                # set the transmit packet to acknowledge the handled options
                self.tx_data = "\x00\x06"
                option_parts = parts[2:]
                # option_parts should be option, value, option, value etc..
                # put these into the self.request_options dictionary
                for index, value in enumerate(option_parts):
                    if not (index % 2):
                        # even index
                        self.request_options[value.lower()] = option_parts[index+1].lower()
                # self.request_options dictionary is now a dictionary of options requested
                # from the client, make another dictionary, self.options of those options
                # that this server will support
                # check if blksize is in there
                if "blksize" in self.request_options:
                    blksize = int(self.request_options["blksize"])
                    if blksize > 4096:
                        blksize = 4096
                    if blksize>7:
                        # This server only allows blocksizes up to 4096
                        self.blksize = blksize
                        self.tx_data += "blksize\x00" + str(blksize) + "\x00"
                        self.options["blksize"] = str(blksize)
                # elif "nextoption" in self.options:
                    # for each further option to be implemented, use an elif chain here
                    # and add the option name and value to tx_data
                if not self.options:
                    # No options recognised
                    self.tx_data = None
        except Exception:
            # On any failure, ignore all options
            self.blksize = 512
            self.options = {}
            self.tx_data = None
 
        # This connection_time is updated to current time every time a packet is
        # sent or received, if it goes over 30 seconds, something is wrong
        # and so the connection is terminated
        self.connection_time=time.time()
        # The second value in this blockcount is incremented for each packet
        self.blkcount=[0, "\x00\x00", 0]
        # fp is the file pointer used to read/write to disc
        self.fp = None
        self.server = server
        self.rx_addr = rx_addr
        self.rx_data = rx_data
        # expired is a flag to indicate to the engine loop that this
        # connection should be removed from the self._connections list
        self.expired = False
        # tx_data is the data to be transmitted
        # and re_tx_data is a copy in case a re-transmission is needed
        self.re_tx_data = self.tx_data
        # This timer is used to measure if a packet has timed out, it
        # increases as the round trip time increases
        self.timer = Stopwatch()
        self.timeouts = 0
        self.last_packet = False


    def increment_blockcount(self):
        """blkcount is a list, index 0 is blkcount_int holding
           the integer value of the blockcount which rolls over at 65535
           index 1 is the two byte string holding the hex value of blkcount_int.
           index 2 is blkcount_total which holds total number of blocks
           This function increments them all."""
        blkcount_total=self.blkcount[2]+1
        blkcount_int=self.blkcount[0]+1
        if blkcount_int>65535: blkcount_int=0
        blkcount_hex=chr(blkcount_int//256) + chr(blkcount_int%256)
        self.blkcount=[blkcount_int, blkcount_hex, blkcount_total]


    def send_data(self, tftp_server_sendto):
        "send any data in self.tx_data, using dispatchers sendto method"
        if self.expired or not self.tx_data:
            return
        # about to send data
        # re-set connection time to current time
        self.connection_time=time.time()
        # send the data
        sent=tftp_server_sendto(self.tx_data, self.rx_addr)
        if sent == -1:
            # Problem has ocurred, drop the connection
            self.shutdown()
            return
        self.tx_data=self.tx_data[sent:]
        if not self.tx_data:
            # All data has been sent
            # if this is the last packet to be sent, shutdown the connection
            if self.last_packet:
                self.shutdown()
            else:
                # expecting a reply, so start TTL timer
                self.timer.start()


    def poll(self):
        """Checks connection is no longer than 30 seconds between packets.
           Checks TTL timer, resend on timeouts, or if too many timeouts
           send an error packet and flag last_packet as True"""
        if time.time()-self.connection_time > 30.0:
            # connection time has been greater than 30 seconds
            # without a packet sent or received, something is wrong
            self.server.add_text("Connection from %s:%s timed out" % self.rx_addr)
            self.shutdown()
            return
        if self.expired:
            return
        if self.tx_data or not self.timer.started:
            # Must be sending data, so nothing to check
            return
        # no tx data and timer has started, so waiting for a packet
        if self.timer.time_it():
            # if True, still within TTL, so ok
            return
        # Outside of TTL, timeout has occurred, send an error
        # if too many have occurred or re-send last packet
        self.timeouts += 1
        if self.timeouts <= 3:
            # send a re-try
            self.tx_data=self.re_tx_data
            return
        # Tried four times, give up and set data to be an error value
        self.tx_data="\x00\x05\x00\x00Terminated due to timeout\x00"
        self.server.add_text("Connection to %s:%s terminated due to timeout" % self.rx_addr)
        # send and shutdown, don't wait for anything further
        self.last_packet = True

    def shutdown(self):
        """Shuts down the connection by closing the file pointer and
           setting the expired flag to True.  Removes the connection from
           the servers connections dictionary"""            
        if self.fp:
            self.fp.close()
        self.expired = True
        self.tx_data=""
        self.server.del_connection(self)

    def __str__(self):
        "String value of connection, for diagnostic purposes"
        str_list = "%s %s" % (self.rx_addr, self.blkcount[2])
        return str_list



class SendData(Connection):
    """A connection which handles file sending
       the client is reading a file, the connection is of type RRQ"""
    def __init__(self, server, rx_data, rx_addr):
        Connection.__init__(self, server, rx_data, rx_addr)
        if rx_data[1] != "\x01" :
            raise DropPacket
        if not os.path.exists(self.filepath) or os.path.isdir(self.filepath):
            server.add_text("%s requested %s: file not found" % (rx_addr[0], self.filename))
            # Send an error value
            self.tx_data="\x00\x05\x00\x01File not found\x00"
            # send and shutdown, don't wait for anything further
            self.last_packet = True
            return
        # Open file for reading
        try:
            if self.mode == "octet":
                self.fp=open(self.filepath, "rb")
            elif self.mode == "netascii":
                self.fp=open(self.filepath, "r")
            else:
                raise DropPacket
        except IOError, e:
            server.add_text("%s requested %s: unable to open file" % (rx_addr[0], self.filename))
            # Send an error value
            self.tx_data="\x00\x05\x00\x02Unable to open file\x00"
            # send and shutdown, don't wait for anything further
            self.last_packet = True
            return
        server.add_text("Sending %s to %s" % (self.filename, rx_addr[0]))
        # If True this flag indicates shutdown on the next received packet 
        self.last_receive = False
        # If self.tx_data has contents, this will be because the parent Connections
        # class is acknowledging an option
        # If there is nothing in self.tx_data, get the first payload
        if not self.tx_data:
            # Make the first packet, call get_payload to put the data into tx_data
            self.get_payload()

    def get_payload(self):
        """Read file, a block of self.blksize bytes at a time which is put
           into re_tx_data and tx_data."""
        assert not self.last_receive
        payload=self.fp.read(self.blksize)
        if len(payload) < self.blksize:
            # The file is read, and no further data is available
            self.fp.close()
            self.fp = None
            bytes = self.blksize*self.blkcount[2] + len(payload)
            self.server.add_text("%s bytes of %s sent to %s" % (bytes, self.filename, self.rx_addr[0]))
            # shutdown on receiving the next ack
            self.last_receive = True
        self.increment_blockcount()
        self.re_tx_data="\x00\x03"+self.blkcount[1]+payload
        self.tx_data=self.re_tx_data

    def incoming_data(self, rx_data):
        """Handles incoming data - these should be acks from the client
           for each data packet sent"""
        if self.expired:
            return
        # if timer hasn't started, we may be in the process of sending
        if self.tx_data or not self.timer.started:
            return
        if rx_data[0] != "\x00":
            # All packets should start 00, so ignore it
            return
        # This should be either an ack, or an error
        # Check if an error packet is received
        if rx_data[1] == "\x05" :
            # Its an error packet, log it and drop the connection
            try:
                if len(rx_data[4:]) > 1  and len(rx_data[4:]) < 255:
                    # Error text available
                    self.server.add_text("Error from %s:%s code %s : %s" % (self.rx_addr[0],
                                                                       self.rx_addr[1],
                                                                       ord(rx_data[3]),
                                                                       rx_data[4:-1]))
                else:
                    # No error text
                    self.server.add_text("Error from %s:%s code %s" % (self.rx_addr[0],
                                                                  self.rx_addr[1],
                                                                  ord(rx_data[3])))
            except Exception:
                # If error trying to read error type, just ignore
                pass
            self.shutdown()
            return
        if rx_data[1] != "\x04" :
            # Should be 04, if not ignore it
            return
        # So this is an ack
        # Check blockcount is ok
        rx_blkcount=rx_data[2:4]
        if self.blkcount[1] != rx_blkcount:
            # wrong blockcount, ignore it
            return
        # Received ack packet ok
        # re-set connection time to current time
        self.connection_time=time.time()
        # re-set any timouts
        self.timeouts = 0
        self.timer.stop()
        if self.last_receive:
            # file is fully read and sent, so shutdown
            self.shutdown()
            return
        # Must create another packet to send
        self.get_payload()
        

class ReceiveData(Connection):
    """A connection which handles file receiving
       the client is sending a file, the connection is of type WRQ"""
    def __init__(self, server, rx_data, rx_addr):
        Connection.__init__(self, server, rx_data, rx_addr)
        if rx_data[1] != "\x02" :
            raise DropPacket
        if os.path.exists(self.filepath):
            server.add_text("%s trying to send %s: file already exists" % (rx_addr[0], self.filename))
            # Send an error value
            self.tx_data="\x00\x05\x00\x06File already exists\x00"
            # send and shutdown, don't wait for anything further
            self.last_packet = True
            return
        # Open filename for writing
        try:
            if self.mode == "octet":
                self.fp=open(self.filepath, "wb")
            elif self.mode == "netascii":
                self.fp=open(self.filepath, "w")
            else:
                raise DropPacket
        except IOError, e:
            server.add_text("%s trying to send %s: unable to open file" % (rx_addr[0], self.filename))
            # Send an error value
            self.tx_data="\x00\x05\x00\x02Unable to open file\x00"
            # send and shutdown, don't wait for anything further
            self.last_packet = True
            return
        server.add_text("Receiving %s from %s" % (self.filename, rx_addr[0]))
        # Create next packet
        # If self.tx_data has contents, this will be because the parent Connections
        # class is acknowledging an option
        # If there is nothing in self.tx_data, create an acknowledgement
        if not self.tx_data:
            self.re_tx_data="\x00\x04"+self.blkcount[1]
            self.tx_data=self.re_tx_data

    def incoming_data(self, rx_data):
        """Handles incoming data, these should contain the data to be saved to a file"""
        if self.expired:
            return
        # if timer hasn't started, we may be in the process of sending
        if self.tx_data or not self.timer.started:
            return
        if rx_data[0] != "\x00":
            # All packets should start 00, so ignore it
            return
        # This should be either data, or an error
        # Check if an error packet is received
        if rx_data[1] == "\x05" :
            # Its an error packet, log it and drop the connection
            try:
                if len(rx_data[4:]) > 1  and len(rx_data[4:]) < 255:
                    # Error text available
                    self.server.add_text("Error from %s:%s code %s : %s" % (self.rx_addr[0],
                                                                       self.rx_addr[1],
                                                                       ord(rx_data[3]),
                                                                       rx_data[4:-1]))
                else:
                    # No error text
                    self.server.add_text("Error from %s:%s code %s" % (self.rx_addr[0],
                                                                  self.rx_addr[1],
                                                                  ord(rx_data[3])))
            except Exception:
                # If error trying to read error type, just ignore
                pass
            self.shutdown()
            return
        if rx_data[1] != "\x03":
            # Should be 03, if not ignore it
            return
        # Check blockcount has incremented
        old_blockcount = self.blkcount
        self.increment_blockcount()
        rx_blkcount=rx_data[2:4]
        if self.blkcount[1] != rx_blkcount:
            # Blockcount mismatch, ignore it
            self.blkcount = old_blockcount
            return
        # re-set any timouts
        self.timeouts = 0
        self.timer.stop()
        if len(rx_data) > self.blksize+4:
            # received data too long
            self.tx_data="\x00\x05\x00\x04Block size too long\x00"
            # send and shutdown, don't wait for anything further
            self.last_packet = True
            return
        payload=rx_data[4:]
        # Received packet ok
        # Make an acknowledgement packet
        self.re_tx_data="\x00\x04"+self.blkcount[1]
        self.tx_data=self.re_tx_data
        # Write the received data to file
        if len(payload)>0:
            self.fp.write(payload)
        if len(payload)<self.blksize:
            # flag all data is written and this ack is the last packet
            self.last_packet = True
            self.fp.close()
            self.fp=None
            bytes = self.blksize*old_blockcount[2] + len(payload)
            self.server.add_text("%s bytes of %s received from %s" % (bytes, self.filename, self.rx_addr[0]))


#### The loop ####

def loop_nogui(server):
    """This loop is run if there is no gui
       It sets server.serving attribute.
       Then enters loop, calling server.poll()
       If an exception
       occurs, then exits loop
       """
    # create logger
    rootLogger = create_logger(server.logfolder)
    if rootLogger is not None:
        server.logging_enabled = True

    # set server to listen
    server.serving = True
    try:
        # This is the main loop
        while True:
            server.poll()
            if not len(server):
                # There are no connections so put in a sleep
                time.sleep(0.1)
    except Exception, e:
        # log the exception and exit the main loop
        server.log_exception(e)
        print server.text
        return 1
    except KeyboardInterrupt:
        return 0
    finally:
        # shutdown the server
        server.shutdown()   
    return 0

def loop(server):
    """This loop runs while server.break_loop is False.
       Intended to run with a GUI in another thread,
       it does not exit the loop if a NoService
       exception occurs.
       If the other thread sets server.break_loop to
       True, then the loop exists and shuts down the server"""

    # create logger
    rootLogger = create_logger(server.logfolder)
    if rootLogger is not None:
        server.logging_enabled = True

    try:
        # This is the main loop
        while not server.break_loop:
            try:
                server.poll()
                if server.serving:
                    if not len(server):
                        # The server is serving, but there are no
                        # connections so put in a sleep
                        time.sleep(0.1)
                else:
                    # if the server is not serving, put a sleep in the loop
                    time.sleep(0.25)
            except NoService, e:
                server.log_exception(e)
                # Unable to bind
                # GUI will handle this, so loop continues
    except Exception, e:
        # log the exception and exit the main loop
        server.log_exception(e)
        return 1
    except KeyboardInterrupt:
        return 0
    finally:
        # shutdown the server
        server.shutdown()
    return 0


def loop_multiserver(server_list):
    """This loop is run with a list of servers

       This is an experimental loop, showing that if multiple servers
       are given (each with different ports) - then multiple tftp servers
       can operate
       """

    # create logger, using logfolder given by the
    # first server in the list
    rootLogger = create_logger(server_list[0].logfolder)
    if rootLogger is not None:
        for server in server_list:
            server.logging_enabled = True

    # set all servers as listenning
    for server in server_list:
        server.serving = True

    try:
        # This is the main loop
        while True:
            for server in server_list:
                server.poll()
    except Exception, e:
        # log the exception and exit the main loop
        server.log_exception(e)
        print server.text
        return 1
    except KeyboardInterrupt:
        return 0
    finally:
        # shutdown the servers
        for server in server_list:
            server.shutdown()   
    return 0
