# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CodingAgentTools::Atoms::CoverageFileReader do
  subject { described_class.new }

  let(:sample_coverage_data) do
    {
      "RSpec" => {
        "coverage" => {
          "/test/file.rb" => {
            "lines" => [nil, 1, 0, 2],
            "branches" => {}
          }
        },
        "timestamp" => 1_753_640_000
      }
    }
  end

  describe "#read" do
    context "with valid JSON file" do
      let(:temp_file) { Tempfile.new(["coverage", ".json"]) }

      before do
        temp_file.write(JSON.generate(sample_coverage_data))
        temp_file.rewind
      end

      after { temp_file.unlink }

      it "successfully parses valid SimpleCov JSON" do
        result = subject.read(temp_file.path)
        expect(result).to eq(sample_coverage_data)
      end
    end

    context "with non-existent file" do
      it "raises InvalidFileError" do
        expect do
          subject.read("/non/existent/file.json")
        end.to raise_error(described_class::InvalidFileError, /File does not exist/)
      end
    end

    context "with malformed JSON" do
      let(:temp_file) { Tempfile.new(["invalid", ".json"]) }

      before do
        temp_file.write("{ invalid json")
        temp_file.rewind
      end

      after { temp_file.unlink }

      it "raises MalformedJsonError" do
        expect do
          subject.read(temp_file.path)
        end.to raise_error(described_class::MalformedJsonError, /Invalid JSON/)
      end
    end
  end

  describe "#validate_structure" do
    context "with valid SimpleCov structure" do
      it "returns true" do
        expect(subject.validate_structure(sample_coverage_data)).to be true
      end
    end

    context "with invalid root structure" do
      it "raises error for non-hash root" do
        expect do
          subject.validate_structure([])
        end.to raise_error(described_class::InvalidFileError, /Root must be a hash/)
      end
    end

    context "with missing coverage key" do
      let(:invalid_data) do
        {
          "RSpec" => {
            "timestamp" => 1_753_640_000
          }
        }
      end

      it "raises error for missing coverage" do
        expect do
          subject.validate_structure(invalid_data)
        end.to raise_error(described_class::InvalidFileError, /missing 'coverage' key/)
      end
    end

    context "with invalid lines structure" do
      let(:invalid_data) do
        {
          "RSpec" => {
            "coverage" => {
              "/test/file.rb" => {
                "lines" => "not an array"
              }
            }
          }
        }
      end

      it "raises error for non-array lines" do
        expect do
          subject.validate_structure(invalid_data)
        end.to raise_error(described_class::InvalidFileError, /lines must be an array/)
      end
    end
  end

  describe "#extract_frameworks" do
    it "extracts framework names" do
      frameworks = subject.extract_frameworks(sample_coverage_data)
      expect(frameworks).to eq(["RSpec"])
    end

    context "with multiple frameworks" do
      let(:multi_framework_data) do
        sample_coverage_data.merge(
          "MiniTest" => {
            "coverage" => {},
            "timestamp" => 1_753_640_001
          }
        )
      end

      it "extracts all framework names" do
        frameworks = subject.extract_frameworks(multi_framework_data)
        expect(frameworks).to contain_exactly("RSpec", "MiniTest")
      end
    end
  end

  describe "#extract_file_paths" do
    it "extracts file paths from coverage data" do
      file_paths = subject.extract_file_paths(sample_coverage_data)
      expect(file_paths).to eq(["/test/file.rb"])
    end

    context "with multiple frameworks and files" do
      let(:multi_file_data) do
        {
          "RSpec" => {
            "coverage" => {
              "/test/file1.rb" => {"lines" => []},
              "/test/file2.rb" => {"lines" => []}
            }
          },
          "MiniTest" => {
            "coverage" => {
              "/test/file2.rb" => {"lines" => []},
              "/test/file3.rb" => {"lines" => []}
            }
          }
        }
      end

      it "extracts unique file paths" do
        file_paths = subject.extract_file_paths(multi_file_data)
        expect(file_paths).to contain_exactly("/test/file1.rb", "/test/file2.rb", "/test/file3.rb")
      end
    end

    context "with malformed framework data" do
      let(:malformed_data) do
        {
          "RSpec" => "not a hash"
        }
      end

      it "handles malformed data gracefully" do
        file_paths = subject.extract_file_paths(malformed_data)
        expect(file_paths).to eq([])
      end
    end
  end
end
