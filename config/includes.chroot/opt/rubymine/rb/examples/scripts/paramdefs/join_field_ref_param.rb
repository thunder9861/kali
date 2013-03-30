include Java

require File.dirname(__FILE__) + '/migration_field_ref_param.rb'

import org.jetbrains.plugins.ruby.rails.migrations.MigrationParser unless defined? MigrationParser
import org.jetbrains.plugins.ruby.rails.InflectorService unless defined? InflectorService

module ParamDefs
  class JoinFieldRefParam < MigrationFieldRefParam
  def initialize(class_dependency = nil)
    super(class_dependency)
  end

  protected
    def get_fields(context)
      dep_value = @model_class_ref_dependency.getValue(context)
      return [] unless dep_value
      self_name = PsiTreeUtil::getParentOfType(context.call, RClass.java_class).name
      dep_name = dep_value.name
      inflector = InflectorService.get_instance(context.module)
      if inflector.is_inflector_available
        self_name = inflector.tableize(self_name)
        dep_name = inflector.tableize(dep_name)
      end
      parser = MigrationParser.get_instance(context.module)
      if self_name < dep_name
        table_name = self_name + "_" + dep_name
      else
        table_name = dep_name + "_" + self_name
      end
      parser.get_fields_by_table_name(table_name)
    end
  end
end