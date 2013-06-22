# -*- coding: utf-8 -*-

#  Copyright © 2012-2013  B. Clausius <barcc@gmx.de>
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

from gi.repository import GObject
from gi.repository import GLib
from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GdkPixbuf
from gi.repository import Gedit
from gi.repository import PeasGtk

from .browserwidget import ClassBrowser
from . import options


class ClassBrowserPlugin (GObject.Object, Gedit.WindowActivatable, PeasGtk.Configurable):
    __gtype_name__ = "ClassBrowser3gPlugin"
    window = GObject.property(type=Gedit.Window)
    options = None
    
    def __init__(self):
        GObject.Object.__init__(self)
        self.handlers = {}
        
    # Plugin interface
    
    def do_create_configure_widget(self):
        return self.options.get_widget()
        
    def do_activate(self):
        if self.options is None:
            self.__class__.options = options.Options()
        # create the browser pane
        self.classbrowser = ClassBrowser(self.window, self.options)
        panel = self.window.get_side_panel()
        filename = os.path.join(os.path.dirname(__file__), "pixmaps", 'panel-icon.png')
        image = Gtk.Image.new_from_file(filename)
        panel.add_item(self.classbrowser.widget, 'ClassBrowser3gPanel', 'Class Browser', image)
        
        self._connect(self.window,
                self.window.connect("tab_added", self.on_window_tab_added),
                self.window.connect("tab_removed", self.on_window_tab_removed),
                self.window.connect("active_tab_changed", self.on_window_active_tab_changed),
                self.window.connect("delete-event", self.on_window_delete_event))
        self._connect(self.options,
                self.options.connect('parser-changed', self.on_options_parser_changed))
        
        submenu = """
            <ui>
              <menubar name="MenuBar">
                <menu name="SearchMenu" action="Search">
                  <placeholder name="SearchOps_7">
                        <menuitem action="JumpPreviousTag"/>
                        <menuitem action="JumpNextTag"/>
                  </placeholder>
                </menu>
              </menubar>
            </ui>
            """
        self.action_group = Gtk.ActionGroup("GeditClassBrowserPluginActions")
        self.action_group.add_actions([
                # name, stock id, label, accelerator, tooltip
                ('JumpNextTag', 'gtk-go-down', _('Jump to next tag'), "<control>j",
                                               _('Jump to next tag'), self.on_next_tag),
                ('JumpPreviousTag', 'gtk-go-up', _('Jump to previous tag'), "<control><shift>j",
                                                 _('Jump to previous tag'), self.on_previous_tag)
            ], self.window)
        ui_manager = self.window.get_ui_manager()
        ui_manager.insert_action_group(self.action_group, 0)
        self.ui_manager_id = ui_manager.add_ui_from_string(submenu)
        
        # if the plugin is activated in the plugin dialog, things that would
        # be done in the on_window_tab_* handlers must be done manually.
        for doc in self.window.get_documents():
            self._init_new_doc(doc)
        tab = self.window.get_active_tab()
        if tab:
            self._init_active_tab(tab)
            
    def do_deactivate(self):
        self._disconnect_all()
        ui_manager = self.window.get_ui_manager()
        ui_manager.remove_ui(self.ui_manager_id)
        ui_manager.remove_action_group(self.action_group)
        pane = self.window.get_side_panel()
        pane.remove_item(self.classbrowser.widget)
        self.classbrowser.deactivate()
        if len(Gedit.App.get_default().get_windows()) == 0:
            self.options.deactivate()
            self.__class__.options = None
        
    # helpers
        
    def _connect(self, obj, *handlers):
        for handler in handlers:
            self.handlers.setdefault(obj, []).append(handler)
    def _disconnect(self, obj):
        try:
            handlers = self.handlers[obj]
        except KeyError:
            return
        for handler in handlers:
            obj.disconnect(handler)
        del self.handlers[obj]
    def _disconnect_all(self):
        for obj, handlers in self.handlers.items():
            for handler in handlers:
                obj.disconnect(handler)
        self.handlers.clear()
        
    def _set_parser_for_doc(self, doc, firstcall=True):
        lang = doc.get_language()
        if lang is None and firstcall:
            #XXX: If the file does not have an extension, the lang not yet available.
            #     Is there a better way to 
            GLib.idle_add(self._set_parser_for_doc, doc, False)
        elif firstcall or doc == self.window.get_active_document():
            parser = self.options.get_parser(lang and lang.get_id())
            self.classbrowser.update_browser(doc, parser)
            
    def _init_new_doc(self, doc):
        self._connect(doc,
                    doc.connect_after("mark-set", self.on_doc_mark_set),
                    doc.connect("modified-changed", self.on_doc_modified_changed),
                    doc.connect("notify::language", self.on_doc_notify_language))
                    
    def _init_active_tab(self, tab):
        doc = tab.get_document()
        self._set_parser_for_doc(doc)
        
    # action handlers
    
    def on_next_tag(self, action, window):
        self.classbrowser.jump_to_next_tag()
        
    def on_previous_tag(self, action, window):
        self.classbrowser.jump_to_prev_tag()
        
    # window handlers
    
    def on_window_tab_added(self, window, tab):
        self._init_new_doc(tab.get_document())
        
    def on_window_tab_removed(self, window, tab):
        self._disconnect(tab.get_document())
        
    def on_window_active_tab_changed(self, unused_window, tab):
        self._init_active_tab(tab)
        
    def on_window_delete_event(self, unused_window, unused_event):
        # prevents unnecessary classbrowser updates
        self._disconnect_all()
        
    # document handlers
    
    def on_doc_mark_set(self, doc, titer, mark):
        if mark.get_name() == 'insert' and doc == self.window.get_active_document():
            self.classbrowser.update_cursor(doc)
        
    def on_doc_modified_changed(self, doc):
        if doc == self.window.get_active_document() and not doc.get_modified():
            self._set_parser_for_doc(doc)
            
    def on_doc_notify_language(self, doc, *args):
        if doc == self.window.get_active_document():
            self._set_parser_for_doc(doc)
            
    # option handlers
    
    def on_options_parser_changed(self, unused_options):
        doc = self.window.get_active_document()
        self._set_parser_for_doc(doc)
        
