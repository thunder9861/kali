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

register_editor_action "InsertRubyInjection",
                       :text => "Insert '<%= %>'",
                       :description => "Inserts '<%= %>' in Erb files",
                       :shortcut => "control shift PERIOD",
                       :group => "ScriptsErb",
                       :file_type => "RHTML" do |editor, file|
  editor.insert_text "<%=  %>"
  editor.move_caret -3
end
