from gi.repository import GObject, Gedit
from regexsearchinstance import RegexSearchInstance

class RegexSearch(GObject.Object, Gedit.WindowActivatable):
    DATA_TAG = "RegexSearchInstance"
    __gtype_name__ = "GeditRESearch"
    window = GObject.property(type=Gedit.Window)

    def __init__(self):
        GObject.Object.__init__(self)

    def do_activate(self):
        regexsearch_instance = RegexSearchInstance(self.window)
        self.window.set_data(self.DATA_TAG, regexsearch_instance)
	
    def do_deactivate(self):
        regexsearch_instance = self.window.get_data(self.DATA_TAG)
        # regexsearch_instance destroy!?
        self.window.set_data(self.DATA_TAG, None)
		
    def do_update_ui(self):
        regexsearch_instance = self.window.get_data(self.DATA_TAG)
        regexsearch_instance.update_ui()
