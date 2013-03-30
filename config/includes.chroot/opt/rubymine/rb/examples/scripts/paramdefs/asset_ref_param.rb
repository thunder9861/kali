include Java

require File.dirname(__FILE__) + '/paramdef_base.rb'

import org.jetbrains.plugins.ruby.rails.facet.RailsFacetUtil unless defined? RailsFacetUtil
import com.intellij.openapi.fileTypes.FileTypeManager unless defined? FileTypeManager
import com.intellij.openapi.vfs.VirtualFileManager unless defined? VirtualFileManager
import org.jetbrains.plugins.ruby.rails.codeInsight.sprockets.SprocketReference unless defined? SprocketReference
import com.intellij.openapi.util.text.StringUtil unless defined? StringUtil
import com.intellij.openapi.util.Ref unless defined? Ref
import org.jetbrains.plugins.ruby.rails.nameConventions.ViewsConventions unless defined? ViewsConventions
import org.jetbrains.plugins.ruby.rails.actions.CreateNamedFileFix unless defined? CreateNamedFileFix
import org.jetbrains.plugins.ruby.rails.codeInsight.sprockets.SprocketsUtil unless defined? SprocketsUtil

module ParamDefs
  class AssetRefParam < ParamDefBase

    def initialize(url, inspection_message, asset_type, has_quickfix = true)
      super()
      asset = SprocketsUtil::AssetsGroup.valueOf(asset_type.upcase)
      @extensions = asset.getSupportedFileTypes
      @url = url
      @inspection_message = inspection_message
      @has_quickfix = has_quickfix
      @need_extension = asset.requiresExtension
      @asset_type = asset_type
    end

    def getAllVariants(context)
      return nil if context.get_value_element.is_a?(RSymbol)

      rails_app = rails_app(context)
      if (rails_app && SprocketsUtil.areAssetsEnabled(rails_app))
        ref = Ref.create("")
        result = java.util.HashSet.new
        SprocketReference.get_variants_from_loadpath(context.value_element, false, result, ref, @asset_type)
        return result
      end

      publ_root = public_root(context)

      publ_root_path = publ_root.path
      stylesh_root_path = default_root(context).path

      collect_files(context.project, publ_root) do |f|
        next unless f.extension && @extensions.include?(f.extension.downcase)
        name = short_name(f, publ_root_path, stylesh_root_path)
        create_lookup_item context, name, LookupItemType::String, FileTypeManager.get_instance.get_file_type_by_file(f).get_icon
      end
    end

    def resolveReference(context)
      rails_app = rails_app(context)
      if (rails_app && SprocketsUtil.areAssetsEnabled(rails_app))
        ref = Ref.create(nil)
        SprocketReference.resolve_in_load_path(context.value_element, element_text(context), ref, false, @asset_type)
        return ref.get if ref.get
      end

      file_relative_name, root = get_expected_path(context, true)

      return nil if root.nil?
      @extensions.each do |ext|
        if (file_relative_name.match(/.+\.#{ext}/))
          psi = find_psi_file context, root.find_file_by_relative_path(file_relative_name)
          return psi if psi
        end
      end
      return nil if @need_extension
      @extensions.each do |ext|
        psi = find_psi_file context, root.find_file_by_relative_path("#{file_relative_name}.#{ext}")
        return psi if psi
      end
      nil
    end

    def default_root(context)
      rails_std_paths_file context, @url
    end

    def public_root(context)
      rails_std_paths_file context, :getPublicRootURL
    end

    def getDescription(formatter)
      wrap_description("list of stylesheets files in " + formatter.monospaced("\#\\{RAILS_ROOT}/public/stylesheets"))
    end

    def handleRename(context, new_name)
      return new_name if @need_extension
      ViewsConventions.get_view_or_layout_name_by_file_name(new_name)
    end

    def handleBindToElement(context, element)
      if element.kind_of? com.intellij.psi.PsiFile
        mod = context.module
        if (RailsUtil.is_rails31_or_higher(mod))
          ref = Ref.create(nil)
          SprocketReference.find_new_path_in_loadpath(context.value_element, element.virtual_file, ref, @asset_type)
          if (!StringUtil.isEmpty(ref.get()))
            return ref.get + '/' + ViewsConventions.get_action_method_name_by_view(element.virtual_file)
          else
            return nil
          end
        end

        short_name(element.virtual_file, public_root(context).path, default_root(context).path)
      end
    end

    protected

    def get_expected_path(context, force_public)
      file_relative_name = element_text(context)
      rails_app = rails_app(context)
      if (!force_public && rails_app && SprocketsUtil.areAssetsEnabled(rails_app))
        assets_dir = rails_std_paths_file(context, :getAppAssetsRootURL)
        return file_relative_name, assets_dir.nil? ? nil : assets_dir.findChild(@asset_type)
      end

      if file_relative_name[0, 1] == "/"
        file_relative_name = file_relative_name[1, file_relative_name.length - 1]
        root = public_root(context)
      else
        root = default_root(context)
      end
      return file_relative_name, root
    end

    def warning_inspection(context, psi_element)
      msg = rbundle_msg(@inspection_message, ParamDef.getTextPresentationForPsiElement(psi_element))
      file_relative_name, root = get_expected_path(context, false)
      if (@has_quickfix && root)
        dir = PsiManager.get_instance(context.project).find_directory(root)
        fix = CreateNamedFileFix.new(file_relative_name, dir, "Ruby.AssetRefParam.#{@asset_type}", @extensions.first, @asset_type[0..-2])
        InspectionResult.create_warning_result_with_fix(psi_element, msg, fix)
      else
        InspectionResult.create_warning_result(psi_element, msg)
      end
    end

    def short_name(f, publ_root_path, stylesh_root_path)
      publ_root_length = publ_root_path.length
      stylesh_root_length = stylesh_root_path.length
      file_path = f.path

      name_offset = file_path[0, stylesh_root_length] == stylesh_root_path ?
                    # "+1" for removing "/" from the name relative to stylesheet
                    stylesh_root_length + 1 : publ_root_length

      suffix_length =  @need_extension ? 0 : (f.extension.length + 1)
      file_path[name_offset, file_path.length - name_offset - suffix_length]
    end
  end
end