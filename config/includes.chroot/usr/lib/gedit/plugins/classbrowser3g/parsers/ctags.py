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


import os, re
import subprocess
import tempfile
from glob import glob

from gi.repository import Gio
from gi.repository import Gtk

from . import ClassParserInterface, register_parser


#  c: class name
#  d: define (from #define XXX)
#  e: enumerator
#  f: function or method name
#  F: file name
#  g: enumeration name
#  m: member (of structure or class data)
#  n: namespace
#  p: function prototype
#  s: structure name
#  t: typedef
#  u: union name
#  v: variable

class CTagsParser (ClassParserInterface):
    """ A class parser that uses ctags.
    
    Note that this is a very rough and hackish implementation.
    Feel free to improve it.
    
    See http://ctags.sourceforge.net for more information about exuberant ctags,
    and http://ctags.sourceforge.net/FORMAT for a description of the file format.
    """
    
    def __init__(self):
        self.location = None
        self.parse_all_files = False

    def parse(self, doc, location, model):
        self.location = location
        
        if os.system("ctags --version >/dev/null") != 0:
            model.append(None, "Please install ctags!", None, None, 1)
            return
        self._parse_doc_to_model(model)
        
    def _get_ctags_result(self, location):
        if location is None:
            return None
        # make sure this is a local file (ie. not via ftp or something)
        if not location.is_native():
            return None
        path = location.get_path()
        if not self.parse_all_files:
            args = [path]
        else:
            args = glob(os.path.join(os.path.dirname(path), '*.*'))
        result = subprocess.Popen(['ctags', '-n', '--langmap=c#:+.vala',
                                    '--fields=afks', '--sort=no', '-f', '-'] + args,
                                stdout=subprocess.PIPE).communicate()[0]
        return result
        
    def _parse_doc_to_model(self, model):
        """ Parse the given document and write the tags to a Gtk.TreeModel.
        
        The parser uses the ctags command from the shell to create a ctags file,
        then parses the file, and finally populates a treemodel. """
        result = self._get_ctags_result(self.location)
        if not result:
            return
            
        containers = []
        for tokens in result.splitlines():
            #name, filename, lineno, typecode, [extfields]
            tokens = tokens.split("\t")
            name_list = re.split(r'\W+', tokens[0])
            uri = Gio.File.new_for_path(tokens[1]).get_uri()
            lineno = int(tokens[2].rstrip(';"'))
            typechar = '' if len(tokens) <= 3 else tokens[3]
            typecode = self._typecodes.get(typechar, None)
            
            # parse extension fields
            access = ''
            parent = []
            for i in tokens[4:]:
                key, value = i.split(":", 1)
                if key == 'access':
                    if value == 'private':
                        access = '_priv'
                    elif value == 'protected':
                        access = '_prot'
                elif key == 'file':
                    access = '_priv'
                else:
                    parent = re.split(r'\W+', value)
            if typecode in ('class', 'enum', 'field', 'function', 'struct', 'union'):
                typecode += access
                
            while containers:
                if parent == containers[-1][0]:
                    titer = containers[-1][1]
                    break
                containers.pop()
            else:
                if not parent:
                    titer = None
                else:
                    # create a dummy element in case the parent doesn't exist
                    titer = model.append(None, parent[-1], None, uri, lineno)
                    containers.append((parent, titer))
                    
            titer = model.append(titer, tokens[0], typecode, uri, lineno)
            containers.append((parent + name_list, titer))
            
    _typecodes = {
            "c": "class", #class name
            "d": "define",
            "e": "enum", #enumerator
            "f": "function", #function or method name
            "p": "field",
            "g": "enum", #enumeration name
            "m": "field",
            "v": "field",
            "n": "namespace", #namespace
            "s": "struct", #structure name
            't': 'typedef',
            "u": "union", #union name
        }
        
        
register_parser(CTagsParser.__name__, CTagsParser, [None],
    'ctags Parser',
    '''The languages ​​are recognized by the file extension.
Recommended as the default parser.''')


