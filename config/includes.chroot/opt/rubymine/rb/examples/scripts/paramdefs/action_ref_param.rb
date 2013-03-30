require File.dirname(__FILE__) + '/controller_method_ref_param'

import org.jetbrains.plugins.ruby.rails.model.RailsController unless defined? RailsController
import com.intellij.psi.PsiFile unless defined? PsiFile
import org.jetbrains.plugins.ruby.rails.actions.RailsActionsUtil unless defined? RailsActionsUtil

module ParamDefs
  class ActionMethodRefParam < ControllerMethodRefParam

    def initialize(class_dependency = nil)
      super Visibility::PUBLIC, {:use_rails_actions_warning => true}
      self.class_dependency = class_dependency
    end

    def getDescription(formatter)
      result = "list of actions from current controller"
      result += " or from specified controller if " + formatter.monospaced(":controller") + " parameter is given " if @class_dependency
      wrap_description result
    end

    def handleRename(context, new_name)
      pos = new_name.index('.')
      return new_name[0..pos-1] if pos
      new_name
    end

    def resolve_reference_in_class(name, target_class)
      ref = super(name, target_class)
      return ref if ref
      if target_class.is_a? RClass
        controller = RailsController.from_class(target_class)
        if controller
          views = controller.get_views(name)
          return views.get(0).psi_file if views.size() > 0
        end
      end
    end

    def get_variants_from_class(context, target_class)
      variants = super(context, target_class)
      return nil unless variants
      controller = RailsController.from_class(target_class)
      if controller
        controller.all_views.each do |view|
          unless variants.any? { |item| item.lookup_string == view.name }
            variants << create_lookup_item(context, view.name, @item_type, RailsIcons::RAILS_ACTION_NODE)
          end
        end
      end
      variants
    end

    def resolve_reference_for_inspection_hook(context)
      psi_method = resolveReference(context)
      return psi_method if (psi_method.kind_of?(RMethod) && is_valid_method(psi_method)) or psi_method.kind_of?(PsiFile)
    end

    def is_valid_method(method)
      rails_action = method.is_a?(RMethod) ? RailsAction::from_method(method) : nil
      !rails_action.nil? && !rails_action.is_hidden_action()
    end
  end
end
