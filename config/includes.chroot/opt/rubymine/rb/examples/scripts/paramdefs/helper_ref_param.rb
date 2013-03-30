include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import com.intellij.psi.PsiManager unless defined? PsiManager
import com.intellij.openapi.vfs.VirtualFileManager unless defined? VirtualFileManager
import org.jetbrains.plugins.ruby.rails.RailsConstants unless defined? RailsConstants
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.ruby.lang.psi.variables.RConstant unless defined? RConstant
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RSymbol unless defined? RSymbol
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.holders.utils.RContainerUtil unless defined? RContainerUtil
import org.jetbrains.plugins.ruby.utils.NamingConventions unless defined? NamingConventions
import org.jetbrains.plugins.ruby.utils.VirtualFileUtil unless defined? VirtualFileUtil
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.RStringLiteral unless defined? RStringLiteral

module ParamDefs
  class HelperRefParam < ParamDefBase
    CONSTANT_VALUES = [:all] unless defined? CONSTANT_VALUES

    def initialize(include_only_real_files)
      super()
      @include_only_real_files = include_only_real_files
    end

    def getAllVariants(context)
      helpers_root = helpers_root(context)
      helpers_root_path = helpers_root ? "#{helpers_root.get_path}/" : nil
      result = collect_files(context.project, helpers_root) do |f|
        relative_name = f.path.gsub(helpers_root_path, "")
        variant = relative_name.chomp("_helper.rb")
        # quote string if contains slash (/)
        if variant.index('/')
          variant = "'#{variant}'"
        end
        create_lookup_item context, variant, LookupItemType::Symbol, RailsIcons::RAILS_HELPERS_FOLDER_NODES
      end
      find_other_helpers(context, result)
    end

    def resolveReference(context)
      find_psi_file_under context, helpers_root(context), element_text(context) + "_helper.rb"
    end

    def inspectReference(context)
      element_at_level = context.value_element

      # common case
      if !resolveReference(context).nil?
        return InspectionResult.create_ok_result element_at_level
      end

      # additional constst
      value_element = context.get_value_element
      return InspectionResult.create_ok_result element_at_level if process_constant_values(context) do |item|
        if item.is_a?(Symbol)
          # context is RSymbol
          item.to_s == value_element.getContent().getText()
        elsif item.is_a?(String)
          item == value_element.getContent().getText()
        end
      end
      # return
      return warning_inspection(context, element_at_level)
    end


    def helpers_root(context)
      settings = module_settings(context)
      return nil if settings.nil?
      VirtualFileManager::get_instance.find_file_by_url settings.getHelpersRootURL
    end

    def getDescription(formatter)
      wrap_description("list of helpers from helpers folder in :symbol format and modules from " +
                        formatter.monospaced("\#\\{RAILS_ROOT}/lib") + " and " +
                        formatter.monospaced("\#\\{RAILS_ROOT}/vendor/plugins") +
                        " in fully qualified name format")
    end

    protected
    def warning_inspection(context, psiElement)
      msg = rbundle_msg("inspection.paramdef.helper.warning", ParamDef.getTextPresentationForPsiElement(psiElement))
      InspectionResult.create_warning_result(psiElement, msg);
    end

    private
    def process_constant_values(context)
      context_value = context.get_value_element

      # Symbol is allowed in Symbol or Constant position
      if context_value.is_a?(RConstant) || context_value.is_a?(RSymbol)
        CONSTANT_VALUES.each do |item|
          if item.is_a?(Symbol)
            return true if yield item
          end
        end
      # String is allowed in StringLiteral position
      elsif context_value.is_a?(RStringLiteral)
        CONSTANT_VALUES.each do |item|
          if item.is_a?(String)
            return true if yield item
          end
        end
      end
      false
    end

    def find_other_helpers(context, prev)
      result = java.util.ArrayList.new
      result.add_all prev

      unless @include_only_real_files
        # we can use :all only in symbols(helpers :magic) or before constant (helper MyHelper) but not in strings
        process_constant_values(context) do |item|
          if item.is_a?(Symbol)
            result.add create_lookup_item(context, item.to_s, LookupItemType::Symbol, RailsIcons::RAILS_HELPERS_FOLDER_NODES)
          elsif item.is_a?(String)
            result.add create_lookup_item(context, item, LookupItemType::String, RailsIcons::RAILS_HELPERS_FOLDER_NODES)
          end
        end
      end
      return result if context.get_value_element.is_a? RSymbol

      files_checked = Hash.new

      lib_root = rails_app(context).libs_root
      lib_root_path = lib_root ? "#{lib_root.get_path}/" : nil
      collect_files(context.project, lib_root) do |f|
        handle_file context, lib_root, lib_root_path, f, result, files_checked
      end

      plugins_root = rails_app(context).plugins_root
      plugins = plugins_root ? plugins_root.getChildren : nil;
      if plugins
        java.util.Arrays.sort(plugins, VirtualFileUtil::VirtualFilesComparator.new);
        plugins.each do |plugin|
          plugin_lib = plugin.find_child RailsConstants::PLUGINS_AND_VENDORS_PACKAGES_LIB_PATH
          plugin_lib_path = plugin_lib ? "#{plugin_lib.get_path}/" : nil
          collect_files(context.project, plugin_lib) do |f|
            handle_file context, plugin_lib, plugin_lib_path, f, result, files_checked
          end
        end
      end
      result
    end

    def contains_module(app, root, file, relative_path, variant, files_checked)
      return false unless file
      files_checked[relative_path] = relative_path
      rfile = PsiManager.getInstance(app.get_module.get_project).findFile(file)
      return false unless rfile && rfile.is_a?(org.jetbrains.plugins.ruby.ruby.lang.psi.RFile)
      modules = RContainerUtil.get_all_modules_names rfile
      modules.each do |mod_name|
        return true if mod_name == variant
      end
      false
    end

    def handle_file(context, root, root_path, file, result, files_checked)
      return nil unless root
      relative_path = file.path.gsub(root_path, "")
      return nil if files_checked[relative_path]
      variant = NamingConventions.to_camel_case(relative_path.chomp(".rb"))
      if contains_module(rails_app(context), root, file, relative_path, variant, files_checked)
        result.add(create_lookup_item(context, variant, LookupItemType::None, RailsIcons::RAILS_HELPERS_FOLDER_NODES))
      end
      nil
    end
  end
end
