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
import com.intellij.openapi.editor.EditorModificationUtil unless defined? EditorModificationUtil

class EditorWrapper
  def initialize(editor)
    @editor = editor
  end

  def insert_text(s)
    EditorModificationUtil::insert_string_at_caret @editor, s
  end

  def replace_selection_text(s)
    EditorModificationUtil::insert_string_at_caret @editor, s, true, true
  end

  def delete_selected_text
    EditorModificationUtil::delete_selected_text @editor
  end

  def move_caret(delta)
    @editor.caret_model.move_caret_relatively delta, 0, false, false, true
  end

  def extend_selection(delta)
    @editor.caret_model.move_caret_relatively delta, 0, true, false, true
  end

  def has_selection?
    @editor.selection_model.has_selection
  end

  def selection
    @editor.selection_model.selected_text
  end

  def select selection_start, selection_end
    @editor.selection_model.set_selection selection_start, selection_end
  end

  def selection_start
    @editor.selection_model.selection_start
  end

  def selection_end
    @editor.selection_model.selection_end
  end

  def method_missing(name, *args, &block)
    @editor.send(name, *args, &block)
  end

  def text
    @editor.getDocument.getText
  end

  def caret_offset
    @editor.caret_model.get_offset
  end
end