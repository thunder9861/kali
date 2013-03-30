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

module JetBrains
  module RubyMine
    module API
    end
  end
end

require File.expand_path(File.dirname(__FILE__) + '/impl/class_or_module_extension')

# Describes extensions for class or module
# Usage:
#   describe "ActionController::Base" do
#     # here we in instance context of ClassOrModuleExtension
#
#     # specify return type "String" for method "action name"
#     return_type "action_name" => "String"
#
#     # specify block variable type "ActionView::Helpers::FormBuilder" for method "form_for"
#     block_variable_type "form_for" => "ActionView::Helpers::FormBuilder"
#
#     # consider ActionController::Base as dynamic type
#     dynamic_class_type
#   end
module JetBrains::RubyMine::API
  def describe(class_or_module, &block)
    ClassOrModuleExtension.new(class_or_module).instance_eval(&block)
  end
end

include JetBrains::RubyMine::API