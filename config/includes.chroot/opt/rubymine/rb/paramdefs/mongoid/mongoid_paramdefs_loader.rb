include Java

require File.dirname(__FILE__) + '/../paramdefs_loader_base'

class MongoidParamDefsLoader < BaseParamDefsLoader

  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefProvider unless defined? ParamDefProvider
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.MongoAttributeRefParam unless defined? MongoAttributeRefParam
  include ParamDefProvider
  include RailsParamDefsHelper

  def registerParamDefs(manager)
    @manager = manager
    paramdef 'Mongoid::Fields::ClassMethods', 'field', field
    paramdef 'Mongoid::Relations::Macros::ClassMethods', 'embeds_many', AssociationRefParam.new, {:as => model_ref,
                                                                                                  :cascade_callbacks => bool,
                                                                                                  :validate => bool}
    paramdef 'Mongoid::Relations::Macros::ClassMethods', 'embeds_one', AssociationRefParam.new, {:cascade_callbacks => bool,
                                                                                                 :validate => bool}
    paramdef 'Mongoid::Relations::Macros::ClassMethods', 'embedded_in', AssociationRefParam.new, {:polymorphic => bool}
    paramdef 'Mongoid::Relations::Macros::ClassMethods', 'belongs_to', AssociationRefParam.new, maybe(class_name)
    paramdef 'Mongoid::Relations::Macros::ClassMethods', 'has_one', AssociationRefParam.new, maybe(class_name)
    paramdef 'Mongoid::Relations::Macros::ClassMethods', 'has_many', AssociationRefParam.new, maybe(class_name)
    paramdef 'Mongoid::Relations::Macros::ClassMethods', 'has_and_belongs_to_many', AssociationRefParam.new, maybe(class_name)

    paramdef 'Mongoid::Attributes::Readonly::ClassMethods', 'attr_readonly', MongoAttributeRefParam.new
    paramdef 'Mongoid::Attributes', 'write_attribute', maybe(nil)
    paramdef 'Mongoid::Attributes', 'read_attribute', field


    paramdef 'ActiveModel::Validations::ClassMethods', 'validates', one_str_literal_or_more_of(MongoAttributeRefParam.new), maybe(class_name)
  end

  private
  def field
    seq(nil, {:type => data_type, :null => bool, :default => nil})
  end

  def class_name
    {:class_name => nil}
  end
end