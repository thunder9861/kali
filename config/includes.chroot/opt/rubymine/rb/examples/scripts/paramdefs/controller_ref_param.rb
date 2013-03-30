include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import org.jetbrains.plugins.ruby.rails.nameConventions.ControllersConventions unless defined? ControllersConventions
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.rails.model.RailsController unless defined? RailsController

module ParamDefs
  class ControllerRefParam < ParamDefBase
    def initialize(lookup_item_type)
      super()
      @lookup_item_type = lookup_item_type      
    end

    def getAllVariants(param_context)
      root = controller_root(param_context)

      collect_files(param_context.project, root) do |f|
        dir = f.parent
        folder_path = ControllersConventions::getRelativePathOfControllerFolder dir.url, param_context.module
        name = ControllersConventions::getControllerName f
        unless folder_path.nil? or name.nil?
          full_path =
                  if folder_path.length > 0 then
                    folder_path + "/" + name
                  else
                    name
                  end
          create_lookup_item param_context, full_path, @lookup_item_type, RailsIcons::RAILS_CONTROLLER_NODE
        end
      end
    end

    def resolveReference(param_context)
      m = param_context.module
      return nil if m.nil?
      text = element_text(param_context)
      controller = RailsController.fromQualifiedName(m, text)
      controller.nil? ? ControllersConventions::getControllerClassByShortName(m, param_context.getValueElement, text) :
                        controller.getRClass
    end

    def getDescription(formatter)
      wrap_description "controllers"
    end

    def handleRename(context, new_controller_class_short_name)
      m = context.module
      return nil if m.nil?
      text = element_text(context)
      return nil if text.nil?

      new_short_name = ControllersConventions.getControllerNameByClassName(new_controller_class_short_name)

      controller = RailsController.fromQualifiedName(m, text)
      unless controller.nil?
        short_name = controller.getName
        short_name_length = short_name.length

        if text.length >= short_name_length
          if text[-short_name_length, short_name_length] == short_name
            return "#{text[0..-short_name_length - 1]}#{new_short_name}"
          end
        end

      end

      new_short_name
    end

    protected
    def warning_inspection(context, psi_element)
      msg = rbundle_msg("inspection.paramdef.controller.warning", ParamDef.getTextPresentationForPsiElement(psi_element))
      InspectionResult.create_warning_result(psi_element, msg);
    end
  end
end
