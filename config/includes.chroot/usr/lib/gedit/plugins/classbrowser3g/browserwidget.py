# -*- coding: utf-8 -*-

#  Copyright © 2012  B. Clausius <barcc@gmx.de>
#  Copyright © 2006-2008  Frederic Back <fredericback@gmail.com>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


import os

from gi.repository import GLib
from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GObject
from gi.repository import Gio
from gi.repository import Gedit


class ParserModel (object):
    def __init__(self, colors, options):
        #       name, stock_id, pixbuf_visible, color, uri, line_start, col_start, line_end, col_end
        self._model = Gtk.TreeStore(str, str, bool, str, str, int, int, int, int)
        self._colors = colors
        self._options = options
        
    def append(self, titer, name, typecode, uri, startline, startcol=0, endline=0, endcol=0):
        if typecode:
            stock_id = 'classbrowser3g-' + typecode
            pixbuf_visible = True
            color = self._colors.get(typecode)
            if color:
                color = self._options.settings[color]
        else:
            stock_id = None
            pixbuf_visible = False
            color = None
        return self._model.append(titer, [name, stock_id, pixbuf_visible, color, uri,
                                    startline, startcol, endline, endcol])
                                    
    def set_end(self, titer, line, col=0):
        self._model.set_value(titer, 7, line)
        self._model.set_value(titer, 8, col)
        
    def get_startline(self, titer):
        return self._model.get_value(titer, 5)
        
        
class ClassBrowser (object):
    """ A widget that resides in gedits side panel. """
    ui_file = os.path.join(os.path.dirname(__file__), 'browser.ui')

    def __init__(self, window, options):
        self.window = window
        self.options = options
        self.parser = None
        self.block_update_cursor = False

        # add ui
        builder = Gtk.Builder()
        builder.add_from_file(self.ui_file)
        self.widget = builder.get_object('widget_browser')
        
        self.browser = builder.get_object('treeview_browser')
        self.browser.connect("button_press_event", self.on_treeview_button_press_event)
        self.browser.connect("popup-menu", self.on_treeview_popup_menu)
        self.browser.connect("row-activated", self.on_row_activated)
        
        self.widget.show_all()
        
    def deactivate(self):
        self.window = None
        self.options = None
        self.parser = None
        self.widget = None
        self.browser = None
        
    def update_browser(self, doc, parser):
        self.parser = parser
        if parser is None:
            self.browser.set_model(None)
            return
            
        model = ParserModel(self.parser.colors, self.options)
        self.parser.parse(doc, doc.get_location(), model)
        self.browser.set_model(model._model)
        self.update_cursor(doc)
        
    def on_row_activated(self, treeview, treepath, unused_column):
        if self.parser:
            self._open_document_from_model(treeview.get_model(), treepath)
            treeview.expand_row(treepath, False)

    def on_treeview_button_press_event(self, treeview, event):
        if event.button == 2:
            if self.options.jump_on_middle_click:
                path_info = treeview.get_path_at_pos(int(event.x), int(event.y))
                if path_info is None:
                    return
                self._open_document_from_model(treeview.get_model(), path_info[0])
                return True
                
        if event.button == 3:
            x, y = int(event.x), int(event.y)
            pthinfo = treeview.get_path_at_pos(x, y)
            if pthinfo is None: return
            path, col, cellx, celly = pthinfo
            
            self.do_popup_menu(path, event.button, event.time)
            
    def on_treeview_popup_menu(self, treeview):
        path, col = treeview.get_cursor()
        self.do_popup_menu(path, 0, Gtk.get_current_event_time())
        return True
        
    def do_popup_menu(self, path, button, time):
        menu = Gtk.Menu()
        model = self.browser.get_model()
        name, filename, line, col = model.get(model.get_iter(path), 0, 4, 5, 6)
        if filename is not None and line > 0:
            menuitem = Gtk.ImageMenuItem.new_from_stock('gtk-jump-to', None)
            menu.append(menuitem)
            menuitem.show()
            def on_menuitem_jump_to(unused_menuitem):
                self._open_document(filename, line, col)
            menuitem.connect("activate", on_menuitem_jump_to)
            
            menuitem = Gtk.SeparatorMenuItem.new()
            menuitem.show()
            menu.append(menuitem)
            
        def on_menuitem_paste_name(unused_menuitem):
            self.window.get_active_document().insert_at_cursor(name)
        menuitem = Gtk.ImageMenuItem.new_from_stock('gtk-paste', None)
        menuitem.show()
        menu.append(menuitem)
        menuitem.connect("activate", on_menuitem_paste_name)
        
        def on_menuitem_copy_name(unused_menuitem):
            cb = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
            cb.set_text(name, -1)
            cb.store()
        menuitem = Gtk.ImageMenuItem.new_from_stock('gtk-copy', None)
        menuitem.show()
        menu.append(menuitem)
        menuitem.connect("activate", on_menuitem_copy_name)
        
        #TODO: Enable menuitems
        ## add the menu items from the parser
        #menuitems = self.parser.get_menu(self.browser.get_model(), path)
        #for menuitem in menuitems:
        #    menu.append(menuitem)
        #    menuitem.show()
            
        menuitem = Gtk.SeparatorMenuItem.new()
        menuitem.show()
        menu.append(menuitem)
        
        menuitem = Gtk.CheckMenuItem("Auto-_collapse")
        menuitem.set_use_underline(True)
        menu.append(menuitem)
        menuitem.show()
        menuitem.set_active(self.options.autocollapse)
        def on_menuitem_autocollapse(menuitem):
            self.options.autocollapse = menuitem.get_active()
        menuitem.connect("toggled", on_menuitem_autocollapse)
        
        menu.attach_to_widget(self.browser, None)
        menu.popup(None, None, None, None, button, time)
        
    @classmethod
    def _get_path_at_line(cls, rowiter, line, col, parent=None):
        found = None
        for row in rowiter:
            filename, line_start, col_start, line_end, col_end = row[4:]
            if (line, col) >= (line_start, col_start):
                if (line, col) < (line_end, col_end):
                    return cls._get_path_at_line(row.iterchildren(), line, col, row)
                elif line_end == 0 or parent is None:
                    if found is None or [line_start, col_start] > found[5:7]:
                        found = row
            elif found:
                # previous token has no (or defect) line_end
                return cls._get_path_at_line(found.iterchildren(), line, col, found)
            elif parent:
                return parent.path
            else:
                # use first token, if line is before first token
                return row.path
        # use last token, if found is None then there are no tokens in the file
        if found:
            return cls._get_path_at_line(found.iterchildren(), line, col, found)
        return parent and parent.path
        
    def get_current_iter(self):
        doc = self.window.get_active_document()
        if doc and self.parser:
            it = doc.get_iter_at_mark(doc.get_insert())
            line = it.get_line() + 1
            offset = it.get_line_index()
            model = self.browser.get_model()
            path = self._get_path_at_line(model, line, offset)
            #if there is no current tag, get the root
            location = doc.get_location()
            if path is None:
                return model.get_iter_first(), [location and location.get_uri(), line, offset]
            else:
                return model.get_iter(path), [location and location.get_uri(), line, offset]
        else:
            return None, [None, 0, 0]

    def jump_to_next_tag(self):
        model = self.browser.get_model()
        titer, filename_line_col = self.get_current_iter()
        filename_line_col_next = model[titer][4:7]
        next_iter = titer
        
        while filename_line_col_next <= filename_line_col:
            parent_iter = titer
            next_iter = model.iter_next(titer)
            while next_iter is None:
                # no next iter, try next of parent
                parent_iter = model.iter_parent(parent_iter)
                if parent_iter is None:
                    # no parent has a next iter, try first child
                    next_iter = model.iter_children(titer)
                    if next_iter is None:
                        # titer is the last
                        return
                    break
                next_iter = model.iter_next(parent_iter)
            titer = next_iter
            filename_line_col_next = model[titer][4:7]
        tab = self._open_document_from_model(model, next_iter)
        self.update_cursor(tab.get_document())
        
    def jump_to_prev_tag(self):
        model = self.browser.get_model()
        titer, filename_line_col = self.get_current_iter()
        filename_line_col = model[titer][4:7]
        filename_line_col_prev = filename_line_col
        
        while filename_line_col_prev == filename_line_col:
            #HACK: Till GTK 3.2 iter_previous may modify the argument
            # and return bool to indicate success/failure.
            # Now it returns a new iter like the other iter functions.
            prev_iter = titer.copy()
            success = model.iter_previous(prev_iter)
            if success not in [False, True]:
                prev_iter = success
                success = prev_iter is not None
            if not success:
                prev_iter = model.iter_parent(titer)
                if prev_iter is None:
                    return
            titer = prev_iter
            filename_line_col_prev = model[titer][4:7]
        tab = self._open_document_from_model(model, prev_iter)
        if tab is not None:
            self.update_cursor(tab.get_document())
        
    def _open_document_from_model(self, model, path_or_iter):
        filename, line, col = model[path_or_iter][4:7]
        if filename is None or line == 0:
            #XXX: should not happen?
            return None
        return self._open_document(filename, line, col)
        
    def _open_document(self, filename, line, column):
        """ open a the file specified by filename at the given line and column
        number. Line and column numbering starts at 1. """
        
        if line == 0:
            raise ValueError, "line and column numbers start at 1"
        
        location = Gio.File.new_for_uri(filename)
        tab = self.window.get_tab_from_location(location)
        if tab is None:
            tab = self.window.create_tab_from_location(location, None,
                                            line, column+1, False, True)
            view = tab.get_view()
        else:
            view = self._set_active_tab(tab, line, column)
        GLib.idle_add(view.grab_focus)
        return tab

    def _set_active_tab(self, tab, lineno, offset):
        self.window.set_active_tab(tab)
        view = tab.get_view()
        if lineno > 0:
            self.block_update_cursor = True
            doc = tab.get_document()
            doc.goto_line(lineno - 1)
            cur_iter = doc.get_iter_at_line(lineno-1)
            linelen = cur_iter.get_chars_in_line() - 1
            if offset >= linelen:
                cur_iter.forward_to_line_end()
            elif offset > 0:
                cur_iter.set_line_offset(offset)
            elif offset == 0 and self.options.smart_home_end == 'before':
                cur_iter.set_line_offset(0)
                while cur_iter.get_char().isspace() and cur_iter.forward_char():
                    pass
            doc.place_cursor(cur_iter)
            view.scroll_to_cursor()
            self.block_update_cursor = False
        return view
        
    def update_cursor(self, doc):
        if not self.parser or self.block_update_cursor:
            return
        it = doc.get_iter_at_mark(doc.get_insert())
        line = it.get_line()
        offset = it.get_line_index()
        path = self._get_path_at_line(self.browser.get_model(), line+1, offset)
        if path and path != self.browser.get_cursor()[0]:
            if self.options.autocollapse:
                self.browser.collapse_all()
            self.browser.expand_to_path(path)
            self.browser.set_cursor(path, None, False)
                
            
