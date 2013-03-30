include Java

require File.dirname(__FILE__) + '/model_ref_param.rb'

import com.intellij.codeInsight.completion.InsertHandler unless defined? InsertHandler
import org.jetbrains.plugins.ruby.rails.associations.AssociationsUtil unless defined? AssociationsUtil
import org.jetbrains.plugins.ruby.rails.associations.AssociationType unless defined? AssociationType
import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefImplUtil unless defined? ParamDefImplUtil
import org.jetbrains.plugins.ruby.ruby.lang.psi.RubyPsiUtil unless defined? RubyPsiUtil
import com.intellij.openapi.util.io.FileUtil unless defined? FileUtil

module ParamDefs
  class AssociationRefParam < ModelRefParam
    class AssociationInsertHandler
      include InsertHandler

      def initialize(class_name, call)
        @class_name = class_name
        @call = call
      end

      def handleInsert(context, item)
        editor = context.getEditor
        tail_offset = context.getTailOffset

        association = AssociationsUtil.create_association @call, RubyPsiUtil.getContainingRClass(@call), nil

        if (association && @class_name.index("::") && !association.getClassName)
          insert = ", :class_name => '#{@class_name}'"
          offset = tail_offset + insert.length
          editor.getDocument().insertString(tail_offset, insert)
          editor.getCaretModel().moveToOffset(offset)
        end
        #editor.getCaretModel().moveToOffset(offset)
      end
    end

    def resolveReference(context)
      AssociationsUtil.resolve_to_model context.call
    end

    def handleRename(context, new_name)
      a_new_name = context.getValueElement.getText
      model = context.getRClass
      call = context.getCall
      return nil unless model

      association = AssociationsUtil::createAssociation(call, model, model)
      return nil unless association
      return a_new_name if association.get_class_name
      a_new_name = AssociationsUtil::isSingularAssociation(call) ? new_name :
                                                                   InflectorService.getInstance(context.getModule).pluralize(new_name)
      NamingConventions.to_underscore_case(a_new_name)
    end

    def getDescription(formatter)
      wrap_description("associations defined using methods from " +
                        formatter.monospaced("ActiveRecord::Associations::ClassMethods"))
    end
    protected
    def warning_inspection(context, psiElement)
      msg = rbundle_msg("inspection.paramdef.association.warning", ParamDef.getTextPresentationForPsiElement(psiElement))
      InspectionResult.create_warning_result(psiElement, msg);
    end

    def get_item_name(context, model_name)
      if AssociationsUtil.isSingularAssociation(context.call)
        return model_name
      end
      StringUtil::pluralize(model_name)
    end

    private
    def create_item(context, file)
      model_name = get_item_name context, file.name_without_extension
      if (file != context.call.get_containing_file.get_virtual_file)
        relative_path = VfsUtil::get_relative_path file, model_root(context), VirtualFileUtil::VFS_PATH_SEPARATOR
        file_name = FileUtil.get_name_without_extension(relative_path)
        class_name = NamingConventions.to_camel_case file_name
        if (class_name.index("::"))
          model_name = get_item_name(context, file_name.gsub("/", "_"))
        end
        insertion_handler = AssociationInsertHandler.new class_name, context.get_call  
        ParamDefImplUtil.create_lookup_element model_name,
                                               LookupItemType::Symbol,
                                               context.value_element,
                                               RailsIcons::RAILS_MODEL_NODE,
                                               insertion_handler, nil
      end

    end
  end
end