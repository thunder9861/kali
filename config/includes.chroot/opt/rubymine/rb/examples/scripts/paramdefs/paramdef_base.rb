include Java
import org.jetbrains.plugins.ruby.rails.RailsUtil unless defined? RailsUtil
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefImplUtil unless defined? ParamDefImplUtil
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.LookupItemType unless defined? LookupItemType
import org.jetbrains.plugins.ruby.ruby.lang.psi.visitors.RubyRecursiveElementVisitor unless defined? RubyRecursiveElementVisitor
import com.intellij.openapi.fileTypes.FileTypeManager unless defined? FileTypeManager
import com.intellij.psi.PsiManager unless defined? PsiManager
import org.jetbrains.plugins.ruby.rails.facet.RailsFacetUtil unless defined? RailsFacetUtil
import org.jetbrains.plugins.ruby.rails.model.RailsApp unless defined? RailsApp
import org.jetbrains.plugins.ruby.ruby.lang.psi.RubyPsiUtil unless defined? RubyPsiUtil
import com.intellij.openapi.vfs.VirtualFileManager unless defined? VirtualFileManager
import org.jetbrains.plugins.ruby.rails.inspections.paramdefs.InspectionResult unless defined? InspectionResult
import org.jetbrains.plugins.ruby.rails.inspections.paramdefs.ParamDefResolveVisitor unless defined? ParamDefResolveVisitor
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDef unless defined? ParamDef
import org.jetbrains.plugins.ruby.RBundle unless defined? RBundle
import com.intellij.codeInsight.daemon.quickFix.CreateFileFix unless defined? CreateFileFix

module ParamDefs
  class MethodCollector < RubyRecursiveElementVisitor
    def initialize(callback)
      super()
      @callback = callback
      @result = []
    end

    attr_reader :result

    def visitRMethod(method)
      item = @callback.call(method)
      @result << item unless item.nil?
    end
  end

  class ParamDefBase < ParamDef

    def inspectReference(context)
      psi_element = context.value_element

      if inspection_enabled_for?(context)
        if resolve_reference_for_inspection_hook(context).nil?
          warning_inspection(context, psi_element)
        else
          InspectionResult.create_ok_result(psi_element);
        end
      elsif ParamDefResolveVisitor.is_probably_acceptible(psi_element)
        InspectionResult.create_probably_acceptible_result(psi_element)
      elsif ParamDefResolveVisitor.is_composite_element(psi_element)
        InspectionResult.create_not_applicable_result(psi_element, ["String literal", "Symbol"].to_java(java.lang.String))
      else
        InspectionResult.create_ignored_result(psi_element)
      end
    end

    protected
    def resolve_reference_for_inspection_hook(context)
       resolveReference(context)
    end

    def inspection_enabled_for?(context)
      psi_element = context.value_element
      ParamDefResolveVisitor.is_primitive_element(psi_element)
    end

    def warning_inspection(context, psi_element)
      InspectionResult.create_default_warning_result(psi_element);
    end

    def rails_app(param_context)
      m = param_context.module
      return nil if m.nil?
      RailsApp.fromModule(m)
    end

    def view_root(param_context)
      app = rails_app(param_context)
      return nil if app.nil?
      app.views_root
    end

    def controller_root(param_context)
      m = param_context.module
      return nil if m.nil?
      RailsUtil::getControllersRoot m
    end

    def model_root(param_context)
      app = rails_app(param_context)
      return nil if app.nil?
      app.getModelsRoot
    end

    def module_settings(context)
      m = context.module
      m ? RailsFacetUtil::get_rails_app_paths(m) : nil
    end

    def element_text(param_context)
      RubyPsiUtil::getElementText param_context.value_element
    end

    def collect_files(project, root)
      return nil unless root

      file_index = com.intellij.openapi.roots.ProjectRootManager::getInstance(project).getFileIndex
      result = []

      iterator = com.intellij.openapi.roots.ContentIterator.impl do |_, f|
        unless f.directory?
          closure_result = yield f
          case closure_result
          when Array
            closure_result.each do |item|
              result << item unless item.nil?
            end
          else
            result << closure_result unless closure_result.nil?
          end
        end
        true
      end
      file_index.iterateContentUnderDirectory root, iterator

      lookup_items_to_java_list(result)
    end

    def collect_lookup_items(context, root, item_type=LookupItemType::String)
      return nil unless root

      file_index = com.intellij.openapi.roots.ProjectRootManager::getInstance(context.project).getFileIndex
      result = []

      iterator = com.intellij.openapi.roots.ContentIterator.impl do |_, f|
        unless f.directory?
          item_name = yield f
          unless item_name.nil?
            item = relative_path(root, f) + item_name
            result << create_lookup_item(context, item, item_type, FileTypeManager.get_instance.get_file_type_by_file(f).get_icon)
          end
        end
        true
      end
      file_index.iterateContentUnderDirectory root, iterator

      lookup_items_to_java_list(result)
    end

   def collect_lookup_items_from_list(context, list, item_type=LookupItemType::String)
      return nil unless list

      result = []
      list.each do |list_item|
        name, icon = *(yield list_item)
        unless name.nil?
          result << create_lookup_item(context, name, item_type, icon)
        end
      end
      lookup_items_to_java_list(result)
    end

    # Relative path to file's parent diractory
    # ("foo", "foo") => ""
    # ("/foo", "/foo/boo/1.png") => "boo/"

    def relative_path(root, f)
      s = ""
      while f.parent != root
        s = "#{f.parent.name}/#{s}"
        f = f.parent
      end
      s
    end

    def collect_methods(psi_element, &callback)
      visitor = MethodCollector.new(callback)
      psi_element.accept visitor unless psi_element.nil?
      lookup_items_to_java_list(visitor.result)
    end

    def create_lookup_item(param_context, value, item_type=LookupItemType::String, icon=nil)
      create_typed_lookup_item(param_context, value, nil, item_type, icon)
    end

    def create_typed_lookup_item(param_context, value, type, item_type, icon)
      return nil unless value

      ParamDefImplUtil::createSimpleLookupItem value, type, item_type, param_context.value_element, icon
    end

    def find_psi_file(param_context, virtual_file)
      return nil unless virtual_file

      PsiManager::getInstance(param_context.project).findFile virtual_file
    end

    def find_psi_file_under(param_context, root, name)
      return nil unless root

      f = root
      components = name.split("/")
      for c in components
        f = f.find_child(c)
        return nil if f.nil?
      end
      find_psi_file param_context, f
    end

    def rails_std_paths_file(param_context, method_name)
      m = param_context.module
      return nil unless m

      paths_class = RailsFacetUtil.getRailsAppPaths(m)
      return nil unless paths_class
      url = paths_class.send method_name

      VirtualFileManager::get_instance.find_file_by_url url
    end

    def lookup_items_to_java_list (results)
      java.util.Arrays.as_list(results.to_java(:"com.intellij.codeInsight.lookup.LookupElement"))
    end

    def wrap_description(result)
      map = java.util.TreeMap.new
      map.put "", result
      map
    end

    def rbundle_msg (msg, *args)
      RBundle.message(msg, args.to_java(:"java.lang.String"))
    end

    def build_create_file_fix(context, file_relative_name, root)
      return nil unless root
      dir = PsiManager.get_instance(context.project).find_directory(root)
      return nil unless dir
      CreateFileFix.new(false, file_relative_name, dir)
    end
  end
end
