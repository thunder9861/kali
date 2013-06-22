from gettext import gettext as _
from gi.repository import GObject, Gtk, Gedit
import base64
import re

ui_str = """
<ui>
    <toolbar name="ToolBar">
        <separator />
        <toolitem name="Encode" action="Encode" />
        <toolitem name="Decode" action="Decode" />
    </toolbar>
</ui>
"""

class Encrypt:
	def encode(self, text_decoded):
		return base64.encodestring(text_decoded)[:-1]

	def decode(self, text_coded):
		text_without_endline = self._delEndLine(text_coded)

		if not self._isBase64(text_without_endline):
			return text_coded
		return base64.decodestring(text_without_endline)

	def _delEndLine(self, text_coded):
		li = []
		for i in range(len(text_coded)):
			if text_coded[i] != '\n':
				li.append(text_coded[i])
		return ''.join(li)

	def _isBase64(self, text_coded):
		text_decoded = ""
		try:
			text_decoded = base64.decodestring(text_coded)
		except:
			return False

		return True

class Zillo(GObject.Object, Gedit.WindowActivatable):
    __gtype_name__ = "Zillo"

    window = GObject.property(type=Gedit.Window)
    
    def __init__(self):
        GObject.Object.__init__(self)
    
    def do_activate(self):
        self._add_ui()

    def do_deactivate(self):
        self._remove_ui()
        self._actions = None

    def do_update_state(self):
        self._actions.set_sensitive(self.window.get_active_document() != None)

    def encode(self, action):
        doc = self.window.get_active_document()
        if doc and doc.get_has_selection():
            encrypt = Encrypt()
            iter = doc.get_selection_bounds()
            text = doc.get_text(iter[0], iter[1], True)
            doc.delete(iter[0], iter[1])
            doc.insert(iter[0], encrypt.encode(text))

    def decode(self, action):
        doc = self.window.get_active_document()
        if doc and doc.get_has_selection():
            encrypt = Encrypt()
            iter = doc.get_selection_bounds()
            text = doc.get_text(iter[0], iter[1], True)
            try:
                decodeText = encrypt.decode(text)
            except:
                decodeText = text
            doc.delete(iter[0], iter[1])
            doc.insert(iter[0], decodeText)

    def _add_ui(self):
        manager = self.window.get_ui_manager()
        self._actions = Gtk.ActionGroup("ZilloActions")
        self._actions.add_actions([("Encode", Gtk.STOCK_CONVERT, _("Encode Text"), None, _("Encode selected text"), self.encode)])
        self._actions.add_actions([("Decode", Gtk.STOCK_CONVERT, _("Decode Text"), None, _("Decode selected text"), self.decode)])
        manager.insert_action_group(self._actions)
        self._ui_merge_id = manager.add_ui_from_string(ui_str)
        manager.ensure_update()

    def _remove_ui(self):
        manager = self.window.get_ui_manager()
        manager.remove_ui(self._ui_merge_id)
        manager.remove_action_group(self._actions)
        manager.ensure_update()
