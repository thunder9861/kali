include Java

module JetBrains::RubyMine::API::CompletionHelper
  module InsertHandlers
    import org.jetbrains.plugins.ruby.ruby.codeInsight.completion.MethodInsertHandlerCreator unless defined? MethodInsertHandlerCreator
    import org.jetbrains.plugins.ruby.ruby.codeInsight.completion.RubyAbstractMethodInsertHandler unless defined? RubyAbstractMethodInsertHandler
    import org.jetbrains.plugins.ruby.ruby.presentation.SymbolLookupUtil unless defined? SymbolLookupUtil

    class MyMethodInsertHandlerCreator
      include MethodInsertHandlerCreator

      def initialize(lines, line_num, column, handler_class = MyRubyMethodInsertHandler)
        @lines, @line_num, @column = lines, line_num, column
        @handler_class = handler_class
      end

      def createInsertHandler(method_declaration)
        @handler_class.new(method_declaration, @lines, @line_num, @column)
      end
    end


    class MyRubyMethodInsertHandler < RubyAbstractMethodInsertHandler
      def initialize(method_declaration, lines, line_num, column)
        super(method_declaration)
        @lines, @line_num, @column = lines, line_num, column
      end

      def handleInsertMethodSignature(context, method_declaration, lookup_item)
        # insert lines and reformat code
        SymbolLookupUtil.insertAndMoveCaret(@lines.to_java(:'java.lang.String'), @column, @line_num, context, lookup_item);
      end
    end

    class MyAdditionalWhiteSpaceInsertHandler < RubyAbstractMethodInsertHandler
      import com.intellij.openapi.editor.EditorModificationUtil unless defined? EditorModificationUtil
      import com.intellij.psi.PsiDocumentManager unless defined? PsiDocumentManager

      def initialize(method_declaration, lines, line_num, column)
        super(method_declaration)
        @lines, @line_num, @column = lines, line_num, column
      end

      def handleInsertMethodSignature(context, method_declaration, lookup_item)
        # insert lines and reformat code
        SymbolLookupUtil.insertAndMoveCaret(@lines.to_java(:'java.lang.String'), @column, @line_num, context, lookup_item)

        # ruby formatter will remove redundant spaces so lets
        # insert space char before 'do' and move caret at prev position : " <caret>do" -> " <caret> do"
        editor = context.getEditor()
        EditorModificationUtil.insertStringAtCaret(editor, " ")
        PsiDocumentManager.getInstance(context.getProject()).commitDocument(editor.getDocument())
        editor.getCaretModel().moveCaretRelatively(-1, 0, false, false, true);
      end
    end

    # This insert handler uses after method name autocompletion.
    # handler will insert lines from code and place caret at <caret> position
    #
    # E.g.
    # simple_after_method_insert_handler(%Q{"should <caret>" do
    #   # TODO
    # end
    # })
    def simple_after_method_insert_handler(descr, handler_class = nil)
      lines = descr.split("\n")

      line_num = 0
      column = 0

      lines.each do |line|
        column = line.index("<caret>")
        unless column.nil?
          # caret was found
          line.gsub!(/<caret>/, "")
          break;
        end
        line_num += 1;
      end

      if (handler_class.nil?)
        MyMethodInsertHandlerCreator.new(lines, line_num, column)
      else
        MyMethodInsertHandlerCreator.new(lines, line_num, column, handler_class)
      end
    end

    def insert_handler_empty_string
      simple_after_method_insert_handler(%Q{ "<caret>"})
    end

    def insert_handler_alias_method
      simple_after_method_insert_handler(%Q{ :<caret>new_name, :old_name})
    end

    def insert_handler_block_call
      simple_after_method_insert_handler(%Q{(<caret>) do

end})
    end

    def insert_handler_block_call_without_args
      simple_after_method_insert_handler(%Q{ <caret> do

end}, MyAdditionalWhiteSpaceInsertHandler)
    end

    def insert_handler_rspec_example
      simple_after_method_insert_handler(%Q{ "should <caret>" do

end})
    end
  end
end