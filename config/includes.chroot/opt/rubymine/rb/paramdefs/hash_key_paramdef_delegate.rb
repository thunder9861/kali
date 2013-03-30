include Java

import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.DynamicHashKeyProvider unless defined? DynamicHashKeyProvider
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ResolvingParamDependency unless defined? ResolvingParamDependency
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RSymbol unless defined? RSymbol

module ParamDefs
  class HashKeyParamdefDelegate
    include DynamicHashKeyProvider

    def initialize(leaf_paramdef)
      @provider = leaf_paramdef
    end

    def as_key(variant)
      str = variant.getLookupString
      # remove header ":" if is symbol
      !str.nil? && str[0, 1] == ":" ? str[1..-1] : str
    end

    def getKeys(context)
      variants = @provider.getAllVariants(context)
      if variants
        return variants.map do |variant|
          as_key(variant)
        end
      end
      java.util.Collections.emptyMap()
    end

    def hasKey(context, text)
      variants = @provider.getAllVariants(context)
      variants.each do |variant|
        return true if as_key(variant) == text
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
