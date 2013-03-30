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

require File.dirname(__FILE__) + '/paramdefs_loader_base'
require File.dirname(__FILE__) + '/rails/paramdefs_helper'

class RSpecParamDefsLoader < BaseParamDefsLoader
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefProvider unless defined? ParamDefProvider

  include RailsParamDefsHelper
  include ParamDefProvider

  def registerParamDefs(manager)
    @manager = manager

    # define/context
    # rspec 2.0
    paramdef 'RSpec::Core::DSL', ['describe', 'context'],
             [nil],
             {:type => maybe_one_of(:controller, :helper, :integration, :model, :view, :routing),
              :scope => nil,
              :location => nil
             }
    define_params_copy 'RSpec::Core::ExampleGroup.describe', 'RSpec::Core::DSL.describe'
    define_params_copy 'RSpec::Core::ExampleGroup.context', 'RSpec::Core::DSL.describe'
    # rspec < 2.8.0 api
    define_params_copy 'RSpec::Core::ObjectExtensions.describe', 'RSpec::Core::DSL.describe'
    define_params_copy 'RSpec::Core::ObjectExtensions.context', 'RSpec::Core::DSL.describe'
    # rspec 1.x
    define_params_copy 'Spec::DSL::Main.describe', 'RSpec::Core::DSL.describe'
    define_params_copy 'Spec::DSL::Main.context', 'Spec::DSL::Main.describe'
    define_params_copy 'Spec::Example::ExampleGroupMethods.describe', 'Spec::DSL::Main.describe'
    define_params_copy 'Spec::Example::ExampleGroupMethods.context', 'Spec::DSL::Main.describe'

    #before/after
    # rspec 2.x
    paramdef 'RSpec::Core::Hooks', ['before', 'after'],
             maybe(one_of(:each, :all, :suite))
    # rspec 1.x
    paramdef 'Spec::Example::BeforeAndAfterHooks', ['before', 'append_before', 'after', 'prepend_after'],
             maybe(one_of(:each, :all, :suite))

    # routing
    # rspec 2.x
    paramdef 'RSpec::Rails::Matchers::RoutingMatchers', "route_to",
             either({
                        :action => action_ref(:class => :controller),
                        :controller => controller_ref,
                    },
                    seq(controller_with_action_ref, {:enable_optional_keys => true})
             )
    # rspec <2.8.0
    define_params_copy 'RSpec::Matchers.route_to', 'RSpec::Rails::Matchers::RoutingMatchers.route_to'
    # rspec 1.x
    paramdef 'Spec::Rails::Example::RoutingHelpers', 'route_for', {
        :action => action_ref(:class => :controller),
        :controller => controller_ref,
    }


    # method available only in rspec 1.x
    paramdef 'Spec::Rails::Example::RoutingHelpers', "params_from",
             link_to_methods,
             nil

    # controllers
    # TODO: RSpec 2.0 support
    paramdef 'Spec::Rails::Example::ControllerExampleGroup', "controller_name",
             controller_ref

    # helpers
    # TODO: RSpec 2.0 support
    paramdef 'Spec::Rails::Example::HelperExampleGroup', "helper_name",
             helper_ref(true)


    # TODO
    # mocks : rspec
    #paramdef 'Spec::Rails::Mocks', "stub_model",
    #         model_name_ref,
    #         model_fields_hash(:model_ref => 0)

  end
end
