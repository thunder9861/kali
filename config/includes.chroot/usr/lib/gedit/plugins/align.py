# -*- coding: utf-8 -*-
# Copyright (c) 2010 Osmo Salomaa
# Copyright (c) 2012 Joe R. Nassimian

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
from gettext import gettext as _

from gi.repository import GObject, Gtk, Gedit


"""
Align blocks of text into colomns
"""

# -----------------------------------------------------------------------------

# Menu item example, insert a new item in the Tools menu
ui_str = """
<ui>
    <menubar name="MenuBar">
        <menu name="EditMenu" action="Edit">
            <placeholder name="EditOps_6">
                <menuitem name="Align" action="Align"/>
            </placeholder>
        </menu>
    </menubar>
</ui>"""

# -----------------------------------------------------------------------------

class AlignDialog(object):
    """
    Dialog for specifying an alignment separator.
    """

    # -------------------------------------------------------------------------

    def __init__(self, parent):
        fn = os.path.join(os.path.dirname(__file__), 'align.ui')
        self.builder = Gtk.Builder()
        self.builder.add_from_file(fn)
        self.builder.connect_signals(self)

        self.dialog = self.builder.get_object("dialog")
        self.entry = self.builder.get_object("entry")

        self.dialog.set_transient_for(parent)
        self.dialog.set_default_response(Gtk.ResponseType.OK)

    # -------------------------------------------------------------------------

    def run(self):
        """
        Show and run the dialog.
        """
        response = self.dialog.run()

        if response == Gtk.ResponseType.OK:
            res = self.entry.get_text()
        else:
            res = None

        self.dialog.destroy()

        return res

# -----------------------------------------------------------------------------

class AlignPlugin(GObject.Object, Gedit.WindowActivatable):
    """
    Align blocks of text into columns.
    """

    __gtype_name__ = "AlignPlugin"

    window = GObject.property(type=Gedit.Window)

    # -------------------------------------------------------------------------

    def __init__(self):
        GObject.Object.__init__(self)

        self._action_group = None
        self.ui_id = None

    # -------------------------------------------------------------------------

    def _insert_menu(self):
        # Create a new action group
        self._action_group = Gtk.ActionGroup("AlignPluginActions")
        self._action_group.add_actions([(
            'Align',
            None,
            _('Ali_gn...'),
            None,
            _("Align the selected text to columns"),
            self.do_align_activate
        )])

        # Get the Gtk.UIManager
        manager = self.window.get_ui_manager()

        # Insert the action group
        manager.insert_action_group(self._action_group, -1)

        # Merge the UI
        self.ui_id = manager.add_ui_from_string(ui_str)

    # -------------------------------------------------------------------------

    def _remove_menu(self):
        # Get the Gtk.UIManager
        manager = self.window.get_ui_manager()

        # Remove the ui
        manager.remove_ui(self.ui_id)

        # Remove the action group
        manager.remove_action_group(self._action_group)

        # Make sure the manager updates
        manager.ensure_update()

    # -------------------------------------------------------------------------

    def do_activate(self):
        """
        Activate plugin.
        """

        # Insert menu items
        self._insert_menu()

    # -------------------------------------------------------------------------

    def do_deactivate(self):
        """
        Deactivate plugin.
        """

        # Remove any installed menu items
        self._remove_menu()

        # Clear attributes
        self._action_group = None
        self.ui_id = None

    # -------------------------------------------------------------------------

    def do_update_state(self):
        """
        Update sensitivity of plugin's actions.
        """

        doc = self.window.get_active_document()
        self._action_group.set_sensitive(doc is not None)

    # -------------------------------------------------------------------------

    def do_align_activate(self, *args):
        """
        Align the selected text into columns.
        """

        doc = self.window.get_active_document()

        bounds = doc.get_selection_bounds()
        if not bounds:
            return

        dialog = AlignDialog(self.window)

        separator = dialog.run()

        if separator:
            self.align(doc, bounds, separator)

    # -------------------------------------------------------------------------

    def align(self, doc, bounds, separator):
        """
        Align the selected text into columns.
        """

        splitter = separator.strip() or ' '
        lines = range(bounds[0].get_line(), bounds[1].get_line() + 1)

        # Split text to rows and columns.
        # Ignore lines that don't match splitter.
        matrix = []
        for i in reversed(range(len(lines))):
            line_start = doc.get_iter_at_line(lines[i])
            line_end = line_start.copy()
            line_end.forward_to_line_end()
            text = doc.get_text(line_start, line_end, False)
            if text.find(splitter) == -1:
                lines.pop(i)
                continue
            matrix.insert(0, text.split(splitter))
        for i in range(len(matrix)):
            matrix[i][0] = matrix[i][0].rstrip()
            for j in range(1, len(matrix[i])):
                matrix[i][j] = matrix[i][j].strip()

        # Find out column count and widths.
        col_count = max(list(len(x) for x in matrix))
        widths = [0] * col_count
        for row in matrix:
            for i, element in enumerate(row):
                widths[i] = max(widths[i], len(element))

        doc.begin_user_action()

        # Remove text and insert column elements.
        for i, line in enumerate(lines):
            line_start = doc.get_iter_at_line(line)
            line_end = line_start.copy()
            line_end.forward_to_line_end()
            doc.delete(line_start, line_end)
            for j, element in enumerate(matrix[i]):
                offset = sum(widths[:j])
                itr = doc.get_iter_at_line(line)
                itr.set_line_offset(offset)
                doc.insert(itr, element)
                if j < col_count - 1:
                    itr.set_line_offset(offset + len(element))
                    space = ' ' * (widths[j] - len(element))
                    doc.insert(itr, space)

        # Insert separators.
        for i, line in enumerate(lines):
            for j in reversed(range(len(matrix[i]) - 1)):
                offset = sum(widths[:j + 1])
                itr = doc.get_iter_at_line(line)
                itr.set_line_offset(offset)
                doc.insert(itr, separator)

        doc.end_user_action()

# -----------------------------------------------------------------------------

