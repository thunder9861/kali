include Java

import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.DynamicHashKeyProvider unless defined? DynamicHashKeyProvider
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ResolvingParamDependency unless defined? ResolvingParamDependency
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RSymbol unless defined? RSymbol
import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ActionMethodRefParam unless defined? ActionMethodRefParam

module ParamDefs
  class ActionKeysProvider
    include DynamicHashKeyProvider

    def initialize
      @provider = ActionMethodRefParam.new(ResolvingParamDependency.new(0))
    end

    def getKeys(context)
      variants = @provider.getAllVariants(context)
      if variants
        return variants.map do |variant|
          variant.getLookupString
        end
      end
      java.util.Collections.emptyMap()
    end

    def hasKey(context, text)
      variants = @provider.getAllVariants(context)
      variants.each do |variant|
        return true if variant.getLookupString == text
      end if variants
      false
    end

    def resolveKey(context, text)
      @provider.resolveReference(context)
    end

    def isSymbolOnly
      true
    end
  end
end
