# -*- coding: utf-8 -*-

#  Copyright © 2012  B. Clausius <barcc@gmx.de>
#  Copyright © 2007  Frederic Back <fredericback@gmail.com>
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


import HTMLParser as htmlparser

from . import ClassParserInterface, register_parser


class CustomHTMLParser (htmlparser.HTMLParser):
    class Token (object):
        def __init__(self, tag, name, line, col, endline=0, endcol=0):
            self.tag = tag
            self.name = name
            self.startline = line
            self.startcol = col
            self.endline = endline
            self.endcol = endcol
            self.children = []
    
    def __init__(self):
        htmlparser.HTMLParser.__init__(self)
        self.opentags = [self.Token(None, None, 0, 0)]
        
    def handle_starttag(self, tag, attrs):
        tagstring = "<"+tag
        for name, value in attrs:
            if name in ['id', 'name', 'class', 'href']:
                tagstring += " %s=%s"%(name,value)
        tagstring += ">"
        lineno, offset = self.getpos()
        taglen = len(self.get_starttag_text())
        self.opentags.append(self.Token(tag, tagstring, lineno, offset, lineno, offset+taglen))
        
    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        token = self.opentags.pop()
        # close tag
        self.opentags[-1].children.append(token)
        
    def handle_endtag(self, tag):
        while len(self.opentags) > 1:
            token = self.opentags.pop()
            # close tag
            self.opentags[-1].children.append(token)
            if token.tag == tag:
                token.endline, token.endcol = self.getpos()
                if tag is not None:
                    token.endcol += len(tag) + 3
                break
            # unclosed tags have no children, so append them to parent
            self.opentags[-1].children += token.children
            token.children = []
            # try the next unclosed tag
            
            
class HTMLParser (ClassParserInterface):
    
    def parse(self, doc, location, model):
        parser = CustomHTMLParser()
        start, end = doc.get_bounds()
        uri = location and location.get_uri()
        error_row = None
        try:
            parser.feed(doc.get_text(start, end, True))
        except htmlparser.HTMLParseError as e:
            error_row = [e.msg, 'error', uri, e.lineno, e.offset]
        parser.handle_endtag(None)
        
        self._append_token_to_model(model, None, parser.opentags[0], uri)
        if error_row:
            model.append(None, *error_row)
        
    def _append_token_to_model(self, model, parent_iter, parent, uri):
        for token in parent.children:
            titer = model.append(parent_iter, token.name, None, uri,
                        token.startline, token.startcol, token.endline, token.endcol)
            self._append_token_to_model(model, titer, token, uri)
            
        
register_parser(HTMLParser.__name__, HTMLParser, ["html", "xml"], 'HTML Parser')

