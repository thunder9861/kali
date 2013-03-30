#
# Copyright 2000-2009 JetBrains s.r.o.
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

class RailsParamDefsLoader < BaseParamDefsLoader
    import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefProvider unless defined? ParamDefProvider

    include RailsParamDefsHelper
    include ParamDefProvider

    def registerParamDefs(manager)
      @manager = manager

      # controllers
      paramdef 'ActionController::Base', ['render', 'render_to_string'],
        either(
              render_paramdef_hash(),
              RenderRefParam.new(ActionMethodRefParam.new),
              [either(partial_ref, file_ref), render_paramdef_hash],
              one_of(:update)
        )

      paramdef 'ActionController::Base', 'hide_action', [controller_public_method_ref(:use_rails_actions_warning => true)]

      paramdef 'ActionDispatch::Assertions::ResponseAssertions', 'assert_redirected_to',
            either(
              maybe(nil),
              one_of(:back),
              either(
                url_for_options_paramdef_hash(),
                url_ref()
              )
            ),
            maybe(nil)
      define_params_copy 'ActionController::Assertions::ResponseAssertions::assert_redirected_to', 'ActionDispatch::Assertions::ResponseAssertions::assert_redirected_to'

      paramdef 'ActionController::Base', 'redirect_to',
            maybe(nil),
            either(
              one_of(:back),
              {:status => status_code_ref,
               :alert => nil, :notice => nil, :flash => nil}.merge(url_for_options_paramdef_hash)
            ),
            { :status => status_code_ref}
      paramdef 'ActionController::Verification::ClassMethods', 'verify',
              { :method => link_to_methods,
                :only => [action_ref],
                :except => [action_ref],    
                :redirect_to => nil,
                :params => nil,
                :session => nil,
                :flash => nil,
                :xhr => bool,
                :add_flash => nil,
                :add_headers => nil,
                :redirect_to => nil,
                :render => render_paramdef_hash }
      # deprecated API
      paramdef 'ActionController::Pagination::ClassMethods', 'paginate', model_ref, {:per_page => nil}

      filters = %w{append_before_filter before_filter prepend_before_filter append_after_filter after_filter prepend_after_filter
                   append_around_filter around_filter prepend_around_filter skip_after_filter skip_before_filter skip_filter}
      paramdef 'ActionController::Filters::ClassMethods', filters,
                    [method_ref('ActionController::Base')], old_before_filter_hash


      paramdef 'ActionController::Base', 'url_for',
            either(
              url_for_options_paramdef_hash(),
              url_ref()
            )
      paramdef 'ActionController::Layout::ClassMethods', 'layout', layout_ref,
              {:except => [action_ref], :only => [action_ref]}

      paramdef 'ActionController::Helpers::ClassMethods', 'helper',
              [helper_ref]
      paramdef 'ActionController::Helpers::ClassMethods', 'helper_method',
              [method_ref]

      paramdef 'ActionController::Routing::RouteSet::Mapper', 'root',
               either(nil, {:controller => controller_ref, :action => action_ref(:class => :controller), :enable_optional_keys => true})
      paramdef 'ActionController::Routing::RouteSet::Mapper', 'connect',
               nil, { :controller => controller_ref, :action => action_ref(:class => :controller), :requirements => nil, :enable_optional_keys => true}
      paramdef 'ActionController::Resources', ['resources', 'resource'],
               [controller_ref(LookupItemType::Symbol)],
               { :controller => controller_ref, :collection => nil, :member => {ActionKeysProvider.new => link_to_methods}, :new => nil, :singular => nil,
                 :requirements => nil, :conditions => nil, :as => nil, :has_one => nil, :has_many => nil, :path_names => nil,
                 :path_prefix => nil, :name_prefix => nil, :shallow => bool, :enable_optional_keys => true }

      paramdef 'ActionController::RequestForgeryProtection::ClassMethods', 'protect_from_forgery',
               { :secret => nil, :digest => nil, :only => [action_with_children_ref], :except => [action_with_children_ref] }

      # deprecated API
      paramdef 'ActionController::SessionManagement::ClassMethods', 'session', maybe(:off),
               {:session_secure => bool, :only => [action_ref], :except => [action_ref],
                :if => nil }
               
      # models
      paramdef 'ActiveRecord::Base', ['attr_accessible', 'attr_protected'],
               one_str_literal_or_more_of(attribute_ref), {:as => nil}

      paramdef 'ActiveRecord::Validations', ['validate', 'validate_on_create', 'validate_on_update'],
               [model_method_ref],
               {:if => either(model_method_ref, nil)}

      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_each',
            one_str_literal_or_more_of(migration_ref),
            validators_each_params_hash

      paramdef 'ActiveRecord::Validations::ClassMethods', ['validates_length_of', 'validates_size_of'],
            one_str_literal_or_more_of(migration_ref),
            {
              :minimum => nil, :maximum => nil,
              :is => nil, :within => nil, :in => nil,
              :too_long => nil, :too_short => nil, :wrong_length => nil,
              :tokenizer => nil
             }.merge(special_validators_params_hash)

      paramdef 'ActiveRecord::Validations::ClassMethods', ['validates_exclusion_of', 'validates_inclusion_of'],
            one_str_literal_or_more_of(migration_ref),
            {
              :in => nil,
              :within => nil,    
            }.merge(special_validators_params_hash)

      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_uniqueness_of',
            one_str_literal_or_more_of(migration_ref),
            {
              :scope => nil, :case_sensitive => nil
            }.merge(special_validators_params_hash)

      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_format_of',
            one_str_literal_or_more_of(migration_ref),
            {
              :with => nil,
            }.merge(special_validators_params_hash)

      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_confirmation_of',
            one_str_literal_or_more_of(migration_ref),
            special_validators_params_hash

      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_presence_of',
            one_str_literal_or_more_of(either(migration_ref, used_association_ref)),
            {
              :message => nil
            }.merge(validation_method_params_hash)

      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_associated',
            one_str_literal_or_more_of(used_association_ref),
            special_validators_params_hash
      
      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_acceptance_of',
            one_str_literal_or_more_of(migration_ref),
            {
              :accept => nil
            }.merge(special_validators_params_hash)

      paramdef 'ActiveRecord::Validations::ClassMethods', 'validates_numericality_of',
            one_str_literal_or_more_of(migration_ref),
            numericality_params_hash

      paramdef 'ActiveRecord::Base', 'find',
            [one_of(:first, :last, :all)],   #TODO 1. one of (:f, :l, :a)) or int value (id=2) or db_field
            finders_params_hash

      paramdef 'ActiveRecord::Base', ['first', 'last', 'all'],
            finders_params_hash

      paramdef 'ActiveRecord::Associations::ClassMethods', 'belongs_to', association_ref,
         { :foreign_key => migration_ref, :primary_key => model_method_ref,
           :dependent => one_of(:delete, :destroy),
           :counter_cache => nil, :polymorphic => nil,
           :touch => bool,
           :inverse_of => inverse_assoc_ref(:model_ref => 0)
         }.merge(associations_common_hash_params)

      # TODO extract common part!
      paramdef 'ActiveRecord::Associations::ClassMethods', 'has_many', association_ref,
        { :foreign_key => migration_ref(:model_ref => 0),
          :primary_key => model_method_ref,
          :dependent => one_of(:destroy, :delete_all, :nullify),
          :counter_sql => nil,
          :finder_sql => nil,
          :extend => nil, :group => nil, :limit => nil, :offset => nil,
          :uniq => nil,
          :inverse_of => inverse_assoc_ref(:model_ref => 0)
        }.merge(associations_common_hash_params).merge(has_one_many_common_hash_params)

      paramdef 'ActiveRecord::Associations::ClassMethods', 'has_one', association_ref,
        { :foreign_key => migration_ref(:model_ref => 0),
          :primary_key => model_method_ref,
          :dependent => one_of(:destroy, :delete, :nullify),
          :inverse_of => inverse_assoc_ref(:model_ref => 0)
        }.merge(associations_common_hash_params).merge(has_one_many_common_hash_params)

      paramdef 'ActiveRecord::Associations::ClassMethods', 'has_and_belongs_to_many', association_ref,
        # TODO[den] - paramdef for value of :association_foreign_key
        { :class_name => association_class_name_ref(),
          :join_table => associations_join_table(),
          :foreign_key => join_field_ref(:model_ref => 0),
          :association_foreign_key => nil,
          :order => nil, :uniq => nil,
          :finder_sql => nil, :delete_sql => nil, :insert_sql => nil, :extend => nil,
          :group => nil, :limit => nil, :offset => nil,
        }.merge(associations_common_hash_params)


      callbacks = %w{after_find after_initialize before_save after_save before_create after_create before_update after_update before_validation
        after_validation before_validation_on_create after_validation_on_create before_validation_on_update
        after_validation_on_update before_destroy after_destroy}
      paramdef 'ActiveRecord::Callbacks', callbacks, [method_ref]

      # views
      paramdef 'ActionView::Helpers::FormTagHelper', 'form_tag',
          maybe(nil),
          url_for_options_paramdef_hash,
          { :enable_optional_keys => true,
            :method => link_to_methods,
            :multipart => nil,
            :id => nil,
            :url => nil,
            } #TODO html tag options here!!!

      paramdef 'ActionView::Helpers::UrlHelper', ['link_to', 'link_to_if', 'link_to_unless', 'link_to_unless_current'],
          nil,
          either(
            { :enable_optional_keys => true}.merge(url_for_options_paramdef_hash),
            one_of(:back),
            nil #TODO or some url string (e.g. "http://www.rubyonrails.org/")
          ),
          {
            :confirm => nil, :method => link_to_methods, :popup => nil,  #TODO  html tag options
            :id => nil, :class => nil, :title => nil,
            :style => maybe_one_of("display: none"),
            :dir => nil, :lang  => nil,
            :charset => nil, :coords => nil, :href => nil, :hreflang => nil, :name => nil,
            :rel => rel_ref, :rev => rel_ref,
            :shape => one_of("rect", "rectangle", "circ", "circle", "poly", "polygon"),
            :target => one_of("_blank", "_parent", "_self", "_top"),
            :enable_optional_keys => true # TODO[den]: add full support for remote tag with rails 3 dependent api
          }

      paramdef 'ActionView::Helpers::UrlHelper', 'mail_to',
          nil,
          maybe(nil),
          {
            :encode => one_of(:javascript, :hex),
            :replace_at => nil,
            :replace_dot => nil,
            :subject => nil,
            :body => nil,
            :cc => nil,
            :bcc => nil
          }

      paramdef 'ActionView::Helpers::FormHelper', 'form_for',
          nil,
          maybe(nil),
          {
            :url => either(nil, url_for_options_paramdef_hash),
            :html => nil,
            :builder => nil
          }

      paramdef 'ActionView::Helpers::PrototypeHelper', 'form_remote_tag',
          :url => url_for_options_paramdef_hash,
          :html => nil

      paramdef "ActionView::Helpers::AssetTagHelper", "stylesheet_link_tag", either(seq(:all, {:recursive => bool, :cache => bool}),
                                                                                    seq(one_str_literal_or_more_of(stylesheet_ref), {:media => one_of_strings_or_symbols(:screen, :all, :aural, :braille, :embossed, :handheld, :print, :projection, :tty, :tv)}))

      paramdef "ActionView::Helpers::AssetTagHelper", "image_tag",
          image_ref,
          {
            :align => one_of("top", "bottom", "middle", "left", "right"), :border => nil,
            :alt => nil,
            :title => nil,
            :id => nil,
            :style => nil,            
            :class => nil,
            :height => nil, :hspace => nil, :ismap => nil, :longdesc => nil, :usemap => nil,
            :vspace => nil, :width => nil, :size => nil,
            :mouseover => image_ref, :onmouseover => image_ref, :onmouseout => image_ref
          }
      
      paramdef "ActionView::Helpers::AssetTagHelper", "javascript_include_tag",
              either(seq(:all, {:recursive => bool}), seq(:defaults), [script_ref])
      paramdef "ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods", "replace_html",
              nil,
              { :partial => partial_ref }

      define_params_copy 'ActionView::Helpers::UrlHelper::url_for', 'ActionController::Base::url_for'
      paramdef 'ActionView::Helpers::UrlHelper', 'button_to',
              nil,
              either({
                :enable_optional_keys => true,
                :controller => controller_ref,
                :action => action_ref(:class => :controller),
                :remote => bool,
                :disabled => bool,
                :confirm => nil,
                :method => link_to_methods
              }, nil),
              {
                :anchor => nil, :only_path => nil, :trailing_slash => nil, :skip_relative_url_root => nil,
                :host => nil, :protocol => nil, :user => nil, :password => nil, :escape => nil,
                :disable => nil, :confirm => nil, :method => link_to_methods,
                :enable_optional_keys => true # TODO[den]: add full support for remote tag with rails 3 dependent api
              }

      #TODO[den]: implement :locals

      paramdef 'ActionView::Base', ['render', 'render_to_string', 'render_with_haml'],
        either(
              render_paramdef_hash(),
              RenderRefParam.new,
              seq(partial_ref, :enable_optional_keys => true),
              one_of(:update)
        )

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'add_column',
               table_name_ref,
               nil,
               table_column_type_ref,
               {
                 :column => nil,
               }.merge(table_column_change_paramdef_hash)

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'remove_column',
               table_name_ref,
               one_complex_arg_or_more_of(either(migration_ref(:table_name => 0), nil))
               table_column_type_ref
      define_params_copy 'ActiveRecord::ConnectionAdapters::SchemaStatements::remove_columns',
                         'ActiveRecord::ConnectionAdapters::SchemaStatements::remove_column'

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'change_column',
               table_name_ref,
               either(migration_ref(:table_name => 0), nil),
               table_column_type_ref,
               {}.merge(table_column_change_paramdef_hash)

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'change_column_default',
               table_name_ref,
               either(migration_ref(:table_name => 0), nil),
               nil

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'rename_column',
               table_name_ref,
               either(migration_ref(:table_name => 0), nil),
               nil

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'create_table',
               nil,
               {
                 :enable_optional_keys => true,
                 :primary_key => nil,
                 :temporary => bool,
                 :force => bool,
                 :options => nil,
                 :id => nil
               }

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'change_table',
               table_name_ref

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'drop_table',
               table_name_ref,
               {:enable_optional_keys => true}
      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'rename_table',
               table_name_ref,
               nil

      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'add_index',
               table_name_ref,
               either(migration_ref(:table_name => 0),
                      array_of(migration_ref(:table_name => 0)),
                      nil),
               either(
                 {
                   :unique => bool,
                   :name => nil
                 },
                 nil
               )
      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', 'remove_index',
               table_name_ref,
               either(migration_ref(:table_name => 0), nil),
               either(
                 {
                   :column => nil,
                   :name => nil
                 },
                 nil
               )
      paramdef 'ActiveRecord::ConnectionAdapters::SchemaStatements', ['add_timestamps', 'remove_timestamps'],
               table_name_ref

      calculations = %w(average count maximum minimum sum)
      paramdef 'ActiveRecord::Calculations::ClassMethods', calculations,
               maybe(migration_ref), calculations_options_hash
      paramdef 'ActiveRecord::Calculations::ClassMethods', 'calculate',
               calculation_ref, maybe(migration_ref), calculations_options_hash
    end

###########################################################################################################
###########################################################################################################
# Shared Parameters Hashes!
###########################################################################################################
###########################################################################################################
    def calculations_options_hash()
      {
        :conditions => nil,
        :joins => nil,
        :include => nil,
        :order => nil,
        :group => nil,
        :select => nil,
        :distinct => bool,
        :from => nil
      }
    end


    def table_column_change_paramdef_hash()
      {
              :enable_optional_keys => true,
              :limit => nil,
              :precision => nil,
              :scale => nil,
              :default => nil,
              :column => nil,
              :null => bool
      }
    end

    def render_paramdef_hash()
      { :action => either(action_ref, view_ref),
        :text => nil,
        :template => view_ref,
        :partial => partial_ref,
        :layout => layout_ref,
        :status => status_code_ref,
        :nothing => nil,
        :object => nil,
        :use_full_path => nil,
        :locals => nil,
        :content_type => maybe_one_of("text/plain", "text/html", "text/javascript", "text/css", "text/calendar", "text/csv",
                                      "application/xml", "application/rss+xml", "application/atom+xml", "application/x-yaml",
                                      "multipart/form-data", "application/x-www-form-urlencoded", "application/json"),
        :location => nil, #TODO the same as string parameter for url_for
        :inline => nil,
        :type => maybe_one_of(:builder),
        :xml => nil,
        :json => nil,
        :js => nil,
        :callback => nil,
        :collection => nil,
        :spacer_template => nil,
        :as => nil,
        :file => view_ref,
        :enable_optional_keys => true
      }
    end


  # shared option for url_for, redirect_to, and similar methods
  def routes_generate_options
    {
            :action => action_ref(:class => :controller),
            #TODO named root params
            :controller => controller_ref,
            :generate_all => nil,
            :method => link_to_methods,
            :use_route => nil,

    }
  end

  # shared option for url_for, redirect_to, and similar methods
  def url_for_options_paramdef_hash
    {
            :anchor => nil,
            :escape => nil,
            :host => nil,
            :only_path => nil,
            :password => nil,
            :port => nil,
            :protocol => nil,
            :skip_relative_url_root => nil,
            :trailing_slash => nil,
            :user => nil,

            :enable_optional_keys => true
    }.merge(routes_generate_options)
  end

  def finders_params_hash
    {
      :conditions => [nil], :order => nil, :group => nil, :limit => nil, :offset => nil,
      :joins => nil, :include => array_of(active_record_finder_includes_list_item()), :select => nil, :from => nil, :readonly => bool,
      :lock => nil
    }  #See array ActiverRecord::Base::VALID_FIND_OPTIONS
  end

  def association_class_name_ref()
    msg = rbundle_msg("inspection.paramdef.warning.forbidden.rsymbol.in.assoc.class_name")
    exclude_rsymbols_filter(model_name_ref, msg)
  end

  def associations_join_table()
    msg = rbundle_msg("inspection.paramdef.warning.forbidden.rsymbol.in.assoc.class_name")
    exclude_rsymbols_filter(nil_paramdef, msg)
  end

  def associations_common_hash_params ()
    {
            :class_name => association_class_name_ref(),
            :conditions => [nil],
            :select => nil,
            :validate => nil,
            :readonly => nil,
            :include => nil,
            :autosave => bool
    }
  end

  def has_one_many_common_hash_params()
    {:as => nil, :order => nil, :through => either(used_association_ref, model_ref), :source => nil, :source_type => nil}
  end

end
