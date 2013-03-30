# -*- encoding:utf-8 -*-


# __init__.py
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



import gedit
import gtk
from smart_highlight import SmartHighlightWindowHelper
from config_ui import ConfigUI


class SmartHighlightingPlugin(gedit.Plugin):
	def __init__(self):
		gedit.Plugin.__init__(self)
		self._instances = {}

	def activate(self, window):
		self._instances[window] = SmartHighlightWindowHelper(window)

	def deactivate(self, window):
		self._instances[window].deactivate()
		del self._instances[window]

	def update_ui(self, window):
		self._instances[window].update_ui()

	def is_configurable(self):
		return True
		
	def create_configure_dialog(self):
		dlg = ConfigUI(self)
		return dlg.configWindow

	def get_instance(self):
		window = gedit.app_get_default().get_active_window()
		return self._instances[window], window


