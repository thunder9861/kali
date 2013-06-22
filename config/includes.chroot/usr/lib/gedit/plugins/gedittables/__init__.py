from gi.repository import GObject, Gtk, Gedit
from gettext import gettext as _
from tablemaker import TableMaker


ui_str = """
<ui>
  <menubar name="MenuBar">
    <menu name="ToolsMenu" action="Tools">
      <placeholder name="ToolsOps_2">
        <menuitem name="GeditTables" action="GeditTables"/>
      </placeholder>
    </menu>
  </menubar>
</ui>
"""
 
    
class GeditTablesWindowActivatable(GObject.Object, Gedit.WindowActivatable):
    
    __gtype_name__ = "GeditTablesWindowActivatable"
    window = GObject.property(type=Gedit.Window)
    
    def __init__(self, plugin, window):
        """Instantiates the main plugin. This is called when Gedit is first 
        opened by the user."""
        GObject.Object.__init__(self)
        self.dialog = None
    
    def do_activate(self):
        """Instantiates a new instance of the plugin for a newly created 
        window."""
        self.insert_menu()
    
    def do_deactivate(self):
        """Closes an instance of the plugin in the event that a Gedit window is 
        closed."""
        self.remove_menu()
        self.action_group = None
        
    def do_update_state(self):
        """Updates the state of the plugin."""
        self.action_group.set_sensitive(
        self.window.get_active_document() != None)
        
    def insert_menu(self):
        """Inserts the 'Create Table' menu item into the Gedit 'Tools' menu."""
        manager = self.window.get_ui_manager()
        
        self.action_group = Gtk.ActionGroup("GeditTablesPluginActions")
        self.action_group.add_actions([("GeditTables", None, _("Create Table"),
                                        None, _("Create a Table"), 
                                        self.on_menu_click)])
        
        manager.insert_action_group(self.action_group, -1)
        self.ui_id = manager.add_ui_from_string(ui_str)
        
    def remove_menu(self):
        """Removes the 'Create Table' menu item from the Gedit 'Tools' menu."""
        manager = self.window.get_ui_manager()
        
        manager.remove_ui(self.ui_id)
        manager.remove_action_group(self.action_group)
        manager.ensure_update()
        
    def on_menu_click(self, action):
        """Callback for when the menu item is clicked to launch our dialog."""
        self.dialog = TableDialog(self)
        self.dialog.set_transient_for(self.window)
        self.dialog.present()
        
    def on_dialog_response(self, dialog, response):
        """Callback for when one of the dialog buttons is clicked."""
        if response == Gtk.ResponseType.ACCEPT:
            doc = self.window.get_active_document()
        else:
            self.dialog = None
            self.dialog.destroy()
        
    def insert_table(self, table_maker):
        """Takes in a TableMaker object and constructs a table, then inserting 
        said table at the cursor position of the current active document."""
        document = self.window.get_active_document()
        document.insert_at_cursor(table_maker.table())
        
    def insert_data_table(self, delimiter, table_maker):
        """Takes in a TableMaker object and a delimiter (designed for building 
        the table around some highlighted data) and constructs the table. This 
        is then inserted at the cursor position of the active document."""
        document = self.window.get_active_document()
        
        bounds = document.get_selection_bounds()
        if not bounds:
            return False
        start, end = bounds
        
        text = document.get_text(start, end, 1)
        table = table_maker.table_data(text, delimiter)
        document.delete(start, end)
        document.insert_at_cursor(table)
        
        return True
    
            
class TableDialog():

    def __init__(self, plugin):
        """Constructs a custom dialog to allow control over table creation for 
        the user. This is actually a Gtk.Window instead of a Gtk.Dialog, in 
        order to allow us more fine control over the layout of the dialog."""
        self.plugin = plugin
        self.window = Gtk.Window()
        self.window.set_title(_("Insert Table"))
        self.window.set_resizable(False)

        main_vbox = Gtk.VBox(False, 5)
        main_vbox.set_border_width(10)
        self.window.add(main_vbox)

        frame = Gtk.Frame()
        main_vbox.pack_start(frame, True, True, 0)

        vbox = Gtk.VBox(False, 0)
        vbox.set_border_width(5)
        frame.add(vbox)

        hbox = Gtk.HBox(False, 0)
        vbox.pack_start(hbox, True, True, 5)

        vbox2 = Gtk.VBox(False, 0)
        hbox.pack_start(vbox2, True, True, 5)

        label = Gtk.Label(label=_("Rows:"))
        label.set_alignment(0, 0.5)
        vbox2.pack_start(label, False, True, 5)

        adj = Gtk.Adjustment(1.0, 1.0, 1000.0, 1.0, 5.0, 0.0)
        spinner_rows = Gtk.SpinButton()
        spinner_rows.set_adjustment(adj)
        spinner_rows.set_wrap(True)
        vbox2.pack_start(spinner_rows, False, True, 0)

        vbox2 = Gtk.VBox(False, 0)
        hbox.pack_start(vbox2, True, True, 5)

        label = Gtk.Label()
        label.set_alignment(0, 0.5)
        vbox2.pack_start(label, False, True, 5)

        adj = Gtk.Adjustment(1.0, 1.0, 1000.0, 1.0, 5.0, 0.0)
        spinner_cols = Gtk.SpinButton()
        spinner_cols.set_adjustment(adj)
        spinner_cols.set_wrap(True)
        vbox2.pack_start(spinner_cols, False, True, 0)

        hbox = Gtk.HBox(False, 0)
        vbox.pack_start(hbox, True, True, 5)

        vbox2 = Gtk.VBox(False, 0)
        hbox.pack_start(vbox2, True, True, 5)

        label = Gtk.Label(label=_("Row Height:"))
        label.set_alignment(0, 0.5)
        vbox2.pack_start(label, False, True, 5)

        hbox2 = Gtk.HBox(False, 0)

        entry_rows = Gtk.Entry()
        entry_rows.set_max_length(3)
        entry_rows.set_text("1")
        entry_rows.set_width_chars(10)
        hbox2.pack_start(entry_rows, False, True, 0)

        label = Gtk.Label(label=_(" lines"))
        label.set_alignment(0, 0.5)
        hbox2.pack_start(label, False, True, 0)

        vbox2.pack_start(hbox2, False, True, 0)

        vbox2 = Gtk.VBox(False, 0)
        hbox.pack_start(vbox2, True, True, 5)

        label = Gtk.Label(label=_("Column Width:"))
        label.set_alignment(0, 0.5)
        vbox2.pack_start(label, False, True, 5)

        hbox2 = Gtk.HBox(False, 0)
        vbox2.pack_start(hbox2, False, True, 0)

        entry_cols = Gtk.Entry()
        entry_cols.set_max_length(3)
        entry_cols.set_text("5")
        entry_cols.set_width_chars(10)
        hbox2.pack_start(entry_cols, False, True, 0)

        label = Gtk.Label(label=_(" spaces"))
        label.set_alignment(0, 0.5)
        hbox2.pack_start(label, False, True, 0)

        borders = Gtk.CheckButton(_("Build outer walls of table"))
        borders.set_active(True)
        vbox.pack_start(borders, False, True, 5)


        frame = Gtk.Frame()
        main_vbox.pack_start(frame, True, True, 0)

        vbox = Gtk.VBox(False, 0)
        vbox.set_border_width(5)
        frame.add(vbox)

        hbox = Gtk.HBox(False, 0)
        vbox.pack_start(hbox, False, True, 5)

        label = Gtk.Label(label=_("Horizontal:"))
        label.set_alignment(0, 0.5)
        hbox.pack_start(label, False, True, 0)

        entry_horiz = Gtk.Entry()
        entry_horiz.set_max_length(1)
        entry_horiz.set_text("-")
        entry_horiz.set_width_chars(3)
        hbox.pack_start(entry_horiz, False, True, 12)

        label = Gtk.Label(label=_("Vertical:"))
        label.set_alignment(0, 0.5)
        hbox.pack_start(label, False, True, 0)

        entry_vert = Gtk.Entry()
        entry_vert.set_max_length(1)
        entry_vert.set_text("|")
        entry_vert.set_width_chars(3)
        hbox.pack_start(entry_vert, False, True, 27)

        hbox = Gtk.HBox(False, 0)
        vbox.pack_start(hbox, False, True, 5)

        label = Gtk.Label(label=_("Outer Cross:"))
        label.set_alignment(0, 0.5)
        hbox.pack_start(label, False, True, 0)

        entry_outer = Gtk.Entry()
        entry_outer.set_max_length(1)
        entry_outer.set_text("o")
        entry_outer.set_width_chars(3)
        hbox.pack_start(entry_outer, False, True, 5)

        label = Gtk.Label(label=_("Inner Cross:"))
        label.set_alignment(0, 0.5)
        hbox.pack_start(label, False, True, 5)

        entry_inner = Gtk.Entry()
        entry_inner.set_max_length(1)
        entry_inner.set_text("+")
        entry_inner.set_width_chars(3)
        hbox.pack_start(entry_inner, False, True, 0)


        frame = Gtk.Frame()
        main_vbox.pack_start(frame, True, True, 0)

        vbox = Gtk.VBox(False, 0)
        vbox.set_border_width(5)
        frame.add(vbox)

        entry_delim = Gtk.Entry()
        check = Gtk.CheckButton(_("Build around highlighted data"))
        check.connect("clicked", self.toggle_with_data, entry_delim, \
        spinner_rows, spinner_cols, entry_cols)
        vbox.pack_start(check, False, True, 5)

        hbox = Gtk.HBox(False, 0)
        vbox.pack_start(hbox, False, True, 0)

        label = Gtk.Label(label=_("Delimiter:"))
        label.set_alignment(0, 0.5)
        hbox.pack_start(label, False, True, 0)

        entry_delim.set_max_length(1)
        entry_delim.set_text(",")
        entry_delim.set_width_chars(10)
        entry_delim.set_sensitive(False)
        hbox.pack_start(entry_delim, False, True, 10)

        hbox = Gtk.HBox(False, 0)
        main_vbox.pack_start(hbox, False, True, 0)

        button_ok = Gtk.Button(_("Insert"))
        button_ok.connect("clicked", self.make_table, spinner_rows, \
        spinner_cols, entry_cols, entry_rows, entry_horiz, entry_vert, \
        entry_outer, entry_inner, entry_delim, check, borders)
        hbox.pack_start(button_ok, True, True, 5)

        button_cancel = Gtk.Button(_("Cancel"))
        button_cancel.connect("clicked", self.close)
        hbox.pack_start(button_cancel, True, True, 5)
        
        self.window.show_all()

    def toggle_with_data(self, widget, delim, row, col, width):
        """Callback for the check button which determines if the user would 
        like to build the table around highlighted data."""
        b = not widget.get_active()
        delim.set_sensitive(not b)
        row.set_sensitive(b)
        col.set_sensitive(b)
        width.set_sensitive(b)
        
    def close(self, widget):
        """Callback for the cancel button."""
        self.plugin.dialog = None
        self.window.destroy()
        
    def make_table(self, widget, row, col, width, height, ch_h, ch_v, ch_io, \
    ch_ii, delim, check, borders):
        """Callback for the insert button. Pulls the data from the fields of 
        the window, validates the data and, if everything is okay, instantiates 
        a TableMaker object. The table is then constructed and inserted into 
        the document and the window is closed."""
        rows = row.get_value_as_int()
        columns = col.get_value_as_int()
        
        try:
            spaces = int(width.get_text())
            lines = int(height.get_text())
        except ValueError:
            dia = Gtk.MessageDialog(None, \
            Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.ERROR, \
            Gtk.ButtonsType.CLOSE, \
            "Please enter only integer data for width and height")
            
            dia.run()
            dia.destroy()
            
        horiz = ch_h.get_text()
        vert = ch_v.get_text()
        inner = ch_ii.get_text()
        outer = ch_io.get_text()
        
        tm = TableMaker(columns, rows, lines, spaces, (horiz, vert, outer, \
        inner), borders.get_active())
        
        if check.get_active():
            delimiter = delim.get_text()
            if self.plugin.insert_data_table(delimiter, tm):
                self.close(widget)
            else:
                dia = Gtk.MessageDialog(None, \
                Gtk.DialogFlags.DESTROY_WITH_PARENT, \
                Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, \
                "Please highlight text if you wish to build a table around data")
                
                dia.run()
                dia.destroy()
        else:
            self.plugin.insert_table(tm)
            self.close(widget)

