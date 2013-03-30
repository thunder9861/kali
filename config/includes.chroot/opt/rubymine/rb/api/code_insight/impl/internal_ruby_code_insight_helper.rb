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

require File.expand_path(File.dirname(__FILE__) + '/code_insight_helper')
require File.expand_path(File.dirname(__FILE__) + '/rails_code_insight_helper')

import org.jetbrains.plugins.ruby.ruby.codeInsight.RubyDynamicExtensionsManager unless defined? RubyDynamicExtensionsManager
import org.jetbrains.plugins.ruby.ruby.codeInsight.RubyInsertHandlerExtensionsManager unless defined? RubyInsertHandlerExtensionsManager
import org.jetbrains.plugins.ruby.rails.codeInsight.RailsTypeUtil unless defined? RailsTypeUtil
import org.jetbrains.plugins.ruby.ruby.codeInsight.types.computable.RSymbolBasedTypeComputable unless defined? RSymbolBasedTypeComputable
import org.jetbrains.plugins.ruby.ruby.codeInsight.types.computable.RPsiBasedTypeComputable unless defined? RPsiBasedTypeComputable

module JetBrains::RubyMine::Internal_RubyCodeInsightHelper
  include JetBrains::RubyMine::API::CodeInsightHelper
  include JetBrains::RubyMine::API::RailsCodeInsightHelper

  @@ruby_dynamic_ext_manager = RubyDynamicExtensionsManager.getInstance
  @@ruby_method_insert_handlers_manager = RubyInsertHandlerExtensionsManager.getInstance

  # registers dynamic methods in module
  def register_dynamic_methods(module_name, type, methods_names, resolve_target = nil, required_gem = nil)
    @@ruby_dynamic_ext_manager.registerDynamicMethods(module_name, symbol_type_for(type), resolve_target,
                                                      required_gem, methods_names.to_java(:'java.lang.String'));
  end

  # Associates existing method with return type based on birth class
  # * method_fqn - method's fully qualified name
  # * type_provider - birth class fully qualified name or type computable object (RSymbolBasedTypeComputable)
  #
  # E.g.
  #   associate_method_with_type "ActionController::Base::params", "HashWithIndifferentAccess"
  def associate_method_with_type(method_fqn, type_provider)
    case type_provider
      when Hash
        rails_version_dependent = type_provider[:version]
        rails_version_dependent ||= type_provider[:'rails 2.3']
        if rails_version_dependent
          rails22_type = rails_version_dependent[:api22]
          rails22_type ||= rails_version_dependent[:old_api]

          rails23_type = rails_version_dependent[:api23]
          rails23_type ||= rails_version_dependent[:new_api]

          rails30_type = rails_version_dependent[:api30]
          rails30_type ||= rails23_type

          rails31_type = rails_version_dependent[:api31]
          rails31_type ||= rails30_type
          
          rails22_type ||= rails23_type

          type_computable = RailsTypeUtil::RailsVersionDependentTypeComputable.new(rails22_type, rails23_type, rails30_type, rails31_type)
          @@ruby_dynamic_ext_manager.addImplicitMethodReturnComputableType(method_fqn, type_computable)
        end
      else
        # type computable(RSymbolBasedTypeComputable) or fqn(String)
        type_computable = to_type_computable(type_provider)
        @@ruby_dynamic_ext_manager.addImplicitMethodReturnComputableType(method_fqn, type_computable)
    end
  end

  def associate_method_with_insert_handler(method_fqn, insert_handler)
   @@ruby_method_insert_handlers_manager.register_handler(method_fqn, insert_handler);
  end

  #
  # * type_provider :
  #    - @String : birth class fully qualified name
  #    - else : RSymbolBasedTypeComputable object
  def associate_yield_variable_with_type(method_fqn, type_provider)
    type_computable = to_type_computable(type_provider)
    @@ruby_dynamic_ext_manager.addBlockVariableComputableType(method_fqn, type_computable)
  end

  def associate_class_with_dynamic_type(class_fqn, options)
    if (options[:recursive])
      @@ruby_dynamic_ext_manager.addRecursiveDynamicClassType class_fqn
    elsif (options[:type])
      type_computable = to_type_computable(options[:type])
      @@ruby_dynamic_ext_manager.addDynamicClassType class_fqn, type_computable
    else
      @@ruby_dynamic_ext_manager.addDynamicClassType class_fqn
    end
  end
end
