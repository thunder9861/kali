include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import org.jetbrains.plugins.ruby.rails.model.RailsModel unless defined? RailsModel
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.structure.SymbolUtil unless defined? SymbolUtil
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.Types unless defined? Types
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.rails.associations.AssociationsUtil unless defined? AssociationsUtil
module ParamDefs
  class AttributeRefParam < ParamDefBase

    def getAllVariants(context)
      clazz = context.getRClass
      symbol = SymbolUtil::get_symbol_by_container clazz
      attributes = symbol.get_children(context.getValueElement).get_symbols_of_types(Types::ATTR_METHODS)
      collect_lookup_items_from_list(context, attributes, LookupItemType::Symbol) { |item|
        name = item.get_name
        icon = item.get_explicit_icon
        name = name[0..-2] if name.rindex('=')
        decl = item.getPsiElement()
        icon = RailsIcons.EXPLICIT_ICON_DB_ASSOC_FIELD if AssociationsUtil.is_association_call(decl)
        [name, icon]
      }
    end

    def resolveReference(context)
      clazz = context.getRClass
      symbol = SymbolUtil::get_symbol_by_container clazz
      return nil unless symbol
      text = RubyPsiUtil.getElementText(context.get_value_element)
      resolved = symbol.get_children(context.getValueElement).get_symbol_by_name_and_types(text, Types::ATTR_METHODS)
      return resolved.get_psi_element() if resolved
    end

    def getDescription(formatter)
      wrap_description("list of images in " + formatter.monospaced("\#\\{RAILS_ROOT}/public/images"))
    end

    protected
    #def warning_inspection(context, psiElement)
    #  #msg = rbundle_msg("inspection.paramdef.image.warning", ParamDef.getTextPresentationForPsiElement(psiElement))
    #  #InspectionResult.create_warning_result(psiElement, msg);
    #end
  end
end