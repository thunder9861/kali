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

require File.dirname(__FILE__) + '/../util/execute_helper'
require File.dirname(__FILE__) + '/../util/editor_wrapper'

import org.jetbrains.plugins.ruby.ruby.actions.editor.handlers.RubyScriptTypedHandler unless defined? RubyScriptTypedHandler
import org.jetbrains.plugins.ruby.ruby.actions.editor.handlers.RubyScriptProvidedTypedHandler unless defined? RubyScriptProvidedTypedHandler

class RubyScriptHandlerImpl
  include RubyScriptTypedHandler

  def initialize(lambda)
    @lambda = lambda
  end

  def apply(c, project, editor, file)
    @lambda.call(c, project, EditorWrapper.new(editor), file)
  end
end


# lambda here has parameters: c, project, editor, file
# lambda -> true | false
def register_typed_action lambda
  RubyScriptProvidedTypedHandler.register_script_typed_handler RubyScriptHandlerImpl.new(lambda)
end

