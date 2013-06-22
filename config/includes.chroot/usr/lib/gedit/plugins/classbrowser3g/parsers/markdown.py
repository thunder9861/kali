#!/usr/bin/python
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
import re

from . import ClassParserInterface, register_parser


class MarkdownParser (ClassParserInterface):
    re_list = re.compile(r'^(\s*)([*+-]|\d*\.)\s+(.*)$')
    re_hrule = re.compile(r'^[ ]{0,3}((-[ ]{0,2}){3,}|(\*[ ]{0,2}){3,})\s*$')
    
    def parse(self, doc, location, model):
        uri = location and location.get_uri()
        
        iters = [(None,0)]
        start, end = doc.get_bounds()
        lines = doc.get_text(start, end, True).splitlines()
        para = False
        
        for lineno, line in enumerate(lines):
            if not line or line.isspace():
                para = False
                continue
                
            if line.startswith('#'):
                depth = len(line) - len(line.lstrip('#'))
                line = line.strip('#').strip()
                style = None
            elif line.count('=') == len(line):
                if not para:
                    para = None
                    continue
                depth = 1
                lineno, line = para
                style = None
            elif line.count('-') == len(line):
                if not para:
                    para = None
                    continue
                depth = 2
                lineno, line = para
                style = None
            else:
                match = self.re_list.match(line)
                if match:
                    if self.re_hrule.match(line):
                        para = None
                        continue
                    depth, listmark, line = match.groups()
                    depth = len(depth) + 1000
                    line = ' '.join((listmark, line))
                    style = None
                else:
                    if para == False:
                        para = (lineno, line)
                    else:
                        para = None
                    continue
            para = None
            while iters[-1][1] >= depth:
                iters.pop()
            it = iters[-1][0]
            it = model.append(it, line, style, uri, lineno+1)
            iters.append((it, depth))
            
        
register_parser(MarkdownParser.__name__, MarkdownParser, ['markdown'], 'Markdown Parser')

