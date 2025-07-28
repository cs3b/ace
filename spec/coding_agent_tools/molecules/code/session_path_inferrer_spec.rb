# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Molecules::Code::SessionPathInferrer do
  let(:inferrer) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe "InferenceResult" do
    describe "#initialize" do
      it "creates result with all parameters" do
        result = described_class::InferenceResult.new(
          session_directory: "/path/to/session",
          session_type: "explicit_session",
          session_id: "session-123",
          metadata: { key: "value" }
        )

        expect(result.session_directory).to eq("/path/to/session")
        expect(result.session_type).to eq("explicit_session")
        expect(result.session_id).to eq("session-123")
        expect(result.metadata).to eq({ key: "value" })
      end

      it "creates result with default parameters" do
        result = described_class::InferenceResult.new

        expect(result.session_directory).to be_nil
        expect(result.session_type).to be_nil
        expect(result.session_id).to be_nil
        expect(result.metadata).to eq({})
      end
    end

    describe "#has_session?" do
      it "returns true when session_directory is present" do
        result = described_class::InferenceResult.new(session_directory: "/path")
        expect(result.has_session?).to be true
      end

      it "returns false when session_directory is nil" do
        result = described_class::InferenceResult.new
        expect(result.has_session?).to be false
      end
    end

    describe "#no_session?" do
      it "returns false when session_directory is present" do
        result = described_class::InferenceResult.new(session_directory: "/path")
        expect(result.no_session?).to be false
      end

      it "returns true when session_directory is nil" do
        result = described_class::InferenceResult.new
        expect(result.no_session?).to be true
      end
    end
  end

  describe "#infer_session_path" do
    context "with nil or empty path" do
      it "returns empty result for nil path" do
        result = inferrer.infer_session_path(nil)
        
        expect(result.no_session?).to be true
        expect(result.session_type).to be_nil
      end

      it "returns empty result for empty string" do
        result = inferrer.infer_session_path("")
        
        expect(result.no_session?).to be true
        expect(result.session_type).to be_nil
      end
    end

    context "with non-existent file" do
      it "returns empty result for non-existent path" do
        result = inferrer.infer_session_path("/non/existent/path.md")
        
        expect(result.no_session?).to be true
        expect(result.session_type).to be_nil
      end
    end

    context "with explicit session directory" do
      it "detects session with session.meta file" do
        session_dir = File.join(temp_dir, "session-20240101-120000")
        FileUtils.mkdir_p(session_dir)
        
        # Create session.meta file
        meta_path = File.join(session_dir, "session.meta")
        File.write(meta_path, "session_id: test-session\ntype: code_review\n")
        
        # Create report file
        report_path = File.join(session_dir, "report.md")
        File.write(report_path, "# Test Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("explicit_session")
        expect(result.session_directory).to eq(session_dir)
        expect(result.session_id).to eq("session-20240101-120000")
        expect(result.metadata["session_id"]).to eq("test-session")
        expect(result.metadata["type"]).to eq("code_review")
      end

      it "handles session.meta with parse errors" do
        session_dir = File.join(temp_dir, "session-test")
        FileUtils.mkdir_p(session_dir)
        
        # Create invalid session.meta file
        meta_path = File.join(session_dir, "session.meta")
        File.write(meta_path, "invalid content without colons")
        
        report_path = File.join(session_dir, "report.md")
        File.write(report_path, "# Test Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("explicit_session")
        expect(result.metadata.key?(:parse_error)).to be false # No error for missing colons
      end

      it "handles session.meta read errors gracefully" do
        session_dir = File.join(temp_dir, "session-test")
        FileUtils.mkdir_p(session_dir)
        
        # Create session.meta file with restricted permissions
        meta_path = File.join(session_dir, "session.meta")
        File.write(meta_path, "test: content")
        File.chmod(0000, meta_path) # No read permissions
        
        report_path = File.join(session_dir, "report.md")
        File.write(report_path, "# Test Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("explicit_session")
        expect(result.metadata[:parse_error]).to include("Permission denied")
        
        # Cleanup
        File.chmod(0644, meta_path)
      end
    end

    context "with taskflow session directory" do
      it "detects taskflow session pattern" do
        # The taskflow detection requires exact pattern: dev-taskflow/current/[version]/code_review/[session]
        # path_parts[code_review_index - 2] must be "dev-taskflow"
        # path_parts[code_review_index - 1] must be "current"
        taskflow_dir = File.join(temp_dir, "dev-taskflow", "current", "code_review", "session-123")
        FileUtils.mkdir_p(taskflow_dir)
        
        report_path = File.join(taskflow_dir, "report.md")
        File.write(report_path, "# Taskflow Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("taskflow_session")
        expect(result.session_directory).to eq(taskflow_dir)
        expect(result.session_id).to eq("session-123")
        expect(result.metadata["taskflow_pattern"]).to be true
      end

      it "handles taskflow pattern without session ID" do
        taskflow_dir = File.join(temp_dir, "dev-taskflow", "current", "code_review")
        FileUtils.mkdir_p(taskflow_dir)
        
        report_path = File.join(taskflow_dir, "report.md")
        File.write(report_path, "# Taskflow Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("taskflow_session")
        expect(result.session_directory).to eq(taskflow_dir)
        expect(result.session_id).to be_nil
      end

      it "does not detect non-taskflow code_review directories" do
        non_taskflow_dir = File.join(temp_dir, "project", "code_review", "session-123")
        FileUtils.mkdir_p(non_taskflow_dir)
        
        report_path = File.join(non_taskflow_dir, "report.md")
        File.write(report_path, "# Non-taskflow Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.session_type).not_to eq("taskflow_session")
      end
    end

    context "with generic session directory" do
      it "detects session based on session files" do
        session_dir = File.join(temp_dir, "analysis-session")
        FileUtils.mkdir_p(session_dir)
        
        # Create session indicator files
        File.write(File.join(session_dir, "input.diff"), "diff content")
        File.write(File.join(session_dir, "project_context.md"), "context")
        File.write(File.join(session_dir, "cr-report-1.md"), "report 1")
        
        report_path = File.join(session_dir, "main-report.md")
        File.write(report_path, "# Main Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("inferred_session")
        expect(result.session_directory).to eq(session_dir)
        expect(result.session_id).to eq("analysis-session")
        expect(result.metadata[:session_files]).to include("input.diff", "project_context.md")
        expect(result.metadata[:report_files]).to include("cr-report-1.md")
        expect(result.metadata[:session_score]).to be >= 3
      end

      it "detects session based on timestamp pattern" do
        session_dir = File.join(temp_dir, "20240101-120000")
        FileUtils.mkdir_p(session_dir)
        
        # Create minimum session indicators
        File.write(File.join(session_dir, "input.xml"), "xml content")
        File.write(File.join(session_dir, "combined_prompt.md"), "prompt")
        File.write(File.join(session_dir, "cr-report.md"), "report")
        
        report_path = File.join(session_dir, "report.md")
        File.write(report_path, "# Timestamped Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("inferred_session")
        expect(result.metadata[:timestamp_pattern]).to be true
        expect(result.metadata[:session_score]).to be >= 3
      end

      it "detects session based on name pattern" do
        session_dir = File.join(temp_dir, "review-analysis")
        FileUtils.mkdir_p(session_dir)
        
        # Create session indicators
        File.write(File.join(session_dir, "README.md"), "readme")
        File.write(File.join(session_dir, "session.log"), "log")
        File.write(File.join(session_dir, "cr-report.md"), "report")
        
        report_path = File.join(session_dir, "report.md")
        File.write(report_path, "# Named Session Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.has_session?).to be true
        expect(result.session_type).to eq("inferred_session")
        expect(result.metadata[:session_name_pattern]).to be true
        expect(result.metadata[:session_score]).to be >= 3
      end

      it "does not detect non-session directories" do
        regular_dir = File.join(temp_dir, "regular-directory")
        FileUtils.mkdir_p(regular_dir)
        
        # Create only one indicator (insufficient for session detection)
        File.write(File.join(regular_dir, "README.md"), "readme")
        
        report_path = File.join(regular_dir, "report.md")
        File.write(report_path, "# Regular Report")

        result = inferrer.infer_session_path(report_path)

        expect(result.no_session?).to be true
        expect(result.session_type).to be_nil
      end
    end

    context "with directory access errors" do
      it "handles permission denied gracefully" do
        restricted_dir = File.join(temp_dir, "restricted")
        FileUtils.mkdir_p(restricted_dir)
        File.chmod(0000, restricted_dir) # No access permissions
        
        report_path = File.join(restricted_dir, "report.md")
        
        # Mock File methods more comprehensively
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(report_path).and_return(true)
        allow(File).to receive(:exist?).with(File.join(restricted_dir, "session.meta")).and_return(false)
        allow(File).to receive(:expand_path).with(report_path).and_return(report_path)
        allow(File).to receive(:dirname).with(report_path).and_return(restricted_dir)
        allow(File).to receive(:directory?).with(restricted_dir).and_return(true)

        result = inferrer.infer_session_path(report_path)

        expect(result.no_session?).to be true
        
        # Cleanup
        File.chmod(0755, restricted_dir)
      end
    end
  end

  describe "#infer_output_path" do
    context "with empty report paths" do
      it "returns default path for empty array" do
        result = inferrer.infer_output_path([])
        expect(result).to eq("/inferred/path.md")
      end
    end

    context "with session directory" do
      it "returns session-relative path when session is detected" do
        session_dir = File.join(temp_dir, "session-test")
        FileUtils.mkdir_p(session_dir)
        
        # Create session.meta file
        meta_path = File.join(session_dir, "session.meta")
        File.write(meta_path, "session_id: test\n")
        
        report_path = File.join(session_dir, "input-report.md")
        File.write(report_path, "# Input Report")

        result = inferrer.infer_output_path([report_path])
        expected_path = File.join(session_dir, "cr-report.md")
        
        expect(result).to eq(expected_path)
      end

      it "handles multiple report paths using first path" do
        session_dir = File.join(temp_dir, "multi-session")
        FileUtils.mkdir_p(session_dir)
        
        # Create session indicators
        File.write(File.join(session_dir, "input.diff"), "diff")
        File.write(File.join(session_dir, "README.md"), "readme")
        File.write(File.join(session_dir, "cr-report.md"), "existing report")
        
        report1_path = File.join(session_dir, "report1.md")
        report2_path = File.join(session_dir, "report2.md")
        File.write(report1_path, "# Report 1")
        File.write(report2_path, "# Report 2")

        result = inferrer.infer_output_path([report1_path, report2_path])
        expected_path = File.join(session_dir, "cr-report.md")
        
        expect(result).to eq(expected_path)
      end
    end

    context "without session directory" do
      it "returns default filename when no session detected" do
        regular_dir = File.join(temp_dir, "regular")
        FileUtils.mkdir_p(regular_dir)
        
        report_path = File.join(regular_dir, "report.md")
        File.write(report_path, "# Regular Report")

        result = inferrer.infer_output_path([report_path])
        
        expect(result).to eq("cr-report.md")
      end
    end
  end

  describe "private methods" do
    describe "#check_session_indicators" do
      it "calculates session score based on multiple indicators" do
        session_dir = File.join(temp_dir, "score-test")
        FileUtils.mkdir_p(session_dir)
        
        # Create various indicators
        File.write(File.join(session_dir, "input.diff"), "diff")
        File.write(File.join(session_dir, "project_context.md"), "context")
        File.write(File.join(session_dir, "synthesis.meta"), "meta")
        File.write(File.join(session_dir, "cr-report-1.md"), "report1")
        File.write(File.join(session_dir, "cr-report-2.md"), "report2")
        
        # Rename directory to include timestamp pattern
        timestamped_dir = File.join(temp_dir, "20240101-120000-session")
        File.rename(session_dir, timestamped_dir)

        indicators = inferrer.send(:check_session_indicators, timestamped_dir)

        expect(indicators[:is_session]).to be true
        expect(indicators[:session_files].length).to be >= 2
        expect(indicators[:report_files].length).to eq(2)
        expect(indicators[:timestamp_pattern]).to be true
        expect(indicators[:session_name_pattern]).to be true
        expect(indicators[:session_score]).to be >= 6
      end

      it "handles directories with insufficient indicators" do
        regular_dir = File.join(temp_dir, "insufficient")
        FileUtils.mkdir_p(regular_dir)
        
        # Create only one indicator
        File.write(File.join(regular_dir, "README.md"), "readme")

        indicators = inferrer.send(:check_session_indicators, regular_dir)

        expect(indicators[:is_session]).to be false
        expect(indicators[:session_score]).to be < 3
      end

      it "handles non-existent directories" do
        indicators = inferrer.send(:check_session_indicators, "/non/existent/path")

        expect(indicators[:is_session]).to be false
        expect(indicators[:session_score]).to be_nil # No session_score calculated for non-existent dirs
      end
    end

    describe "#parse_session_metadata" do
      it "parses valid metadata format" do
        meta_path = File.join(temp_dir, "test.meta")
        content = <<~META
          session_id: test-123
          type: code_review
          timestamp: 2024-01-01T12:00:00Z
          
          # This is a comment
          empty_line_above:
          
          key_with_colon: value:with:colons
        META
        File.write(meta_path, content)

        metadata = inferrer.send(:parse_session_metadata, meta_path)

        expect(metadata["session_id"]).to eq("test-123")
        expect(metadata["type"]).to eq("code_review")
        expect(metadata["timestamp"]).to eq("2024-01-01T12:00:00Z")
        expect(metadata["key_with_colon"]).to eq("value:with:colons")
        expect(metadata.key?("# This is a comment")).to be false
        expect(metadata.key?("empty_line_above")).to be true # Key with empty value is still stored
      end

      it "handles files with no colon separators" do
        meta_path = File.join(temp_dir, "no-colons.meta")
        File.write(meta_path, "just plain text\nno colons here\n")

        metadata = inferrer.send(:parse_session_metadata, meta_path)

        expect(metadata).to be_empty
      end

      it "handles file read errors" do
        non_existent_path = File.join(temp_dir, "non-existent.meta")

        metadata = inferrer.send(:parse_session_metadata, non_existent_path)

        expect(metadata[:parse_error]).to include("No such file or directory")
      end
    end

    describe "#extract_session_id_from_path" do
      it "extracts timestamp-style session IDs" do
        session_id = inferrer.send(:extract_session_id_from_path, "/path/to/20240101-120000")
        expect(session_id).to eq("20240101-120000")
      end

      it "extracts session-prefixed IDs" do
        session_id = inferrer.send(:extract_session_id_from_path, "/path/to/session-abc123")
        expect(session_id).to eq("session-abc123")
      end

      it "extracts review-prefixed IDs" do
        session_id = inferrer.send(:extract_session_id_from_path, "/path/to/review-feature-x")
        expect(session_id).to eq("review-feature-x")
      end

      it "uses directory name as fallback" do
        session_id = inferrer.send(:extract_session_id_from_path, "/path/to/custom-directory")
        expect(session_id).to eq("custom-directory")
      end

      it "handles root directory edge case" do
        session_id = inferrer.send(:extract_session_id_from_path, "/")
        expect(session_id).to eq("/")
      end

      it "handles current directory edge case" do
        session_id = inferrer.send(:extract_session_id_from_path, ".")
        expect(session_id).to be_nil
      end
    end
  end

  describe "integration scenarios" do
    it "handles complex nested session detection" do
      # Create a complex directory structure
      base_dir = File.join(temp_dir, "complex-project")
      taskflow_session = File.join(base_dir, "dev-taskflow", "current", "code_review", "20240101-120000")
      FileUtils.mkdir_p(taskflow_session)
      
      # Add session.meta for explicit detection
      meta_content = "session_id: complex-test\nproject: test-project\n"
      File.write(File.join(taskflow_session, "session.meta"), meta_content)
      
      # Add session indicator files
      File.write(File.join(taskflow_session, "input.diff"), "complex diff")
      File.write(File.join(taskflow_session, "project_context.md"), "complex context")
      
      report_path = File.join(taskflow_session, "comprehensive-report.md")
      File.write(report_path, "# Comprehensive Report")

      result = inferrer.infer_session_path(report_path)

      # Should detect explicit session first (higher priority)
      expect(result.has_session?).to be true
      expect(result.session_type).to eq("explicit_session")
      expect(result.session_directory).to eq(taskflow_session)
      expect(result.session_id).to eq("20240101-120000")
      expect(result.metadata["session_id"]).to eq("complex-test")
    end

    it "handles edge case with multiple detection methods" do
      # Create directory that matches multiple patterns
      multi_pattern_dir = File.join(temp_dir, "session-20240101-120000-review")
      FileUtils.mkdir_p(multi_pattern_dir)
      
      # Add enough generic session indicators
      %w[input.diff input.xml project_context.md combined_prompt.md].each do |file|
        File.write(File.join(multi_pattern_dir, file), "content")
      end
      File.write(File.join(multi_pattern_dir, "cr-report.md"), "existing report")
      
      report_path = File.join(multi_pattern_dir, "test-report.md")
      File.write(report_path, "# Multi-pattern Report")

      result = inferrer.infer_session_path(report_path)

      expect(result.has_session?).to be true
      expect(result.session_type).to eq("inferred_session")
      expect(result.metadata[:timestamp_pattern]).to be true
      expect(result.metadata[:session_name_pattern]).to be true
      expect(result.metadata[:session_score]).to be >= 6
    end
  end
end