

include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'
require File.dirname(__FILE__) + '/method_ref_param'

import com.intellij.openapi.fileTypes.FileTypeManager unless defined? FileTypeManager
import com.intellij.openapi.vfs.LocalFileSystem unless defined? LocalFileSystem
import org.jetbrains.plugins.ruby.rails.nameConventions.ViewsConventions unless defined? ViewsConventions
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RSymbol unless defined? RSymbol
import org.jetbrains.plugins.ruby.utils.VirtualFileUtil unless defined? VirtualFileUtil
import com.intellij.openapi.util.io.FileUtil unless defined? FileUtil
import org.jetbrains.plugins.ruby.rails.actions.CreateNamedFileFix unless defined? CreateNamedFileFix
import org.jetbrains.plugins.ruby.rails.model.RailsMailer unless defined? RailsMailer
import com.intellij.openapi.vfs.VfsUtilCore unless defined? VfsUtilCore

module ParamDefs
  class ViewRefParam < ParamDefBase
    def initialize(root_dependency = nil)
      super()
      @root_dependency = root_dependency
    end

    def getDescription(formatter)
      wrap_description "views"
    end

    def getAllVariants(context)
      if (@root_dependency.nil?)
        root = view_root(context)
      else
        root_candidate = @root_dependency.getValue(context)
        root = root_candidate.nil? ? view_root(context) : root_candidate.getVirtualFile
      end
      collect_files(context.project, root) do |f|
        build_items(root, f, context)
      end if root
    end

    def resolveReference(context)
      root = view_root(context)
      return nil if root.nil?

      relative_path = element_text(context)
      path_and_name_and_ext = view_file_path_name_ext(context, root, relative_path)
      return nil if path_and_name_and_ext.nil?
      
      file_path = path_and_name_and_ext[0]
      file_name = path_and_name_and_ext[1]
      file_ext = path_and_name_and_ext[2]
      folder = root.find_file_by_relative_path file_path
      return nil unless folder

      virtual_file = file_ext.nil? ? nil : folder.findChild("#{file_name}.#{file_ext}")

      if virtual_file.nil?
        folder.get_children.each do |file|
          if file_name == ViewsConventions::getActionMethodNameByView(file) && (file_ext.nil? || file_ext == file.getExtension)
            virtual_file = file
          end
        end
      end
      virtual_file.nil? ? nil : find_psi_file(context, virtual_file)
    end

    def handleRename(paramContext, new_name)
      path_and_name = split_to_relative_path_and_filename(paramContext, element_text(paramContext))
      path = path_and_name[0]
      name = path_and_name[1]

      folderPathPart = (path.nil? ? '' : path)
      # if old name contains extention than new name should also contain ext
      if !name.index('.').nil?
        return folderPathPart + new_name
      else
        # otherwise use new name without ext
        new_name_without_ext = ViewsConventions.getViewOrLayoutNameByFileName(FileUtil.get_name_without_extension(new_name))
        return folderPathPart + new_name_without_ext
      end
    end

    protected

    def warning_inspection(context, psi_element)
      msg = rbundle_msg("inspection.paramdef.view.warning", ParamDef.getTextPresentationForPsiElement(psi_element))
      build_result_with_fix msg, context, psi_element
    end

    def build_result_with_fix(msg, context, psi_element)
      fix = nil
      relative_path = element_text(context)
      root = view_root(context)
      return if root.nil?
      path_and_name_and_ext = view_file_path_name_ext(context, root, relative_path)
      unless path_and_name_and_ext.nil?
        folder = root.find_file_by_relative_path path_and_name_and_ext[0]
        name = path_and_name_and_ext[1]
        if folder and name.size > 0
          ext = path_and_name_and_ext[2]
          name = name + "." + ext if ext
          fix = CreateNamedFileFix.new name, psi_element.manager.find_directory(folder), "Ruby.ViewRefParam.DefaultExtension", "html.erb", "View"
        end
      end
      InspectionResult.create_warning_result_with_fix(psi_element, msg, fix);
    end

    def view_file_path_name_ext(param_context, root, name)
      path_and_name = split_to_file_path_and_filename(param_context, root, name)
      return nil if path_and_name.nil?

      path = path_and_name[0]
      name = path_and_name[1]
      if name.rindex '.'
        view_name = ViewsConventions.get_view_or_layout_name_by_file_name(name[0..name.rindex('.')])
        [path, view_name, name[view_name.size + 1..-1]]
      else
        [path, name, nil]
      end
    end

    def split_to_file_path_and_filename(param_context, root, name)
      # see Agile Web Development with Rails (SE - p. 511)
       if name.index '/'
         pos = name.rindex('/')
         path = name[0..pos]
         path = path[1..-1] if path[0,1] == '/'
         [path, name[pos+1..name.length]]
       else
         folder = view_folder_from_context(param_context)
         return nil unless folder
         [VfsUtil::get_relative_path(folder, root, VirtualFileUtil::VFS_PATH_SEPARATOR), name]
       end
    end

    def split_to_relative_path_and_filename(paramContext, name)
      if name.rindex '/'
        pos = name.rindex('/')
        [name[0..pos], name[pos+1..name.length]]
      else
        [nil, name]
      end
    end

    def build_view_names(paramContext, root, path)
      s = com.intellij.openapi.vfs.VfsUtil::getRelativePath(path, root, '/'[0])
      start = s[0] == '/' ? 1 : 0
      index = s.index('.')
      return nil unless index || index <= start
      [s[start..(index - 1)]]
    end

    private

    def view_folder_from_context(context)
      containing_file = context.value_element.containing_file.virtual_file
      app = rails_app(context)
      return nil if app.nil?
      views_root = app.views_root
      if VfsUtilCore::isAncestor views_root, containing_file, false
        containing_file.parent
      else
        if (@root_dependency)
          candidate = @root_dependency.getValue(context)
          return candidate.virtual_file if candidate
        end
        controller = RailsController::fromFile(context.module, containing_file)
        return controller.views_folder if controller
        mailer = RailsMailer::fromFile(context.module, containing_file)
        return mailer.views_folder if mailer
      end
    end

    def build_items(root, path, paramContext)
      names = build_view_names(paramContext, root, path)
      return nil if names.nil?

      items = []
      names.each do |view_name|
        _, name = split_to_relative_path_and_filename(paramContext, view_name)
        if (name[0,1] != '_')
          s = wrap_if_symbol(paramContext, view_name)
          items << create_lookup_item(paramContext, s, LookupItemType::String, FileTypeManager.get_instance.get_file_type_by_file(path).get_icon)
        end
      end
      items
    end

    def wrap_if_symbol(paramContext, s)
      return nil unless s
      paramContext.get_value_element.is_a?(RSymbol) && s.index('/') ? '\'' + s + '\'' : s       
    end
  end

  class LayoutRefParam < ViewRefParam
    @@method_ref = MethodRefParam.new 'ActionController::Base', Visibility::PRIVATE, LookupItemType::Symbol

    def getAllVariants(paramContext)
      return @@method_ref.getAllVariants(paramContext) if paramContext.get_value_element.is_a? RSymbol
      super paramContext
    end


    def resolveReference(paramContext)
      return @@method_ref.resolveReference(paramContext) if paramContext.get_value_element.is_a? RSymbol
      super paramContext
    end

    def view_root(paramContext)
      root = super(paramContext)
      root.find_child("layouts") if root
    end

    def split_to_file_path_and_filename(param_context, root, name)
      path_and_name = split_to_relative_path_and_filename(param_context, name)

      # return [$path, $name]
      [path_and_name[0].nil? ? "" : path_and_name[0], path_and_name[1]]
    end

    def getDescription(formatter)
      wrap_description "layouts"
    end

    protected
    def warning_inspection(context, psiElement)
      msg = rbundle_msg("inspection.paramdef.layout.warning", ParamDef.getTextPresentationForPsiElement(psiElement))
      InspectionResult.create_warning_result(psiElement, msg);
    end

  end
end