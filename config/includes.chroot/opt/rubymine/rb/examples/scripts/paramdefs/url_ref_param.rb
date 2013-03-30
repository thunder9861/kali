include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

module ParamDefs
  class UrlRefParam < ParamDefBase

    def resolveReference(context)
      file_relative_name = element_text(context)
      if file_relative_name[0, 1] == "/"
        file_relative_name = file_relative_name[1, file_relative_name.length - 1]
      end
      root = public_root(context)
      return nil if root.nil?
      find_psi_file context, root.find_file_by_relative_path(file_relative_name)
    end

    def getAllVariants(context)
      publ_root = public_root(context)

      publ_root_path = publ_root.path
      publ_root_length = publ_root_path.length

      collect_files(context.project, publ_root) do |f|
        file_path = f.path
        name = file_path[publ_root_length, file_path.length - publ_root_length]
        create_lookup_item context, name, LookupItemType::String, FileTypeManager.get_instance.get_file_type_by_file(f).get_icon
      end
    end

    def public_root(context)
      rails_std_paths_file context, :getPublicRootURL
    end
  end
end
