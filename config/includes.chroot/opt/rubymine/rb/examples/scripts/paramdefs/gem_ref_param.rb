include Java

require File.dirname(__FILE__) + '/../rails/paramdef_base'

import org.jetbrains.plugins.ruby.gem.GemReference unless defined? GemReference
import org.jetbrains.plugins.ruby.gem.inspection.GemReferenceVisitor unless defined? GemReferenceVisitor
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.RStringLiteral unless defined? RStringLiteral

module ParamDefs
  class GemRefParam < ParamDefBase

    def resolveReference(context)
      GemReference.new(context.call, context.get_value_element).resolve
    end

    def getAllVariants(context)
      java.util.Arrays.as_list GemReference.new(context.call, context.get_value_element).getVariants
    end

    def inspection_enabled_for?(context)
      false
    end
  end
end