# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Code::ReviewPrepare::ProjectTarget do
  let(:command) { described_class.new }
  let(:mock_content_extractor) { instance_double("CodingAgentTools::Organisms::Code::ContentExtractor") }
  let(:temp_dir) { Dir.mktmpdir }
  let(:session_dir) { File.join(temp_dir, "session") }

  before do
    FileUtils.mkdir_p(session_dir)
    allow(CodingAgentTools::Organisms::Code::ContentExtractor).to receive(:new).and_return(mock_content_extractor)

    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#call" do
    context "with successful target extraction" do
      let(:successful_target) do
        double("target",
          type: "git_range",
          content_type: "diff",
          file_count: 5,
          line_count: 150,
          size_info: {error: nil})
      end

      before do
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(successful_target)
      end

      it "extracts and saves target successfully" do
        result = command.call(target: "HEAD~1..HEAD", session_dir: session_dir)

        expect(result).to eq(0)
        expect(mock_content_extractor).to have_received(:extract_and_save).with(
          "HEAD~1..HEAD", session_dir
        )
      end

      it "displays success information" do
        command.call(target: "HEAD~1..HEAD", session_dir: session_dir)

        expect($stdout).to have_received(:puts).with("✅ Extracted target: git_range")
        expect($stdout).to have_received(:puts).with("📄 Content type: diff")
        expect($stdout).to have_received(:puts).with("📊 Files: 5, Lines: 150")
      end

      it "handles different target types" do
        targets = [
          {type: "file_pattern", content_type: "files", file_count: 10, line_count: 500},
          {type: "staged", content_type: "diff", file_count: 3, line_count: 75},
          {type: "working", content_type: "diff", file_count: 8, line_count: 200}
        ]

        targets.each do |target_info|
          target = double("target",
            type: target_info[:type],
            content_type: target_info[:content_type],
            file_count: target_info[:file_count],
            line_count: target_info[:line_count],
            size_info: {error: nil})

          allow(mock_content_extractor).to receive(:extract_and_save).and_return(target)

          result = command.call(target: "test", session_dir: session_dir)

          expect(result).to eq(0)
          expect($stdout).to have_received(:puts).with("✅ Extracted target: #{target_info[:type]}")
          expect($stdout).to have_received(:puts).with("📄 Content type: #{target_info[:content_type]}")
          expect($stdout).to have_received(:puts).with("📊 Files: #{target_info[:file_count]}, Lines: #{target_info[:line_count]}")
        end
      end

      it "handles zero file/line counts" do
        empty_target = double("target",
          type: "empty",
          content_type: "none",
          file_count: 0,
          line_count: 0,
          size_info: {error: nil})
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(empty_target)

        result = command.call(target: "empty", session_dir: session_dir)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with("📊 Files: 0, Lines: 0")
      end
    end

    context "with different target specifications" do
      let(:successful_target) do
        double("target",
          type: "test",
          content_type: "test",
          file_count: 1,
          line_count: 10,
          size_info: {error: nil})
      end

      before do
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(successful_target)
      end

      it "handles git range targets" do
        command.call(target: "HEAD~1..HEAD", session_dir: session_dir)

        expect(mock_content_extractor).to have_received(:extract_and_save).with(
          "HEAD~1..HEAD", session_dir
        )
      end

      it "handles file pattern targets" do
        command.call(target: "lib/**/*.rb", session_dir: session_dir)

        expect(mock_content_extractor).to have_received(:extract_and_save).with(
          "lib/**/*.rb", session_dir
        )
      end

      it "handles special targets" do
        %w[staged unstaged working].each do |special_target|
          command.call(target: special_target, session_dir: session_dir)

          expect(mock_content_extractor).to have_received(:extract_and_save).with(
            special_target, session_dir
          )
        end
      end

      it "handles complex file patterns" do
        complex_patterns = [
          "src/**/*.{js,ts}",
          "spec/**/*_spec.rb",
          "{lib,app}/**/*.rb"
        ]

        complex_patterns.each do |pattern|
          command.call(target: pattern, session_dir: session_dir)

          expect(mock_content_extractor).to have_received(:extract_and_save).with(
            pattern, session_dir
          )
        end
      end
    end

    context "with error target" do
      let(:error_target) do
        double("target",
          type: "error",
          content_type: "none",
          file_count: 0,
          line_count: 0,
          size_info: {error: "Target not found"})
      end

      before do
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(error_target)
      end

      it "returns error code and shows error message" do
        result = command.call(target: "invalid-target", session_dir: session_dir)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Target not found\n")
      end

      it "handles different error messages" do
        error_messages = [
          "Git range not found",
          "No files match pattern",
          "Invalid target specification"
        ]

        error_messages.each do |error_msg|
          error_target = double("target",
            type: "error",
            content_type: "none",
            file_count: 0,
            line_count: 0,
            size_info: {error: error_msg})
          allow(mock_content_extractor).to receive(:extract_and_save).and_return(error_target)

          result = command.call(target: "invalid", session_dir: session_dir)

          expect(result).to eq(1)
          expect($stderr).to have_received(:write).with("Error: #{error_msg}\n")
        end
      end
    end

    context "with extraction exceptions" do
      before do
        allow(mock_content_extractor).to receive(:extract_and_save).and_raise(StandardError, "Extraction failed")
      end

      it "handles exceptions gracefully" do
        result = command.call(target: "HEAD~1..HEAD", session_dir: session_dir)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Extraction failed\n")
      end

      it "handles different exception types" do
        exceptions = [
          [IOError, "File access denied"],
          [ArgumentError, "Invalid argument"],
          [RuntimeError, "Runtime error occurred"]
        ]

        exceptions.each do |exception_class, message|
          allow(mock_content_extractor).to receive(:extract_and_save).and_raise(exception_class, message)

          result = command.call(target: "test", session_dir: session_dir)

          expect(result).to eq(1)
          expect($stderr).to have_received(:write).with("Error: #{message}\n")
        end
      end
    end

    context "with missing session directory" do
      it "passes missing directory to content extractor" do
        # The content extractor should handle missing directories
        nonexistent_dir = "/nonexistent/session"

        result = command.call(target: "HEAD~1..HEAD", session_dir: nonexistent_dir)

        expect(mock_content_extractor).to have_received(:extract_and_save).with(
          "HEAD~1..HEAD", nonexistent_dir
        )
        # Result depends on how content extractor handles missing directories
        expect(result).to be_a(Integer)
      end
    end

    context "with large targets" do
      let(:large_target) do
        double("target",
          type: "file_pattern",
          content_type: "files",
          file_count: 1000,
          line_count: 50000,
          size_info: {error: nil})
      end

      before do
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(large_target)
      end

      it "handles large file counts" do
        result = command.call(target: "**/*.rb", session_dir: session_dir)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with("📊 Files: 1000, Lines: 50000")
      end
    end

    context "with edge case targets" do
      let(:edge_case_targets) do
        [
          {file_count: nil, line_count: nil},
          {file_count: -1, line_count: -1},
          {file_count: 0, line_count: nil}
        ]
      end

      it "handles edge case file/line counts" do
        edge_case_targets.each do |counts|
          target = double("target",
            type: "edge_case",
            content_type: "test",
            file_count: counts[:file_count],
            line_count: counts[:line_count],
            size_info: {error: nil})
          allow(mock_content_extractor).to receive(:extract_and_save).and_return(target)

          result = command.call(target: "test", session_dir: session_dir)

          expect(result).to eq(0)
          expect($stdout).to have_received(:puts).with("📊 Files: #{counts[:file_count]}, Lines: #{counts[:line_count]}")
        end
      end
    end

    context "with special characters in paths" do
      it "handles session directories with special characters" do
        special_session_dir = File.join(temp_dir, "session with spaces & symbols!")
        FileUtils.mkdir_p(special_session_dir)

        successful_target = double("target",
          type: "test", content_type: "test", file_count: 1, line_count: 10, size_info: {error: nil})
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(successful_target)

        result = command.call(target: "test", session_dir: special_session_dir)

        expect(result).to eq(0)
        expect(mock_content_extractor).to have_received(:extract_and_save).with(
          "test", special_session_dir
        )
      end

      it "handles targets with special characters" do
        special_targets = [
          "files with spaces/**/*.rb",
          "path/with-dashes/**/*",
          "path_with_underscores/**/*"
        ]

        successful_target = double("target",
          type: "test", content_type: "test", file_count: 1, line_count: 10, size_info: {error: nil})
        allow(mock_content_extractor).to receive(:extract_and_save).and_return(successful_target)

        special_targets.each do |target_spec|
          result = command.call(target: target_spec, session_dir: session_dir)

          expect(result).to eq(0)
          expect(mock_content_extractor).to have_received(:extract_and_save).with(
            target_spec, session_dir
          )
        end
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.desc).to eq("Extract target content (diff or files)")
    end

    it "requires target option" do
      expect { command.call(session_dir: session_dir) }.to raise_error(ArgumentError)
    end

    it "requires session_dir option" do
      expect { command.call(target: "test") }.to raise_error(ArgumentError)
    end

    it "has usage examples defined" do
      expect(described_class).to respond_to(:example)
    end
  end

  describe "integration with dependencies" do
    it "creates content extractor instance" do
      expect(CodingAgentTools::Organisms::Code::ContentExtractor).to receive(:new)

      begin
        command.call(target: "test", session_dir: session_dir)
      rescue
        nil
      end
    end

    it "delegates to content extractor properly" do
      target_spec = "HEAD~1..HEAD"
      session_path = "/path/to/session"

      expect(mock_content_extractor).to receive(:extract_and_save).with(target_spec, session_path)

      begin
        command.call(target: target_spec, session_dir: session_path)
      rescue
        nil
      end
    end
  end

  describe "return codes" do
    it "returns 0 for successful extraction" do
      successful_target = double("target",
        type: "success", content_type: "test", file_count: 1, line_count: 10, size_info: {error: nil})
      allow(mock_content_extractor).to receive(:extract_and_save).and_return(successful_target)

      result = command.call(target: "test", session_dir: session_dir)
      expect(result).to eq(0)
    end

    it "returns 1 for error targets" do
      error_target = double("target",
        type: "error", content_type: "none", file_count: 0, line_count: 0,
        size_info: {error: "Test error"})
      allow(mock_content_extractor).to receive(:extract_and_save).and_return(error_target)

      result = command.call(target: "test", session_dir: session_dir)
      expect(result).to eq(1)
    end

    it "returns 1 for exceptions" do
      allow(mock_content_extractor).to receive(:extract_and_save).and_raise(StandardError)

      result = command.call(target: "test", session_dir: session_dir)
      expect(result).to eq(1)
    end
  end
end
