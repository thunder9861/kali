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

require File.dirname(__FILE__) + '/generate_helper'

module PsiHelper
  import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
  import org.jetbrains.plugins.ruby.ruby.lang.psi.RPsiElement unless defined? RPsiElement
  import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.blocks.RCompoundStatement unless defined? RCompoundStatement
  import org.jetbrains.plugins.ruby.ruby.lang.psi.expressions.RExpression unless defined? RExpression
  import org.jetbrains.plugins.ruby.ruby.lang.psi.RubyPsiUtil unless defined? RubyPsiUtil
  import org.jetbrains.plugins.ruby.ruby.lang.documentation.RubyCommentsUtil unless defined? RubyCommentsUtil
  import org.jetbrains.plugins.ruby.ruby.lang.psi.holders.RContainer unless defined? RContainer
  import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.names.RSuperClass unless defined? RSuperClass
  import com.intellij.psi.PsiComment unless defined? PsiComment
  import com.intellij.psi.PsiWhiteSpace unless defined? PsiWhiteSpace
  import org.jetbrains.plugins.ruby.ruby.lang.lexer.RubyTokenTypes unless defined? RubyTokenTypes
  import org.jetbrains.plugins.ruby.ruby.lang.psi.expressions.RBinaryExpression unless defined? RBinaryExpression
  import com.intellij.psi.util.PsiUtilBase unless defined? PsiUtilBase
  import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.RStringLiteral unless defined? RStringLiteral
  import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.RExpressionSubstitution unless defined? RExpressionSubstitution
  import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.RMethod unless defined? RMethod
  import org.jetbrains.plugins.ruby.ruby.lang.psi.RubyElementFactory unless defined? RubyElementFactory
  import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.expressions.RAssignmentExpressionNavigator unless defined? RAssignmentExpressionNavigator
  import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.expressions.RSelfAssignmentExpressionNavigator unless defined? RSelfAssignmentExpressionNavigator
  import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.assoc.RAssocNavigator unless defined? RAssocNavigator
  import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.methodCall.RCallNavigator unless defined? RCallNavigator
  import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.references.RReferenceNavigator unless defined? RReferenceNavigator
  import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.iterators.RBlockCallNavigator unless defined? RBlockCallNavigator
  import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.heredocs.RHeredocValue unless defined? RHeredocValue
  import org.jetbrains.plugins.ruby.ruby.codeInsight.codeFragment.RCodeFragmentBuilder unless defined? RCodeFragmentBuilder
  import com.intellij.refactoring.util.CommonRefactoringUtil unless defined? CommonRefactoringUtil
  import org.jetbrains.plugins.ruby.RBundle unless defined? RBundle
  import org.jetbrains.plugins.ruby.ruby.lang.psi.expressions.RListOfExpressions unless defined? RListOfExpressions
  import org.jetbrains.plugins.ruby.ruby.lang.psi.variables.RIdentifier unless defined? RIdentifier
  import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.RubyLanguageLevelPusher unless defined? RubyLanguageLevelPusher

  class <<self

    # returns element of given class clazzz in current editor with given psi_file
    def get_element_at(editor, psi_file, clazzz=nil)
      element = psi_file.find_element_at(editor.caret_model.offset)
      clazzz.nil? ? element : PsiTreeUtil.getParentOfType(element, clazzz.java_class)
    end

    # returns RPsiElement in current editor with given psi_file

    def get_rpsielement_at(editor, psi_file)
      get_element_at editor, psi_file, RPsiElement
    end

    # This method returns true or false or error message if refactoring is impossible
    def can_extract?(element, help_id, check_only, check_for_state_change_inside)
      if RCallNavigator.get_by_command(element) || RBlockCallNavigator.get_by_call(element)
        return RBundle.message("refactoring.introduce.command.error") unless check_only
        return false
      end

      # In this case common error message will be shown in this
      return false unless RReferenceNavigator.get_reference_by_right_part(element).nil? and
              !element.kind_of?(RHeredocValue)

      # We can skip in/out check if we introduce identifier
      if help_id.end_with?("Parameter") && element.kind_of?(RIdentifier)
        return true
      end

      # In this case common error message will be shown in this
      return false unless RAssignmentExpressionNavigator.get_assignment_by_left_part(element).nil? and
              RSelfAssignmentExpressionNavigator.get_self_assignment_by_left_part(element).nil?

      return true unless check_for_state_change_inside

      # Check that we don't have any state changes inside given fragment
      builder = RCodeFragmentBuilder.new(element.text_offset, element.text_offset + element.text_length)
      element.parent_container.accept_children(builder)
      if !help_id.end_with?("Variable") && !builder.in_elements.empty?
        return RBundle.message("refactoring.introduce.input.error") unless check_only
        return false
      end
      unless builder.out_elements.empty? && builder.modified_fields.empty?
        return RBundle.message("refactoring.introduce.state.changed.error") unless check_only
        return false
      end
      true
    end

    # returns expression, nil or error message if refactoring is impossible
    def get_selected_expression(help_id, project, file, element1, element2, check_for_state_change_inside)
      parent = PsiTreeUtil.findCommonParent element1, element2
      parent = parent.kind_of?(RPsiElement) ? parent : PsiTreeUtil.getParentOfType(parent, RPsiElement.java_class)
      return nil unless parent
      # Process result
      can_extract = can_extract?(parent, help_id, false, check_for_state_change_inside)
      return nil if can_extract == false
      return can_extract if can_extract.kind_of?(String)

      if element1 == PsiTreeUtil.get_deepest_first(parent) and element2 == PsiTreeUtil.get_deepest_last(parent)
        return parent
      end
      # Check if selection breaks ast node in binary expression
      if parent.kind_of? RBinaryExpression
        # Check if selection doesn't have errors inside
        selection = file.text[element1.text_offset .. element2.text_offset + element2.text_length]
        language_level = RubyLanguageLevelPusher.get_language_level_by_element(element1)
        expression = RubyElementFactory.get_top_level_elements(project, selection, language_level)[0]
        return nil if PsiUtilBase.has_error_element_child expression

        # Check if we can replace it with dummy identifier
        parent_text = parent.text
        start_offset = element1.text_offset - parent.text_offset - 1
        end_offset = element2.text_offset + element2.text_length - parent.text_offset

        prefix = parent_text[0 .. start_offset]
        suffix = parent_text[end_offset .. parent.text_length]
        text_range = com.intellij.openapi.util.TextRange.new(start_offset, end_offset)

        fake_parent = RubyElementFactory.get_top_level_elements(project, prefix + "RubyMineRulezzz" + suffix, language_level)[0]
        return nil if PsiUtilBase.has_error_element_child fake_parent

        expression.put_user_data(RubyPsiUtil::SELECTION_BREAKS_AST_NODE,
                com.intellij.openapi.util.Pair.create(parent, text_range))
        return expression
      end
      nil
    end

    def replace_expression(project, expression, new_expression)
      data = expression.get_user_data(RubyPsiUtil::SELECTION_BREAKS_AST_NODE)
      if data
        parent = data.first
        text_range = data.second
        parent_text = parent.text
        prefix = parent_text[0 .. text_range.start_offset]
        suffix = parent_text[text_range.end_offset .. parent.text_length]
        new_parent = RubyElementFactory.get_top_level_elements(project, prefix + new_expression.text + suffix,
                                                               RubyLanguageLevelPusher.get_language_level_by_element(expression))[0]
        parent.replace new_parent
      else
        expression.replace new_expression
      end
    end

    def replace_expression_with_text(project, expression, new_text)
      literal = PsiTreeUtil.get_parent_of_type expression, RStringLiteral.java_class
      subst = PsiTreeUtil.get_parent_of_type expression, RExpressionSubstitution.java_class
      if literal and subst.nil?
        new_expression = RubyElementFactory.create_expression_substitution_from_text project, '#{' + new_text + '}'
      else
        new_expression = RubyElementFactory.create_expression_from_text project, new_text
      end
      replace_expression project, expression, new_expression
    end

    # Return selected elements ignoring whitespaces and comments
    def get_selected_elements(editor, file)
      selection_model = editor.selection_model
      if selection_model.has_selection
        element1 = file.find_element_at(selection_model.selection_start)
        element2 = file.find_element_at(selection_model.selection_end-1)
      else
        caret_model = editor.caret_model
        document = editor.document
        line_number = document.line_number caret_model.offset
        # if we cannot find correct line
        if 0 <= line_number && line_number < document.line_count
          element1 = file.find_element_at(document.line_start_offset(line_number))
          element2 =file.find_element_at(document.line_end_offset(line_number)-1)
        else
          element1, element2 = nil, nil
        end
      end
      return nil, nil unless element1 && element2

      # Pass whitespaces and comments
      element1 = process_element(element1) do |element|
        element = element.next_sibling
        element && element.kind_of?(RPsiElement) ? PsiTreeUtil.get_deepest_first(element) : element
      end

      # Pass whitespaces and comments
      element2 = process_element(element2) do |element|
        element = element.prev_sibling
        element && element.kind_of?(RPsiElement) ? PsiTreeUtil.get_deepest_last(element) : element
      end
      return element1, element2
    end

    def process_element element
      while element && (element.node.element_type == RubyTokenTypes::tEOL or element.kind_of? PsiWhiteSpace or element.kind_of? PsiComment)
        element = yield element
      end
      element
    end


    # inserts new statements in container after element
    # element - anchor element
    # new_elements - new generated elements list

    def insert_elements element, new_elements
      inserted_elements = []
      container = PsiTreeUtil.getParentOfType element, RContainer.java_class
      comp_statement = container.compound_statement

      # looking for the following statement
      statements = comp_statement.getStatements

      @next_statement = nil
      statements.each do |statement|
        if RubyPsiUtil.isBefore(element, statement)
          @next_statement = statement
          break
        end
      end

      anchor = nil
      if @next_statement
        comments = RubyCommentsUtil.getPsiComments(@next_statement)
        if comments.size > 0
          anchor = comments[0]
        else
          anchor = @next_statement
        end
      end

      new_elements.each do |m|
        inserted_elements << comp_statement.add_before(m, anchor)
      end
      inserted_elements
    end

    def get_class_or_module_or_file(element)
      parent_element = element.parent
      if parent_element.kind_of?(RSuperClass)
        # from RConstant -> RSuperClass -> RClass to container of the class
        element = parent_element.parent.parent
      end

      container = element.kind_of?(RContainer) ? element : PsiTreeUtil.get_parent_of_type(element, RContainer.java_class)
      while container.kind_of?( RMethod)
        container = container.parent_container
      end
      container
    end
  end
end