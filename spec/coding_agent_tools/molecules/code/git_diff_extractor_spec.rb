# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::Code::GitDiffExtractor do
  let(:extractor) { described_class.new }
  let(:git_executor_mock) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }
  let(:file_reader_mock) { instance_double(CodingAgentTools::Atoms::Code::FileContentReader) }

  before do
    # Mock the atoms dependencies
    allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(git_executor_mock)
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(file_reader_mock)
    
    # Set up the instance variable mocks
    extractor.instance_variable_set(:@git_executor, git_executor_mock)
    extractor.instance_variable_set(:@file_reader, file_reader_mock)
  end

  describe "#extract_diff" do
    context "when extracting staged changes" do
      let(:target_spec) { "staged" }
      let(:diff_output) do
        <<~DIFF
          diff --git a/lib/example.rb b/lib/example.rb
          index 1234567..abcdefg 100644
          --- a/lib/example.rb
          +++ b/lib/example.rb
          @@ -1,3 +1,4 @@
           # Example file
          +puts "Hello World"
           def example_method
             true
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).with("diff --no-color --staged").and_return(
          success: true,
          stdout: diff_output,
          stderr: ""
        )
      end

      it "returns successful result with diff content" do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq(diff_output)
        expect(result[:metadata][:target]).to eq("staged")
        expect(result[:metadata][:empty]).to be false
        expect(result[:error]).to be_nil
      end

      it "extracts metadata about changes" do
        result = extractor.extract_diff(target_spec)

        metadata = result[:metadata]
        expect(metadata[:files_changed]).to eq(1)
        expect(metadata[:additions]).to be_positive
        expect(metadata[:target]).to eq(target_spec)
      end
    end

    context "when extracting commit range" do
      let(:target_spec) { "HEAD~2..HEAD" }
      let(:diff_output) do
        <<~DIFF
          diff --git a/README.md b/README.md
          index 1111111..2222222 100644
          --- a/README.md
          +++ b/README.md
          @@ -1,2 +1,3 @@
           # Project Title
           Description
          +New line added
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).with("diff --no-color HEAD~2..HEAD").and_return(
          success: true,
          stdout: diff_output,
          stderr: ""
        )
      end

      it "returns diff for specified commit range" do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq(diff_output)
        expect(result[:metadata][:type]).to eq("git_diff")
        expect(result[:metadata][:target]).to eq(target_spec)
      end
    end

    context "when no changes exist" do
      let(:target_spec) { "staged" }

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: "",
          stderr: ""
        )
      end

      it "returns successful result with empty content" do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq("")
        expect(result[:metadata][:empty]).to be true
        expect(result[:metadata][:files_changed]).to eq(0)
      end
    end

    context "when git command fails" do
      let(:target_spec) { "invalid-range" }

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: false,
          stdout: "",
          stderr: "fatal: ambiguous argument 'invalid-range'"
        )
      end

      it "returns failure result with error message" do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:metadata]).to eq({})
        expect(result[:error]).to include("ambiguous argument")
      end
    end

    context "when git executor raises exception" do
      let(:target_spec) { "staged" }

      before do
        allow(git_executor_mock).to receive(:execute).and_raise(StandardError.new("Git not found"))
      end

      it "handles exceptions gracefully" do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to include("Git command failed: Git not found")
      end
    end
  end

  describe "#extract_and_save" do
    let(:target_spec) { "staged" }
    let(:session_dir) { "/tmp/session" }
    let(:diff_content) { "diff --git a/test.rb b/test.rb\n+new line" }

    before do
      allow(git_executor_mock).to receive(:execute).and_return(
        success: true,
        stdout: diff_content,
        stderr: ""
      )
      allow(File).to receive(:write)
    end

    it "saves diff and metadata files" do
      diff_file = File.join(session_dir, "input.diff")
      meta_file = File.join(session_dir, "input.meta")

      result = extractor.extract_and_save(target_spec, session_dir)

      expect(result[:success]).to be true
      expect(result[:diff_file]).to eq(diff_file)
      expect(result[:meta_file]).to eq(meta_file)
      
      expect(File).to have_received(:write).with(diff_file, diff_content)
      expect(File).to have_received(:write).with(meta_file, anything)
    end

    it "handles file write errors" do
      allow(File).to receive(:write).and_raise(StandardError.new("Permission denied"))

      result = extractor.extract_and_save(target_spec, session_dir)

      expect(result[:success]).to be false
      expect(result[:error]).to include("Failed to save diff: Permission denied")
    end
  end

  describe "private methods" do
    describe "#build_diff_command" do
      it "builds command for staged changes" do
        command = extractor.send(:build_diff_command, "staged")
        expect(command).to eq("diff --no-color --staged")
      end

      it "builds command for working directory changes" do
        command = extractor.send(:build_diff_command, "working")
        expect(command).to eq("diff --no-color HEAD")
      end

      it "builds command for commit ranges" do
        command = extractor.send(:build_diff_command, "HEAD~1..HEAD")
        expect(command).to eq("diff --no-color HEAD~1..HEAD")
      end

      it "builds command for specific commits" do
        command = extractor.send(:build_diff_command, "abc123")
        expect(command).to eq("diff --no-color abc123")
      end
    end

    describe "#build_diff_metadata" do
      let(:diff_with_changes) do
        <<~DIFF
          diff --git a/file1.rb b/file1.rb
          index 1234567..abcdefg 100644
          --- a/file1.rb
          +++ b/file1.rb
          @@ -1,2 +1,3 @@
           existing line
          +new line
           another line
          diff --git a/file2.rb b/file2.rb
          index 7890abc..defghij 100644
          --- a/file2.rb
          +++ b/file2.rb
          @@ -1 +1,2 @@
           original
          +added line
        DIFF
      end

      it "extracts metadata from diff output" do
        metadata = extractor.send(:build_diff_metadata, "staged", diff_with_changes)

        expect(metadata[:target]).to eq("staged")
        expect(metadata[:type]).to eq("git_diff")
        expect(metadata[:empty]).to be false
        expect(metadata[:files_changed]).to eq(2)
        expect(metadata[:additions]).to eq(2)
        expect(metadata[:deletions]).to eq(0)
      end

      it "handles empty diff output" do
        metadata = extractor.send(:build_diff_metadata, "working", "")

        expect(metadata[:empty]).to be true
        expect(metadata[:files_changed]).to eq(0)
        expect(metadata[:additions]).to eq(0)
        expect(metadata[:deletions]).to eq(0)
      end
    end

    describe "#git_diff_target?" do
      it "identifies staged changes" do
        result = extractor.git_diff_target?("staged")
        expect(result).to be true
      end

      it "identifies working directory changes" do
        result = extractor.git_diff_target?("working")
        expect(result).to be true
      end

      it "identifies commit ranges" do
        result = extractor.git_diff_target?("HEAD~2..HEAD")
        expect(result).to be true
      end

      it "identifies single commits" do
        result = extractor.git_diff_target?("abc123def")
        expect(result).to be true
      end

      it "rejects non-git targets" do
        result = extractor.git_diff_target?("invalid-target")
        expect(result).to be false
      end
    end
  end
end