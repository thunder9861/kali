
from gi.repository.Gtk import accelerator_parse
from gi.repository.Gio import Settings


# Check if gschema installed
if 'org.gnome.gedit.plugins.imitation' not in Settings.list_schemas():
    class ImitationPluginConfigError(Exception):
        pass
    raise ImitationPluginConfigError('Imitation gschema not installed')


# Functions for getting config values
s = Settings.new('org.gnome.gedit.plugins.imitation').get_string

def p(accel_str):
    """ Parse accelerator string and warn of invalid formats """
    # Always results in lowercase keyvals (accounted for when matching)
    accel = accelerator_parse(accel_str)
    if accel[0] == 0:
        print 'Imitation plugin: invalid accelerator string "' + accel_str + '"'
    return accel


# configurable (restart gedit to apply changes)
MARK_TOGGLE = p(s('mark-toggle'))
MARK_UP = p(s('mark-up'))
MARK_DOWN = p(s('mark-down'))
MARK_ALT_UP = p(s('mark-alt-up'))
MARK_ALT_DOWN = p(s('mark-alt-down'))

INCR_NUM = p(s('incr-num'))
INCR_NUM1 = p(s('incr-num1'))
INCR_LOWER = p(s('incr-lower'))
INCR_UPPER = p(s('incr-upper'))

WORD_SEPERATORS = s('word-seperators') + ' ' + '\t'
MARK_SELECTION_BG = s('mark-selection-bg')
MARK_SELECTION_FG = s('mark-selection-fg')


# non-configurable (here for single processing)
CLEAR_MARKS = p('Escape')
BACKSPACE = p('BackSpace')
DELETE = p('Delete')

