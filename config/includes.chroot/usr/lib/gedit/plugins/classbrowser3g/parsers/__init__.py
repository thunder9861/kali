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


import os

all_parsers = {}


def register_parser(parser_id, parser, lang_ids, title, description=None):
    if not parser_id:
        print 'classbrowser3g warning: parser_id must be a non-empty string (%r)' % parser_id
    elif parser_id in all_parsers:
        print 'classbrowser3g warning: %r is already registered' % parser_id
    else:
        all_parsers[parser_id] = (parser, lang_ids, title, description)
    
    
class ClassParserInterface:
    """An abstract interface for class parsers.
    
    A class parser monitors gedit documents and provides a Gtk.TreeModel
    that contains the browser tree.
    There is always only *one* active instance of each parser. They are created
    at startup (in __init__.py).
    """
    
    colors = {
            'class':       'color-class',
            'class_prot':  'color-class',
            'class_priv':  'color-class',
            'struct':      'color-class',
            'struct_prot': 'color-class',
            'struct_priv': 'color-class',
            'union':       'color-class',
            'union_prot':  'color-class',
            'union_priv':  'color-class',
            'typedef':     'color-class',
            'field':       'color-field',
            'field_prot':  'color-field',
            'field_priv':  'color-field',
            'function':      'color-function',
            'function_prot': 'color-function',
            'function_priv': 'color-function',
            'namespace':   'color-namespace',
            'file':        'color-class',
            'directory':   'color-namespace',
            'enum':        'color-enumerator',
            'enum_prot':   'color-enumerator',
            'enum_priv':   'color-enumerator',
            'define':      'color-define',
            'error':       'color-error',
        }
        
    def __init__(self):
        pass
        
    def parse(self, doc, location, model):
        pass
        
    #TODO: Parser menu items currently not supported
    #def get_menu(self, model, path):
    #    """Return a list of Gtk.Menu items for the specified tag. 
    #    Defaults to an empty list
    #    
    #    model -- a Gtk.TreeModel (previously filled by parse())
    #    path -- a tuple containing the treepath
    #    """
    #    return []
        
        

