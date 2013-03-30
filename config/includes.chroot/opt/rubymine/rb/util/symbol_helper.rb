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

module SymbolHelper
    include_class 'com.intellij.psi.util.PsiTreeUtil' unless defined? PsiTreeUtil
    include_class 'org.jetbrains.plugins.ruby.ruby.lang.psi.holders.RContainer' unless defined? RContainer
    include_class 'org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.structure.SymbolUtil' unless defined? SymbolUtil
    include_class 'org.jetbrains.plugins.ruby.ruby.codeInsight.symbols.Type' unless defined? Type

    def with_element_and_symbol editor, file
        # here we find symbol for given location
        element = file.find_element_at editor.caret_model.offset
        unless element
            yield nil, nil
            return
        end

        container = PsiTreeUtil.getParentOfType element, RContainer.java_class
        unless container
            yield nil, nil
            return
        end


        symbol = SymbolUtil.getSymbolByContainer container
        unless symbol
            yield nil, nil
            return
        end

        # check for symbol type. We should perform only if we`re in module or class
        type = symbol.getType
        unless type == Type::CLASS or type == Type::MODULE
            yield nil, nil
            return
        end
        # if everything is ok)
        yield element, symbol
    end
end