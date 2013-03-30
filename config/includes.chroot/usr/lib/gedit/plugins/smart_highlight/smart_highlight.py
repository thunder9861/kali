# -*- encoding:utf-8 -*-


# smart_highlight.py
#
#
# Copyright 2010 swatch
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#




import gtk
import gedit
import re
import os.path
#import pango

import config_manager

import gettext
APP_NAME = 'smart-highlight'
LOCALE_DIR = '/usr/share/locale'
#LOCALE_DIR = os.path.join(os.path.dirname(__file__), 'locale')
#if not os.path.exists(LOCALE_DIR):
#	LOCALE_DIR = '/usr/share/locale'
gettext.install(APP_NAME, LOCALE_DIR, unicode=True)




class SmartHighlightWindowHelper:
	def __init__(self, window):
		self._window = window
		views = self._window.get_views()
		for view in views:
			view.get_buffer().connect('mark-set', self.on_textbuffer_markset_event)
		self.active_tab_added_id = self._window.connect("tab-added", self.tab_added_action)
		
		configfile = os.path.join(os.path.dirname(__file__), "config.xml")
		self.config_manager = config_manager.ConfigManager(configfile)
		self.options = self.config_manager.load_configure('search_option')
		for key in self.options.keys():
			if self.options[key] == 'True':
				self.options[key] = True
			elif self.options[key] == 'False':
				self.options[key] = False
		self.smart_highlight = self.config_manager.load_configure('smart_highlight')

	def deactivate(self):
		# Remove any installed menu items
		self._window.disconnect(self.active_tab_added_id)
		self.config_manager.update_config_file(self.config_manager.config_file, 'search_option', self.options)
		self.config_manager.update_config_file(self.config_manager.config_file, 'smart_highlight', self.smart_highlight)
	
	def _remove_menu(self):
		pass

	def update_ui(self):
		pass

		
	def show_message_dialog(self, text):
		dlg = gtk.MessageDialog(self._window, 
								gtk.DIALOG_MODAL | gtk.DIALOG_DESTROY_WITH_PARENT,
								gtk.MESSAGE_INFO,
								gtk.BUTTONS_CLOSE,
								_(text))
		dlg.run()
		dlg.hide()
		
		
	def create_regex(self, pattern, options):
		if options['REGEX_SEARCH'] == False:
			pattern = re.escape(unicode(r'%s' % pattern, "utf-8"))
		else:
			pattern = unicode(r'%s' % pattern, "utf-8")
		
		if options['MATCH_WHOLE_WORD'] == True:
			pattern = r'\b%s\b' % pattern
			
		if options['MATCH_CASE'] == True:
			regex = re.compile(pattern, re.MULTILINE)
		else:
			regex = re.compile(pattern, re.IGNORECASE | re.MULTILINE)
		
		return regex

	def smart_highlighting_action(self, doc, search_pattern):
		regex = self.create_regex(search_pattern, self.options)
		self.smart_highlight_off(doc)
		start, end = doc.get_bounds()
		text = unicode(doc.get_text(start, end), 'utf-8')
		
		match = regex.search(text)
		while(match):
			self.smart_highlight_on(doc, match.start(), match.end() - match.start())
			match = regex.search(text, match.end()+1)
			
	def tab_added_action(self, action, tab):
		view = tab.get_view()
		view.get_buffer().connect('mark-set', self.on_textbuffer_markset_event)
	
	def on_textbuffer_markset_event(self, textbuffer, iter, textmark):
		if textmark.get_name() == None:
			return
		if textbuffer.get_selection_bounds():
			start, end = textbuffer.get_selection_bounds()
 			self.smart_highlighting_action(textbuffer, textbuffer.get_text(start, end))
 		else:
 			self.smart_highlight_off(textbuffer)
	
	def smart_highlight_on(self, doc, highlight_start, highlight_len):
		if doc.get_tag_table().lookup('smart_highlight') == None:
			tag = doc.create_tag("smart_highlight", foreground=self.smart_highlight['FOREGROUND_COLOR'], background=self.smart_highlight['BACKGROUND_COLOR'])
		doc.apply_tag_by_name('smart_highlight', doc.get_iter_at_offset(highlight_start), doc.get_iter_at_offset(highlight_start + highlight_len))
		
	def smart_highlight_off(self, doc):
		start, end = doc.get_bounds()
		if doc.get_tag_table().lookup('smart_highlight') == None:
			tag = doc.create_tag("smart_highlight", foreground=self.smart_highlight['FOREGROUND_COLOR'], background=self.smart_highlight['BACKGROUND_COLOR'])
		doc.remove_tag_by_name('smart_highlight', start, end)
	

