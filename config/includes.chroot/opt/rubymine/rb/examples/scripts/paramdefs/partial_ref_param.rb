include Java

require File.dirname(__FILE__) + '/view_ref_param'

import org.jetbrains.plugins.ruby.rails.RailsUtil unless defined? RailsUtil
import com.intellij.openapi.vfs.VfsUtil unless defined? VfsUtil
import org.jetbrains.plugins.ruby.rails.nameConventions.ViewsConventions unless defined? ViewsConventions
import org.jetbrains.plugins.ruby.rails.model.RailsController unless defined? RailsController

module ParamDefs
  # See actionpack/lib/action_view/partial_template.rb, extract_partial_name_and_path(view, partial_path)
  class PartialRefParam < ViewRefParam
    def split_to_file_path_and_filename(param_context, root, name)
      # see Agile Web Development with Rails (SE - p. 511)
       if name.index '/'
         pos = name.rindex('/')
         path = name[0..pos]
         path = path[1..-1] if path[0,1] == '/'
         name = name[pos+1..name.length]
         real_name = determine_name(root, path, name)
         return [path, real_name] if real_name
       else
         folder = view_folder_from_context(param_context)
         return nil unless folder
         path = VfsUtil::get_relative_path(folder, root, VirtualFileUtil::VFS_PATH_SEPARATOR)
         real_name = determine_name(root, path, name)
         unless real_name
           containing_file = param_context.value_element.containing_file.virtual_file
           controller = RailsController::fromLayout(param_context.module, containing_file.get_parent.get_url, containing_file.get_name)
           if (controller)
             contoller_views_folder = controller.get_views_folder
             return nil unless contoller_views_folder
             path = VfsUtil::get_relative_path(contoller_views_folder, root, VirtualFileUtil::VFS_PATH_SEPARATOR)
             real_name = determine_name(root, path, name)
           end
         end
         return [path, real_name] if real_name
       end
      [path, '_' + name]
    end

    def determine_name(root, path, name)
      folder = root.findFileByRelativePath(path)
      had_non_underscored = false
      folder.getChildren.each do |child|
        if (child.getName.index("_#{name}.") == 0 || child.getName == "_#{name}")
          return '_' + name
        elsif (child.getName.index("#{name}.") == 0 || child.getName == name)
          had_non_underscored = true
        end
      end if folder
      had_non_underscored ? name : nil
    end

    def build_view_names(context, root, path)
      return nil if path.name[0,1] != '_'
      view_name = path.name[1, path.name.index('.') - 1]
      folder = view_folder_from_context(context)

      full_relative_path = "#{VfsUtil::getRelativePath(path.parent, root, VirtualFileUtil::VFS_PATH_SEPARATOR)}/#{view_name}"
      if path.parent == folder
        [full_relative_path, view_name]
      else
        [full_relative_path]
      end
    end

    def getDescription(formatter)
      wrap_description "partial views"
    end

    protected

    def warning_inspection(context, psi_element)
      msg = rbundle_msg("inspection.paramdef.partial.warning", ParamDef.getTextPresentationForPsiElement(psi_element))
      build_result_with_fix msg, context, psi_element
    end

    private

    def handleRename(context, new_name)
      view_name = super(context, new_name)
      if !view_name.empty? && view_name[0] == ?_
        view_name.slice(1, view_name.size)
      else
        last_slash = view_name.rindex('/')
        if last_slash and view_name[last_slash+1] == ?_
          view_name[0..last_slash] + view_name[last_slash+2..-1]
        else
          view_name
        end
      end
    end
  end
end
