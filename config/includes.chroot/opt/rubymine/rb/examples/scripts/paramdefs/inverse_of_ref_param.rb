include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.classes.RClass unless defined? RClass
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.structure.SymbolUtil unless defined? SymbolUtil
import org.jetbrains.plugins.ruby.rails.associations.AssociationsUtil unless defined? AssociationsUtil
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ResolvingParamDependency unless defined? ResolvingParamDependency
import org.jetbrains.plugins.ruby.rails.associations.AssociationsParser unless defined? AssociationsParser
import com.intellij.openapi.module.ModuleUtil unless defined? ModuleUtil

module ParamDefs
  class InverseOfRefParam < ParamDefBase

    def initialize
      super()
      @model_class_ref_dependency = ResolvingParamDependency.new(0)
    end

    def resolveReference(context)
      resolve_container_class(context)
    end

    def resolve_container_class(context)
      context_element = context.call
      PsiTreeUtil::getParentOfType(context_element, RClass.java_class)
    end

    def getAllVariants(context)
      association_class = @model_class_ref_dependency.get_value(context)
      if (!(association_class.is_a?(RClass)))
        return nil
      end

      container_class = resolve_container_class(context)
      if (container_class == nil)
        return nil
      end

      result = []
      puts association_class.get_name()
      association_parser = AssociationsParser.get_instance(ModuleUtil.find_module_for_psi_element(association_class))
      associations = association_parser.get_all_associations(association_class)
      associations.each do |association|
        resolved_model = association.get_resolved_model()
        if (resolved_model != nil && resolved_model.get_full_name() == container_class.get_full_name())
          result << association
        end
      end

      collect_lookup_items_from_list(context, result, LookupItemType::Symbol) { |item|
        name = item.get_name()
        icon = RailsIcons.EXPLICIT_ICON_DB_ASSOC_FIELD
        [name, icon]
      }
    end
  end
end
