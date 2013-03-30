####### TFTPgui #######
#
# gui_stuff.py  - runs the GUI for TFTPgui
#
# Version : 2.2
# Date : 20110906
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


import Tkinter, tkFileDialog, tkMessageBox, socket, os

from tftp_package import tftpcfg


class TopFrame(Tkinter.Frame):
    "The startup frame holding buttons, the status canvas and the progress bar"

    def __init__(self, parent, server):
        "Create the buttons, and assign actions, check the server every 100ms"
        Tkinter.Frame.__init__(self, parent)
        self.server = server
        self.parent = parent
        # Create the buttons
        ButtonFrame=Tkinter.Frame(self)
        ButtonFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X)
        # create four buttons
        # START
        self.StartButton=Tkinter.Button(ButtonFrame)
        self.StartButton["text"]="Start"
        self.StartButton["command"]=self.start_server
        self.StartButton.pack(side=Tkinter.LEFT, expand=Tkinter.YES, fill=Tkinter.X)
        # STOP
        self.StopButton=Tkinter.Button(ButtonFrame)
        self.StopButton["text"]="Stop"
        self.StopButton["command"]=self.stop_server
        self.StopButton.pack(side=Tkinter.LEFT, expand=Tkinter.YES, fill=Tkinter.X)
        # SETUP
        self.SetupButton=Tkinter.Button(ButtonFrame)
        self.SetupButton["text"]="Setup"
        self.SetupButton["command"]=self.setup_server
        self.SetupButton.pack(side=Tkinter.LEFT, expand=Tkinter.YES, fill=Tkinter.X)
        # EXIT
        self.ExitButton=Tkinter.Button(ButtonFrame)
        self.ExitButton["text"]="Exit"
        self.ExitButton["command"]=self.exit_app
        self.ExitButton["state"]=Tkinter.NORMAL
        self.ExitButton.pack(side=Tkinter.LEFT, expand=Tkinter.YES, fill=Tkinter.X)

        # Create a label area, showing tftp progress
        self.TextArea=Tkinter.Label(self, width=50, height=16, relief=Tkinter.SUNKEN,
                                    background="white", borderwidth=2,
                                    anchor=Tkinter.NW, justify=Tkinter.LEFT)
        self.TextArea.pack(side=Tkinter.TOP, padx=10, pady=10)

        # Create a Progress Bar
        BarFrame=Tkinter.Frame(self)
        BarFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X)
        self.Bar=ProgressBar(BarFrame)
        self.bar_value = 0

        # address and port status at bottom of frame
        self.StatusText = Tkinter.Label(self)
        self.StatusText.pack(side=Tkinter.TOP, pady=5)

        # Set screen text and status text
        self.status_text()

        # set the buttons enabled or disabled
        self.update_buttons()

        # Pack and display the frame
        self.pack()

        # Check server every 100 msec
        self.parent.after(10, self.check_server,)

        # Create an instance of the setup frame
        self.setup_frame = SetupFrame(parent, server, self)


    def status_text(self):
        """Sets up screen message, and address and port status at bottom of frame,
           also called from setup_frame when config changes applied"""
        # Set  screen message
        self.TextArea["text"] = self.server.text
        # Create a status label showing current ip address of this PC
        if self.server.listenipaddress:
            text="TFTP service address : " + self.server.listenipaddress + " : " + str(self.server.listenport)
        else:
            text="TFTP service port : " + str(self.server.listenport)
        self.StatusText["text"] = text

    def check_server(self):
            """Check if server available, and text messages from server"""
            if not self.server.engine_available:
                # attribute engine_available becomes False if the server
                # becomes unavailable due to an error, or ctrl-c, so this exit
                # the application
                self.exit_app()
            if self.server.text != self.TextArea["text"]:
                self.TextArea["text"] = self.server.text
            if len(self.server):
                # len(self.server) gives the number of connections available
                # so this checks if any are connections are current
                self.bar_value += 1
                if self.bar_value >=100:
                    self.bar_value = 0
                self.Bar.ShowProgress(self.bar_value)
            elif self.server.serving:
                # Show progress bar oscillating
                self.Bar.ShowProgress(-1)
            elif self.Bar.oscillating:
                # Clear the progress bar
                self.Bar.Clear()
            if not self.server.serving and self.StartButton["state"] == Tkinter.DISABLED:
                # Update the buttons
                self.update_buttons()
            # and call this function again, in another 100 msec
            self.parent.after(10, self.check_server,)

    def setup_server(self):
        self.pack_forget()
        self.setup_frame.pack()

    def start_server(self):
        "Start the server listenning"
        self.server.serving = True
        self.StartButton["state"]=Tkinter.DISABLED
        self.StopButton["state"]=Tkinter.NORMAL
        self.SetupButton["state"]=Tkinter.DISABLED

    def stop_server(self):
        "Stop the server listenning"
        self.server.serving = False
        self.StartButton["state"]=Tkinter.NORMAL
        self.StopButton["state"]=Tkinter.DISABLED
        self.SetupButton["state"]=Tkinter.NORMAL

    def update_buttons(self):
        if self.server.serving:
            self.StartButton["state"]=Tkinter.DISABLED
            self.StopButton["state"]=Tkinter.NORMAL
            self.SetupButton["state"]=Tkinter.DISABLED
        else:
            self.StartButton["state"]=Tkinter.NORMAL
            self.StopButton["state"]=Tkinter.DISABLED
            self.SetupButton["state"]=Tkinter.NORMAL

    def exit_app(self):
        self.quit()


class ProgressBar(object):
    "Creates the progress bar shown in TopFrame"

    def __init__(self, parent, Height=10, Width=200, ForegroundColor=None,
                 BackgroundColor=None):
        self.Height=Height
        self.Width=Width
        # shaker is a variable used to show an oscillating dot on the bar
        self.shaker=1
        self.Progress=0
        self.oscillating = False
        self.BarCanvas=Tkinter.Canvas(parent, width=Width, height=Height,
                                      borderwidth=1, relief=Tkinter.SUNKEN)
        self.BarCanvas["background"] = "white" if BackgroundColor is None else BackgroundColor
        self.BarCanvas.pack(padx=5, pady=2)
        self.RectangleID=self.BarCanvas.create_rectangle(0, 0, 0, Height)
        fillcolor = "red" if ForegroundColor is None else ForegroundColor
        self.BarCanvas.itemconfigure(self.RectangleID, fill=fillcolor)
        self.Clear()
        
    def SetProgressPercent(self, NewLevel):
        self.Progress=NewLevel
        self.Progress=min(100, self.Progress)
        self.Progress=max(0, self.Progress)
        ProgressPixel=(self.Progress/100.0)*self.Width
        self.BarCanvas.coords(self.RectangleID, 0, 0, ProgressPixel, self.Height)
        
    def Clear(self):
        self.SetProgressPercent(0)
        self.oscillating = False
        
    def ShowProgress(self, barinfo):
        """This is the main function of the class, and is called
           with input variable barinfo set to:
           0 if the progress bar should be blank
           1 to 100 if a percent should be shown
           -1 if the bar should oscilate"""
        if barinfo >= 0:
            self.SetProgressPercent(barinfo)
            self.oscillating = False
            return
        # So if barinfo is less than 0, draw oscillating bar
        self.oscillating = True
        if (self.Progress>98):
            self.shaker = -1
        if (self.Progress<4):
            self.shaker=1
        self.Progress=self.Progress+self.shaker
        ProgressPixel=(self.Progress/100.0)*self.Width
        self.BarCanvas.coords(self.RectangleID, ProgressPixel-2, 0, ProgressPixel, self.Height)


class SetupFrame(Tkinter.Frame):
    "This is the frame showing setup options"

    def __init__(self, parent, server, top_frame):
        Tkinter.Frame.__init__(self, parent)

        self.server = server
        self.top_frame = top_frame

        # Create the widgit variables
        self.tftprootfolder=Tkinter.StringVar()
        self.logfolder=Tkinter.StringVar()
        self.anyclient=Tkinter.StringVar()
        self.clientipaddress=Tkinter.StringVar()
        self.clientmask=Tkinter.StringVar()
        self.listenport=Tkinter.StringVar()

        # get the config values from the server as a dictionary
        cfgdict = server.get_config_dict()
        # assign the dictionary values to the widget variables
        self.AssignDictToValues(cfgdict)

        # Create the tfp root directory entry widget
        BigTftprootFrame=Tkinter.Frame(self)
        BigTftprootFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X, pady=5)
        # Create the text label for the entry
        Tkinter.Label(BigTftprootFrame, text="Tftp root folder for GET and PUT files").pack(side=Tkinter.TOP, anchor=Tkinter.W)
        TftprootFrame=Tkinter.Frame(BigTftprootFrame)
        TftprootFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X)
        # Create the entry field
        Tkinter.Entry(TftprootFrame, textvariable=self.tftprootfolder, width=30).pack(side=Tkinter.LEFT)
        # Create the browse button
        self.RootBrowseButton=Tkinter.Button(TftprootFrame)
        self.RootBrowseButton["text"]="Browse"
        self.RootBrowseButton["width"]=8
        self.RootBrowseButton["command"]=self.BrowseRootFolder
        self.RootBrowseButton["state"]=Tkinter.NORMAL
        self.RootBrowseButton.pack(side=Tkinter.LEFT,padx=5)

        # Create the log directory entry widget
        BigLogFrame=Tkinter.Frame(self)
        BigLogFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X, pady=5)
        # Create the text label for the entry
        Tkinter.Label(BigLogFrame, text="Folder for Log files").pack(side=Tkinter.TOP, anchor=Tkinter.W)
        LogFrame=Tkinter.Frame(BigLogFrame)
        LogFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X)
        # Create the entry field
        Tkinter.Entry(LogFrame, textvariable=self.logfolder, width=30).pack(side=Tkinter.LEFT)
        # Create the browse button
        self.LogBrowseButton=Tkinter.Button(LogFrame)
        self.LogBrowseButton["text"]="Browse"
        self.LogBrowseButton["width"]=8
        self.LogBrowseButton["command"]=self.BrowseLogFolder
        self.LogBrowseButton["state"]=Tkinter.NORMAL
        self.LogBrowseButton.pack(side=Tkinter.LEFT,padx=5)

        # Create the input client ip address radio buttons
        ClientFrame=Tkinter.Frame(self)
        ClientFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X, pady=5)
        # Create the text label for the entry
        Tkinter.Label(ClientFrame, text="Allow TFTP from :").pack(side=Tkinter.LEFT)
        # Create the buttons
        self.RadioAny=Tkinter.Radiobutton(ClientFrame, text="Any", variable=self.anyclient, value="1")
        self.RadioAny.pack(side=Tkinter.LEFT, padx=10)
        self.RadioAny["command"]=self.ToggleRadio
        self.RadioSubnet=Tkinter.Radiobutton(ClientFrame, text="Subnet", variable=self.anyclient, value="0")
        self.RadioSubnet.pack(side=Tkinter.LEFT, padx=10)
        self.RadioSubnet["command"]=self.ToggleRadio

        # Create the entry client ip address and mask fields
        AddressFrame=Tkinter.Frame(self)
        AddressFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X)
        Tkinter.Label(AddressFrame, text="IP :").pack(side=Tkinter.LEFT)
        self.IPEntry=Tkinter.Entry(AddressFrame, textvariable=self.clientipaddress, width=17)
        self.IPEntry.pack(side=Tkinter.LEFT)
        Tkinter.Label(AddressFrame, text="   MASK :").pack(side=Tkinter.LEFT)
        self.MASKEntry=Tkinter.Entry(AddressFrame, textvariable=self.clientmask, width=3)
        self.MASKEntry.pack(side=Tkinter.LEFT)
        # Set field enabled or disabled depending on Any or Subnet radio buttons
        self.ToggleRadio()

        # Set udp port
        PortFrame=Tkinter.Frame(self)
        PortFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X, pady=15)
        Tkinter.Label(PortFrame, text="UDP port :").pack(side=Tkinter.LEFT)
        self.PortEntry=Tkinter.Entry(PortFrame, textvariable=self.listenport, width=6)
        self.PortEntry.pack(side=Tkinter.LEFT)
        Tkinter.Label(PortFrame, text="(Default 69)").pack(side=Tkinter.LEFT, padx=10)

        # Create the Apply and Cancel buttons
        ButtonFrame=Tkinter.Frame(self)
        ButtonFrame.pack(side=Tkinter.TOP, expand=Tkinter.YES, fill=Tkinter.X, pady=10)
        # create two buttons - Apply Cancel
        self.ApplyButton=Tkinter.Button(ButtonFrame)
        self.ApplyButton["text"]="Apply"
        self.ApplyButton["width"]=8
        self.ApplyButton["command"]=self.ApplySetup
        self.ApplyButton["state"]=Tkinter.NORMAL
        self.ApplyButton.pack(side=Tkinter.LEFT, padx=10)
        self.CancelButton=Tkinter.Button(ButtonFrame)
        self.CancelButton["text"]="Cancel"
        self.CancelButton["width"]=8
        self.CancelButton["command"]=self.CancelSetup
        self.CancelButton["state"]=Tkinter.NORMAL
        self.CancelButton.pack(side=Tkinter.LEFT, padx=10)
        self.DefaultButton=Tkinter.Button(ButtonFrame)
        self.DefaultButton["text"]="Default"
        self.DefaultButton["width"]=8
        self.DefaultButton["command"]=self.DefaultSetup
        self.DefaultButton["state"]=Tkinter.NORMAL
        self.DefaultButton.pack(side=Tkinter.LEFT, padx=10)

        # Create another text label
        label_text = """Press Apply to set the changes.
Cancel deletes any changes and reverts to current settings.
Default sets fields to default values, but Apply must still
be pressed to apply the values."""
        Tkinter.Label(self, text=label_text).pack(side=Tkinter.BOTTOM, anchor=Tkinter.W)

    def BrowseRootFolder(self):
        dirname = tkFileDialog.askdirectory(parent=self, mustexist=1, initialdir=self.tftprootfolder.get())
        if not dirname:
           return
        self.tftprootfolder.set(dirname)

    def BrowseLogFolder(self):
        dirname = tkFileDialog.askdirectory(parent=self, mustexist=1, initialdir=self.logfolder.get())
        if not dirname:
            return
        self.logfolder.set(dirname)

    def ApplySetup(self):
        "Put values into the server, and save to the config file"
        # Assign field values to a dictionary
        # Check mask and port are integers
        try:
            clientmask = int(self.clientmask.get())
        except Exception:
            tkMessageBox.showerror("Error", "The mask value should be an integer between 0 and 32")
            return
        try:
            listenport = int(self.listenport.get())
        except Exception:
            tkMessageBox.showerror("Error", "The UDP port is incorrect")
            return
        anyclient = True if self.anyclient.get() == "1" else False
        clientipaddress = self.clientipaddress.get()
        status, message = tftpcfg.validate_client_ip_mask(clientipaddress, clientmask)
        if not status:
            tkMessageBox.showerror("Error", message)
            return
        # convert the clientipaddress to a proper subnet if it is not already one.
        clientipaddress = tftpcfg.make_subnet(clientipaddress, clientmask)
        self.clientipaddress.set(clientipaddress)
        cfgdict = {"tftprootfolder":os.path.abspath(self.tftprootfolder.get()),
                   "logfolder":os.path.abspath(self.logfolder.get()),
                   "clientipaddress":clientipaddress,
                   "clientmask":clientmask,
                   "listenport":listenport,
                   "anyclient":anyclient}
        # Get listenipaddress from server
        cfgdict["listenipaddress"] = self.server.listenipaddress
        # validate
        status, message = tftpcfg.validate(cfgdict)
        if not status:
            tkMessageBox.showerror("Error", message)
            return
        # Assign dictionary to the server
        self.server.set_from_config_dict(cfgdict)
        # Save this new configuration dictionary to the config file
        tftpcfg.setconfig(cfgdict)
        # Set text on top_frame, then show top_frame
        self.server.text = "Press Start to enable the tftp server"
        self.top_frame.status_text()
        self.pack_forget()
        self.top_frame.pack()

    def CancelSetup(self):
        "Return option values to as they were"
        # get the config values from the server as a dictionary
        cfgdict = self.server.get_config_dict()
        # assign the dictionary values to the widget variables
        self.AssignDictToValues(cfgdict)
        self.ToggleRadio()
        self.pack_forget()
        self.top_frame.pack()

    def DefaultSetup(self):
        # Set option values to Default
        cfgdict = tftpcfg.get_defaults()
        self.AssignDictToValues(cfgdict)
        self.ToggleRadio()

    def AssignDictToValues(self, cfgdict):
        "Assigns a configuration dictionary to the field values"
        self.tftprootfolder.set(cfgdict["tftprootfolder"])
        self.logfolder.set(cfgdict["logfolder"])
        if cfgdict["anyclient"]:
            self.anyclient.set("1")
        else:
            self.anyclient.set("0")
        self.clientipaddress.set(cfgdict["clientipaddress"])
        self.clientmask.set(str(cfgdict["clientmask"]))
        self.listenport.set(str(cfgdict["listenport"]))

    def ToggleRadio(self):
        if self.anyclient.get() == "1":
            self.IPEntry["state"]=Tkinter.DISABLED
            self.MASKEntry["state"]=Tkinter.DISABLED
        else:
            self.IPEntry["state"]=Tkinter.NORMAL
            self.MASKEntry["state"]=Tkinter.NORMAL



def create_gui(server):
    "Create the GUI, and run the GUI mainloop"
    MainWindow = Tkinter.Tk()
    MainWindow.title("TFTPgui")
    MainWindow.minsize(width=450, height=350)
    MainWindow.resizable(Tkinter.NO, Tkinter.NO)
    # set up a frame, with the root as its MainWindow window
    top_frame = TopFrame(MainWindow, server)
    # enter the event loop
    MainWindow.mainloop()

        
