include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

module ParamDefs
  class FileRefParam < ParamDefBase
    def initialize(global_only = true, root_method = nil, directory = false)
      super()
      @global_only = global_only
      @root_method = root_method
      @directory = directory
    end

    def resolveReference(context)
      text = element_text(context)
      return nil unless text
      at_root = text[0, 1] == '/'
      return nil if @global_only && !at_root

      app = rails_app(context)
      return nil if app.nil?

      if (@root_method)
        root = send(@root_method, context)
      elsif (@global_only || at_root)
        root = app.railsApplicationRoot
        text = text[1..-1] if at_root
      else
        containing_file = context.value_element.containing_file.virtual_file
        root = containing_file.getParent
      end

      return nil unless root

      pos = text.rindex('/')
      folder = pos && pos > 0 ? root.findFileByRelativePath(text[0..pos]) : root
      name = pos && pos > 0 ? text[pos + 1..text.length] : text
      folder.getChildren.each do |child|
        if (@directory && child.getName == name)
          return PsiManager.getInstance(context.getProject).find_directory(child)
        elsif (child.getName.index("#{name}.") == 0)
          return PsiManager.getInstance(context.getProject).find_file(child)
        end
      end if folder
      nil
    end

    def warning_inspection(context, psiElement)
      msg = rbundle_msg("inspection.paramdef.file.warning", ParamDef.getTextPresentationForPsiElement(psiElement))
      InspectionResult.create_warning_result(psiElement, msg);
    end
  end
end