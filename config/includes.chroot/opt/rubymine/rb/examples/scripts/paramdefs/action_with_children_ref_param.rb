require File.dirname(__FILE__) + '/action_ref_param'

import org.jetbrains.plugins.ruby.ruby.codeInsight.RubyOverrideImplementUtil unless defined? RubyOverrideImplementUtil

module ParamDefs

  class ActionWithChildrenRefParam < ActionMethodRefParam
    def initialize(class_dependency = nil)
      super class_dependency
    end

    def resolve_reference_in_class(name, target_class)
      ref = super(name, target_class)
      return ref if ref
      RubyOverrideImplementUtil.getOverridingElements(target_class).each do |clazz|
        ref = super(name, clazz)
        return ref if ref
      end
    end

    def get_variants_from_class(context, target_class)
      variants = super(context, target_class)
      return nil unless variants
      strings = variants.map { |var| var.getLookupString}

      RubyOverrideImplementUtil.getOverridingElements(target_class).each do |clazz|
        vars = super(context, clazz)
        vars.each do |var|
          if !strings.include?(var.getLookupString)
            strings << var.getLookupString
            variants << var
          end
        end if vars
      end
      variants
    end

    def resolve_reference_for_inspection_hook(context)
      psi_method = resolveReference(context)
      psi_method if (psi_method.kind_of?(RMethod) && is_valid_method(psi_method)) or psi_method.kind_of?(PsiFile)
    end
  end
end