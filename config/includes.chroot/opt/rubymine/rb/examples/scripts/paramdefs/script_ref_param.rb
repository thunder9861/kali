include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

module ParamDefs
  class ScriptRefParam < ParamDefBase
    begin
      import com.intellij.lang.javascript.library.JSLibReferenceResolver unless defined? JSLibReferenceResolver
      import com.intellij.lang.javascript.library.JSLibraryUtil unless defined? JSLibraryUtil
      import com.intellij.lang.javascript.inspections.JSUnresolvedLibraryURLInspection unless defined? JSUnresolvedLibraryURLInspection
      @@javascript_plugin_enabled = true
    rescue
      @@javascript_plugin_enabled = false
    end

    def getAllVariants(context)
      collect_lookup_items(context, scripts_root(context)) { |f| f.name_without_extension }
    end

    def resolveReference(context)
      filename = element_text(context)
      if (@@javascript_plugin_enabled && JSLibraryUtil.containsLibURL(filename))
        return JSLibReferenceResolver::JSLibReference.resolveToLibrary filename, context.get_project
      end
      filename << '.js' unless filename =~ /.+\.js/
      find_psi_file_under context, scripts_root(context), filename
    end

    def scripts_root(context)
      rails_std_paths_file context, :getJavascriptsRootURL
    end

    def getDescription(formatter)
      wrap_description("list of javascript files in " + formatter.monospaced("\#\\{RAILS_ROOT}/public/javascripts"))
    end

    protected
    def warning_inspection(context, psiElement)
      msg = rbundle_msg("inspection.paramdef.script.warning", ParamDef.getTextPresentationForPsiElement(psiElement))
      filename = element_text(context)
      if (@@javascript_plugin_enabled && JSLibraryUtil.containsLibURL(filename))
        return InspectionResult.create_warning_result_with_fix(psiElement, msg, JSUnresolvedLibraryURLInspection::DOWNLOAD_LIB_FIX)
      end
      fix = build_create_file_fix context, filename + ".js", scripts_root(context)
      InspectionResult.create_warning_result_with_fix(psiElement, msg, fix)
    end

  end
end