# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/organisms/code/content_extractor"

RSpec.describe CodingAgentTools::Organisms::Code::ContentExtractor do
  let(:content_extractor) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir("content_extractor_test") }
  let(:test_file_path) { File.join(temp_dir, "test_file.rb") }
  let(:test_file_content) { "# Test Ruby file\nclass TestClass\nend\n" }

  before do
    # Create test files
    File.write(test_file_path, test_file_content)
    
    # Mock molecules
    @mock_diff_extractor = instance_double(CodingAgentTools::Molecules::Code::GitDiffExtractor)
    @mock_file_extractor = instance_double(CodingAgentTools::Molecules::Code::FilePatternExtractor)
    
    allow(CodingAgentTools::Molecules::Code::GitDiffExtractor).to receive(:new).and_return(@mock_diff_extractor)
    allow(CodingAgentTools::Molecules::Code::FilePatternExtractor).to receive(:new).and_return(@mock_file_extractor)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "initializes with diff and file extractors" do
      expect(content_extractor.instance_variable_get(:@diff_extractor)).to eq(@mock_diff_extractor)
      expect(content_extractor.instance_variable_get(:@file_extractor)).to eq(@mock_file_extractor)
    end
  end

  describe "#extract_content" do
    context "when target is a git diff" do
      let(:git_diff_target) { "HEAD~1..HEAD" }
      let(:diff_result) do
        {
          success: true,
          metadata: {
            line_count: 50,
            word_count: 200,
            files_changed: 3,
            additions: 25,
            deletions: 5
          }
        }
      end

      before do
        allow(@mock_diff_extractor).to receive(:git_diff_target?).with(git_diff_target).and_return(true)
        allow(@mock_diff_extractor).to receive(:extract_diff).with(git_diff_target).and_return(diff_result)
      end

      it "extracts git diff content and returns proper ReviewTarget" do
        result = content_extractor.extract_content(git_diff_target)

        expect(result).to be_a(CodingAgentTools::Models::Code::ReviewTarget)
        expect(result.type).to eq("git_diff")
        expect(result.target_spec).to eq(git_diff_target)
        expect(result.content_type).to eq("diff")
        expect(result.size_info[:lines]).to eq(50)
        expect(result.size_info[:files]).to eq(3)
        expect(result.size_info[:additions]).to eq(25)
        expect(result.size_info[:deletions]).to eq(5)
      end

      context "when git diff extraction fails" do
        let(:error_result) { { success: false, error: "Git command failed" } }

        before do
          allow(@mock_diff_extractor).to receive(:extract_diff).with(git_diff_target).and_return(error_result)
        end

        it "returns error ReviewTarget" do
          result = content_extractor.extract_content(git_diff_target)

          expect(result.type).to eq("error")
          expect(result.size_info[:error]).to eq("Git command failed")
        end
      end
    end

    context "when target is a single file" do
      let(:file_result) do
        {
          success: true,
          file_list: [test_file_path]
        }
      end

      before do
        allow(@mock_diff_extractor).to receive(:git_diff_target?).with(test_file_path).and_return(false)
        allow(@mock_file_extractor).to receive(:extract_files).with(test_file_path).and_return(file_result)
      end

      it "extracts single file content and returns proper ReviewTarget" do
        result = content_extractor.extract_content(test_file_path)

        expect(result).to be_a(CodingAgentTools::Models::Code::ReviewTarget)
        expect(result.type).to eq("single_file")
        expect(result.target_spec).to eq(test_file_path)
        expect(result.content_type).to eq("xml")
        expect(result.resolved_paths).to eq([test_file_path])
        expect(result.size_info[:files]).to eq(1)
        expect(result.size_info[:lines]).to eq(3) # Based on test file content
      end

      context "when single file extraction fails" do
        let(:error_result) { { success: false, error: "File not found" } }

        before do
          allow(@mock_file_extractor).to receive(:extract_files).with(test_file_path).and_return(error_result)
        end

        it "returns error ReviewTarget" do
          result = content_extractor.extract_content(test_file_path)

          expect(result.type).to eq("error")
          expect(result.size_info[:error]).to eq("File not found")
        end
      end
    end

    context "when target is a file pattern" do
      let(:pattern_target) { "*.rb" }
      let(:pattern_result) do
        {
          success: true,
          file_list: [test_file_path, "#{temp_dir}/another.rb"]
        }
      end

      before do
        File.write("#{temp_dir}/another.rb", "# Another file\nmodule Test\nend\n")
        allow(@mock_diff_extractor).to receive(:git_diff_target?).with(pattern_target).and_return(false)
        allow(@mock_file_extractor).to receive(:extract_files).with(pattern_target).and_return(pattern_result)
      end

      it "extracts pattern-based content and returns proper ReviewTarget" do
        result = content_extractor.extract_content(pattern_target)

        expect(result).to be_a(CodingAgentTools::Models::Code::ReviewTarget)
        expect(result.type).to eq("file_pattern")
        expect(result.target_spec).to eq(pattern_target)
        expect(result.content_type).to eq("xml")
        expect(result.resolved_paths).to eq(pattern_result[:file_list])
        expect(result.size_info[:files]).to eq(2)
        expect(result.size_info[:lines]).to eq(6) # Sum of both files
      end
    end
  end

  describe "#save_content" do
    let(:session_dir) { File.join(temp_dir, "session") }
    
    before do
      FileUtils.mkdir_p(session_dir)
    end

    context "with git_diff target" do
      let(:git_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "git_diff",
          target_spec: "HEAD~1..HEAD",
          resolved_paths: [],
          content_type: "diff",
          size_info: {}
        )
      end

      it "delegates to diff extractor" do
        save_result = { success: true, error: nil }
        expect(@mock_diff_extractor).to receive(:extract_and_save).with("HEAD~1..HEAD", session_dir).and_return(save_result)

        result = content_extractor.save_content(git_target, session_dir)
        expect(result).to eq(save_result)
      end
    end

    context "with file targets" do
      let(:file_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "single_file",
          target_spec: test_file_path,
          resolved_paths: [test_file_path],
          content_type: "xml",
          size_info: {}
        )
      end

      it "delegates to file extractor" do
        save_result = { success: true, error: nil }
        expect(@mock_file_extractor).to receive(:extract_and_save).with(test_file_path, session_dir).and_return(save_result)

        result = content_extractor.save_content(file_target, session_dir)
        expect(result).to eq(save_result)
      end
    end

    context "with unknown target type" do
      let(:unknown_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "unknown",
          target_spec: "test",
          resolved_paths: [],
          content_type: "none",
          size_info: {}
        )
      end

      it "returns error for unknown type" do
        result = content_extractor.save_content(unknown_target, session_dir)
        
        expect(result[:success]).to be(false)
        expect(result[:error]).to eq("Unknown target type: unknown")
      end
    end
  end

  describe "#extract_and_save" do
    let(:session_dir) { File.join(temp_dir, "session") }
    
    before do
      FileUtils.mkdir_p(session_dir)
    end

    context "when extraction succeeds and save succeeds" do
      let(:successful_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "single_file",
          target_spec: test_file_path,
          resolved_paths: [test_file_path],
          content_type: "xml",
          size_info: { files: 1, lines: 3 }
        )
      end

      before do
        allow(content_extractor).to receive(:extract_content).with(test_file_path).and_return(successful_target)
        allow(content_extractor).to receive(:save_content).with(successful_target, session_dir).and_return({ success: true, error: nil })
      end

      it "returns the successful target" do
        result = content_extractor.extract_and_save(test_file_path, session_dir)
        
        expect(result).to eq(successful_target)
        expect(result.type).to eq("single_file")
      end
    end

    context "when extraction succeeds but save fails" do
      let(:successful_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "single_file",
          target_spec: test_file_path,
          resolved_paths: [test_file_path],
          content_type: "xml",
          size_info: { files: 1, lines: 3 }
        )
      end

      before do
        allow(content_extractor).to receive(:extract_content).with(test_file_path).and_return(successful_target)
        allow(content_extractor).to receive(:save_content).with(successful_target, session_dir).and_return({ success: false, error: "Save failed" })
      end

      it "returns error target with save error" do
        result = content_extractor.extract_and_save(test_file_path, session_dir)
        
        expect(result.type).to eq("error")
        expect(result.target_spec).to eq(test_file_path)
        expect(result.size_info[:error]).to eq("Save failed")
      end
    end

    context "when extraction fails" do
      let(:error_target) do
        CodingAgentTools::Models::Code::ReviewTarget.new(
          type: "error",
          target_spec: test_file_path,
          resolved_paths: [],
          content_type: "none",
          size_info: { error: "Extraction failed" }
        )
      end

      before do
        allow(content_extractor).to receive(:extract_content).with(test_file_path).and_return(error_target)
      end

      it "returns the error target without attempting save" do
        expect(content_extractor).not_to receive(:save_content)
        
        result = content_extractor.extract_and_save(test_file_path, session_dir)
        expect(result).to eq(error_target)
      end
    end
  end

  describe "private methods" do
    describe "#count_lines_in_file" do
      it "counts lines correctly" do
        line_count = content_extractor.send(:count_lines_in_file, test_file_path)
        expect(line_count).to eq(3)
      end

      it "returns 0 for non-existent file" do
        line_count = content_extractor.send(:count_lines_in_file, "/non/existent/file")
        expect(line_count).to eq(0)
      end
    end

    describe "#count_total_lines" do
      let(:another_file) { File.join(temp_dir, "another.rb") }
      
      before do
        File.write(another_file, "# Line 1\n# Line 2\n")
      end

      it "sums lines across multiple files" do
        total_lines = content_extractor.send(:count_total_lines, [test_file_path, another_file])
        expect(total_lines).to eq(5) # 3 + 2
      end
    end
  end
end