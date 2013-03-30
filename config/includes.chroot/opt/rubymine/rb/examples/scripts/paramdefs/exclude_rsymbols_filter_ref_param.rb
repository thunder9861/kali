include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

module ParamDefs
  # Proxy which removes ruby symbol(e.g. :foo) form autocompletion, forbid resolve for it
  # and inspection show that ruby symbol cannot be used here. User can customize inspection message

  class ExcludeRSymbolsFilter < ParamDefBase
    import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RSymbol unless defined? RSymbol

    def initialize(paramdef_ref, custom_inspection_msg = nil)
      super()

      @real_paramdef_ref = paramdef_ref
      @inspection_msg = custom_inspection_msg || rbundle_msg("inspection.paramdef.warning.forbidden.rsymbol.usage")
    end

    def rsymbol?(context)
      context.value_element.kind_of?(RSymbol)
    end

    def getAllVariants(context)
      if (rsymbol?(context))
        return nil
      else
        lookup_items = @real_paramdef_ref.getAllVariants(context)
        filtred_lookup_items = []

        # let's remove symbols from lookup items
        lookup_items.each do |item|
          lookup_string = item.getLookupString;
          unless lookup_string[0,1] == ':'
            filtred_lookup_items << item
          end
        end
        lookup_items_to_java_list(filtred_lookup_items)
      end
    end

    def resolveReference(context)
      res = if (rsymbol?(context))
        nil
      else
        @real_paramdef_ref.resolveReference(context)
      end
      res
    end

    def inspectReference(context)
      if (rsymbol?(context))
        InspectionResult.create_warning_result(context.value_element, @inspection_msg);
      else
        @real_paramdef_ref.inspectReference(context)
      end
    end
  end
end