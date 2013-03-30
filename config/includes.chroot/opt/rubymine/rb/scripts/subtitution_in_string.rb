#
# Copyright 2000-2009 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Java

require 'typed_action_helper.rb'
require File.expand_path(File.dirname(__FILE__) + '/../util/psi_helper')

import org.jetbrains.plugins.ruby.ruby.lang.TextUtil unless defined? TextUtil
import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
import org.jetbrains.plugins.ruby.ruby.lang.lexer.RubyTokenTypes unless defined? RubyTokenTypes
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.basicTypes.stringLiterals.baseString.RDStringLiteralImpl unless defined? RDStringLiteralImpl
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.basicTypes.stringLiterals.xString.RDXStringLiteralImpl unless defined? RDXStringLiteralImpl
import org.jetbrains.plugins.ruby.ruby.lang.psi.expressions.RExpression unless defined? RExpression
import org.jetbrains.plugins.ruby.ruby.lang.parser.bnf.TokenBNF unless defined? TokenBNF

register_typed_action lambda { |character, project, editor, file|
  return false unless character == ?# && editor.has_selection?

  start_element = file.find_element_at(editor.selection_start)
  end_element = file.find_element_at(editor.selection_end - 1)

  return false if (start_element.nil? || end_element.nil?)

  parent = start_element.parent

  return false unless (parent.kind_of?(RDStringLiteralImpl) ||
                      parent.kind_of?(RDXStringLiteralImpl) ||
                      parent.kind_of?(RExpression))

  if start_element && end_element
    start_in_string = is_string_content(start_element)
    end_in_string = is_string_content(end_element)

    # if two selection is inside string literal
    if start_element.parent == end_element.parent
      if start_in_string && end_in_string
        editor.insert_text '#{' + editor.selection + '}'
        return true
      end
    end
    # otherwise if both selection aren't in string
    if !start_in_string && !is_string_content(end_element)
      editor.insert_text '"#{' + editor.selection + '}"'
      return true
    end
  end

  return false
}

def is_string_content element
  element_type = element.node.element_type
  TokenBNF::tSTRING_LIKE_CONTENTS.contains(element_type) ||
          element_type == RubyTokenTypes::tSTRING_END ||
          element_type == RubyTokenTypes::tREGEXP_END ||
          element_type == RubyTokenTypes::tWORDS_END
end