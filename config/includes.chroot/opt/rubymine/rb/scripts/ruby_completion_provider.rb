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

require 'code_insight/code_insight_helper'

def register_insert_handlers
  describe "Kernel" do
    set_insert_handler insert_handler_empty_string, "require", "load" , "gem"
    set_insert_handler nil, "include"
  end

  describe "Object" do
    set_insert_handler nil, "extend"

    # Rails SDK overrides this methods in Object
    set_insert_handler insert_handler_empty_string, "require", "load"
  end

  describe "Module" do
    set_insert_handler insert_handler_alias_method, "alias_method"
  end
end

###########################################################################
# insert handlers
###########################################################################
register_insert_handlers()