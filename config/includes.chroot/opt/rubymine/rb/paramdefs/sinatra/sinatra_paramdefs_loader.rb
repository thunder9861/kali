include Java

require File.dirname(__FILE__) + '/../paramdefs_loader_base'

class SinatraParamDefsLoader < BaseParamDefsLoader
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefProvider unless defined? ParamDefProvider
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.SinatraViewRefParam unless defined? SinatraViewRefParam
  import org.jetbrains.plugins.ruby.sinatra.SinatraTemplateType unless defined? SinatraTemplateType
  include ParamDefProvider

  def registerParamDefs(manager)
    @manager = manager
    base 'get', nil, {:agent => nil, :hostname => nil, :provides => nil, :auth => nil, :probability => nil}
    base 'set', either(seq(maybe({:add_charsets => nil,
                           :app_file => nil,
                           :bind => nil,
                           :github_options => nil,
                           :default_encoding => nil,
                           :environment => maybe(either(:development, nil)),
                           :hostname => nil,
                           :port => nil,
                           :prefixed_redirects => nil,
                           :protection => nil,
                           :public => nil,
                           :public_folder => nil,
                           :root => nil,
                           :server => nil,
                           :static_cache_control => nil,
                           :views => nil}),
                    set_boolean_args), nil), nil
    base 'enable', enable_disable_arg
    base 'disable', enable_disable_arg
    template_type_values = SinatraTemplateType.values()
    template_type_values.each { |value|
      paramdef 'Sinatra::Templates', "#{value.getSinatraCall}", view_ref(value), maybe({:layout => nil,
                                                                                        :format => nil,
                                                                                        :style => nil,
                                                                                        :locals => nil,
                                                                                        :layout_engine => nil})
    }
  end

  private
  def base(call, *params)
    paramdef 'Sinatra::Base', call, *params
  end

  def set_boolean_args
    maybe({:absolute_redirects => bool,
           :dump_errors => bool,
           :logging => bool,
           :lock => bool,
           :method_override => bool,
           :reload_templates => bool,
           :raise_errors => bool,
           :run => bool,
           :running => bool,
           :sessions => bool,
           :show_exceptions => bool,
           :static => bool,
           :threaded => bool, })
  end

  def enable_disable_arg
    maybe_one_of(:absolute_redirects,
                 :dump_errors,
                 :logging,
                 :lock,
                 :method_override,
                 :reload_templates,
                 :raise_errors,
                 :run,
                 :running,
                 :sessions,
                 :show_exceptions,
                 :static,
                 :threaded)
  end

  def view_ref(template_type)
    either(SinatraViewRefParam.new(template_type), nil)
  end
end