# -*- coding: utf-8 -*-

#  Copyright © 2012  B. Clausius <barcc@gmx.de>
#  Copyright © 2007  Kristoffer Lundén <kristoffer.lunden@gmail.com>
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

from . import ClassParserInterface, register_parser


class Token:
    def __init__(self):
        self.name = None
        self.name2 = None
        self.type = None
        self.start = 0
        self.end = 0
        self.children = []


class DiffParser(ClassParserInterface):
    
    def parse(self, doc, location, model):
        start, end = doc.get_bounds()
        text = doc.get_text(start, end, True)
        linecount = 0
        current_file = None
        changeset = None
        files = []
        uri = location and location.get_uri()
        
        for line in text.splitlines():
            linecount += 1
            line = line.split(None, 1) or [line]
            if line[0] == '---' and len(line) == 2:
                current_file = Token()
                changeset = None
                current_file.name = line[1]
                current_file.start = linecount
                current_file.type = 'file'
                files.append(current_file)
            elif current_file is None:
                continue
            elif line[0] == '+++' and len(line) == 2:
                current_file.name2 = line[1]
            elif current_file.name2 is None:
                pass
            elif line[0] == '@@' and len(line) == 2:
                changeset = Token()
                changeset.name = line[1].rstrip('@@').rstrip()
                changeset.start = linecount
                current_file.children.append(changeset)
                        
            # Ending line
            current_file.end = linecount + 1
            if changeset is not None:
                changeset.end = linecount + 1
        
        piter = None
        # "Fake" common top folder, if any
        # TODO: Create hierarchy if patch applies in multiple directories
        if len(files) > 0:
            paths = map(lambda f:f.name, files)
            prefix = os.path.dirname(os.path.commonprefix(paths)) + '/'
            if len(prefix) > 1:
                parent = Token()
                parent.type = 'directory'
                parent.name = prefix
                for f in files:
                    f.name = f.name.replace(prefix, '', 1)
                piter = model.append(None, parent.name, parent.type, None,
                                            parent.start, 0, parent.end, 0)
                
        # Build tree
        for f in files:
            titer = model.append(piter, f.name, f.type, uri, f.start, 0, f.end, 0)
            for c in f.children:
                model.append(titer, c.name, c.type, uri, c.start, 0, c.end, 0)
                
        
register_parser(DiffParser.__name__, DiffParser, ["diff"], 'Diff Parser')

