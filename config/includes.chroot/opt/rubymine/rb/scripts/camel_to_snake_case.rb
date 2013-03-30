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

require 'default_scripts_groups'
require 'editor_action_helper'
import org.jetbrains.plugins.ruby.utils.NamingConventions unless defined? NamingConventions

register_editor_action "toggle_camel_snake_case",
                       :text => "Toggle Camel/Snake Case",
                       :description => "Converts a string in CamelCase to snake_case and vice versa.",
                       :group => ["EditorActions", {:id => "EditSmartGroup",
                                                    :anchor => 'after',
                                                    :relative_to_action => 'EditorToggleCase' }],
                       :enable_in_modal_context => true,
                       :shortcut => "control alt U" do |editor, file|


  if editor.has_selection?
    text = editor.selection
    s_start = editor.selection_start

    # Here we will use RubyMine's implementation of camel/snake case convertor
    # E.g. in Merb:
    #  merb/core_ext/string.rb, line 19
    #     split('_').map{|e| e.capitalize}.join
    #  merb/core_ext/string.rb, line 14
    #     gsub(/\B[A-Z]/, '_\&').downcase

    changed_text = NamingConventions.is_in_underscored_case_ext(text) ?
                                            NamingConventions.to_camel_case(text) :
                                            NamingConventions.to_underscore_case(text)
    editor.replace_selection_text(changed_text);

    # restore selection
    editor.select(s_start, s_start + changed_text.length)

    # TODO: probably restore caret position
  end
end
