include Java

require File.dirname(__FILE__) + '/action_keys_provider'

module RailsParamDefsHelper
  import com.intellij.util.containers.HashMap unless defined? HashMap
  import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.Visibility unless defined? Visibility
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ResolvingParamDependency unless defined? ResolvingParamDependency
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ArgumentValueParamDependency unless defined? ArgumentValueParamDependency
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.LookupItemType unless defined? LookupItemType

  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ActionMethodRefParam unless defined? ActionMethodRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ActionWithChildrenRefParam unless defined? ActionWithChildrenRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.AssetRefParam unless defined? AssetRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.AssociationRefParam unless defined? AssociationRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.AttributeRefParam unless defined? AttributeRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ControllerMethodRefParam unless defined? ControllerMethodRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ControllerRefParam unless defined? ControllerRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ExcludeRSymbolsFilter unless defined? ExcludeRSymbolsFilter
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.FileRefParam unless defined? FileRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.HelperRefParam unless defined? HelperRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.InverseOfRefParam unless defined? InverseOfRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.JoinFieldRefParam unless defined? JoinFieldRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.LayoutRefParam unless defined? LayoutRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.MethodRefParam unless defined? MethodRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.MigrationFieldRefParam unless defined? MigrationFieldRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ModelNameRefParam unless defined? ModelNameRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ModelRefParam unless defined? ModelRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.PartialRefParam unless defined? PartialRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.RenderRefParam unless defined? RenderRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ScriptRefParam unless defined? ScriptRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.StatusCodeRefParam unless defined? StatusCodeRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.TableNameRefParam unless defined? TableNameRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.UrlRefParam unless defined? UrlRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.UsedAssociationRefParam unless defined? UsedAssociationRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ViewRefParam unless defined? ViewRefParam
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ClassOrModuleDependency unless defined? ClassOrModuleDependency
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ControllerActionRefParam unless defined? ControllerActionRefParam

  include ParamDefs

  def action_ref(options = {})
    ActionMethodRefParam.new((options.has_key? :class) ? ResolvingParamDependency.new(':' + options[:class].to_s) : nil)
  end

  def action_with_children_ref(options = {})
    ActionWithChildrenRefParam.new((options.has_key? :class) ? ResolvingParamDependency.new(':' + options[:class].to_s) : nil)
  end

  def association_ref
    AssociationRefParam.new
  end

  # Options:
  #   :use_rails_actions_warning - tell that "action" not found instead of "method not found"
  def controller_public_method_ref(options = {})
    hash = com.intellij.util.containers.HashMap.new(
        options.inject({}) { |memo, (k, v)| memo[k.to_java(:"java.lang.String")] = v.to_java("java.lang.Boolean"); memo })
    ControllerMethodRefParam.new(Visibility::PUBLIC, hash)
  end

  def controller_ref(lookup_item_type=LookupItemType::String)
    ControllerRefParam.new lookup_item_type
  end

  def helper_ref(include_only_real_files = false)
    HelperRefParam.new(include_only_real_files)
  end

  def layout_ref
    LayoutRefParam.new
  end

  def image_ref
    AssetRefParam.new("getImagesRootURL", "inspection.paramdef.image.warning", "images", false)
  end

  def inverse_assoc_ref(options = {})
    if (options.has_key?(:model_ref))
      InverseOfRefParam.new
    else
      nil
    end
  end

  def link_to_methods
    one_of_strings_or_symbols(:get, :post, :put, :delete, :head)
  end

  def method_ref(top_parent=nil, min_access=Visibility::PRIVATE, options={})
    key = :class
    key = :module if !options.has_key?(key)
    class_or_module_dependency = (options.has_key? key) ? ClassOrModuleDependency.new(options[key], key == :class) : nil
    MethodRefParam.new top_parent, min_access, LookupItemType::Symbol, class_or_module_dependency
  end

  def migration_ref(options = {})
    model_ref, table_name = *(
    if options.has_key?(:model_ref)
      [ResolvingParamDependency.new(options[:model_ref].to_i), nil]
    elsif options.has_key?(:table_name)
      [nil, ArgumentValueParamDependency.new(options[:table_name].to_i)]
    else
      [nil, nil]
    end)
    MigrationFieldRefParam.new(model_ref, table_name)
  end

  def join_field_ref(options = {})
    JoinFieldRefParam.new(options.has_key?(:model_ref) ? ResolvingParamDependency.new(options[:model_ref].to_i) : nil)
  end

  def model_ref
    ModelRefParam.new
  end

  def exclude_rsymbols_filter (paramdef_ref, custom_inspection_msg = nil)
    ExcludeRSymbolsFilter.new(paramdef_ref, custom_inspection_msg)
  end

  def model_name_ref
    ModelNameRefParam.new
  end

  def model_method_ref
    method_ref('ActiveRecord::Base')
  end

  def attribute_ref
    AttributeRefParam.new
  end

  def partial_ref
    PartialRefParam.new
  end

  def file_ref(global_only = true, root_method = nil, directory = false)
    FileRefParam.new(global_only, (!root_method.nil?) ? root_method.to_s.to_java(:"java.lang.String") : nil, directory)
  end

  def rel_ref
    one_of("alternate", "stylesheet", "start", "next", "prev", "contents", "index", "glossary", "copyright", "chapter", "section", "subsection", "appendix", "help", "bookmark", "tag")
  end

  def calculation_ref
    one_of(:average, :count, :maximum, :minimum, :sum)
  end

  def status_code_ref
    StatusCodeRefParam.new
  end

  def script_ref
    AssetRefParam.new("getJavascriptsRootURL", "inspection.paramdef.script.warning", "javascripts")
  end

  def stylesheet_ref
    AssetRefParam.new("getStylesheetsRootURL", "inspection.paramdef.stylesheet.warning", "stylesheets")
  end

  def table_name_ref
    TableNameRefParam.new
  end

  def table_column_type_ref
    types_strings = org.jetbrains.plugins.ruby.rails.codeInsight.ActiveRecordType::COLUMN_TYPES

    # convert string array to symbols array
    types_symbols = types_strings.collect { |item| item.to_sym }

    one_of_strings_or_symbols(*types_symbols)
  end

  def used_association_ref
    UsedAssociationRefParam.new
  end

  def view_ref(options = {})
    ViewRefParam.new((options.has_key? :root) ? ResolvingParamDependency.new(':' + options[:root].to_s) : nil)
  end

  def url_ref
    UrlRefParam.new
  end

  def controller_with_action_ref(split = '#')
    ControllerActionRefParam.new(split)
  end

  def before_filter_hash
    {
        :except => [action_with_children_ref, :*],
        :only => [action_with_children_ref, :*],
        :if => method_ref,
        :unless => method_ref
    }
  end

  def numericality_params_hash
    {
        :only_integer => nil,
        :greater_than => nil,
        :greater_than_or_equal_to => nil,
        :equal_to => nil,
        :less_than => nil,
        :less_than_or_equal_to => nil,
        :odd => nil,
        :even => nil,
    }.merge(special_validators_params_hash)
  end

  def validation_method_params_hash
    {
        :on => one_of(:save, :create, :update),
        :if => model_method_ref,
        :unless => model_method_ref,
    }
  end

  def validators_each_params_hash
    {
        :allow_nil => nil,
        :allow_blank => nil
    }.merge(validation_method_params_hash)
  end

  def special_validators_params_hash
    {
        :message => nil,
    }.merge(validators_each_params_hash)
  end

  def old_before_filter_hash
    {
        :except => [action_with_children_ref, :*],
        :only => [action_with_children_ref, :*]
    }
  end

  def active_record_finder_includes_list_item
    either({:enable_optional_keys => true}, used_association_ref)
  end

  def rbundle_msg (msg, *args)
    org.jetbrains.plugins.ruby.RBundle.message(msg, args.to_java(:"java.lang.String"))
  end
end
