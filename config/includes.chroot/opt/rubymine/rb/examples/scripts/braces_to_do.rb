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

import org.jetbrains.plugins.ruby.ruby.lang.psi.iterators.RBraceCodeBlock unless defined? RBraceCodeBlock
import org.jetbrains.plugins.ruby.ruby.lang.psi.iterators.RDoCodeBlock unless defined? RDoCodeBlock
import org.jetbrains.plugins.ruby.ruby.lang.psi.iterators.RBlockCall unless defined? RBlockCall
import org.jetbrains.plugins.ruby.ruby.lang.documentation.RubyCommentsUtil unless defined? RubyCommentsUtil
import org.jetbrains.plugins.ruby.ruby.lang.psi.methodCall.RCall unless defined? RCall

module BraceConvert

  def self.can_convert(block)
    return false if block.is_a?(RBraceCodeBlock) && block.parent.parent.parent.kind_of?(RCall)
    return false if block.is_a?(RDoCodeBlock) && block.compound_statement.statements.size > 1
    return true
  end

  def self.create_block_text(block, body_builder)
    block_vars_text = ""
    if block.block_variables
      block_vars_text = "|" + block.block_variables.text + "|"
    end
    compound_statement = block.compound_statement
    help = RubyCommentsUtil.get_psi_help compound_statement
    body_text = help ? "#{help}\n#{compound_statement.text}" : compound_statement.text
    block_text = body_builder.call(block_vars_text, body_text)
    block_text
  end

  def self.replace_block(context, block_type, &body_builder)
    block = context.element_at_caret(block_type)
    if not block
      block_call = context.element_at_caret(RBlockCall)
      block = block_call.block if block_call and block_call.block.is_a? block_type
    end
    if block and can_convert(block) && context.file.view_provider.languages.size == 1
      context.action do
        block_text = create_block_text(block, body_builder)
        call = block.parent.get_call
        # Replace call with parens call in case of brace block call
        if block_type == RDoCodeBlock
          if call.kind_of? RCall
            new_call_text = call.psi_command.text + "(" + call.call_arguments.text + ")"
            new_call = RubyElementFactory.createExpressionFromText(context.project, new_call_text, call.getLanguageLevel)
            call.replace new_call
          end
        end
        new_block = RubyElementFactory.createCodeBlockFromText(context.project, block_text, call.getLanguageLevel)
        block.replace new_block
      end
    end
  end
end

register_intention_action "Convert { } to 'do' block",
                          :category => "Ruby",
                          :description => "Converts a { } block to a 'do' block",
                          :before => "[].each { |e| puts e }",
                          :after => "[].each do |e|\n  puts e\nend" do |context|
  BraceConvert::replace_block(context, RBraceCodeBlock) { |vars, statements|  "do #{vars}\n#{statements}\nend" }
end

register_intention_action "Convert 'do' block to { }",
                          :category => "Ruby",
                          :description => "Converts a 'do' block to a '{ }' block",
                          :before => "[].each do |e|\n  puts e\nend" ,
                          :after => "[].each { |e| puts e }" do |context|
  BraceConvert::replace_block(context, RDoCodeBlock) { |vars, statements| "{ #{vars} #{statements} }" }
end
