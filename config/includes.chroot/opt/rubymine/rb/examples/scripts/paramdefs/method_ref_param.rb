include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
import org.jetbrains.plugins.ruby.rails.model.RailsAction unless defined? RailsAction
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.RMethod unless defined? RMethod
import org.jetbrains.plugins.ruby.ruby.RubyIcons unless defined? RubyIcons
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.v2.ClassModuleSymbol
import org.jetbrains.plugins.ruby.ruby.codeInsight.types.Context unless defined? Context
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.structure.SymbolProcessor unless defined? SymbolProcessor
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.structure.util.SymbolScopeUtil unless defined? SymbolScopeUtil
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.structure.SymbolUtil unless defined? SymbolUtil
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.Type unless defined? Type
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.TypeSet unless defined? TypeSet
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.classes.RClass unless defined? RClass
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.modules.RModule unless defined? RModule
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.Visibility unless defined? Visibility
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.RAliasStatement unless defined? RAliasStatement
import org.jetbrains.plugins.ruby.ruby.inspections.resolve.CreateRubyMethodFix unless defined? CreateRubyMethodFix
import org.jetbrains.plugins.ruby.ruby.lang.TextUtil unless defined? TextUtil

module ParamDefs
  class MethodRefParam < ParamDefBase

    def initialize(top_parent, min_access, item_type=LookupItemType::String)
      super()
      @min_access = min_access
      @item_type = item_type
      @class_dependency = nil

      @top_parent = top_parent
    end

    attr_accessor :class_dependency

    def getAllVariants(context)
      target_class = get_target_class context
      return nil if target_class == nil
      get_variants_from_class(context, target_class)
    end

    def resolveReference(context)
      name = element_text(context)
      target_class = get_target_class context
      return nil if target_class == nil 
      resolve_reference_in_class(name, target_class)
    end

    def getDescription(formatter)
      result = "list of "
      result += "public " if @min_access == Visibility::PUBLIC
      result += "methods defined in "
      if controller?
        result += "controller"
      elsif model?
        result += "model"
      else
        result += "class"
      end
      result += " and all its parents"
      result += " up to " + formatter.monospaced(@top_parent) if @top_parent
      wrap_description result
    end

    def is_valid_method(method)
      return false unless method.is_a?(RMethod)
      visibility = method.getVisibility()
      if @min_access == Visibility::PUBLIC
        return visibility == Visibility::PUBLIC
      end
      true
    end

    protected
    def resolve_reference_in_class(name, target_class)
      symbol = SymbolUtil.get_symbol_by_container target_class
      return nil unless symbol
      method = SymbolUtil.find_symbol symbol, name, Type::INSTANCE_METHOD.asSet, Context::INSTANCE_PRIVATE.immutable(), target_class
      method ||= SymbolUtil.find_symbol symbol, name, Type::ALIAS.asSet, Context::INSTANCE_PRIVATE.immutable(), target_class
      declaration = method == nil ? nil : method.get_psi_element
      declaration == nil || !is_valid_method(declaration) ? nil : declaration
    end

    def get_variants_from_class(context, target_class)
      symbol = SymbolUtil.get_symbol_by_container target_class
      return nil unless symbol
      methods = collect_methods_with_parents(symbol, context.getValueElement)
      methods.map! {|method| create_lookup_item(context, method.name, @item_type, get_icon(method)) }
    end

    def collect_methods_with_parents(symbol, element)
      result = Hash.new
      while symbol.is_a?(ClassModuleSymbol) && symbol.getPsiElement.is_a?(RClass) do
        if SymbolUtil.get_symbol_full_path(symbol) == @top_parent
          return result.values
        end

        methodz = symbol.get_children(element).get_symbols_of_types(Type::INSTANCE_METHOD.asSet())
        methodz.each do |method|
          last_declaration = method.getPsiElement()
          result[method.get_name] ||= last_declaration if is_valid_method(last_declaration)
        end

        aliases = symbol.get_children(element).get_symbols_of_types(Type::ALIAS.asSet())
        aliases.each do |aliaz|
          aliased = SymbolUtil.get_method_symbol_by_alias(aliaz)
          last_declaration = aliased == nil ? nil : aliased.getPsiElement()
          if is_valid_method(last_declaration)
            result[aliaz.get_name] ||= aliaz.getPsiElement()
          end
        end
        symbol = symbol.getSuperClassSymbol(element)
      end
      result.values
    end

    def resolve_reference_for_inspection_hook(context)
      psi_method = resolveReference(context)

      if psi_method.kind_of?(RMethod) && is_valid_method(psi_method)
        psi_method
      else
        nil
      end
    end

    def build_result_with_fix(context, msg, psi_element)
      target_class = get_target_class(context)
      method_name = element_text(context)
      if target_class and TextUtil::isAnyID(method_name)
        fix = CreateRubyMethodFix.new(nil, target_class.compound_statement, method_name, Context::INSTANCE, @min_access || Visibility::PROTECTED)
      end
      InspectionResult.create_warning_result_with_fix(psi_element, msg, fix)
    end

    def warning_inspection(context, psi_element)
      msg = warning_inspection_msg(psi_element)
      build_result_with_fix(context, msg, psi_element)
    end

    def warning_inspection_msg(psi_element)
      msg = rbundle_msg("inspection.paramdef.method.warning",
                         @top_parent.nil? ? '' : ' ' + rbundle_msg("inspection.paramdef.method.warning.up.to.part", @top_parent),
                         ParamDef.getTextPresentationForPsiElement(psi_element))
      if @min_access != Visibility::PRIVATE
        msg += " " + rbundle_msg("inspection.paramdef.access.warning", @min_access.to_s)
      end
      msg
    end

    def find_target_class(context)
      context_element = context.call
      PsiTreeUtil::getParentOfType context_element, [RClass.java_class, RModule.java_class].to_java(:'java.lang.Class')
    end

    def get_target_class(context)
      if not @class_dependency.nil?
        dependency_value = @class_dependency.getValue(context)
        return dependency_value if dependency_value.is_a? RClass
      end
      find_target_class context
    end

    def get_icon(method)
      return method.get_icon(0) unless method.is_a? RMethod 
      rails_action = RailsAction::from_method method
      rails_action ? RailsIcons::RAILS_ACTION_NODE : RubyIcons::RUBY_METHOD_NODE 
    end

    def controller?()
      @top_parent && @top_parent.index("ActionController") == 0
    end

    def model?()
      @top_parent && @top_parent.index("ActiveRecord") == 0
    end
    
  end
end
