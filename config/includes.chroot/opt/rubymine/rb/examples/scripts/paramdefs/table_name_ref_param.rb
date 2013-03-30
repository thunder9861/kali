include Java

require File.dirname(__FILE__) + '/model_ref_param.rb'

import com.intellij.openapi.vfs.VfsUtil unless defined? VfsUtil
import org.jetbrains.plugins.ruby.utils.NamingConventions unless defined? NamingConventions
import org.jetbrains.plugins.ruby.utils.VirtualFileUtil unless defined? VirtualFileUtil
import org.jetbrains.plugins.ruby.rails.migrations.MigrationParser unless defined? MigrationParser

module ParamDefs
  class TableNameRefParam < ParamDefBase

    def getAllVariants(context)
      m = context.module
      return nil if m.nil?

      all_tables = MigrationParser.get_instance(m).get_all_tables

      collect_lookup_items_from_list(context, all_tables, LookupItemType::Symbol) { |table_name|
        [table_name, RailsIcons::DB_TABLE]
      }
    end

    def resolveReference(context)
      m = context.module
      return nil if m.nil?

      name = element_text(context)
      return nil if name.nil?

      migration_parser = org.jetbrains.plugins.ruby.rails.migrations.MigrationParser.get_instance(m)
      migration_parser.get_table_def(name)
    end

    def getDescription(formatter)
      wrap_description("DB table name")
    end

    protected

    def warning_inspection(context, psi_element)
      m = context.module
      table_example_name = if (m.nil?)
        nil # return
      else
        tables = MigrationParser.get_instance(m).get_all_tables
        java.util.Arrays::sort(tables)
        tables.length == 0 ? nil : tables[0] # return
      end
      eg_text = table_example_name.nil? ? "" : rbundle_msg("inspection.paramdef.warning.eg.singular", table_example_name)
      msg = rbundle_msg("inspection.paramdef.table_name.warning", ParamDef.getTextPresentationForPsiElement(psi_element), eg_text)
      InspectionResult.create_warning_result(psi_element, msg);
    end
  end
end