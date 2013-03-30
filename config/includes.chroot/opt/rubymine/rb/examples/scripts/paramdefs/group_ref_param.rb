include Java

require File.dirname(__FILE__) + '/../rails/paramdef_base'

import com.intellij.openapi.fileTypes.FileTypeManager unless defined? FileTypeManager
import com.intellij.openapi.vfs.VirtualFileManager unless defined? VirtualFileManager

module ParamDefs
  class GroupRefParam < ParamDefBase

    def getAllVariants(context)
      app = rails_app(context)
      return nil unless app
      envs = app.get_environments_root
      return nil unless envs
      collect_files(context.project, envs) do |file|
        name = file.name
        next unless name.index(".rb") == name.length - 3
        variant = file.getNameWithoutExtension
        create_lookup_item context, variant, LookupItemType::Symbol, FileTypeManager.get_instance.get_file_type_by_file(file).get_icon
      end
    end

    def resolveReference(context)
      app = rails_app(context)
      return nil unless app
      envs = app.get_environments_root
      return nil unless envs
      text = element_text(context)
      find_psi_file context, envs.find_file_by_relative_path(text + ".rb")
    end

    def handleRename(context, new_name)
      pos = new_name.index(".rb")
      pos == new_name.length - 3 ? new_name[0..pos-1] : new_name
    end
  end
end