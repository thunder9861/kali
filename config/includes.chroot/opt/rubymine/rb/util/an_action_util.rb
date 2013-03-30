#
# Copyright 2000-2010 JetBrains s.r.o.
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

import org.jetbrains.plugins.ruby.ruby.lang.RubySupportLoader unless defined? RubySupportLoader
import com.intellij.openapi.actionSystem.impl.ActionManagerImpl unless defined? ActionManagerImpl
import com.intellij.openapi.actionSystem.ActionManager unless defined? ActionManager

module RubyMine
  module AnActionUtil
    def self.add_to_group(group_id, action_name, action, options)
      return if group_id.nil?

      action_manager_impl = ActionManager.get_instance
      parent_group = action_manager_impl.getParentGroup(group_id, action_name, nil)
      return if parent_group.nil?

      # anchor
      anchor_str = options[:anchor]
      unless anchor_str.nil?
        anchor_str = anchor_str.to_s
        anchor = ActionManagerImpl::parseAnchor(anchor_str, action_name, nil)
        return if anchor.nil?
      else
        anchor = nil
      end

      # relative to action
      relative_to_action_id = options[:relative_to_action]
      unless relative_to_action_id.nil?
        relative_to_action_id = relative_to_action_id.to_s
        valid = ActionManagerImpl::checkRelativeToAction(relative_to_action_id, anchor, action_name, nil)
        return unless valid
      end

      # Add action to DefaultActionGroup
      constraints = Constraints.new(anchor, relative_to_action_id)
      parent_group.addAction(action, constraints, action_manager_impl).setAsSecondary(false);
      RubySupportLoader::getInstance().registerActionToGroup(group_id, action.action_id)
    end

    def self.process_group_params(action_or_group, action_or_group_name, group_params)
      return if group_params.nil?
      case group_params
        when Hash
          add_to_group(group_params[:id],  action_or_group_name, action_or_group, group_params)
        when Symbol, String
          options = {:id => (group_params == :extensions ? "ToolsExtensions" : group_params.to_s)}
          add_to_group(options[:id],  action_or_group_name, action_or_group, options)
        when Array
          group_params.each do |group|
            return unless group.is_a?(Hash) || group.is_a?(String)
            process_group_params(action_or_group, action_or_group_name, group)
          end
      end
    end
  end
end

