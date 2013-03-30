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

class BundlerParamDefsLoader < BaseParamDefsLoader
  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefProvider unless defined? ParamDefProvider
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.GemRefParam unless defined? GemRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.GroupRefParam unless defined? GroupRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.FileRefParam unless defined? FileRefParam

  include ParamDefProvider

  def registerParamDefs(manager)
    @manager = manager
    
    pdef 'gem', gem_ref, maybe(nil), {:group => [group_ref], :groups => [group_ref], :git => nil,
                                      :path => nil, :require => either(bool, nil),
                                      :platforms => platforms, :platform => platforms}.merge(git_options)

    pdef 'source', either(one_of(:gemcutter, :rubygems, :rubyforge, "http://gemcutter.org",
                                 "http://rubygems.org", "http://gems.rubyforge.org"), nil), 
                  {:prepend => bool}
    pdef 'git', nil, git_options
    pdef 'group', [group_ref]
    pdef 'platforms', platforms
    pdef 'platform', platforms
    pdef 'gemspec', {:name => nil, :path => nil}
  end

  private
  def pdef(class_name, *params)
    paramdef 'Bundler::Dsl', class_name, *params
  end

  def file_ref(global_only = true)
    FileRefParam.new(global_only)
  end

  def gem_ref
    GemRefParam.new
  end

  def group_ref
    either(GroupRefParam.new, nil)
  end

  def platforms
    [one_of(:ruby, :ruby_18, :ruby_19, :mri, :mri_18, :mri_19, :jruby, :mswin, :mingw, :mingw_18, :mingw_19)]
  end

  def git_options
    {:branch => nil, :ref => nil, :tag => nil}
  end
end
