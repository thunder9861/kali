require File.dirname(__FILE__) + '/method_ref_param'

import org.jetbrains.plugins.ruby.rails.model.RailsLayout unless defined? RailsLayout
import org.jetbrains.plugins.ruby.rails.model.RailsView unless defined? RailsView
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.holders.utils.RContainerUtil unless defined? RContainerUtil

module ParamDefs
  class ControllerMethodRefParam < MethodRefParam

    def initialize(min_access, options = {})
      super 'ActionController::Base', min_access, LookupItemType::Symbol
      @my_options = options
    end

    def getDescription(formatter)
      result = "list of methods from current controller"
      result += " or from specified controller if " + formatter.monospaced(":controller") + " parameter is given " if @class_dependency
      wrap_description result
    end

    protected

    def find_target_class(context)
      m = context.module
      # try to interpret as call from view/layout template
      unless m.nil? then
        context_element = context.call
        file = context_element.containing_file

        # view - delegate to corresponding controller
        view = RailsView::from_file file
        controller_class = get_class view
        return controller_class unless controller_class.nil?

        # layout  - delegate to corresponding controller
        layout = RailsLayout::from_file file
        controller_class = get_class layout
        return controller_class unless controller_class.nil?
      end
      # if not in view/layout file - use general implementation
      super context
    end

    def warning_inspection_msg(psi_element)
      if @my_options[:use_rails_actions_warning]
        rbundle_msg("inspection.paramdef.controller_action.warning", ParamDef.getTextPresentationForPsiElement(psi_element))
      else
        super(psi_element)
      end
    end


    def get_class(view)
      controller = view.get_controller unless view.nil?
      file = controller.get_psi_file unless controller.nil?
      controller_class = RContainerUtil::get_first_class_in_file(file) unless file.nil?
      controller_class
    end
  end
end