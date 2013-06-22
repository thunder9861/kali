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


import ast

from . import ClassParserInterface, register_parser


class Visitor (ast.NodeVisitor):
    def __init__(self, uri, model):
        self.uri = uri
        self.model = model
        self.titer = None
        self.import_iter = None
        self.in_function = False
        self.in_assign = False
        self.instance_attrs = []
        self.unclosed_iters = []
        
    @staticmethod
    def _typecode_access(typecode, name):
        if name.startswith('__') and not name.endswith('__'):
            return typecode + '_priv'
        if name.startswith('_'):
            return typecode + '_prot'
        return typecode
        
    def close_iters(self, node):
        while self.unclosed_iters:
            citer = self.unclosed_iters.pop()
            if self.model.get_startline(citer) == node.lineno:
                self.model.set_end(citer, node.lineno, node.col_offset)
            else:
                self.model.set_end(citer, node.lineno)
                
    def visit(self, node):
        if not self.in_assign:
            self.close_iters(node)
        ast.NodeVisitor.visit(self, node)
        
    @classmethod
    def str_attribute(cls, node):
        if isinstance(node, ast.Name):
            return node.id
        if isinstance(node, ast.Attribute):
            return cls.str_attribute(node.value) + '.' + node.attr
        return '?'
        
    @classmethod
    def str_decorator(cls, node):
        if isinstance(node, ast.Name):
            return node.id
        if isinstance(node, ast.Attribute):
            return cls.str_attribute(node)
        if isinstance(node, ast.Call):
            return cls.str_decorator(node.func) + '()'
        return '?'
        
    def visit_Name(self, node):
        if self.in_assign and not self.in_function:
            typecode = self._typecode_access('field', node.id)
            if self.unclosed_iters:
                self.close_iters(node)
                col_offset = node.col_offset
            else:
                col_offset = 0
            citer = self.model.append(self.titer, node.id, typecode, self.uri,
                                                    node.lineno, col_offset)
            self.unclosed_iters.append(citer)
    def visit_Attribute(self, node):
        if (self.in_assign and self.in_function and isinstance(node.value, ast.Name)
                and node.value.id == 'self' and node.attr not in self.instance_attrs):
            self.instance_attrs.append(node.attr)
            typecode = self._typecode_access('field', node.attr)
            if self.unclosed_iters:
                self.close_iters(node)
                col_offset = node.col_offset
            else:
                col_offset = 0
            citer = self.model.append(self.titer, node.attr, typecode, self.uri,
                                                    node.lineno, col_offset)
            self.unclosed_iters.append(citer)
    def visit_Assign(self, node):
        self.in_assign = True
        for n in node.targets:
            self.visit(n)
        self.in_assign = False
        
    def visit_FunctionDef(self, node):
        self.import_iter = None
        in_function = self.in_function
        self.in_function = True
        
        if node.decorator_list:
            decorator_list = ' '.join([self.str_decorator(n) for n in node.decorator_list])
            name = '%s @%s' % (node.name, decorator_list)
        else:
            name = node.name
        titer = self.titer
        typecode = self._typecode_access('function', node.name)
        self.titer = citer = self.model.append(self.titer, name, typecode, self.uri, node.lineno)
        for body in node.body:
            self.visit(body)
            
        self.unclosed_iters.append(citer)
        self.titer = titer
        self.in_function = in_function
        
    def visit_ClassDef(self, node):
        self.import_iter = None
        instance_attrs = self.instance_attrs
        self.instance_attrs = []
        in_function = self.in_function
        self.in_function = False
        
        if node.bases:
            bases = ','.join([self.str_attribute(b) for b in node.bases])
            name = '%s (%s)' % (node.name, bases)
        else:
            name = node.name
        titer = self.titer
        typecode = self._typecode_access('class', node.name)
        self.titer = citer = self.model.append(self.titer, name, typecode, self.uri, node.lineno)
        for body in node.body:
            self.visit(body)
            
        self.unclosed_iters.append(citer)
        self.titer = titer
        self.instance_attrs = instance_attrs
        self.in_function = in_function
        
    def visit_Import(self, node):
        for alias in node.names:
            if not self.import_iter:
                self.import_iter = self.model.append(self.titer,
                                    'import', 'namespace', self.uri, node.lineno)
            module = '%s (%s)'%(alias.asname, alias.name) if alias.asname else alias.name
            citer = self.model.append(self.import_iter,
                                    module, 'namespace', self.uri, node.lineno)
            self.unclosed_iters.append(citer)
        if self.import_iter:
            self.unclosed_iters.append(self.import_iter)
    def visit_ImportFrom(self, node):
        for alias in node.names:
            level = '.' * (node.level or 0)
            if not self.import_iter:
                self.import_iter = self.model.append(self.titer,
                                'import', 'namespace', self.uri, node.lineno, 0, node.lineno+1, 0)
            module = ('%s (%s%s.%s)'%(alias.asname, level, node.module or '', alias.name)
                if alias.asname else '%s (from %s%s)'%(alias.name, level, node.module or ''))
            citer = self.model.append(self.import_iter,
                                module, 'namespace', self.uri, node.lineno)
            self.unclosed_iters.append(citer)
        if self.import_iter:
            self.unclosed_iters.append(self.import_iter)
            
            
class PythonParserAst (ClassParserInterface):
    def parse(self, doc, location, model):
        start, end = doc.get_bounds()
        text = doc.get_text(start, end, True)
        uri = location and location.get_uri()
        
        try:
            root = ast.parse(text)
        except Exception, e:
            model.append(None, str(e), 'error', uri, e.lineno or 0)
        else:
            visitor = Visitor(uri, model)
            visitor.visit(root)
        
        
register_parser(PythonParserAst.__name__, PythonParserAst, ['python'], 'Python Parser (ast)',
'''Parser using the python ast module''')

