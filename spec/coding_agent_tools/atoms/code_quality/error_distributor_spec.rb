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
          { file: "file1.rb", message: "Error 1a", line: 10 },
          { file: "file1.rb", message: "Error 1b", line: 20 },
          { file: "file2.rb", message: "Error 2a", line: 5 },
          { file: "file3.rb", message: "Error 3a", line: 15 },
          { file: "file4.rb", message: "Error 4a", line: 25 },
          { file: "file5.rb", message: "Error 5a", line: 35 }
        ]
      end

      it "distributes one error per file across max_files distributions" do
        result = distributor.distribute(errors)
        
        expect(result[:total_errors]).to eq(6)
        expect(result[:files_with_errors]).to eq(5)
        expect(result[:distributions].size).to eq(4) # max_files
        
        # Each distribution should have one error from each file (cycling through)
        expect(result[:distributions][0][:errors]).to contain_exactly(
          { file: "file1.rb", message: "Error 1a", line: 10 },
          { file: "file5.rb", message: "Error 5a", line: 35 }
        )
        expect(result[:distributions][1][:errors]).to contain_exactly(
          { file: "file2.rb", message: "Error 2a", line: 5 }
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
          { file: "file1.rb", message: "Error 1a" },
          { file: "file1.rb", message: "Error 1b" },
          { file: "file2.rb", message: "Error 2a" },
          { file: "file3.rb", message: "Error 3a" }
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
          { "file" => "file1.rb", "message" => "Error 1" },
          { "file" => "file2.rb", "message" => "Error 2" }
        ]
        
        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(2)
        expect(result[:files_with_errors]).to eq(2)
      end

      it "handles missing file information" do
        errors = [
          { message: "Error without file" },
          { file: "file1.rb", message: "Error with file" }
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
          { file: "file1.rb", message: "Symbol key" },
          { "file" => "file2.rb", "message" => "String key" }
        ]
        
        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(2)
        expect(result[:files_with_errors]).to eq(2)
      end
    end

    context "with different distribution sizes" do
      let(:errors) do
        (1..7).map { |i| { file: "file#{i}.rb", message: "Error #{i}" } }
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
          { file: "file1.rb", message: "Error 1" },
          { file: "file2.rb", message: "Error 2" }
        ]
        
        result = distributor.distribute(small_errors)
        
        expect(result[:distributions].size).to eq(2) # Only non-empty distributions
        expect(result[:distributions][0][:errors].size).to eq(1)
        expect(result[:distributions][1][:errors].size).to eq(1)
      end
    end

    context "edge cases" do
      it "handles single error" do
        errors = [{ file: "file1.rb", message: "Single error" }]
        
        result = distributor.distribute(errors)
        expect(result[:total_errors]).to eq(1)
        expect(result[:files_with_errors]).to eq(1)
        expect(result[:distributions].size).to eq(1)
        expect(result[:distributions][0][:errors].size).to eq(1)
      end

      it "removes empty distributions" do
        errors = [{ file: "file1.rb", message: "Only error" }]
        
        # With max_files = 4, only first distribution should have content
        result = distributor.distribute(errors)
        expect(result[:distributions].size).to eq(1) # Empty ones removed
      end

      it "handles very large number of files" do
        large_errors = (1..100).map { |i| { file: "file#{i}.rb", message: "Error #{i}" } }
        
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
        { file: "file1.rb", message: "Error 1" },
        { file: "file2.rb", message: "Error 2" }
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
end