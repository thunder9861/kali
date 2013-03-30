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

register_editor_action "InsertHashRocket",
                       :text => "Insert ' => '",
                       :description => "Inserts ' => '",
                       :shortcut => "control L",
                       :group => "ScriptsRuby",
                       :keymap => "TextMate" do |editor, file|
  editor.insert_text " => "
end

add_to_action_group "ScriptsRails" do |group|
  register_editor_action "InsertParams",
                         :text => "Insert 'params[:id]'",
                         :description => "Inserts 'params[:id]'",
                         :shortcut => "control P",
                         :keymap => "TextMate" do |editor, file|
    editor.insert_text "params[:id]"
    editor.move_caret -3
    editor.extend_selection 2
  end

  register_editor_action "InsertSession",
                         :text => "Insert 'session[:user]'",
                         :description => "Inserts 'session[:user]'",
                         :shortcut => "control J",
                         :keymap => "TextMate" do |editor, file|
    editor.insert_text "session[:user]"
    editor.move_caret -5
    editor.extend_selection 4
  end
end