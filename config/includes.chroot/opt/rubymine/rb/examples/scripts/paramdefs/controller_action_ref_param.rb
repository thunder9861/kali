include Java

import org.jetbrains.plugins.ruby.rails.nameConventions.ControllersConventions unless defined? ControllersConventions
import org.jetbrains.plugins.ruby.rails.model.RailsController unless defined? RailsController
import org.jetbrains.plugins.ruby.ruby.lang.TextUtil unless defined? TextUtil
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.LookupItemType unless defined? LookupItemType

module ParamDefs
  class ControllerActionRefParam < ParamDefBase
    def initialize(split)
      super()
      @split = split
    end

    def getAllVariants(context)
      root = controller_root(context)
      collect_files(context.project, root) do |f|
        dir = f.parent
        folder_path = ControllersConventions::getRelativePathOfControllerFolder dir.url, context.module
        name = ControllersConventions::getControllerName f
        variants = []
        unless folder_path.nil? or name.nil?
          if folder_path.length == 0 then
            controller = RailsController.from_file(context.module, f)
            next unless controller
            controller.all_views.each do |view|
              action = view.get_action
              next unless action
              full_path = "#{name}#{@split}#{action.get_name}"
              variants << create_lookup_item(context, full_path, LookupItemType::String, RailsIcons::RAILS_ACTION_NODE)
            end
          end
        end
        variants
      end
    end

    def resolveReference(context)
      m = context.module
      return nil if m.nil?

      text = element_text(context)
      split = TextUtil.removeQuoting(text).split(@split)
      controller_name = split[0] if split.size > 0
      action_name = split[1] if split.size > 1

      return nil unless controller_name

      clazz = ControllersConventions::getControllerClassByShortName m, context.getValueElement, controller_name
      return clazz unless action_name

      controller = RailsController::from_class clazz
      return clazz unless controller

      controller.get_action action_name
    end
  end
end
