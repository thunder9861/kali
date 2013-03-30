# Change list
#
# 30.09.2009
#   Support for cucumber >= 0.3.103 new api
#
# 15.05.2009
#   Fully rewritten using RubyMine ServiceMessage API. Also semantics was changed:
#      * steps should be reported as tests
#      * scenarios, features as suites
#   New cucumber 0.3.6 API was used (including --expand) option
#
# 14.05.2009
#  Initial version was given from http://github.com/darrell/cucumber_teamcity/tree/master
#  Thanks to Darrell Fuhriman (darrell [at] garnix.org)
require 'cucumber/formatter/console'
require 'fileutils'

require 'teamcity/runner_common'
require 'teamcity/utils/service_message_factory'
require 'teamcity/utils/runner_utils'
require 'teamcity/utils/url_formatter'

module Teamcity
  module Cucumber

    # old formatter api, cucumber < 0.3.103
    # new formatter api, cucumber >= 0.3.103

    USE_OLD_API = (defined? ::Cucumber::Ast::TreeWalker).nil?
    if USE_OLD_API
      require File.expand_path(File.dirname(__FILE__) + '/old_formatter')
    else
      require File.expand_path(File.dirname(__FILE__) + '/formatter_03103')
    end

    def self.same_or_newer?(version)
      given_version = version.split('.', 4)
      cuke_version = ::Cucumber::VERSION.split('.', 4)
      while cuke_version.size < given_version.size
        cuke_version << "0"
      end
      cuke_version.each_with_index do |num, i|
        gnum = given_version[i]
        if num =~ /\d*/ && gnum =~ /\d*/ && num.to_i > gnum.to_i
          return true
        elsif (num =~ /\d*/ && gnum =~ /a-zA-Z/)
          return true
        end
      end
      false
    end
  end
end