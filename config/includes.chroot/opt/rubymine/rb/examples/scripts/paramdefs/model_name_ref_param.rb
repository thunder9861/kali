include Java

require File.dirname(__FILE__) + '/model_ref_param.rb'

import com.intellij.openapi.vfs.VfsUtil unless defined? VfsUtil
import org.jetbrains.plugins.ruby.utils.NamingConventions unless defined? NamingConventions
import com.intellij.openapi.util.io.FileUtil unless defined? FileUtil
import org.jetbrains.plugins.ruby.utils.VirtualFileUtil unless defined? VirtualFileUtil

module ParamDefs
  class ModelNameRefParam < ModelRefParam

    def resolveReference(context)
      model_name = element_text(context)
      find_model context, model_name
    end


    def getDescription(formatter)
      wrap_description "model names"
    end

    protected
    def warning_inspection(context, psi_element)
      msg = rbundle_msg("inspection.paramdef.model_name.warning", ParamDef.getTextPresentationForPsiElement(psi_element))
      InspectionResult.create_warning_result(psi_element, msg);
    end

    private

    def create_item(context, file)
      relative_path = VfsUtil::get_relative_path file, model_root(context), VirtualFileUtil::VFS_PATH_SEPARATOR
      model_name = NamingConventions.to_camel_case FileUtil.get_name_without_extension(relative_path)
      if (file != context.call.get_containing_file.get_virtual_file)
        create_lookup_item context, model_name, LookupItemType::String, RailsIcons::RAILS_MODEL_NODE
      end
    end
  end
end