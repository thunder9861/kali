include Java

require File.dirname(__FILE__) + '/../../../ruby/rb/util/psi_helper'

import org.jetbrains.plugins.ruby.ruby.codeInsight.resolve.ResolveUtil unless defined? ResolveUtil
import org.jetbrains.plugins.ruby.ruby.lang.psi.RPsiElement unless defined? RPsiElement
import org.jetbrains.plugins.ruby.jruby.types.JavaSymbolTypes unless defined? JavaSymbolTypes
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.methods.RMethod unless defined? RMethod
import org.jetbrains.plugins.ruby.ruby.lang.psi.controlStructures.modifierStatements.RModifierStatement unless defined? RModifierStatement
import org.jetbrains.plugins.ruby.ruby.lang.psi.methodCall.RCall unless defined? RCall
import org.jetbrains.plugins.ruby.jruby.psi.JRubyCallTypeProvider unless defined? JRubyCallTypeProvider
import org.jetbrains.plugins.ruby.ruby.lang.psi.methodCall.RubyCallTypes unless defined? RubyCallTypes

register_intention_action "Import Java class",
                          :category => "Ruby",
                          :description => "Replaces a qualified Java class name with a short name and adds 'import' command",
                          :before => "<spot>java.lang.System</spot>.out.print \"hello!\"",
                          :after => "import java.lang.System\nSystem.out.print \"hello!\"" do |context|
  rpsi_element = context.element_at_caret RPsiElement
  if rpsi_element
    ref = org.jetbrains.plugins.ruby.ruby.lang.psi.impl.references.RReferenceNavigator.getReferenceByRightPart(rpsi_element)
    rpsi_element = ref if ref
    symbol = ResolveUtil.resolveToSymbolWithCaching(rpsi_element.reference)
    if symbol && symbol.type == JavaSymbolTypes::JAVA_CLASS
      context.action do
        rpsi_element = rpsi_element.replace context.create_element("#{symbol.name}")

        fqn = symbol.getPsiElement.getQualifiedName
        if org.jetbrains.plugins.ruby.jruby.symbols.JavaResolveUtil.isClassInsideTopLevelPackage(symbol.getPsiElement)
          import_statement = context.create_element("import #{fqn}")
        else
          import_statement = context.create_element("import \"#{fqn}\"")
        end

        container = PsiHelper.get_class_or_module_or_file(rpsi_element)
        statements = container.statements

        if statements.empty?
          compound_statement = container.compound_statement
          compound_statement.parent.add_before import_statement, compound_statement
        else
          import_section_found = false
          prev_statement = nil
          statements.each do |statement|
            is_import = import_statement?(statement)
            if import_section_found && !is_import
              prev_statement.parent.add_after import_statement, prev_statement
              break
            end
            import_section_found ||= is_import
            prev_statement = statement
          end
          unless import_section_found
            anchor_statement = statements[0]
            parent = anchor_statement.parent
            if include_java_statement? anchor_statement
              parent.add_after import_statement, anchor_statement
            else
              parent.add_before import_statement, anchor_statement
            end
          end
        end
      end
    end
  end
end

private
def import_statement?(statement)
  if statement.kind_of?(RModifierStatement)
    return import_statement? statement.command
  end
  statement.kind_of?(RCall) && (statement.call_type == JRubyCallTypeProvider.IMPORT_CALL || statement.call_type == JRubyCallTypeProvider.JAVA_IMPORT_CALL)
end

def include_java_statement?(statement)
  if statement.kind_of?(RModifierStatement)
    return include_java_statement? statement.command
  end
  statement.kind_of?(RCall) && statement.call_type == RubyCallTypes.INCLUDE_CALL && statement.call_arguments.text == "Java"
end
