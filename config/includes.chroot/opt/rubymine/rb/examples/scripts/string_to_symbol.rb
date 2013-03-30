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

import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.RBaseString unless defined? RBaseString
import org.jetbrains.plugins.ruby.ruby.lang.TextUtil unless defined? TextUtil

register_intention_action "Convert string to symbol",
                          :category => "Ruby",
                          :description => "Converts a string into a symbol with the same text.",
                          :before => "puts <spot>\"Foo\"</spot>",
                          :after => "puts :Foo" do |context|
  s = context.element_at_caret(RBaseString)
  if not s.nil? and not s.has_expression_substitutions and TextUtil.isCID s.content
    context.action do
      s.replace context.create_element(":#{s.content}")
    end
  end
end
