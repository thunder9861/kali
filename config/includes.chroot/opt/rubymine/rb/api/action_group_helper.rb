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
require File.expand_path(File.dirname(__FILE__) + "/../api/editor_action_helper")

import com.intellij.openapi.actionSystem.ActionManager unless defined? ActionManager
import com.intellij.openapi.actionSystem.DefaultActionGroup unless defined? DefaultActionGroup
import com.intellij.openapi.actionSystem.Separator unless defined? Separator

class RubyActionGroup < DefaultActionGroup
  def initialize(id, options)
    super(options[:text], true)
    @id = id
  end

  def separator
    separator = Separator.getInstance();
    add(separator, ActionManager.get_instance)
  end

  def action_id
    @id
  end
end

# adds actions to existing groups
#
# Example: Let's register InsertParams action in ScriptRails group:
#  add_to_action_group "ScriptsRails" do |group|
#    register_editor_action "InsertParams",
#                           :shortcut => "control P" do |editor, file|
# ...
# end

def add_to_action_group(group_id, &block)
  # group
  group = ActionManager.get_instance.getParentGroup(group_id, nil, nil)
  return if group.nil?

  GroupActionsDefinition.new(group).instance_eval(&block) if block_given?
end

# registers new action group
# * id - action group id
# * options - action group id
#   - text - group name
#   - description - group description
#   - group - parent group name(String) or :extensions for 'Tools | Extensions' group. If hash key isn't specified 'Tools | Extensions' will be used.
#   - popup - false if group's actions should be inlined in paren group
def register_action_group(id, options)
  options[:text] ||= id
  options[:group] ||= :extensions

  return unless ActionManager.get_instance.getAction(id).nil?

  group = RubyActionGroup.new(id, options)

  # presentation
  presentation = group.getTemplatePresentation();

  # * text
  presentation.setText(options[:text]);

  # * description
  description = options[:description]
  presentation.setDescription(description) unless description.nil?;

  # * icon - TODO

  # * popup
  popup = options[:popup]
  group.setPopup(popup) unless popup.nil?;

  ActionManager.get_instance.register_action id, group

  # group
  RubyMine::AnActionUtil::process_group_params(group, options[:text], options[:group])
end