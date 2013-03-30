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

import org.jetbrains.plugins.ruby.ruby.codeInsight.ResolveTargetDescriptor unless defined? ResolveTargetDescriptor
import org.jetbrains.plugins.ruby.ruby.codeInsight.types.computable.RSymbolBasedTypeComputable unless defined? RSymbolBasedTypeComputable
import org.jetbrains.plugins.ruby.ruby.codeInsight.types.computable.RPsiBasedTypeComputable unless defined? RPsiBasedTypeComputable
import org.jetbrains.plugins.ruby.ruby.codeInsight.types.computable.OrSymbolTypeComputable unless defined? OrSymbolTypeComputable
import org.jetbrains.plugins.ruby.ruby.codeInsight.types.RTypeUtil unless defined? RTypeUtil

module JetBrains::RubyMine::API::CodeInsightHelper
  # Converts type from RubyMine Ruby api to RubyMine Java api type
  # Ruby API supports:
  #   :instance_context - for instance context methods
  #   :class_context  - for class context methods
  def symbol_type_for (type)
    case type
      when :instance_method
        org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.Type::INSTANCE_METHOD
      when :class_method
        org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.Type::CLASS_METHOD
      when :class
        org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.Type::CLASS
      when :module
        org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.Type::MODULE
      else
        $stderr << "Unknown symbol type: #{type}.\n  Stacktrace:\n#{caller.join["\n    "]}\n"
        nil
    end
  end

  # Creates link to existing method
  def target_descriptor (fqn, type)
    ResolveTargetDescriptor.new(fqn, symbol_type_for(type))
  end

  def or_type(type_provider1, type_provider2)
    type_computable1 = to_type_computable(type_provider1)
    type_computable2 = to_type_computable(type_provider2)
    OrSymbolTypeComputable.new(type_computable1, type_computable2)
  end

  private
  def to_type_computable(type_provider)
    case type_provider
      when String
        # by fqn
        RTypeUtil.createTypeByNameComputable(type_provider)
      when RSymbolBasedTypeComputable, RPsiBasedTypeComputable
        # is type computable
        type_provider
      else
        # unsupported variant
        nil
    end
  end
end