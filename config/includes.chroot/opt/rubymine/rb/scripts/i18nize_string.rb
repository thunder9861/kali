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

require 'intention_action_helper'
require File.expand_path(File.dirname(__FILE__) + '/../util/execute_helper')

import com.intellij.openapi.module.ModuleUtil unless defined? ModuleUtil
import org.jetbrains.plugins.ruby.i18n.I18nUtil unless defined? I18nUtil
import org.jetbrains.plugins.ruby.i18n.inspection.quickfixes.I18nCreatePropertyDialog
import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RSymbol unless defined? RSymbol
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.RStringLiteral unless defined? RStringLiteral
import org.jetbrains.plugins.ruby.ruby.lang.psi.impl.methodCall.RCallNavigator unless defined? RCallNavigator
import org.jetbrains.plugins.ruby.i18n.I18nTranslateCallType unless defined? I18nTranslateCallType
import org.jetbrains.plugins.ruby.ruby.lang.RubyLanguage unless defined? RubyLanguage
import org.jetbrains.plugins.ruby.templates.TemplateIntegrationUtils unless defined? TemplateIntegrationUtils
import com.intellij.lang.xml.XMLLanguage unless defined? XMLLanguage
import com.intellij.lang.html.HTMLLanguage unless defined? HTMLLanguage
import org.jetbrains.plugins.ruby.erb.psi.ERbFile unless defined? ERbFile

LOG = com.intellij.openapi.diagnostic.Logger.getInstance("#rb.scripts.I18nize")

module I18nize
  I18NIZE_TEXT = "I18n string value"

  import com.intellij.openapi.editor.EditorModificationUtil unless defined? EditorModificationUtil
  import com.intellij.psi.xml.XmlTokenType unless defined? XmlTokenType


  def self.initial_value element
    if element.kind_of?(RStringLiteral)
      return nil if element.has_expression_substitutions
      return element.content
    end
    if element.kind_of?(RSymbol)
      content = element.content
      return nil if content.kind_of?(RStringLiteral) && content.has_expression_substitutions
      return element.value
    end
  end

  def self.find_element context
    editor = context.editor
    file = context.file
    selection_model = editor.selection_model
    if selection_model.has_selection
      selection_start = selection_model.selection_start
      selection_end = selection_model.selection_end

      element1 = file.find_element_at(selection_start)
      element2 = file.find_element_at(selection_end - 1)
      element1 = element1.parent if element1 && element1.language == RubyLanguage::INSTANCE
      element2 = element2.parent if element2 && element2.language == RubyLanguage::INSTANCE

      return nil unless element1 && element1 == element2
      return nil unless selection_start == element1.text_offset && selection_end == selection_start + element1.text_length
      return element1
    else
      return context.element_at_caret
    end
  end

  def self.process_ruby_code (context, mod, element)
    LOG.debug("Processing ruby code with element: #{element}") if LOG.is_debug_enabled
    return if element.nil?
    unless element.kind_of?(RSymbol) || element.kind_of?(RStringLiteral)
      element = PsiTreeUtil.get_parent_of_type(element,
                                               [RSymbol.java_class, RStringLiteral.java_class].to_java("java.lang.Class"))
    end

    LOG.debug("Element to process: #{element}") if LOG.is_debug_enabled
    return if element.nil?

    # Do not prompt this intention for translate calls arguments
    call = RCallNavigator.getByRArgument(element)
    return if call && call.get_call_type.kind_of?(I18nTranslateCallType)

    # Compute value
    initial_value = I18nize.initial_value(element)
    LOG.debug("Value to i18nize: #{initial_value}") if LOG.is_debug_enabled
    return unless initial_value

    # TODO[oleg]: check whether it is controller, helper or view context
    context.action do
      dictionary = I18nUtil.getDictionary(mod)
      project = context.project
      map = {}
      dictionary.all_locale_entries.each do |locale_entry|
        map[locale_entry.get_locale_entry_presentable_name()] = locale_entry
      end

      dialog = I18nCreatePropertyDialog.new(project, nil, initial_value, map, dictionary)
      dialog.show
      if dialog.isOK()
        ExecuteHelper.run_as_command_in_write_action(project, I18NIZE_TEXT) do
          key = dialog.property_key
          value = dialog.property_value

          element.replace(context.create_element("t('#{key}')"))
          selected_locale = map[dialog.selected_locale]
          # Create property record
          selected_locale.createI18nRecord(key, %Q("#{value}"));
        end
      end
    end
  end

  # for now we support only HAML.  As soon as your template language
  # will not fit current scheme feel free to change everything ;)
  def self.process_template_code (context, mod, element)
    return if element.nil?
    return unless TemplateIntegrationUtils.can_apply_i18n element
    # Perform i18n
    process_i18nization(context, mod, element.text_offset, element.text_offset + element.text_length) do |key|
      "= t('#{key}')"
    end
  end

  def self.process_html_code(context, mod)
    # Calculate selection
    editor = context.editor
    selection_model = editor.selection_model
    return unless selection_model.has_selection
    selection_start = selection_model.selection_start
    selection_end = selection_model.selection_end
    # Perform i18n
    process_i18nization(context, mod, selection_start, selection_end) do |key|
      "<%= t('#{key}') %>"
    end
  end

  def self.process_i18nization context, mod, selection_start, selection_end, &block
    return if selection_start.nil? || selection_end.nil?
    editor = context.editor
    file = context.file

    # TODO[oleg]: check whether it is controller, helper or view context
    initial_value = file.text[selection_start..selection_end-1]
    context.action do
      dictionary = I18nUtil.getDictionary(mod)
      project = context.project
      ExecuteHelper.run_in_edt do
        map = {}
        dictionary.all_locale_entries.each do |locale_entry|
          map[locale_entry.get_locale_entry_presentable_name()] = locale_entry
        end
        dialog = I18nCreatePropertyDialog.new(project, nil, initial_value, map, dictionary)
        dialog.show
        if dialog.isOK()
          ExecuteHelper.run_as_command_in_write_action(project, "I18nize plain text") do
            editor.selection_model.set_selection(selection_start, selection_end)
            key = dialog.property_key
            value = dialog.property_value
            EditorModificationUtil.delete_selected_text(editor)
            replacement_text = block.call(key)
            EditorModificationUtil.insert_string_at_caret(editor, replacement_text)
            selected_locale = map[dialog.selected_locale]
            # Create property record
            selected_locale.createI18nRecord(key, %Q("#{value}"));
          end
        end
      end
    end
  end

end


register_intention_action I18nize::I18NIZE_TEXT,
                          :category => "Ruby",
                          :description => I18nize::I18NIZE_TEXT,
                          :before => "<spot>'Hello world!'</spot>",
                          :after => "t(:hello_world)" do |context|
  LOG.debug("I18nize intention called") if LOG.is_debug_enabled
  file = context.file
  unless file.nil?
    mod = ModuleUtil.find_module_for_psi_element(file)
    if I18nUtil.isI18nSupportEnabled(mod)
      element = I18nize.find_element context
      unless element.nil?
        language = element.language
        LOG.debug("Language: #{language}") if LOG.is_debug_enabled
        # Process Ruby Code
        if language == RubyLanguage::INSTANCE
          LOG.debug("Processing ruby code") if LOG.is_debug_enabled
          I18nize.process_ruby_code(context, mod, element)

          # Process Template Code
        else
          if !TemplateIntegrationUtils.getTemplateLanguage(language).nil?
            LOG.debug("Processing #{language} code") if LOG.is_debug_enabled
            I18nize.process_template_code(context, mod, element)
          else
            LOG.debug("Cannot process") if LOG.is_debug_enabled
          end
        end
      end

      # Process HTML text within Erb file
    elsif file.kind_of?(ERbFile)
      LOG.debug("Processing HTML code") if LOG.is_debug_enabled
      I18nize.process_html_code(context, mod)
    else
      LOG.debug("Cannot process") if LOG.is_debug_enabled
    end
  end
end
