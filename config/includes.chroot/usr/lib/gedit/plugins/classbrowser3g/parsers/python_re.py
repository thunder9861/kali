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


import os
import re

from . import ClassParserInterface, register_parser


def functionTokenFromString(string):
    """ Parse a string containing a function or class definition and return
        a tuple containing information about the function, or None if the
        parsing failed.

        Example:
            "#def foo(bar):" would return :
            {'comment':True,'type':"def",'name':"foo",'params':"bar" } """

    e = r"([# ]*?)([a-zA-Z0-9_]+)( +)([a-zA-Z0-9_]+)(.*)"
    try:
        r = re.match(e, string).groups()
    except AttributeError:
        return None # return None to skip if unable to parse
    token = Token()
    token.comment = '#' in r[0]
    token.type = r[1]
    token.name = r[3]
    token.params = r[4]
    token.original = string
    return token


class Token(object):
    """ Rules:
            type "attribute" may only be nested to "class"
    """

    def __init__(self):
        self.type = None # "attribute", "class" or "function"
        self.original = None # the line in the file, unparsed

        self.indent = 0
        self.name = None
        self.comment = False # if true, the token is commented, ie. inactive
        self.params = None   # string containing additional info
        self.expanded = False

        # start and end points (line number)
        self.start = 0
        self.end = 0

        self.pythonfile = None

        self.parent = None
        self.children = [] # a list of nested tokens
        self.attributes = [] # a list of class attributes
        
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
            if tc is None or tc.type == "file":
                return self #hack
            else:
                return tc
        return None

    def printout(self):
        for r in range(self.indent): print "",
        print self.name,
        if self.parent:
            print " (parent: ",self.parent.name
        else:
            print
        for tok in self.children:
            tok.printout()


class PythonFile(Token):
    """ A class that represents a python file.
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
                return token
        return None

    def parse(self):
        newtokenlist = []
        indent = 0
        lastElement = None
        self.children = []
        lastToken = None
        indentDictionary = { 0: self, } # indentation level: token
        self.linestotal = self.doc.get_line_count()
        start, end = self.doc.get_bounds()
        text = self.doc.get_text(start, end, True)
        linecount = -1
        for line in text.splitlines():
            linecount += 1
            lstrip = line.lstrip()
            ln = lstrip.split()
            if len(ln) == 0: continue

            if ln[0] in ("class","def","#class","#def"):
                token = functionTokenFromString(lstrip)
                if token is None: continue
                token.indent = len(line)-len(lstrip)
                token.pythonfile = self
                
                token.original = line

                # set start and end line of a token. The end line will get set
                # when the next token is parsed.
                token.start = linecount
                if lastToken: lastToken.end = linecount
                newtokenlist.append(token)

                if token.indent == indent:
                    # as deep as the last row: append the last e's parent
                    if lastToken: p = lastToken.parent
                    else: p = self
                    p.children.append(token)
                    token.parent = p
                    indentDictionary[ token.indent ] = token
                elif token.indent > indent:
                    # this row is deeper than the last, use last e as parent
                    if lastToken: p = lastToken
                    else: p = self
                    p.children.append(token)
                    token.parent = p
                    indentDictionary[ token.indent ] = token
                elif token.indent < indent:
                    # this row is shallower than the last
                    if token.indent in indentDictionary.keys():
                        p = indentDictionary[ token.indent ].parent
                    else: p = self
                    if p == None: p = self # might happen with try blocks
                    p.children.append(token)
                    token.parent = p

                idx = len(newtokenlist) - 1
                if idx < len(self.tokens):
                    if newtokenlist[idx].original == self.tokens[idx].original:
                        newtokenlist[idx].expanded = self.tokens[idx].expanded
                lastToken = token
                indent = token.indent

            # not a class or function definition
            else:
                # check for class attributes, append to last class in last token
                try:
                    # must match "self.* ="
                    if ln[0][:5] == "self." and ln[1] == "=":
                        # make sure there is only one dot in the declaration
                        # -> attribute is direct descendant of the class
                        if lastToken and ln[0].count(".") == 1:
                            attr = ln[0].split(".")[1]
                            self.__appendClassAttribute(lastToken,attr,linecount)
                except IndexError:
                    pass

        # set the ending line of the last token
        if len(newtokenlist) > 0:
            newtokenlist[ len(newtokenlist)-1 ].end = linecount + 2 # don't ask

        # set new token list
        self.tokens = newtokenlist
        return True

    def __appendClassAttribute(self, token, attrName, linenumber):
        """ Append a class attribute to the class a given token belongs to. """
        # get next parent class
        while token.type != "class":
            token = token.parent
            if not token: return
        # make sure attribute is not set yet
        for i in token.attributes:
            if i.name == attrName:
                return
        # append a new attribute
        attr = Token()
        attr.type = "attribute"
        attr.name = attrName
        attr.start = linenumber
        attr.end = linenumber
        attr.pythonfile = self
        token.attributes.append(attr)
        

class PythonParserRe (ClassParserInterface):
    """ A class parser that uses ctags.
    
    Note that this is a very rough and hackish implementation.
    Feel free to improve it.
    
    See http://ctags.sourceforge.net for more information about exuberant ctags,
    and http://ctags.sourceforge.net/FORMAT for a description of the file format.
    """
    
    def __init__(self):
        self.pythonfile = None
    
    def get_values(self, tok):
        name = tok.name
        style = "function"
        
        # set label and color
        if tok.type == "class":
            name = "class " + name + tok.params
            style = "class"
        elif tok.type == "attribute":
            if tok.name[:2] == "__":
                style = "field_priv"
            elif tok.name.startswith("_"):
                style = "field_prot"
            else:
                style = "field"
        elif tok.parent:
            if tok.parent.type == "class":
                if tok.name[:2] == "__":
                    style = "function_priv"
                elif tok.name[0] == "_":
                    style = "function_prot"
                else:
                    style = "function"
        if tok.comment:
            name = "#" + name
        uri = tok.pythonfile and tok.pythonfile.uri
        return name, style, uri, tok.start+1
        
    def append_token(self, model, token, parent_iter):
        name, style, uri, line = self.get_values(token)
        titer = model.append(parent_iter, name, style, uri, line)
        
        # add special subtree for attributes
        if len(token.attributes) > 0:
            holder = Token()
            holder.name = "Attributes"
            holder.type = "attribute"
            name, style, uri, line = self.get_values(holder)
            titer2 = model.append(titer, name, style, uri, line)
            
            for child in token.attributes   :
                name, style, uri, line = self.get_values(child)
                model.append(titer2, name, style, uri, line)
        
        for child in token.children:
            self.append_token(model, child, titer)

    def parse(self, doc, location, model):
        self.pythonfile = PythonFile(doc)
        self.pythonfile.parse()
        for child in self.pythonfile.children:
            self.append_token(model, child, None)
        
        
register_parser(PythonParserRe.__name__, PythonParserRe, ['python'], 'Python Parser (re)',
'''Simple parser using regular expressions''')


