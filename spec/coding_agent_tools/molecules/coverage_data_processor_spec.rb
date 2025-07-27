# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CodingAgentTools::Molecules::CoverageDataProcessor do
  subject { described_class.new }

  let(:sample_raw_data) do
    {
      "RSpec" => {
        "coverage" => {
          "/test/lib/example.rb" => {
            "lines" => [nil, 1, 0, 2, nil],
            "branches" => {}
          },
          "/test/spec/example_spec.rb" => {
            "lines" => [nil, 1, 1, 1],
            "branches" => {}
          }
        },
        "timestamp" => 1753640000
      },
      "MiniTest" => {
        "coverage" => {
          "/test/lib/example.rb" => {
            "lines" => [nil, 0, 1, 1, nil],
            "branches" => {}
          }
        },
        "timestamp" => 1753640001
      }
    }
  end

  describe "#process_coverage_data" do
    context "with default options" do
      it "processes coverage data correctly" do
        result = subject.process_coverage_data(sample_raw_data)

        expect(result[:total_files]).to eq(1)  # Only lib file included by default
        expect(result[:processed_files]).to eq(1)
        expect(result[:frameworks]).to contain_exactly("RSpec", "MiniTest")
        expect(result[:timestamp]).to eq(1753640001)  # Latest timestamp
      end

      it "filters spec files by default" do
        result = subject.process_coverage_data(sample_raw_data)

        file_paths = result[:file_coverage].keys
        expect(file_paths).not_to include("/test/spec/example_spec.rb")
        expect(file_paths).to include("/test/lib/example.rb")
      end

      it "combines coverage from multiple frameworks" do
        result = subject.process_coverage_data(sample_raw_data)
        
        file_data = result[:file_coverage]["/test/lib/example.rb"]
        coverage = file_data[:coverage_data]
        
        # Combined lines: [nil, 1, 1, 3, nil] -> 3 executable, 3 covered = 100%
        expect(coverage[:total_lines]).to eq(3)
        expect(coverage[:covered_lines]).to eq(3)
        expect(coverage[:coverage_percentage]).to eq(100.0)
      end
    end

    context "with custom include patterns" do
      let(:options) { { include_patterns: ["**/*.rb"], exclude_patterns: [] } }

      it "includes all files matching pattern" do
        result = subject.process_coverage_data(sample_raw_data, options)

        expect(result[:total_files]).to eq(2)  # Both lib and spec files
        expect(result[:file_coverage].keys).to include("/test/spec/example_spec.rb")
      end
    end

    context "with custom exclude patterns" do
      let(:options) { { exclude_patterns: ["**/lib/**"] } }

      it "excludes files matching pattern" do
        result = subject.process_coverage_data(sample_raw_data, options)

        file_paths = result[:file_coverage].keys
        expect(file_paths).not_to include("/test/lib/example.rb")
      end
    end

    context "with malformed framework data" do
      let(:malformed_data) do
        {
          "RSpec" => "not a hash",
          "MiniTest" => {
            "coverage" => {
              "/test/lib/example.rb" => {
                "lines" => [nil, 1, 0],
                "branches" => {}
              }
            }
          }
        }
      end

      it "handles malformed data gracefully" do
        result = subject.process_coverage_data(malformed_data)

        expect(result[:total_files]).to eq(1)
        expect(result[:frameworks]).to contain_exactly("RSpec", "MiniTest")
      end
    end
  end

  describe "#prioritize_under_covered_files" do
    let(:processed_data) do
      {
        file_coverage: {
          "/test/lib/low_coverage.rb" => {
            coverage_data: { coverage_percentage: 60.0 }
          },
          "/test/lib/high_coverage.rb" => {
            coverage_data: { coverage_percentage: 95.0 }
          }
        }
      }
    end

    it "separates files by threshold" do
      result = subject.prioritize_under_covered_files(processed_data, 80.0)

      expect(result[:under_covered_count]).to eq(1)
      expect(result[:under_covered_files]).to have_key("/test/lib/low_coverage.rb")
      expect(result[:well_covered_files]).to have_key("/test/lib/high_coverage.rb")
      expect(result[:threshold_used]).to eq(80.0)
    end

    it "validates threshold parameter" do
      expect {
        subject.prioritize_under_covered_files(processed_data, "invalid")
      }.to raise_error(CodingAgentTools::Atoms::ThresholdValidator::ValidationError)
    end
  end

  describe "#process_file" do
    let(:temp_file) { Tempfile.new(["coverage", ".json"]) }

    before do
      temp_file.write(JSON.generate(sample_raw_data))
      temp_file.rewind
    end

    after { temp_file.unlink }

    it "reads and processes SimpleCov file" do
      result = subject.process_file(temp_file.path)

      expect(result[:total_files]).to eq(1)
      expect(result[:processed_files]).to eq(1)
      expect(result[:frameworks]).to contain_exactly("RSpec", "MiniTest")
    end

    it "validates file structure" do
      invalid_file = Tempfile.new(["invalid", ".json"])
      invalid_file.write('{"invalid": "structure"}')
      invalid_file.rewind

      expect {
        subject.process_file(invalid_file.path)
      }.to raise_error(CodingAgentTools::Atoms::CoverageFileReader::InvalidFileError)

      invalid_file.unlink
    end
  end

  describe "private methods" do
    describe "#filter_file_paths" do
      let(:file_paths) do
        [
          "/test/lib/example.rb",
          "/test/spec/example_spec.rb",
          "/test/lib/another.rb",
          "/test/test/unit_test.rb"
        ]
      end

      it "prioritizes lib files in sort order" do
        filtered = subject.send(:filter_file_paths, file_paths, ["**/*.rb"], [])
        
        lib_files = filtered.select { |path| path.include?("/lib/") }
        non_lib_files = filtered.reject { |path| path.include?("/lib/") }
        
        # Check that lib files come first
        expect(filtered.first(lib_files.length)).to eq(lib_files)
      end
    end

    describe "#combine_lines_data" do
      let(:coverage_arrays) do
        [
          [nil, 1, 0, 2],
          [nil, 0, 1, 1]
        ]
      end

      it "combines coverage arrays correctly" do
        result = subject.send(:combine_lines_data, coverage_arrays)
        
        expect(result).to eq([nil, 1, 1, 3])
      end

      it "handles arrays of different lengths" do
        arrays = [
          [nil, 1, 0],
          [nil, 0, 1, 1, 2]
        ]
        
        result = subject.send(:combine_lines_data, arrays)
        
        expect(result).to eq([nil, 1, 1, 1, 2])
      end
    end
  end
end