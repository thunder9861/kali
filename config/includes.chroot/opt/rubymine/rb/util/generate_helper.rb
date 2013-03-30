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

module GenerateHelper

    import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.RubyLanguageLevelPusher unless defined? RubyLanguageLevelPusher
    include_class 'org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.RMethod' unless defined? RMethod
    include_class 'org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.RSingletonMethod' unless
            defined? RSingletonMethod
    include_class 'org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.ArgumentInfo' unless
            defined? ArgumentInfo
    include_class 'org.jetbrains.plugins.ruby.ruby.lang.psi.RubyElementFactory' unless defined? RubyElementFactory
    include_class 'org.jetbrains.plugins.ruby.ruby.lang.parser.bnf.BNF' unless defined? BNF

    COMMENT_TEXT = "#code here" unless defined? COMMENT_TEXT

    # Generates new method with the same signature
    def self.generate_new_method element
        # Ruby method
        if element.kind_of? RMethod
            text = "def "
            text << "self." if element.kind_of? RSingletonMethod
            text << "#{element.name}("
            first = true
            # arguments generating
            element.getArgumentInfos.each do |arg_info|
                text << ',' unless first
                first = false

                type = arg_info.type

                if type == ArgumentInfo::Type::SIMPLE
                    text << "#{arg_info.name}"
                elsif type == ArgumentInfo::Type::PREDEFINED
                    text << "#{arg_info.name}=nil"
                elsif type == ArgumentInfo::Type::ARRAY
                    text << "*#{arg_info.name}"
                elsif type == ArgumentInfo::Type::BLOCK
                    text << "&#{arg_info.name}"
                end
            end
            text << ")\n  #{COMMENT_TEXT}\nend"

            # text is ok now. Creating psiElement by text
            RubyElementFactory.getTopLevelElements(element.project, text, RubyLanguageLevelPusher.get_language_level_by_element(element))[0]
        else
            org.jetbrains.plugins.ruby.ruby.codeInsight.OverriddenMethodGenerator.generate element
        end
    end
end