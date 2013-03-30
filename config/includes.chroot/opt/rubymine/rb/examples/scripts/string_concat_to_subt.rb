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

require 'intention_action_helper'
import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.expressions.RMathBinExpressionImpl unless defined? RMathBinExpressionImpl
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.basicTypes.stringLiterals.RBaseStringImpl unless defined? RBaseStringImpl
import org.jetbrains.plugins.ruby.ruby.lang.lexer.RubyTokenTypes unless defined? RubyTokenTypes
import org.jetbrains.plugins.ruby.ruby.lang.psi.expressions.RBinaryExpression unless defined? RBinaryExpression


module SumToSubstitution

  def self.perform(context)
    expression = context.element_at_caret RMathBinExpressionImpl
    return if expression.nil?
    parent = expression.parent
    while parent.kind_of? RMathBinExpressionImpl
      expression = parent
      parent = parent.parent
    end

    replacement_text = calculate_replacement(expression)
    return if replacement_text.nil?
    new_element = RubyElementFactory.create_expression_from_text context.project, replacement_text
    context.action do
      expression.replace new_element
    end
  end

  def self.get_sum_arguments element
    if element.kind_of?(RMathBinExpressionImpl) and element.operation_type == RubyTokenTypes::tPLUS
      left_operand = element.left_operand
      right_operand = element.right_operand
      if left_operand && right_operand
        result = []
        # It is important to use + instead of << here!!!
        result += get_sum_arguments(left_operand)
        result += get_sum_arguments(right_operand)
        return result
      end
    end
    return [element]
  end

  def self.process_argument (arg, replacement)
    if arg.kind_of?(RBaseStringImpl)
      arg.psi_content.each do |child|
        replacement << child.text
      end
    else
      replacement << '#{' + arg.text + '}'
    end
  end

  def self.calculate_replacement(expression)
    replacement = ""
    args = get_sum_arguments(expression)
    args.each_with_index do |arg, index|
      return nil if (index == 0 && !arg.kind_of?(RBaseStringImpl))
      process_argument(arg, replacement)
    end
    return '"' + replacement + '"'
  end
end

register_intention_action "Convert concatenation of strings to substitutions \#{}",
                          :category => "Ruby",
                          :description => "Converts concatenations of strings to a single one with substitutions \#{}",
                          :before => '"Hello Mr." + @name + "! Welcome to RubyMine!"',
                          :after => '"Hello Mr.#{@name}! Welcome to RubyMine!"' do |context|
  SumToSubstitution::perform(context)
end