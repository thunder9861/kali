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

class CapistranoParamDefsLoader < BaseParamDefsLoader

  import org.jetbrains.plugins.ruby.ruby.codeInsight.paramDefs.ParamDefProvider unless defined? ParamDefProvider
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.GroupRefParam unless defined? GroupRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.GemRefParam unless defined? GemRefParam
  import org.jetbrains.plugins.ruby.rails.codeInsight.paramDefs.CapistranoStageRefParam unless defined? CapistranoStageRefParam
  include ParamDefProvider

  def registerParamDefs(manager)
    @manager = manager
    paramdef 'Capistrano::Configuration::Variables', 'set', either(application,
                                                                   deploy, deploy_to, deploy_via,
                                                                   group,
                                                                   repository,
                                                                   password,
                                                                   user,
                                                                   csm,
                                                                   use_sudo,
                                                                   branch,
                                                                   scm_verbose,
                                                                   copy_cache,
                                                                   copy_compression,
                                                                   rails_env,
                                                                   repository_cache,
                                                                   copy_remote_dir,
                                                                   rake,
                                                                   scm_auth_cache,
                                                                   migrate_env,
                                                                   migrate_target,
                                                                   gem_command,
                                                                   keep_releases,
                                                                   gateway,
                                                                   normalize_asset_timestamps,
                                                                   default_shell, shell,
                                                                   git_enable_submodules, git_shallow_clone,
                                                                   stages, default_stage,
                                                                   deploy_env,
                                                                   svn_options

    )
    paramdef 'Capistrano::Configuration::Roles', 'role', role
    paramdef 'Capistrano::Configuration::Roles', 'server', server
    paramdef 'Capistrano::Configuration::Namespaces', 'task', task

  end

  private
  #set section
  def application
    seq(:application, nil)
  end

  def deploy
    seq(:deploy, nil)
  end

  def deploy_to
    seq(:deploy_to, nil)
  end

  def repository
    seq(:repository, nil)
  end

  def password
    seq(:password, nil)
  end

  def user
    seq(:user, nil)
  end

  def csm
    seq(:scm, maybe_one_of(:accurev, :bzr, :cvs, :darcs, :git, :mercurial, :perforce, :subversion, :none))
  end

  def use_sudo
    seq(:use_sudo, bool)
  end

  def branch
    seq(:branch, nil)
  end

  def scm_verbose
    seq(:scm_verbose, bool)
  end

  def deploy_via
    seq(:deploy_via, maybe_one_of(:checkout, :export, :remote_cache, :copy))
  end

  def gateway
    seq(:gateway, nil)
  end

  def copy_cache
    seq(:copy_cache, bool)
  end

  def copy_compression
    seq(:copy_compression, maybe_one_of(:gzip, :gz, :bzip2, :bz2, :zip))
  end

  def rails_env
    seq(:rails_env, either(GroupRefParam.new, nil))
  end

  def repository_cache
    seq(:repository_cache, nil)
  end

  def copy_remote_dir
    seq(:copy_remote_dir, nil)
  end

  def rake
    seq(:rake, nil)
  end

  def scm_auth_cache
    seq(:scm_auth_cache, bool)
  end

  def migrate_env
    seq(:migrate_env, GroupRefParam.new)
  end

  def migrate_target
    seq(:migrate_target, maybe(:latest))
  end

  def gem_command
    seq(:gem_command, GemRefParam.new)
  end

  def keep_releases
    seq(:keep_releases, nil)
  end

  def admin_runner
    seq(:admin_runner, maybe_one_of("root", nil))
  end

  def normalize_asset_timestamps
    seq(:normalize_asset_timestamps, bool)
  end

  def default_shell
    seq(:default_shell, nil)
  end

  def shell
    seq(:shell, nil)
  end

  def git_enable_submodules
    seq(:git_enable_submodules, bool)
  end

  def git_shallow_clone
    seq(:git_shallow_clone, bool)
  end

  #staging
  def stages
    seq(:stages, nil)
  end

  def default_stage
    seq(:default_stage, nil)
  end

  def group
    seq(:group, nil)
  end

  def deploy_env
    seq(:deploy_env, CapistranoStageRefParam.new)
  end

  def svn_options
    maybe_one_of(:svn_username, :svn_password, :checkout)
  end

  #others
  def role
    seq(maybe_one_of(:web, :app, :db), one_str_literal_or_more_of(nil), maybe({:primary => nil}))
  end

  def task
    seq(nil, maybe(:search_libs), {:hosts => nil}, {:roles => maybe_one_of(:web, :app, :db), one_of(:only, :except) => {maybe_one_of(:no_release, :primary) => bool}})
  end

  def server
    seq(nil, seq(:app, :web, :db), maybe({:primary => nil}))
  end
end