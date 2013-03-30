include Java
import org.jetbrains.plugins.ruby.coverage.RubyCoverageDeserializationService
import org.jetbrains.plugins.ruby.coverage.RubyCoverageDeserializationProvider
import org.jetbrains.plugins.ruby.coverage.RCovCoverageType
import org.jetbrains.plugins.ruby.coverage.RCovRawFileData
import org.jetbrains.plugins.ruby.coverage.RubyCoverageUtil
import java.util.ArrayList

module RubyMine
  class RCovDeserializer
    include RubyCoverageDeserializationProvider

    # Current Marshal format version
    # TODO - load from rcov?
    FORMAT_VERSION = [0, 1, 0]

    include RubyCoverageDeserializationProvider

    def getFormatName()
      "rcov.marshal"
    end

    def getReportGeneratorGemName()
      "rcov"
    end

    def acceptsFormat(data_file_path, first_line)
      # accepts all files [fix me]
      true
    end

    def SERIALIZER
      Marshal
    end
    # State format:
    #   state = {}
    #    state[filename] = {:lines => SCRIPT_LINES__[filename],
    #                       :coverage => fileinfo.coverage.to_a,
    #                       :counts   => fileinfo.counts}
    # E.g.:
    # { "foo.rb" => {:counts=>[2, 2, 1, 1, 3, 0, 0, 0, 1],
    #                :lines=>["class Foo\n",
    #                        "  def foo\n",
    #                        "    @ddd = 1\n",
    #                        "    p @ddd\n",
    #                        "    p ddd\n",
    #                        "  end\n",
    #                        "end\n",
    #                        "\n",
    #                        "Foo.new.foo"],
    #                :coverage=>[true, true, true, true, true, :inferred, :inferred, :inferred, true]
    #               }
    def deserialize(raw_data_file_path)
      begin
        format, state = File.open(raw_data_file_path){|f| self.SERIALIZER.load(f) }

      rescue Exception => ex
        raise ex
      end

      if !(Array === format) or FORMAT_VERSION[0] != format[0] || FORMAT_VERSION[1] < format[1]
        file_format = FORMAT_VERSION.inspect
        raise Exception.new("incorrect file format: expected #{file_format}, got #{format.inspect}")
      end

      files_data = ArrayList.new
      state.each_pair do |file_path, data|
        # load useful data
        hits = data[:counts]
        coverage = data[:coverage]

        java_coverage_list = ArrayList.new
        coverage.each do |line_cov|
          cov_type = line_cov == :inferred ? RCovCoverageType::INFERRED :
                                           line_cov ? RCovCoverageType::COVERED : RCovCoverageType::NOT_COVERED
          java_coverage_list.add cov_type
        end

        # Determine real src lines number
        src_lines_mask = RubyCoverageUtil.determineSrcCodeLines(data[:lines].to_java(:'java.lang.String'),
                                                            java_coverage_list)

        files_data.add RCovRawFileData.new(file_path, java_coverage_list, hits.to_java(Java::int), src_lines_mask)

        # let's allow GC to collect unused data
        data[:lines] = nil
        data[:counts] = nil
        data[:coverage] = nil
      end

      files_data;
    end
  end
end

RubyCoverageDeserializationService.getInstance.registerDeserializer(RubyMine::RCovDeserializer.new)
