# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::ErrorDistributor do
  let(:distributor) { described_class.new }
  let(:distributor_with_options) { described_class.new(max_files: 2, one_issue_per_file: false) }

  describe "#initialize" do
    it "uses default options when none provided" do
      distributor = described_class.new
      expect(distributor.max_files).to eq(4)
      expect(distributor.one_issue_per_file).to be true
    end

    it "uses provided options" do
      distributor = described_class.new(max_files: 3, one_issue_per_file: false)
      expect(distributor.max_files).to eq(3)
      expect(distributor.one_issue_per_file).to be false
    end

    it "uses default max_files when not provided" do
      distributor = described_class.new(one_issue_per_file: false)
      expect(distributor.max_files).to eq(4)
      expect(distributor.one_issue_per_file).to be false
    end
  end

  describe "#distribute" do
    context "with empty errors" do
      it "returns empty result structure" do
        result = distributor.distribute([])

        expect(result).to eq({
          distributions: [],
          total_errors: 0
        })
      end
    end

    context "with one issue per file enabled (default)" do
      let(:errors) do
        [
          {file: "file1.rb", message: "Error 1a", line: 10},
          {file: "file1.rb", message: "Error 1b", line: 20},
          {file: "file2.rb", message: "Error 2a", line: 5},
          {file: "file3.rb", message: "Error 3a", line: 15},
          {file: "file4.rb", message: "Error 4a", line: 25},
          {file: "file5.rb", message: "Error 5a", line: 35}
        ]
      end

      it "distributes one error per file across max_files distributions" do
        result = distributor.distribute(errors)

        expect(result[:total_errors]).to eq(6)
        expect(result[:files_with_errors]).to eq(5)
        expect(result[:distributions].size).to eq(4) # max_files

        # Each distribution should have one error from each file (cycling through)
        expect(result[:distributions][0][:errors]).to contain_exactly(
          {file: "file1.rb", message: "Error 1a", line: 10},
          {file: "file5.rb", message: "Error 5a", line: 35}
        )
        expect(result[:distributions][1][:errors]).to contain_exactly(
          {file: "file2.rb", message: "Error 2a", line: 5}
        )
      end

      it "only takes first error from files with multiple errors" do
        result = distributor.distribute(errors)

        # file1.rb has two errors, but only first should be included
        file1_errors = result[:distributions].flat_map { |d| d[:errors] }
          .select { |e| e[:file] == "file1.rb" }

        expect(file1_errors.size).to eq(1)
        expect(file1_errors.first[:message]).to eq("Error 1a")
      end

      it "numbers distributions correctly" do
        result = distributor.distribute(errors)

        result[:distributions].each_with_index do |dist, idx|
          expect(dist[:file_number]).to eq(idx + 1)
          expect(dist[:error_count]).to eq(dist[:errors].size)
        end
      end
    end

    context "with one issue per file disabled" do
      let(:errors) do
        [
          {file: "file1.rb", message: "Error 1a"},
          {file: "file1.rb", message: "Error 1b"},
          {file: "file2.rb", message: "Error 2a"},
          {file: "file3.rb", message: "Error 3a"}
        ]
      end

      it "distributes all errors evenly across distributions" do
        result = distributor_with_options.distribute(errors)

        expect(result[:total_errors]).to eq(4)
        expect(result[:files_with_errors]).to eq(3)
        expect(result[:distributions].size).to eq(2) # max_files = 2

        # Should distribute all 4 errors across 2 distributions
        total_distributed = result[:distributions].sum { |d| d[:errors].size }
        expect(total_distributed).to eq(4)

        # Each distribution should have 2 errors (4 / 2)
        result[:distributions].each do |dist|
          expect(dist[:errors].size).to eq(2)
        end
      end

      it "includes all errors from files with multiple errors" do
        result = distributor_with_options.distribute(errors)

        # Both errors from file1.rb should be included
        file1_errors = result[:distributions].flat_map { |d| d[:errors] }
          .select { |e| e[:file] == "file1.rb" }

        expect(file1_errors.size).to eq(2)
        expect(file1_errors.map { |e| e[:message] }).to contain_exactly("Error 1a", "Error 1b")
      end
    end

    context "with different error formats" do
      it "handles string keys" do
        errors = [
          {"file" => "file1.rb", "message" => "Error 1"},
          {"file" => "file2.rb", "message" => "Error 2"}
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(2)
        expect(result[:files_with_errors]).to eq(2)
      end

      it "handles missing file information" do
        errors = [
          {message: "Error without file"},
          {file: "file1.rb", message: "Error with file"}
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(2)
        expect(result[:files_with_errors]).to eq(2) # "unknown" and "file1.rb"

        # The original error objects are preserved in the distribution
        # We can check that the error without file is still there
        all_errors = result[:distributions].flat_map { |d| d[:errors] }
        error_without_file = all_errors.find { |e| e[:message] == "Error without file" }
        expect(error_without_file).not_to be_nil
      end

      it "handles mixed symbol and string keys" do
        errors = [
          {file: "file1.rb", message: "Symbol key"},
          {"file" => "file2.rb", "message" => "String key"}
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(2)
        expect(result[:files_with_errors]).to eq(2)
      end
    end

    context "with different distribution sizes" do
      let(:errors) do
        (1..7).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }
      end

      it "handles more files than max_files" do
        result = distributor.distribute(errors)

        expect(result[:total_errors]).to eq(7)
        expect(result[:files_with_errors]).to eq(7)
        expect(result[:distributions].size).to eq(4) # max_files

        # Should cycle through distributions
        expect(result[:distributions][0][:errors].size).to eq(2) # files 1, 5
        expect(result[:distributions][1][:errors].size).to eq(2) # files 2, 6
        expect(result[:distributions][2][:errors].size).to eq(2) # files 3, 7
        expect(result[:distributions][3][:errors].size).to eq(1) # file 4
      end

      it "handles fewer files than max_files" do
        small_errors = [
          {file: "file1.rb", message: "Error 1"},
          {file: "file2.rb", message: "Error 2"}
        ]

        result = distributor.distribute(small_errors)

        expect(result[:distributions].size).to eq(2) # Only non-empty distributions
        expect(result[:distributions][0][:errors].size).to eq(1)
        expect(result[:distributions][1][:errors].size).to eq(1)
      end
    end

    context "edge cases" do
      it "handles single error" do
        errors = [{file: "file1.rb", message: "Single error"}]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(1)
        expect(result[:files_with_errors]).to eq(1)
        expect(result[:distributions].size).to eq(1)
        expect(result[:distributions][0][:errors].size).to eq(1)
      end

      it "removes empty distributions" do
        errors = [{file: "file1.rb", message: "Only error"}]

        # With max_files = 4, only first distribution should have content
        result = distributor.distribute(errors)
        expect(result[:distributions].size).to eq(1) # Empty ones removed
      end

      it "handles very large number of files" do
        large_errors = (1..100).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }

        result = distributor.distribute(large_errors)
        expect(result[:total_errors]).to eq(100)
        expect(result[:files_with_errors]).to eq(100)
        expect(result[:distributions].size).to eq(4) # max_files

        # Should distribute evenly: 25 per distribution
        result[:distributions].each do |dist|
          expect(dist[:errors].size).to eq(25)
        end
      end
    end
  end

  describe "result structure" do
    let(:errors) do
      [
        {file: "file1.rb", message: "Error 1"},
        {file: "file2.rb", message: "Error 2"}
      ]
    end

    it "returns correct structure" do
      result = distributor.distribute(errors)

      expect(result).to have_key(:distributions)
      expect(result).to have_key(:total_errors)
      expect(result).to have_key(:files_with_errors)

      result[:distributions].each do |dist|
        expect(dist).to have_key(:file_number)
        expect(dist).to have_key(:errors)
        expect(dist).to have_key(:error_count)
        expect(dist[:error_count]).to eq(dist[:errors].size)
      end
    end
  end

  describe "comprehensive edge cases and error handling" do
    context "with malformed input data" do
      it "handles nil errors gracefully" do
        expect { distributor.distribute(nil) }.to raise_error(NoMethodError)
      end

      it "handles non-array input" do
        expect { distributor.distribute("not an array") }.to raise_error(NoMethodError)
      end

      it "handles errors with nil values" do
        errors = [
          nil,
          {file: "file1.rb", message: "Valid error"},
          nil
        ]

        expect { distributor.distribute(errors) }.to raise_error(NoMethodError)
      end

      it "handles errors with completely empty hashes" do
        errors = [
          {},
          {file: "file1.rb", message: "Valid error"},
          {}
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(3)
        expect(result[:files_with_errors]).to eq(2) # "unknown" and "file1.rb"
      end

      it "handles very large error messages" do
        large_message = "x" * 10000
        errors = [{file: "file1.rb", message: large_message}]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(1)
        expect(result[:distributions][0][:errors][0][:message]).to eq(large_message)
      end
    end

    context "with special file names" do
      it "handles files with special characters" do
        errors = [
          {file: "file with spaces.rb", message: "Error 1"},
          {file: "file@#$%^&*().rb", message: "Error 2"},
          {file: "file-with-dashes.rb", message: "Error 3"}
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(3)
        expect(result[:files_with_errors]).to eq(3)
      end

      it "handles Unicode file names" do
        errors = [
          {file: "файл.rb", message: "Unicode error"},
          {file: "测试.rb", message: "Chinese error"},
          {file: "🔥.rb", message: "Emoji error"}
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(3)
        expect(result[:files_with_errors]).to eq(3)
      end

      it "handles very long file paths" do
        long_path = ("long/" * 100) + "file.rb"
        errors = [{file: long_path, message: "Long path error"}]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(1)
        expect(result[:distributions][0][:errors][0][:file]).to eq(long_path)
      end

      it "handles empty file names" do
        errors = [
          {file: "", message: "Empty file name"},
          {file: nil, message: "Nil file name"},
          {message: "No file key"}
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(3)
        # Empty string, "unknown", and "unknown" for the three cases
        expect(result[:files_with_errors]).to eq(2) # "" and "unknown"
      end
    end

    context "with boundary conditions" do
      it "handles exactly max_files number of files" do
        errors = (1..4).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }

        result = distributor.distribute(errors)
        expect(result[:distributions].size).to eq(4)
        result[:distributions].each do |dist|
          expect(dist[:errors].size).to eq(1)
        end
      end

      it "handles max_files + 1 files" do
        errors = (1..5).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }

        result = distributor.distribute(errors)
        expect(result[:distributions].size).to eq(4) # max_files
        expect(result[:distributions][0][:errors].size).to eq(2) # files 1 and 5
      end

      it "handles max_files set to 1" do
        single_distributor = described_class.new(max_files: 1)
        errors = [
          {file: "file1.rb", message: "Error 1"},
          {file: "file2.rb", message: "Error 2"}
        ]

        result = single_distributor.distribute(errors)
        expect(result[:distributions].size).to eq(1)
        expect(result[:distributions][0][:errors].size).to eq(2)
      end

      it "handles max_files set to very large number" do
        large_distributor = described_class.new(max_files: 1000)
        errors = [
          {file: "file1.rb", message: "Error 1"},
          {file: "file2.rb", message: "Error 2"}
        ]

        result = large_distributor.distribute(errors)
        expect(result[:distributions].size).to eq(2) # Only non-empty ones
      end
    end

    context "with complex error structures" do
      it "preserves complete error structure in distributions" do
        complex_error = {
          file: "complex.rb",
          message: "Complex error",
          line: 42,
          column: 15,
          severity: "error",
          rule: "RuboCop/ComplexRule",
          context: {before: "line before", after: "line after"},
          metadata: {tool: "rubocop", version: "1.0.0"}
        }

        result = distributor.distribute([complex_error])
        distributed_error = result[:distributions][0][:errors][0]

        expect(distributed_error).to eq(complex_error)
        expect(distributed_error[:context]).to eq(complex_error[:context])
        expect(distributed_error[:metadata]).to eq(complex_error[:metadata])
      end

      it "handles mixed error structure formats" do
        errors = [
          {file: "file1.rb", message: "Simple error"},
          {
            file: "file2.rb",
            message: "Complex error",
            details: {
              line: 10,
              column: 5,
              suggestions: ["Fix A", "Fix B"]
            }
          }
        ]

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(2)
        expect(result[:files_with_errors]).to eq(2)

        # Verify complex structure is preserved
        complex_error = result[:distributions].flat_map { |d| d[:errors] }
          .find { |e| e[:file] == "file2.rb" }
        expect(complex_error[:details][:suggestions]).to eq(["Fix A", "Fix B"])
      end

      it "handles invalid error structure gracefully" do
        errors = [
          {file: "file1.rb", message: "Valid error"},
          {"file3.rb" => "string-based error"} # Invalid hash structure
        ]

        # The distributor should handle this without crashing
        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(2)

        # The invalid structure should be treated as having no file
        expect(result[:files_with_errors]).to eq(2) # "file1.rb" and "unknown"
      end
    end

    context "with distribution strategy variations" do
      it "handles one_issue_per_file with files having many errors" do
        errors = []
        # Create 10 errors for each of 3 files
        3.times do |file_idx|
          10.times do |error_idx|
            errors << {
              file: "file#{file_idx + 1}.rb",
              message: "Error #{error_idx + 1}",
              line: (error_idx + 1) * 10
            }
          end
        end

        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(30)
        expect(result[:files_with_errors]).to eq(3)

        # Should only have 3 errors total (one per file)
        total_distributed = result[:distributions].sum { |d| d[:errors].size }
        expect(total_distributed).to eq(3)

        # Verify only first error from each file is used
        all_errors = result[:distributions].flat_map { |d| d[:errors] }
        file1_error = all_errors.find { |e| e[:file] == "file1.rb" }
        expect(file1_error[:message]).to eq("Error 1")
      end

      it "handles even distribution with uneven error counts" do
        # 7 errors across 3 files (uneven: 3, 2, 2)
        errors = [
          {file: "file1.rb", message: "Error 1a"},
          {file: "file1.rb", message: "Error 1b"},
          {file: "file1.rb", message: "Error 1c"},
          {file: "file2.rb", message: "Error 2a"},
          {file: "file2.rb", message: "Error 2b"},
          {file: "file3.rb", message: "Error 3a"},
          {file: "file3.rb", message: "Error 3b"}
        ]

        even_distributor = described_class.new(max_files: 3, one_issue_per_file: false)
        result = even_distributor.distribute(errors)

        expect(result[:total_errors]).to eq(7)
        # Should distribute as evenly as possible: 3, 2, 2 or 2, 2, 3
        sizes = result[:distributions].map { |d| d[:errors].size }.sort
        expect(sizes).to match([2, 2, 3])
      end
    end

    context "with performance and stress testing" do
      it "handles large number of errors efficiently" do
        large_errors = (1..1000).map { |i| {file: "file#{i % 100}.rb", message: "Error #{i}"} }

        start_time = Time.now
        result = distributor.distribute(large_errors)
        end_time = Time.now

        expect(result[:total_errors]).to eq(1000)
        expect(end_time - start_time).to be < 1.0 # Should complete in under 1 second
      end

      it "handles many files with few errors each" do
        many_files_errors = (1..500).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }

        result = distributor.distribute(many_files_errors)
        expect(result[:total_errors]).to eq(500)
        expect(result[:files_with_errors]).to eq(500)

        # With one_issue_per_file, should have exactly 500 distributed errors
        total_distributed = result[:distributions].sum { |d| d[:errors].size }
        expect(total_distributed).to eq(500)
      end
    end

    context "with concurrent access simulation" do
      it "maintains consistency during concurrent distribution calls" do
        errors = (1..20).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }

        threads = []
        results = Queue.new

        10.times do
          threads << Thread.new do
            local_distributor = described_class.new
            results << local_distributor.distribute(errors)
          end
        end

        threads.each(&:join)

        # All results should be identical
        first_result = results.pop
        until results.empty?
          next_result = results.pop
          expect(next_result[:total_errors]).to eq(first_result[:total_errors])
          expect(next_result[:files_with_errors]).to eq(first_result[:files_with_errors])
          expect(next_result[:distributions].size).to eq(first_result[:distributions].size)
        end
      end
    end
  end

  describe "algorithm correctness verification" do
    context "distribution fairness" do
      it "maintains round-robin distribution order" do
        errors = (1..8).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }

        result = distributor.distribute(errors)

        # With max_files = 4, distribution should be:
        # Dist 1: files 1, 5 | Dist 2: files 2, 6 | Dist 3: files 3, 7 | Dist 4: files 4, 8
        expect(result[:distributions][0][:errors].map { |e| e[:file] }).to eq(["file1.rb", "file5.rb"])
        expect(result[:distributions][1][:errors].map { |e| e[:file] }).to eq(["file2.rb", "file6.rb"])
        expect(result[:distributions][2][:errors].map { |e| e[:file] }).to eq(["file3.rb", "file7.rb"])
        expect(result[:distributions][3][:errors].map { |e| e[:file] }).to eq(["file4.rb", "file8.rb"])
      end

      it "balances distribution sizes as evenly as possible" do
        # Test with prime number of files to ensure even distribution
        errors = (1..11).map { |i| {file: "file#{i}.rb", message: "Error #{i}"} }

        result = distributor.distribute(errors)

        sizes = result[:distributions].map { |d| d[:errors].size }.sort
        # 11 files across 4 distributions: 3, 3, 3, 2 (or similar)
        expect(sizes.max - sizes.min).to be <= 1
      end
    end

    context "error preservation" do
      it "preserves all error attributes without modification" do
        original_error = {
          file: "test.rb",
          message: "Original message",
          line: 123,
          severity: :critical,
          nested: {data: "preserved"}
        }

        result = distributor.distribute([original_error])
        preserved_error = result[:distributions][0][:errors][0]

        expect(preserved_error).to eq(original_error)
        expect(preserved_error.object_id).to eq(original_error.object_id) # Same object reference
      end

      it "maintains error order within each file when one_issue_per_file is false" do
        errors = [
          {file: "file1.rb", message: "Error A", line: 1},
          {file: "file1.rb", message: "Error B", line: 2},
          {file: "file1.rb", message: "Error C", line: 3}
        ]

        even_distributor = described_class.new(max_files: 2, one_issue_per_file: false)
        result = even_distributor.distribute(errors)

        # Errors should be distributed in order: A to dist 1, B to dist 2, C to dist 1
        dist1_messages = result[:distributions][0][:errors].map { |e| e[:message] }
        dist2_messages = result[:distributions][1][:errors].map { |e| e[:message] }

        expect(dist1_messages).to eq(["Error A", "Error C"])
        expect(dist2_messages).to eq(["Error B"])
      end
    end
  end
end
