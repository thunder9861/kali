import dbus
from gi.repository import GLib, Gtk

class Encrypter(object):
    def __init__(self, ui):
        self.ui = ui
        self.bus = dbus.SessionBus()
        self.init_dbus()
            
    def init_dbus(self):
        keys_proxy = self.bus.get_object('org.gnome.seahorse', '/org/gnome/seahorse/keys')
        key_service = dbus.Interface(keys_proxy, 'org.gnome.seahorse.KeyService')
        
        types = key_service.GetKeyTypes()
        
        path = key_service.GetKeyset(types[0])
        
        proxy_obj = self.bus.get_object('org.gnome.seahorse', path)
        self.keyset = dbus.Interface(proxy_obj, "org.gnome.seahorse.Keys")
    
    def select_key(self):
        self.populate_keys_list()
        
        resp = self.ui.main.run()
        self.ui.main.hide()
        if resp != 1:
            return
        return list( self.shown[self.ui.key_selection.get_selected()[1]] )
    
    def populate_keys_list(self):
        keys = self.keyset.ListKeys()
        
        self.shown = Gtk.TreeModelFilter( child_model=self.ui.keys )
        self.shown.set_visible_func( self.show_key, None )
                
        self.ui.keys_view.set_model( self.shown )
        self.ui.search.connect( "changed", (lambda x : self.shown.refilter()) )
        self.ui.key_selection.connect( "changed", self.activate_OK_button )
        
        self.ui.keys.clear()
        
        fields_names = [ "display-name", "display-id", "fingerprint" ]
        # Fields are well described in
        # https://lug.asprion.org/wiki/1/Seahorse_DBUS_Interface
        # "fingerprint" is present iff it is a main key (and we want only
        # those).
        # Never found: "expires","enc-type"
        # "display-id" always the same as "raw-id"
        
        for key in keys:
            fields = dict( self.keyset.GetKeyFields(key, fields_names ) )
            if "fingerprint" in fields:
                self.ui.keys.append( [unicode( fields["display-name"] ),
                                      unicode( fields["display-id"] ),
                                      unicode( fields["fingerprint"] ),
                                      unicode( fields["display-name"] ).lower(),
                                      key] )
    
    def show_key(self, store, the_iter, data):
        search = self.ui.search.get_text()
        if not search:
            # No search currently active
            return True
        
        return search.lower() in self.ui.keys[the_iter][3]
    
    def activate_OK_button(self, selection):
        self.ui.OK_button.set_sensitive( bool( selection.get_selected()[1] ) )
    
    def encrypt(self, cleartext):
        self.chosen = self.select_key()
        if not self.chosen:
            return
        
        cr_proxy = self.bus.get_object('org.gnome.seahorse', '/org/gnome/seahorse/crypto')
        cr_service = dbus.Interface(cr_proxy, 'org.gnome.seahorse.CryptoService')
        
        try:
            key = self.chosen[-1]
            encrypted = cr_service.EncryptText([key], "", 0, cleartext)
            return encrypted
        except dbus.exceptions.DBusException, msg:
            self.ui.error.set_title( "Encryption error" )
            self.ui.error.set_markup( "The encryption process failed due to the following error:" )
            self.ui.error.format_secondary_text( msg )
            self.ui.error.run()
            self.ui.error.hide()
    
    def decrypt(self, encrypted_text):
        cr_proxy = self.bus.get_object('org.gnome.seahorse', '/org/gnome/seahorse/crypto')
        cr_service = dbus.Interface(cr_proxy, 'org.gnome.seahorse.CryptoService')
        
        try:
            # Notice "signer" is not returned:
            cleartext, signer = cr_service.DecryptText( "openpgp", 0, encrypted_text )
            return cleartext
        except dbus.exceptions.DBusException, msg:
            self.ui.error.set_title( "Decryption error" )
            self.ui.error.set_markup( "The decryption process failed due to the following error:" )
            self.ui.error.format_secondary_text( msg )
            self.ui.error.run()
            self.ui.error.hide()

