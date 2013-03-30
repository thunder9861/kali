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

require File.expand_path(File.dirname(__FILE__) + '/../util/execute_helper')
require File.expand_path(File.dirname(__FILE__) + "/../util/editor_wrapper")
require File.expand_path(File.dirname(__FILE__) + "/../util/an_action_util")

import com.intellij.openapi.actionSystem.AnAction unless defined? AnAction
import com.intellij.openapi.actionSystem.ActionManager unless defined? ActionManager
import com.intellij.openapi.actionSystem.impl.ActionManagerImpl unless defined? ActionManagerImpl
import com.intellij.openapi.actionSystem.ex.ActionManagerEx unless defined? ActionManagerEx
import com.intellij.openapi.actionSystem.PlatformDataKeys unless defined? PlatformDataKeys
import com.intellij.openapi.actionSystem.LangDataKeys unless defined? LangDataKeys
import com.intellij.openapi.actionSystem.KeyboardShortcut unless defined? KeyboardShortcut
import com.intellij.openapi.keymap.KeymapManager unless defined? KeymapManager
import com.intellij.openapi.actionSystem.Constraints unless defined? Constraints
import com.intellij.refactoring.util.CommonRefactoringUtil unless defined? CommonRefactoringUtil

class RubyEditorAction < AnAction
  def initialize(id, options)
    super(options[:text], options[:description], nil)
    @id = id
    file_types = options[:file_type]
    @file_types = case file_types
      when Array
        file_types
      when String
       [file_types]
      else
       nil
    end
    @block = options[:block]
    # enable in Modal dialogs, e.g. rename refactoring dialog, search, etc.
    setEnabledInModalContext(true) if options[:enable_in_modal_context]
  end

  def action_id()
    @id
  end

  def actionPerformed(e)
    project = e.get_data PlatformDataKeys::PROJECT
    editor = e.get_data PlatformDataKeys::EDITOR
    file = e.get_data LangDataKeys::PSI_FILE
    ExecuteHelper.run_as_command_in_write_action(project, @id) do
      if file
        CommonRefactoringUtil.check_read_only_status project, file
      end
      
      @block.call EditorWrapper.new(editor), file
    end
  end

  def update(e)
    project = e.get_data PlatformDataKeys::PROJECT
    editor = e.get_data PlatformDataKeys::EDITOR
    file = e.get_data LangDataKeys::PSI_FILE
    e.presentation.enabled = is_enabled(project,editor,file)
  end

  def is_enabled(project, editor, file)
    if project.nil? or editor.nil?
      return false
    end
    unless @file_types.nil?
      return false if file.nil?
      return false unless @file_types.inject(false) { |memo, file_type| memo || file.file_type.name == file_type }
    end
    true
  end
end

class GroupActionsDefinition
  def initialize(group)
    @group_id = group.action_id
  end

  def register_editor_action(id, options, &block)
    options[:group] ||= @group_id
    register_editor_action_impl(id, options, &block)
  end
end

# * id - action id
# * options
#   - :text Action presentable name, if not specified id will be used
#   - :description Action description
#   - :file_type Valid file type name or array of file type names
#        Examples:
#         :file_type => 'RHTML'
#         :file_type => 'Ruby'
#         :file_type => ["RHTML", "HAML", "CSS", "HTML", "XML"]
#   - :enable_in_modal_context If true action will be enabled in modal dialogs (rename, search, replace dialogs, etc)
#   - :group Describes action group(s) which should contain the action
#        Examples:
#         :group => :extensions
#         :group => "group id"
#         :group => ["group id", "other group id"]
#         :group => {:id => "group_id", :anchor => 'before', :relative_to_action => "relative_action_id"}
#         :group => [{:id => "group_id", :anchor => 'before', :relative_to_action => "relative_action_id"}, "other group"]
#
#         :anchor valid values: "first", "last", "before", "after""
#   - :shortcut
# * &block(editor, file)
#   - editor : current editor field
#   - file : may be nil, e.g. if action was invoked in rename/search modal dialog.
def register_editor_action_impl(id, options, &block)
  options[:block] = block
  options[:text] ||= id
  action = RubyEditorAction.new(id, options)
  ActionManager.get_instance.register_action id, action

  # shortcut
  shortcut = options[:shortcut]
  if shortcut
    keystroke = ActionManagerEx.get_key_stroke shortcut
    if keystroke
      shortcut = KeyboardShortcut.new keystroke, nil
      keymap_manager = KeymapManager.get_instance
      keymap_name = options[:keymap] || KeymapManager::DEFAULT_IDEA_KEYMAP
      keymap = keymap_manager.get_keymap keymap_name
      keymap.add_shortcut id, shortcut if keymap
    end
  end

  # group
  RubyMine::AnActionUtil.process_group_params(action, options[:text], options[:group])
end

alias register_editor_action register_editor_action_impl