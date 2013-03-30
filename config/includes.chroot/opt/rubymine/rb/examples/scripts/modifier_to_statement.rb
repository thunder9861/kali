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

import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.modifierStatements.RModifierStatement unless defined? RModifierStatement
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.RIfStatement unless defined? RIfStatement
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.RUnlessStatement unless defined? RUnlessStatement

module ModifierConvert
  def self.get_statement_to_convert(context)
    if_stmt = context.element_at_caret RIfStatement
    if if_stmt and if_stmt.elsif_blocks.size == 0 and if_stmt.else_block.nil?
      return if_stmt, "if", if_stmt.then_block
    end

    unless_stmt = context.element_at_caret RUnlessStatement
    if unless_stmt and unless_stmt.else_block.nil?
      return unless_stmt, "unless", unless_stmt.then_block
    end

    return nil, nil, nil
  end
end

register_intention_action "Convert modifier to statement",
                          :category => "Ruby",
                          :description => "Converts an 'if' or 'unless' modifier to the corresponding statement",
                          :before => "puts e if a",
                          :after => "if a\n  puts e\nend" do |context|
  stmt = context.element_at_caret RModifierStatement
  if stmt && context.file.view_provider.languages.size == 1

    context.action do
      text = "#{stmt.modifier_keyword.text} #{stmt.condition.text}\n  #{stmt.command.text}\nend"
      stmt.replace context.create_element(text)
    end
  end
end

register_intention_action "Convert statement to modifier",
                          :category => "Ruby",
                          :description => "Converts an 'if' or 'unless' statement to the corresponding modifier",
                          :before => "if a\n  puts e\nend",
                          :after => "puts e if a" do |context|
  stmt, keyword, body = ModifierConvert::get_statement_to_convert context
  if keyword and body.statements.size == 1 && context.file.view_provider.languages.size == 1
    context.action do
      text = body.statements[0].text + " " + keyword + " " + stmt.condition.text
      stmt.replace context.create_element(text)
    end
  end
end