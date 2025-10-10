# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/error_distribution"

RSpec.describe CodingAgentTools::Models::ErrorDistribution do
  let(:sample_errors) do
    [
      {file: "app/models/user.rb", line: 10, message: "Style/StringLiterals"},
      {file: "app/models/user.rb", line: 15, message: "Layout/TrailingWhitespace"},
      {file: "app/controllers/users_controller.rb", line: 5, message: "Style/HashSyntax"},
      {file: "spec/models/user_spec.rb", line: 20, message: "RSpec/ExampleLength"}
    ]
  end

  let(:valid_attributes) do
    {
      file_number: 1,
      file_path: "app/models/user.rb",
      errors: sample_errors,
      error_count: sample_errors.size,
      files_covered: sample_errors.map { |e| e[:file] }.uniq.size
    }
  end

  describe "#initialize" do
    it "creates a new error distribution with provided attributes" do
      distribution = described_class.new(valid_attributes)

      expect(distribution.file_number).to eq(1)
      expect(distribution.file_path).to eq("app/models/user.rb")
      expect(distribution.errors).to eq(sample_errors)
      expect(distribution.error_count).to eq(4)
      expect(distribution.files_covered).to eq(3)
    end

    it "initializes with empty arrays and counts when not provided" do
      distribution = described_class.new

      expect(distribution.file_number).to be_nil
      expect(distribution.file_path).to be_nil
      expect(distribution.errors).to eq([])
      expect(distribution.error_count).to eq(0)
      expect(distribution.files_covered).to eq(0)
    end

    it "calculates error_count from errors array when not provided" do
      distribution = described_class.new(errors: sample_errors)

      expect(distribution.errors).to eq(sample_errors)
      expect(distribution.error_count).to eq(4)
    end

    it "calculates files_covered from unique error files when not provided" do
      distribution = described_class.new(errors: sample_errors)

      unique_files = sample_errors.map { |e| e[:file] }.uniq
      expect(distribution.files_covered).to eq(unique_files.size)
    end

    it "handles nil errors gracefully" do
      distribution = described_class.new(errors: nil)

      expect(distribution.errors).to eq([])
      expect(distribution.error_count).to eq(0)
      expect(distribution.files_covered).to eq(0)
    end
  end

  describe "#empty?" do
    it "returns true when no errors" do
      distribution = described_class.new(errors: [])
      expect(distribution.empty?).to be(true)
    end

    it "returns false when errors are present" do
      distribution = described_class.new(errors: sample_errors)
      expect(distribution.empty?).to be(false)
    end

    it "returns true when errors is nil" do
      distribution = described_class.new(errors: nil)
      expect(distribution.empty?).to be(true)
    end
  end

  describe "#add_error" do
    let(:new_error) { {file: "lib/helper.rb", line: 8, message: "Style/Documentation"} }

    it "adds a new error to the errors array" do
      distribution = described_class.new(errors: sample_errors.dup)
      initial_count = distribution.errors.size

      distribution.add_error(new_error)

      expect(distribution.errors).to include(new_error)
      expect(distribution.errors.size).to eq(initial_count + 1)
    end

    it "updates error_count after adding error" do
      distribution = described_class.new(errors: sample_errors.dup)
      initial_count = distribution.error_count

      distribution.add_error(new_error)

      expect(distribution.error_count).to eq(initial_count + 1)
    end

    it "updates files_covered when adding error from new file" do
      distribution = described_class.new(errors: sample_errors.dup)
      initial_files_covered = distribution.files_covered

      distribution.add_error(new_error)

      expect(distribution.files_covered).to eq(initial_files_covered + 1)
    end

    it "does not increase files_covered when adding error from existing file" do
      distribution = described_class.new(errors: sample_errors.dup)
      initial_files_covered = distribution.files_covered

      existing_file_error = {file: "app/models/user.rb", line: 25, message: "New error"}
      distribution.add_error(existing_file_error)

      expect(distribution.files_covered).to eq(initial_files_covered)
      expect(distribution.error_count).to eq(sample_errors.size + 1)
    end

    it "works correctly when starting with empty errors" do
      distribution = described_class.new

      distribution.add_error(new_error)

      expect(distribution.errors).to eq([new_error])
      expect(distribution.error_count).to eq(1)
      expect(distribution.files_covered).to eq(1)
    end
  end

  describe "data consistency" do
    it "maintains consistency between errors array and error_count" do
      distribution = described_class.new(errors: sample_errors)

      expect(distribution.error_count).to eq(distribution.errors.size)

      # Add another error and check consistency
      new_error = {file: "new_file.rb", line: 1, message: "Test error"}
      distribution.add_error(new_error)

      expect(distribution.error_count).to eq(distribution.errors.size)
    end

    it "maintains consistency between errors and files_covered" do
      distribution = described_class.new(errors: sample_errors)

      unique_files = distribution.errors.map { |e| e[:file] }.uniq
      expect(distribution.files_covered).to eq(unique_files.size)

      # Add error from existing file
      existing_file_error = {file: sample_errors.first[:file], line: 99, message: "Another error"}
      distribution.add_error(existing_file_error)

      unique_files_after = distribution.errors.map { |e| e[:file] }.uniq
      expect(distribution.files_covered).to eq(unique_files_after.size)
    end
  end

  describe "error structure handling" do
    it "handles errors with different structures" do
      varied_errors = [
        {file: "file1.rb", line: 10, message: "Error 1"},
        {file: "file2.rb", line: 20, message: "Error 2", severity: "warning"},
        {file: "file3.rb", line: 30, message: "Error 3", rule: "Style/Something", linter: "rubocop"}
      ]

      distribution = described_class.new(errors: varied_errors)

      expect(distribution.errors).to eq(varied_errors)
      expect(distribution.error_count).to eq(3)
      expect(distribution.files_covered).to eq(3)
    end

    it "handles errors with missing file information" do
      errors_missing_files = [
        {line: 10, message: "Error without file"},
        {file: nil, line: 20, message: "Error with nil file"},
        {file: "valid_file.rb", line: 30, message: "Valid error"}
      ]

      distribution = described_class.new(errors: errors_missing_files)

      expect(distribution.error_count).to eq(3)
      # files_covered calculation should handle nil values gracefully
      expect(distribution.files_covered).to be_a(Integer)
      expect(distribution.files_covered).to be >= 0
    end
  end

  describe "edge cases", :edge_cases do
    it "handles very large error arrays" do
      large_errors = Array.new(10_000) do |i|
        {file: "file#{i % 100}.rb", line: i, message: "Error #{i}"}
      end

      distribution = described_class.new(errors: large_errors)

      expect(distribution.error_count).to eq(10_000)
      expect(distribution.files_covered).to eq(100) # 100 unique files
    end

    it "handles errors with empty or whitespace-only file names" do
      edge_case_errors = [
        {file: "", line: 1, message: "Empty file name"},
        {file: "   ", line: 2, message: "Whitespace file name"},
        {file: "valid.rb", line: 3, message: "Valid error"}
      ]

      distribution = described_class.new(errors: edge_case_errors)

      expect(distribution.error_count).to eq(3)
      expect(distribution.files_covered).to be_a(Integer)
    end

    it "handles errors with special characters in file paths" do
      special_errors = [
        {file: "path/with spaces/file.rb", line: 1, message: "Space in path"},
        {file: "path/with-dashes/file.rb", line: 2, message: "Dashes in path"},
        {file: "path/with_underscores/file.rb", line: 3, message: "Underscores in path"},
        {file: "émojis🚀/ñéẅ_file.rb", line: 4, message: "Unicode in path"}
      ]

      distribution = described_class.new(errors: special_errors)

      expect(distribution.error_count).to eq(4)
      expect(distribution.files_covered).to eq(4)
    end

    it "handles errors with very long messages" do
      long_message = "A" * 10_000
      long_message_error = {file: "file.rb", line: 1, message: long_message}

      distribution = described_class.new(errors: [long_message_error])

      expect(distribution.error_count).to eq(1)
      expect(distribution.errors.first[:message]).to eq(long_message)
    end

    it "handles zero and negative line numbers" do
      edge_line_errors = [
        {file: "file1.rb", line: 0, message: "Zero line number"},
        {file: "file2.rb", line: -1, message: "Negative line number"},
        {file: "file3.rb", line: nil, message: "Nil line number"}
      ]

      distribution = described_class.new(errors: edge_line_errors)

      expect(distribution.error_count).to eq(3)
      expect(distribution.files_covered).to eq(3)
    end

    it "handles adding nil as error" do
      distribution = described_class.new

      # This tests current behavior - the method will fail on nil
      expect { distribution.add_error(nil) }.to raise_error(NoMethodError)
    end

    it "handles complex error objects" do
      complex_error = {
        file: "complex.rb",
        line: 42,
        message: "Complex error",
        metadata: {
          severity: "high",
          tags: ["performance", "security"],
          context: {method: "process_data", class: "DataProcessor"}
        },
        timestamp: Time.now
      }

      distribution = described_class.new
      distribution.add_error(complex_error)

      expect(distribution.errors.first).to eq(complex_error)
      expect(distribution.error_count).to eq(1)
      expect(distribution.files_covered).to eq(1)
    end
  end
end
