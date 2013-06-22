"""
Dear friend, do not imitate what is evil but what is good.
Anyone who does what is good is from God.
Anyone who does what is evil has not seen God.
3 John 1:11 (NIV)

Imitation is a plugin for gedit that allows the user to mark multiple places
in a document with virtual cursors that imitate the user's cursor. The virtual
cursors are not clones, as in addition to normal editing, they can also
increment and alternate values, hence Imitation.
The user's cursor is disabled during imitation.

"""

from gi.repository import GObject, Gedit

from imitation.tab import ImitationTab


class ImitationPlugin(GObject.Object, Gedit.WindowActivatable):
    
    """ Plugin attached to windows
    
    Imitation is loaded per window, and applied per active-tab.
    If the active-tab for that window changes, then Imitation will be applied
    to the newly active-tab, and will lose state for the previous tab.
    This is to prevent accidental edits when returning to a previous tab.
    
    """
    
    window = GObject.property(type=Gedit.Window)
    
    def __init__(self):
        GObject.Object.__init__(self)
    
    def do_activate(self):
        """ Activate the plugin """
        self._active_tab = ImitationTab(self.window.get_active_tab())
        self._tab_change_handler_id = self.window.connect(
                'active-tab-changed', self._on_active_tab_changed)
    
    def do_deactivate(self):
        """ Deactivate the plugin """
        self.window.disconnect(self._tab_change_handler_id)
        self._active_tab.originalise()
    
    def _on_active_tab_changed(self, window, tab):
        """ Handle active-tab changes """
        self._active_tab.originalise()
        self._active_tab = ImitationTab(tab)

