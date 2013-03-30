include Java

require File.dirname(__FILE__) + '/model_ref_param.rb'

import org.jetbrains.plugins.ruby.rails.associations.AssociationsUtil unless defined? AssociationsUtil
import org.jetbrains.plugins.ruby.rails.associations.AssociationType unless defined? AssociationType
import org.jetbrains.plugins.ruby.rails.model.ActiveRecordModel unless defined? ActiveRecordModel
import org.jetbrains.plugins.ruby.ruby.lang.psi.references.RReference unless defined? RReference
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.classes.RClass unless defined? RClass

module ParamDefs
  class UsedAssociationRefParam < ParamDefBase

    def getAllVariants(paramContext)
      modelClass = extractRailsModelClass(paramContext)

      # works only for models
      return nil if modelClass.nil?

      associations_names = AssociationsUtil.get_associations_names(modelClass)
      lookup_items = []
      associations_names.each do |name|
        lookup_items << create_lookup_item(paramContext, name, LookupItemType::Symbol, RailsIcons::EXPLICIT_ICON_DB_ASSOC_FIELD)
      end
      lookup_items_to_java_list(lookup_items)
    end

    def resolveReference(context)
      modelClass = extractRailsModelClass(context)
      return modelClass.nil? ? nil : AssociationsUtil.resolve_to_association_name(modelClass, element_text(context))
    end

    def getDescription(formatter)
      wrap_description("associations names defined using methods from " +
                        formatter.monospaced("ActiveRecord::Associations::ClassMethods"))
    end

    protected
    def warning_inspection(context, psiElement)
      msg = rbundle_msg("inspection.paramdef.association.name.warning", ParamDef.getTextPresentationForPsiElement(psiElement))
      InspectionResult.create_warning_result(psiElement, msg);
    end

    private
    def extractRailsModelClass(context)
      call = context.getCall
      command = call.getPsiCommand
      receiver = command.getReceiver if command.is_a? RReference
      if receiver
        refs = receiver.getReferences
        ref = refs.length > 0 ? refs[0] : nil
        clazz = ref.resolve if ref
        if clazz.is_a? RClass
          rails_model = ActiveRecordModel.from_class(clazz)
        end
      end
      rails_model = ActiveRecordModel.from_file(context.getRFile) unless rails_model 

      # returns
      rails_model.nil? ? nil : rails_model.getRClass
    end
  end
end