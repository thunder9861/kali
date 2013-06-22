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


import xml.parsers.expat

from . import ClassParserInterface, register_parser


class XMLParserExpat (ClassParserInterface):
    
    def parse(self, doc, location, model):
        self.model = model
        self.titers = [None]
        self.close_iter = None
        self.indent = False
        start, end = doc.get_bounds()
        self.uri = location and location.get_uri()
        
        self.parser = xml.parsers.expat.ParserCreate()
        self.parser.returns_unicode = False
        self.parser.buffer_text = False
        self.parser.StartElementHandler = self.handle_starttag
        self.parser.EndElementHandler = self.handle_endtag
        self.parser.DefaultHandler = self.handle_default
        try:
            self.parser.Parse(doc.get_text(start, end, True), True)
        except xml.parsers.expat.ExpatError as e:
            errorstring = xml.parsers.expat.ErrorString(self.parser.ErrorCode)
            self.model.append(None, errorstring, 'error', self.uri, e.lineno, e.offset)
            
    def handle_starttag(self, tag, attrs):
        tagstring = "<"+tag
        for name, value in attrs.items():
            if name in ['id', 'name', 'class']:
                tagstring += " {}={}".format(name, value)
        tagstring += ">"
        lineno = self.parser.CurrentLineNumber
        if self.indent:
            offset = 0
            self.indent = False
        else:
            offset = self.parser.CurrentColumnNumber
        titer = self.model.append(self.titers[-1], tagstring, None, self.uri, lineno, offset)
        self.titers.append(titer)
        
    def handle_endtag(self, tag):
        self.close_iter = self.titers.pop()
        lineno = self.parser.CurrentLineNumber
        offset = self.parser.CurrentColumnNumber
        
    def handle_default(self, data):
        lineno = self.parser.CurrentLineNumber
        offset = self.parser.CurrentColumnNumber
        if self.close_iter is not None:
            if data.endswith('\n'):
                self.model.set_end(self.close_iter, lineno+1)
            else:
                self.model.set_end(self.close_iter, lineno, offset)
            self.close_iter = None
        elif offset == 0 and data.isspace():
            self.indent = True
        else:
            self.indent = False
        
        
register_parser(XMLParserExpat.__name__, XMLParserExpat,
            ['docbook', 'mallard', 'xml', 'xslt'],
            'XML Parser')

