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

import com.intellij.codeInsight.intention.IntentionAction unless defined? IntentionAction
import com.intellij.codeInsight.intention.IntentionManager unless defined? IntentionManager
import org.jetbrains.plugins.ruby.ruby.lang.psi.RubyElementFactory unless defined? RubyElementFactory

require File.dirname(__FILE__) + '/../util/psi_helper'

class IntentionContext
  def initialize(project, editor, file)
    @project = project
    @editor = editor
    @file = file
  end

  attr_reader :project, :editor, :file

  def element_at_caret(cls=nil)
    PsiHelper.get_element_at @editor, @file, cls
  end

  def create_element(text)
    RubyElementFactory.create_element_from_text @file, text
  end
end

class CheckAvailableContext < IntentionContext
  def initialize(project, editor, file)
    super
    @available = false
  end

  attr_reader :available

  def action(&block)
    @available = true
  end
end

class ExecuteContext < IntentionContext
  def action(&block)
    block.call
  end
end

class RubyIntentionAction
  import com.intellij.refactoring.util.CommonRefactoringUtil unless defined? CommonRefactoringUtil
  include IntentionAction
  
  def initialize(name, block)
    @name = name
    @block = block
  end

  def getText()
    @name
  end

  def getFamilyName()
    @name
  end

  def isAvailable(project, editor, file)
    context = CheckAvailableContext.new(project, editor, file)
    begin
      @block.call context
    rescue com.intellij.openapi.progress.ProcessCanceledException
      return false
    end
    context.available
  end

  def invoke(project, editor, file)
    CommonRefactoringUtil.check_read_only_status project, file
    @block.call ExecuteContext.new(project, editor, file)
  end

  def startInWriteAction()
    false
  end
end

def register_intention_action(name, options, &block)
  action = RubyIntentionAction.new name, block
  if options.has_key? :category
    categories = [options[:category]]
  else
    categories = []
  end
  description = options[:description]
  if options.has_key? :before
    example_before = [options[:before]].to_java(:'java.lang.String')
    example_after = [options[:after]].to_java(:'java.lang.String')
  else
    example_before = [].to_java(:'java.lang.String')
    example_after = [].to_java(:'java.lang.String')
  end

  IntentionManager.get_instance.register_intention_and_meta_data action, categories.to_java(:'java.lang.String'),
          description, "rb", example_before, example_after
end
