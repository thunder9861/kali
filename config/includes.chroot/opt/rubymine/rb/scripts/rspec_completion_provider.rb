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

require File.expand_path(File.dirname(__FILE__) + '/../api/code_insight/code_insight_helper')


def register_insert_handlers
  # describe/context
  # 2.0
  describe "RSpec::Core::ExampleGroup" do
    set_insert_handler insert_handler_block_call_without_args, "describe", "context"
  end
  describe "RSpec::Core::DSL" do
    set_insert_handler insert_handler_block_call_without_args, "describe"
  end
  # rspec < 2.8.0
  describe "RSpec::Core::ObjectExtensions" do
    set_insert_handler insert_handler_block_call_without_args, "describe"
  end
  # 1.x
  describe "Spec::Example::ExampleGroupMethods" do
    set_insert_handler insert_handler_block_call_without_args, "describe", "context"
  end
  describe "Spec::DSL::Main" do
    set_insert_handler insert_handler_block_call_without_args, "describe", "context"
  end

  # before/after
  # 2.x
  describe "RSpec::Core::Hooks" do
    set_insert_handler insert_handler_block_call, "before", "after"
  end
  # 1.x
  describe "Spec::Example::BeforeAndAfterHooks" do
    set_insert_handler insert_handler_block_call, "before", "after"
  end

  # it
  # 2.0
  describe "RSpec::Core::ExampleGroup" do
    set_insert_handler insert_handler_rspec_example, "it", "specify", "example", "pending", "focused"
  end
  # 1.x
  describe "Spec::Example::ExampleGroupMethods" do
    set_insert_handler insert_handler_rspec_example, "it", "xit", "specify", "xspecify", "example", "xexample"
  end

  # should
  # 2.0
  describe "Kernel" do
    set_insert_handler nil, "should", "should_not"
  end
  # 1.x
  describe "Spec::Expectations::ObjectExpectations" do
    set_insert_handler nil, "should", "should_not"
  end
end
###########################################################################
# insert handlers
###########################################################################
register_insert_handlers()
