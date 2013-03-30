include Java

require File.dirname(__FILE__) + '/action_ref_param'
require File.dirname(__FILE__) + '/view_ref_param'

import org.jetbrains.plugins.ruby.rails.RailsUtil unless defined? RailsUtil

module ParamDefs
  class RenderRefParam < ParamDefBase
    def initialize(default_ref = nil)
      super()
      @default_ref = default_ref
      @view_ref = ViewRefParam.new
    end

    def resolveReference(context)
      ref = find_matching_ref(context)
      ref.resolveReference(context)
    end

    def inspectReference(context)
      ref = find_matching_ref(context)
      ref.inspectReference(context)
    end

    def handleRename(context, new_name)
      ref = find_matching_ref(context)
      ref.handleRename(context, new_name)
    end

    def getAllVariants(context)
      result = java.util.ArrayList.new
      if RailsUtil.isAttachedRails_2_3_OrHigher(context.module)
        if (@default_ref)
          action_variants = @default_ref.getAllVariants(context)
          result.add_all(action_variants) if action_variants
        end

        view_variants = @view_ref.getAllVariants(context)
        result.add_all(view_variants) if view_variants
      end
      result
    end

    private
    def find_matching_ref(context)
      return @view_ref unless @default_ref
      
      text = element_text(context)
      pos = text.index('/')
      if pos.nil?
        @default_ref
      else
        @view_ref
      end
    end
  end
end