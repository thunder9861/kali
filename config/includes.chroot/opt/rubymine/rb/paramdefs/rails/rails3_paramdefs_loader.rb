#
# Copyright 2000-2010 JetBrains s.r.o.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Java

require File.dirname(__FILE__) + '/../paramdefs_loader_base'
require File.dirname(__FILE__) + '/paramdefs_helper'

class Rails3ParamDefsLoader < BaseParamDefsLoader
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefProvider unless defined? ParamDefProvider
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.ValidatesKeysProvider unless defined? ValidatesKeysProvider

  include RailsParamDefsHelper
  include ParamDefProvider

  def registerParamDefs(manager)
    @manager = manager

    # Action Dispatch
    paramdef 'ActionDispatch::Routing::Mapper::Base', 'match', maybe(either(controller_with_action_ref, nil)),
             {:to => controller_with_action_ref, :as => nil, :via => nil, :enable_optional_keys => controller_with_action_ref}
    paramdef 'ActionDispatch::Routing::Mapper::Base', 'root',
               either(nil, {:controller => controller_ref, :action => action_ref(:class => :controller), :enable_optional_keys => true,
                            :to => controller_with_action_ref, :as => nil, :via => nil})
    define_params_copy 'ActionDispatch::Routing::UrlFor::url_for', 'ActionController::Base::url_for'
    define_params_copy 'ActionDispatch::Routing::Mapper::Resources::resources', 'ActionController::Resources::resources'
    define_params_copy 'ActionDispatch::Routing::Mapper::Resources::resource', 'ActionController::Resources::resource'
    define_params_copy 'ActionDispatch::Routing::DeprecatedMapper::resources', 'ActionController::Resources::resources'
    define_params_copy 'ActionDispatch::Routing::DeprecatedMapper::resource', 'ActionController::Resources::resource'

    # Abstract Controller
    filters = %w{append_before_filter before_filter prepend_before_filter append_after_filter after_filter prepend_after_filter
                 append_around_filter around_filter prepend_around_filter skip_after_filter skip_before_filter skip_filter}
    filters.each do |name|
      paramdef 'AbstractController::Callbacks::ClassMethods', name, [method_ref('ActionController::Base')], before_filter_hash
    end
    define_params_copy 'AbstractController::Rendering::render', 'ActionController::Base::render'
    define_params_copy 'AbstractController::Rendering::render_to_string', 'ActionController::Base::render_to_string'
    define_params_copy 'AbstractController::Helpers::ClassMethods::helper', 'ActionController::Helpers::ClassMethods::helper'
    define_params_copy 'AbstractController::Helpers::ClassMethods::helper_method', 'ActionController::Helpers::ClassMethods::helper_method'
    define_params_copy 'AbstractController::Layouts::ClassMethods::layout', 'ActionController::Layout::ClassMethods::layout'

    # Action Controller
    define_params_copy 'ActionController::HideActions::ClassMethods::hide_action', 'ActionController::Base::hide_action'
    define_params_copy 'ActionController::Rendering::render', 'ActionController::Base::render'
    define_params_copy 'ActionController::Redirecting::redirect_to', 'ActionController::Base::redirect_to'
    # since rails 3.1
    paramdef 'ActionController::ForceSSL::ClassMethods', 'force_ssl', before_filter_hash
    paramdef 'ActionController::HttpAuthentication::Basic::ControllerMethods::ClassMethods',
             'http_basic_authenticate_with', {:name => nil, :password => nil,
                                              :realm => nil}.merge(before_filter_hash)
    paramdef 'ActionController::Streaming::ClassMethods', 'stream', before_filter_hash

    # Active Record
    calculators = %w{average count maximum minimum sum calculate}
    calculators.each do |name|
      define_params_copy "ActiveRecord::Base::#{name}",
                         "ActiveRecord::Calculations::ClassMethods::#{name}"
      define_params_copy "ActiveRecord::Calculations::#{name}",
                         "ActiveRecord::Calculations::ClassMethods::#{name}"
      # rails 3.2
      define_params_copy "ActiveRecord::Querying::#{name}", "ActiveRecord::Calculations::ClassMethods::#{name}"
    end

    # Active Record and Relation
    paramdef_arel 'includes', either(array_of(active_record_finder_includes_list_item()),
                                     one_complex_arg_or_more_of(either(active_record_finder_includes_list_item)))
    define_params_copy 'ActiveRecord::Base::includes',
                       'ActiveRecord::Relation::includes'
    paramdef_arel 'readonly', bool
    define_params_copy 'ActiveRecord::Querying::includes', 'ActiveRecord::Relation::includes'

    # Active Model
    paramdef 'ActiveModel::Validations::ClassMethods', 'validates', one_str_literal_or_more_of(migration_ref),
             {:acceptance => bool, :confirmation => bool, :inclusion => nil,
              :exclusion => nil,:numericality => either(bool, numericality_params_hash),
              :presence => bool, :uniqueness => either(bool, {:case_sensitive => bool}),
              :format => either({:with => nil, :message => nil}.merge(default_validation_options), nil),
              :length => either({:minimum => nil, :maximum => nil, :within => nil, :is => nil, :tokenizer => nil,
                                 :too_short => nil, :too_long => nil}.merge(default_validation_options), nil),
              ValidatesKeysProvider.new => bool}.merge(default_validation_options)

    validators = %w{validates_length_of validates_size_of validates_exclusion_of
                    validates_inclusion_of validates_uniqueness_of validates_format_of
                    validates_confirmation_of validates_presence_of validates_associated
                    validates_acceptance_of validates_numericality_of}
    validators.each do |name|
      define_params_copy "ActiveModel::Validations::HelperMethods::#{name}",
                         "ActiveRecord::Validations::ClassMethods::#{name}"
    end
    define_params_copy 'ActiveModel::Validations::ClassMethods::validates_each', 'ActiveRecord::Validations::ClassMethods::validates_each'     
    define_params_copy 'ActiveModel::Validations::ClassMethods::validate', 'ActiveRecord::Validations::validate'
    define_params_copy 'ActiveModel::MassAssignmentSecurity::ClassMethods::attr_accessible', 'ActiveRecord::Base::attr_accessible'
    define_params_copy 'ActiveModel::MassAssignmentSecurity::ClassMethods::attr_protected', 'ActiveRecord::Base::attr_protected'

    # Action View
    define_params_copy 'ActionView::Rendering::render', 'ActionView::Base::render'
    # since rails 3.1
    define_params_copy 'ActionView::Helpers::RenderingHelper::render', 'ActionView::Base::render'
    define_params_copy 'ActionView::Helpers::AssetTagHelper::JavascriptTagHelpers::javascript_include_tag',
                       'ActionView::Helpers::AssetTagHelper::javascript_include_tag'
    define_params_copy 'ActionView::Helpers::AssetTagHelper::StylesheetTagHelpers::stylesheet_link_tag',
                       'ActionView::Helpers::AssetTagHelper::stylesheet_link_tag'
    paramdef 'ActionView::Helpers::FormTagHelper', 'button_tag', nil,
             {:confirm? => nil, :disabled => bool, :disable_with => nil,
              :enable_optional_keys => true}   #TODO  html tag options

    # ActionMailer
    paramdef 'ActionMailer::Base', 'mail',
             {:to => nil, :from => nil, :content_type => nil, :parts_order => nil,
              :subject => nil, :charset => nil, :body => nil, :template_name => view_ref(:root => :template_path),
              :template_path => file_ref(false, :view_root, true)}

    # ActiveRecord::Relations
    paramdef 'ActiveRecord::Relation', 'order',
             either(
                     maybe(nil),
                     one_str_literal_or_more_of(migration_ref)
             ),
             maybe(nil)
    define_params_copy 'ActiveRecord::Base::order',
                       'ActiveRecord::Relation::order'

    paramdef 'ActiveRecord::Relation', 'where',
             either(
                     [maybe(nil)],
                     { migration_ref => nil,
                       table_name_ref => nil,
                       :enable_optional_keys => true }
             )
    define_params_copy 'ActiveRecord::Base::where',
                       'ActiveRecord::Relation::where'

    paramdef 'ActiveRecord::Relation', 'joins',
             either(
                     maybe(nil),
                     table_name_ref
             )
    define_params_copy 'ActiveRecord::Base::joins',
                       'ActiveRecord::Relation::joins'

    # rails 3.2
    define_params_copy 'ActiveRecord::Querying::order', 'ActiveRecord::Relation::order'
    define_params_copy 'ActiveRecord::Querying::where', 'ActiveRecord::Relation::where'
    define_params_copy 'ActiveRecord::Querying::joins', 'ActiveRecord::Relation::joins'
    define_params_copy 'ActiveRecord::Querying::find', 'ActiveRecord::Base::find'
  end

  def default_validation_options
    {:if => model_method_ref, :unless => model_method_ref, :on => nil,
     :allow_blank => bool, :allow_nil => bool}
  end

  def paramdef_arel(class_name, *params)
    paramdef 'ActiveRecord::Base', class_name, *params
    paramdef 'ActiveRecord::Relation', class_name, *params
  end
end
