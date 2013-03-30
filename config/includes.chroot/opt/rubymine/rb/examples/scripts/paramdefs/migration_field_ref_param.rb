include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
import com.intellij.openapi.module.ModuleUtil unless defined? ModuleUtil
import org.jetbrains.plugins.ruby.rails.model.ActiveRecordModel unless defined? ActiveRecordModel
import org.jetbrains.plugins.ruby.rails.RailsIcons unless defined? RailsIcons
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.classes.RClass unless defined? RClass
import org.jetbrains.plugins.ruby.rails.migrations.MigrationParser unless defined? MigrationParser
import org.jetbrains.plugins.ruby.ruby.lang.psi.references.RDotReference unless defined? RDotReference
import org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.structure.SymbolUtil unless defined? SymbolUtil

module ParamDefs
  class MigrationFieldRefParam < ParamDefBase
    def initialize(model_class_ref_dependency = nil, tablename_dependency = nil)
      super()
      @model_class_ref_dependency = model_class_ref_dependency
      @tablename_dependency = tablename_dependency
    end

    def getAllVariants(context)
      fields = get_fields(context)
      result = Array.new
      if not fields.nil?
        fields.each do |field|
          result << create_typed_lookup_item(context, field.name, field.data_type, LookupItemType::Symbol, RailsIcons::EXPLICIT_ICON_DB_FIELD) unless field.name == "id"
        end
      end 
      result
    end

    def resolveReference(context)
      name = element_text(context)
      fields = get_fields(context)
      return nil unless fields

      fields.each do |field|
        if field.name == name
          decl = field.get_declarations
          return decl.get(decl.size - 1) unless decl.empty?
        end
      end
      nil
    end

    def getDescription(formatter)
      wrap_description "table attributes for current model"
    end


    def inspection_enabled_for?(context)
      m = context.module
      return false if m.nil?
      # ignore if undefined table name is provided by unresolved table
      # name dependency
      if @tablename_dependency && !MigrationParser.get_instance(m).containsTable(determine_table_name(context))
        return false
      end
      # ignore if undefined table name is provided by unresolved model
      # name dependency
      if @model_class_ref_dependency && !MigrationParser.get_instance(m).containsTable(determine_table_name(context))
        return false
      end
      super(context)
    end

    def warning_inspection(context, psi_element)
      table_name = determine_table_name(context)
      if (table_name.nil?)
        msg = rbundle_msg("inspection.paramdef.migration.warning.undefined.db",
                           get_target_class_name(context), ParamDef.getTextPresentationForPsiElement(psi_element))
      else
        fields_collection = get_fields(context)
        eg_text = if !fields_collection.nil? && !fields_collection.is_empty?
          iterator = fields_collection.iterator
          some_fields = []
          count = 0
          while (count < 3 && iterator.has_next) do
            next_field = iterator.next.get_name
            if (next_field && "id" != next_field.downcase)
              some_fields << next_field
            end
            count += 1
          end
          variants_text = nil
          if (!some_fields.at(0).nil?)
            variants_text = ":#{some_fields.at(0)}"
            if (!some_fields.at(1).nil?)
              variants_text << " or :#{some_fields.at(1)}"
            end
          end
          variants_text.nil? ? "" : " " + rbundle_msg("inspection.paramdef.warning.eg.singular", variants_text)
        else
          ""
        end

        msg = rbundle_msg("inspection.paramdef.migration.warning",
                           table_name, ParamDef.getTextPresentationForPsiElement(psi_element),
                           eg_text)
      end
      InspectionResult.create_warning_result(psi_element, msg)
    end

    protected
    def get_fields(context)
      m = context.module
      return if m.nil?

      # table name
      tablename = determine_table_name(context)

      return nil if tablename.nil?

      # fields by table name
      return MigrationParser.get_instance(m).get_fields_by_table_name(tablename)
    end

    def determine_table_name(context)
      if @tablename_dependency
        m = context.module
        return nil if m.nil?

        # psi argument with name
        table_name_element = @tablename_dependency.getValue(context)
        return nil if table_name_element.nil?

        # table name
        return RubyPsiUtil.getElementText(table_name_element)
      else
        # fields by model class name
        model_class_name = get_target_class_name(context)
        active_record_model = ActiveRecordModel.from_model_name(context.module, model_class_name)
        return nil if active_record_model.nil?

        return active_record_model.table_name
      end
    end

    private

    def get_target_class_name(context)
      if @model_class_ref_dependency
        value = @model_class_ref_dependency.getValue(context)
        return nil unless value
        return value.name
      end

      context_element = context.call
      command = context_element.getPsiCommand
      clazz = nil
      receiver = nil
      while command.is_a? RDotReference do
        receiver = command.getReceiver
        command = receiver
      end
      if receiver
        ref = receiver.getReference
        clazz = ref.resolve if ref
      end
      clazz = PsiTreeUtil::getParentOfType(context_element, RClass.java_class) unless clazz
      return nil unless clazz.is_a?(RClass)
      symbol = SymbolUtil::getSymbolByContainer(clazz)
      SymbolUtil::getSymbolFullQualifiedName(symbol)
    end
  end
end