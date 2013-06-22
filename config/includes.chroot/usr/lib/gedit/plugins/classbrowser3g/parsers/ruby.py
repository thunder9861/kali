# -*- coding: utf-8 -*-

#  Copyright © 2012  B. Clausius <barcc@gmx.de>
#  Copyright © 2007  Kristoffer Lundén <kristoffer.lunden@gmail.com>
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


import os
import re

from . import ClassParserInterface, register_parser


def tokenFromString(string):
    """ Parse a string containing a function or class definition and return
        a tuple containing information about the function, or None if the
        parsing failed.

        Example: 
            "#def foo(bar):" would return :
            {'comment':True,'type':"def",'name':"foo",'params':"bar" } """

    try:
        e = r"([# ]*?)([a-zA-Z0-9_]+)( +)([a-zA-Z0-9_\?\!<>\+=\.]+)(.*)"
        r = re.match(e,string).groups()
        token = Token()
        token.comment = '#' in r[0]
        token.type = r[1]
        token.name = r[3]
        token.params = r[4]
        token.original = string
        return token
    except: return None # return None to skip if unable to parse
    
    def test():
        pass


class Token:
    def __init__(self):
        self.type = None
        self.original = None # the line in the file, unparsed

        self.indent = 0
        self.name = None
        self.comment = False # if true, the token is commented, ie. inactive
        self.params = None   # string containing additional info
        self.expanded = False

        self.access = "public"

        # start and end points
        self.start = 0
        self.end = 0

        self.rubyfile = None

        self.parent = None
        self.children = []

    def get_endline(self):
        """ Get the line number where this token's declaration, including all
            its children, finishes. Use it for copy operations."""
        if len(self.children) > 0:
            return self.children[-1].get_endline()
        return self.end

        def test_nested():
            pass
            
    def get_toplevel_class(self):
        """ Try to get the class a token is in. """
        if self.type == "class":
            return self    
        if self.parent is not None:
            tc = self.parent.get_toplevel_class()
            if tc is None or tc.type == "file": return self #hack
            else: return tc
                
        return None

    def printout(self):
        for r in range(self.indent): print "",
        print self.name,
        if self.parent: print " (parent: ",self.parent.name       
        else: print
        for tok in self.children: tok.printout()


class RubyFile(Token):
    """ A class that represents a ruby file.
        Manages "tokens", ie. classes and functions."""

    def __init__(self, doc):
        Token.__init__(self)
        self.doc = doc
        self.uri = doc.get_location().get_uri()
        self.linestotal = 0 # total line count
        self.type = "file"
        if self.uri:
            self.name = os.path.basename(self.uri)
        self.tokens = []

    def getTokenAtLine(self, line):
        """ get the token at the specified line number """
        for token in self.tokens:
            if token.start <= line and token.end > line:
                return self.__findInnermostTokenAtLine(token, line)
        return None

    def __findInnermostTokenAtLine(self, token, line):
        """" ruby is parsed as nested, unlike python """
        for child in token.children:
            if child.start <= line and child.end > line:
                return self.__findInnermostTokenAtLine(child, line)
        return token

    def parse(self):
        newtokenlist = []

        self.children = []

        currentParent = self

        self.linestotal = self.doc.get_line_count()

        start, end = self.doc.get_bounds()
        text = self.doc.get_text(start, end, True)
        linecount = -1
        ends_to_skip = 0
        
        access = "public"
        
        for line in text.splitlines():
            linecount += 1
            lstrip = line.lstrip()
            ln = lstrip.split()
            if len(ln) == 0: continue
            if ln[0] == '#': continue
            
            if ln[0] in ("class","module","def"):
                token = tokenFromString(lstrip)
                if token is None: continue
                token.rubyfile = self
                token.start = linecount
                if token.type == "def":
                    token.access = access
                    
                currentParent.children.append(token)
                token.parent = currentParent
                currentParent = token
                newtokenlist.append(token)
                
                idx = len(newtokenlist) - 1
                if idx < len(self.tokens):
                    if newtokenlist[idx].original == self.tokens[idx].original:
                        newtokenlist[idx].expanded = self.tokens[idx].expanded
                
            elif ln[0] in("begin","while","until","case","if","unless","for"):
                    ends_to_skip += 1
                    
            elif ln[0] in ("attr_reader","attr_writer","attr_accessor"):
                for attr in ln:
                    m = re.match(r":(\w+)",attr)
                    if m:
                        token = Token()
                        token.rubyfile = self
                        token.type = 'def'
                        token.name = m.group(1)
                        token.start = linecount
                        token.end = linecount
                        token.original = lstrip
                        currentParent.children.append(token)
                        token.parent = currentParent
                        newtokenlist.append(token)
            
            elif re.search(r"\sdo(\s+\|.*?\|)?\s*(#|$)", line):
                # Support for new style RSpec
                if re.match(r"^(describe|it|before|after)\b", ln[0]):
                    token = Token()
                    token.rubyfile = self
                    token.start = linecount
                    
                    if currentParent.type == "describe":                    
                        if ln[0] == "it":
                            token.name = " ".join(ln[1:-1])
                        else:
                            token.name = ln[0]
                        token.type = "def"
                    elif ln[0] == "describe":
                        token.type = "describe"
                        token.name = " ".join(ln[1:-1])
                    else:
                        continue
                    currentParent.children.append(token)
                    token.parent = currentParent
                    currentParent = token
                    newtokenlist.append(token)

                # Deprectated support for old style RSpec, will be removed later
                elif ln[0] in ("context","specify","setup","teardown","context_setup","context_teardown"):
                    token = Token()
                    token.rubyfile = self
                    token.start = linecount
                    
                    if currentParent.type == "context":                    
                        if ln[0] == "specify":
                            token.name = " ".join(ln[1:-1])
                        else:
                            token.name = ln[0]
                        token.type = "def"
                    elif ln[0] == "context":
                        token.type = "context"
                        token.name = " ".join(ln[1:-1])
                    else:
                        continue
                    currentParent.children.append(token)
                    token.parent = currentParent
                    currentParent = token
                    newtokenlist.append(token)
                else:
                    ends_to_skip += 1
                
            elif ln[0] in ("public","private","protected"):
                if len(ln) == 1:
                    access = ln[0]
                    
            if re.search(r";?\s*end(?:\s*$|\s+(?:while|until))", line):
                if ends_to_skip > 0:
                    ends_to_skip -= 1
                else:
                    token = currentParent
                    #print "end",currentParent.name
                    token.end = linecount
                    if token.parent:
                        currentParent = token.parent
                
        # set new token list
        self.tokens = newtokenlist
        return True


class RubyParser (ClassParserInterface):
    def __init__(self):
        self.rubyfile = None

    def appendTokenToBrowser(self, model, token, parentit):
        name, style = self._get_values(token)
        it = model.append(parentit, name, style, token.rubyfile.uri, token.start+1)
        for child in token.children:
            self.appendTokenToBrowser(model, child, it)

    def parse(self, doc, location, model):
        self.rubyfile = RubyFile(doc)
        self.rubyfile.parse()
        for child in self.rubyfile.children:
            self.appendTokenToBrowser(model, child, None)
        
    def _get_values(self, token):
        name = token.name
        if token.type == "class":
            name = "class "+name
            style = "class"
        elif token.type == "module":
            name = "module "+name
            style = "namespace"
        elif token.type == "describe": # new style RSpec
            name = "describe "+name
            style = "namespace"
        elif token.type == "context": # Old style RSpec, deprecated
            name = "context "+name
            style = "namespace"
        elif token.type == "def":
            if token.access == "public":
                style = "function"
            elif token.access == "protected":
                style = "function_prot"
            elif token.access == "private":
                style = "function_priv"
        else:
            style = None
        if token.comment:
            name = "#"+name
        return name, style
        
        
register_parser(RubyParser.__name__, RubyParser, ['ruby'], 'Ruby Parser',
'''Simple parser using regular expressions''')

