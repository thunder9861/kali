# -*- coding: utf-8 -*-

#  Copyright © 2012  B. Clausius <barcc@gmx.de>
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


import os, locale

from gi.repository import GObject
from gi.repository import GLib
from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import GdkPixbuf
from gi.repository import Gio
from gi.repository import GtkSource

from . import parsers


class Options (GObject.GObject):
    __gsignals__ = {
        'parser-changed': (GObject.SignalFlags.RUN_FIRST, None, ()),
    }
    ui_file = os.path.join(os.path.dirname(__file__), 'options.ui')
    settings_schema = "org.gnome.gedit.plugins.classbrowser3g"
    settings_schema_editor = 'org.gnome.gedit.preferences.editor'
    
    def __init__(self):
        GObject.GObject.__init__(self)
        self.settings = Gio.Settings.new(self.settings_schema)
        self.settings_editor = Gio.Settings.new(self.settings_schema_editor)
        self.image_names = []
        self.language_parsers = {} # key: lang_id, value:(parser_id, parser instance)
        
        self.init_images()
        self._import_parsers()
        self.init_parsers()
        self.settings.connect('changed::used-parsers', self.on_used_parsers_changed)
        
    def init_images(self):
        pixbufpath = os.path.join(os.path.dirname(__file__), "pixmaps")
        pixbufs = os.listdir(pixbufpath)
        self.factory = Gtk.IconFactory()
        for filename in pixbufs:
            name = os.path.splitext(filename)[0]
            path = os.path.join(pixbufpath, filename)
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
            except Exception: #XXX: gi._glib.GError
                continue
            icon_set = Gtk.IconSet.new_from_pixbuf(pixbuf)
            self.factory.add('classbrowser3g-' + name, icon_set)
            self.image_names.append(name)
        for name in ['directory', 'file']:
            icon_set = Gtk.IconFactory.lookup_default('gtk-' + name)
            self.factory.add('classbrowser3g-' + name, icon_set)
            self.image_names.append(name)
        icon_set = Gtk.IconFactory.lookup_default('gtk-dialog-error')
        self.factory.add('classbrowser3g-error', icon_set)
        self.image_names.append('error')
        Gtk.IconFactory.add_default(self.factory)
        
    @staticmethod
    def _import_parsers():
        dirname = os.path.dirname(parsers.__file__)
        modules = {('parsers.' + os.path.splitext(f)[0]) for f in os.listdir(dirname) if not f.startswith('_')}
        for module in sorted(modules):
            try:
                __import__(module, globals(), locals(), level=1)
            except ImportError:
                pass
            
    def init_parsers(self):
        used_parsers = self.used_parsers
        self.language_parsers.clear()
        for parser_id, (parser, lang_ids, title, description) in parsers.all_parsers.items():
            for lang_id in lang_ids:
                if lang_id not in self.language_parsers:
                    self.language_parsers[lang_id] = (parser_id, parser())
        for lang, parser_id in used_parsers.items():
            lang_id = lang or None
            if not parser_id:
                if lang_id in self.language_parsers:
                    del self.language_parsers[lang_id]
            elif parser_id in parsers.all_parsers:
                self.language_parsers[lang_id] = (parser_id, parsers.all_parsers[parser_id][0]())
                
    def deactivate(self):
        Gtk.IconFactory.remove_default(self.factory)
        del self.image_names[:]
        self.language_parsers.clear()
        self.settings = None
        
    def _make_settings_property(settings_id):
        return property(
            lambda self: self.settings[settings_id],
            lambda self, value: self.settings.__setitem__(settings_id, value))
    autocollapse = _make_settings_property('autocollapse')
    jump_on_middle_click = _make_settings_property('jump-on-middle-click')
    used_parsers = _make_settings_property('used-parsers')
    smart_home_end = property(lambda self: self.settings_editor['smart-home-end'])
    
    def get_parser(self, lang_id):
        try:
            parser_info = self.language_parsers[lang_id]
        except KeyError:
            parser_info = self.language_parsers.get(None, None)
        return parser_info and parser_info[1]
        
    def on_used_parsers_changed(self, *unused_args):
        self.init_parsers()
        self.emit('parser-changed')
        
    def get_widget(self):
        builder = Gtk.Builder()
        builder.add_from_file(self.ui_file)
        
        def bind_clear_settings(settings_id, widget_name):
            builder.get_object(widget_name).connect('clicked',
                    lambda unused: self.settings.reset(settings_id))
        def bind_settings(settings_id, widget_name, widget_prop):
            self.settings.bind(settings_id,
                           builder.get_object(widget_name), widget_prop,
                           Gio.SettingsBindFlags.DEFAULT)
            bind_clear_settings(settings_id, widget_name + '_clear')
        def bind_settings_color(settings_id, widget_name):
            widget = builder.get_object(widget_name)
            def settings_changed(*unused_args):
                color = Gdk.Color.parse(self.settings[settings_id])[1]
                widget.set_color(color)
            settings_changed()
            self.settings.connect('changed::'+settings_id, settings_changed)
            def widget_changed(unused_widget):
                self.settings[settings_id] = widget.get_color().to_string()
            widget.connect('color-set', widget_changed)
            bind_clear_settings(settings_id, widget_name + '_clear')
        bind_settings('autocollapse', 'button_autocollapse', 'active')
        bind_settings('jump-on-middle-click', 'button_jump_on_middle_click', 'active')
        bind_settings_color('color-class', 'button_color_class')
        bind_settings_color('color-define', 'button_color_define')
        bind_settings_color('color-enumerator', 'button_color_enumerator')
        bind_settings_color('color-error', 'button_color_error')
        bind_settings_color('color-field', 'button_color_field')
        bind_settings_color('color-function', 'button_color_function')
        bind_settings_color('color-namespace', 'button_color_namespace')
        self._bind_settings_parsers(builder, bind_clear_settings)
        
        return builder.get_object('widget_config')
        
    def _bind_settings_parsers(self, builder, bind_clear_settings):
        def _get_parser_info(parser_id):
            if parser_id:
                return parsers.all_parsers[parser_id][2:]
            else:
                return '', None
                
        manager = GtkSource.LanguageManager.get_default()
        
        liststore_parsers = builder.get_object('liststore_parsers')
        liststore_parsers.append(['', '<Default Parser>'])
        for parser_id in sorted(parsers.all_parsers.keys()):
            assert parser_id is not None
            liststore_parsers.append([parser_id, parsers.all_parsers[parser_id][2]])
            
        liststore_language_mapping = builder.get_object('liststore_language_mapping')
        parser_id = self.language_parsers.get(None, ('', None))[0]
        parser_title, parser_desc = _get_parser_info(parser_id)
        liststore_language_mapping.append([None, parser_id, '<Default Parser>', parser_title, parser_desc])
        lang_infos = sorted(((manager.get_language(lang_id).get_name(), lang_id)
                                            for lang_id in manager.get_language_ids()),
                            key=lambda lang_info: locale.strxfrm(lang_info[0]))
        for lang_name, lang_id in lang_infos:
            parser_id = self.language_parsers.get(lang_id, ('', None))[0]
            parser_title, parser_desc = _get_parser_info(parser_id)
            liststore_language_mapping.append([lang_id, parser_id, lang_name, parser_title, parser_desc])
            
        def settings_changed(*unused_args):
            used_parsers = self.used_parsers
            for row in liststore_language_mapping:
                lang_id, parser_id, lang_name, parser_title, parser_desc = row
                new_parser_id = self.language_parsers.get(lang_id or None, ('',None))[0]
                if new_parser_id != parser_id:
                    parser_title, parser_desc = _get_parser_info(new_parser_id)
                    liststore_language_mapping[row.iter] = (
                                lang_id, new_parser_id, lang_name, parser_title, parser_desc)
        self.settings.connect('changed::used-parsers', settings_changed)
        def parser_changed(unused_combo, path, new_iter):
            lang_id, parser_id, lang_name, parser_title, parser_desc = liststore_language_mapping[path]
            parser_id = liststore_parsers[new_iter][0]
            parser_title, parser_desc = _get_parser_info(parser_id)
            liststore_language_mapping[path] = (lang_id, parser_id, lang_name, parser_title, parser_desc)
            used_parsers = self.used_parsers
            if used_parsers.get(lang_id, None) != parser_id:
                used_parsers[lang_id or ''] = parser_id
                self.used_parsers = used_parsers
        cellrenderercombo_parser = builder.get_object('cellrenderercombo_parser')
        cellrenderercombo_parser.connect('changed', parser_changed)
        bind_clear_settings('used-parsers', 'button_used_parsers_clear')
        

