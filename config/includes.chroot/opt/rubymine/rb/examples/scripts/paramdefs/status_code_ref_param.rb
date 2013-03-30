include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import com.intellij.openapi.vfs.VfsUtil unless defined? VfsUtil
import com.intellij.psi.PsiManager unless defined? PsiManager
import org.jetbrains.plugins.ruby.utils.NamingConventions unless defined? NamingConventions
import org.jetbrains.plugins.ruby.gem.util.GemSearchUtil unless defined? GemSearchUtil
import org.jetbrains.plugins.ruby.ruby.RubyIcons unless defined? RubyIcons
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RSymbol unless defined? RSymbol
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.RIntegerConstant unless defined? RIntegerConstant
import org.jetbrains.plugins.ruby.ruby.lang.psi.basicTypes.stringLiterals.RStringLiteral unless defined? RStringLiteral
import com.intellij.psi.util.PsiTreeUtil unless defined? PsiTreeUtil
import org.jetbrains.plugins.ruby.ruby.lang.TextUtil unless defined? TextUtil

module ParamDefs
  class StatusCodeRefParam < ParamDefBase
    def getDescription(formatter)
      wrap_description "HTTP Error Codes"
    end

    def getAllVariants(context)
      status_file = find_codes context
      return nil unless status_file
      is_in_symbol = context.get_value_element.is_a?(RSymbol)
      is_in_string = context.get_value_element.is_a?(RStringLiteral)
      codes = VfsUtil::loadText(status_file)
      result = []
      icon = RubyIcons::RUBY_CONSTANT_NODE
      codes.scan(/^\s*(\d\d\d)\s*=>\s*['|"](.*)['|"],?\r?$/) do |code, status|
        type = "#{status} (#{code})"
        if (!is_in_symbol)
          result << create_typed_lookup_item(context, code, type, LookupItemType::None, icon) if !is_in_string
          result << create_typed_lookup_item(context, "#{code} #{status}", type, LookupItemType::String, icon) if is_in_string
        end
        symbol = status_to_symbol status
        result << create_typed_lookup_item(context, symbol, type, LookupItemType::Symbol, icon) if !is_in_string
      end
      lookup_items_to_java_list(result)
    end

    def resolveReference(context)
      status_file = find_codes context
      return nil unless status_file

      ruby_file = PsiManager.getInstance(context.project).findFile(status_file)
      return nil unless ruby_file

      codes = VfsUtil::loadText(status_file)
      codes.gsub!(/\r/, "")
      
      element = context.value_element
      if element.is_a? RIntegerConstant
        status_code = element.getText
        return find_by_status_code(codes, ruby_file, status_code)
      elsif element.is_a? RStringLiteral
        text = TextUtil.removeQuoting element.get_text
        text.scan(/^\s*(\d\d\d).*$/) do |status_code|
          return find_by_status_code(codes, ruby_file, status_code)
        end
      elsif element.is_a? RSymbol
        text = element.getContent.getText
        status = nil
        codes.scan(/^\s*(\d\d\d)\s*=>\s*['|"](.*)['|"],?\r?$/) do |_, stat|
          if status_to_symbol(stat) == text
            status = stat
          end
        end
        index = codes.index(/\d\d\d\s*=>\s*['|"]#{status}['|"]/)
        return PsiTreeUtil::findElementOfClassAtOffset(ruby_file, index, RIntegerConstant.java_class, true) if index
      end

      nil
    end

    #protected
    #def warning_inspection(context, level, psiElement)
    #  msg = rBundle_msg("", ParamDef.getTextPresentationForPsiElement(psiElement))
    #  InspectionResult.create_warning_result(psiElement, msg, [].to_java(:'com.intellij.codeInspection.LocalQuickFix'));
    #end

    private
    def find_codes(context)
      action_pack = GemSearchUtil::findGem(context.module, "actionpack")
      rack = GemSearchUtil::findGem(context.module, "rack")
      result = nil
      if action_pack
        child = action_pack.getFile
        result = child.findFileByRelativePath("lib/action_controller/status_codes.rb") if child && !result
      end
      if rack
        child = rack.getFile
        result = child.findFileByRelativePath("lib/rack/utils.rb") if child && !result
      end
      result
    end

    def status_to_symbol(status)
      NamingConventions::toUnderscoreCase(status.gsub(/ /, ""))
    end

    def find_by_status_code(codes, ruby_file, status_code)
      index = codes.index(/#{status_code}\s*=>\s*['|"](.*)['|"],?\r?$/)
      return PsiTreeUtil::findElementOfClassAtOffset(ruby_file, index, RIntegerConstant.java_class, true) if index
      nil
    end
  end
end