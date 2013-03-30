include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import com.intellij.openapi.util.text.StringUtil unless defined? StringUtil
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.rails.InflectorService unless defined? InflectorService
import org.jetbrains.plugins.ruby.rails.associations.AssociationsUtil unless defined? AssociationsUtil
import org.jetbrains.plugins.ruby.utils.NamingConventions unless defined? NamingConventions
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.holders.utils.RContainerUtil unless defined? RContainerUtil

module ParamDefs
  class ModelRefParam < ParamDefBase

    def getAllVariants(param_context)
      collect_files(param_context.project, model_root(param_context)) do |f|
        #TODO[den] : do not collect garbage - only real model files!
        create_item param_context, f
      end
    end

    def resolveReference(context)
      mod = context.module
      return nil unless mod
      return nil unless InflectorService.get_instance(mod).is_inflector_available
      model_name = InflectorService.get_instance(mod).singularize(element_text(context))
      find_model context, model_name
    end

    def getDescription(formatter)
      wrap_description "models"
    end

    protected
    def warning_inspection(context, psi_element)
      msg = rbundle_msg("inspection.paramdef.model.warning", ParamDef.getTextPresentationForPsiElement(psi_element))
      InspectionResult.create_warning_result(psi_element, msg);
    end


    def find_model(context, class_or_model_name)
      name = NamingConventions.toCamelCase(class_or_model_name)
      AssociationsUtil.findModel(name, context.module)
    end

    def get_item_name(context, model_name)
      StringUtil::pluralize(model_name)
    end

    private

    def create_item(context, file)
      model_name = get_item_name context, file.name_without_extension
      if (file != context.call.get_containing_file.get_virtual_file)
        create_lookup_item context, model_name, LookupItemType::Symbol, RailsIcons::RAILS_MODEL_NODE
      end
    end
  end
end
