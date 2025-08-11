# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::Code::ReportCollector do
  let(:collector) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#collect_reports" do
    context "when report_paths is nil" do
      it "returns error result" do
        result = collector.collect_reports(nil)

        expect(result).to be_invalid
        expect(result.error).to eq("No report paths provided")
        expect(result.reports).to be_empty
      end
    end

    context "when report_paths is empty" do
      it "returns error result" do
        result = collector.collect_reports([])

        expect(result).to be_invalid
        expect(result.error).to eq("No report paths provided")
        expect(result.reports).to be_empty
      end
    end

    context "when handling glob patterns" do
      let(:review_file1) { File.join(temp_dir, "cr-report-001.md") }
      let(:review_file2) { File.join(temp_dir, "cr-report-002.md") }

      before do
        File.write(review_file1, <<~CONTENT)
          # Code Review Report

          ## Executive Summary
          This is a code review report.

          ## Code Quality
          Good overall quality.
        CONTENT

        File.write(review_file2, <<~CONTENT)
          # Review Synthesis Report

          ## Implementation Recommendations
          Several improvements needed.

          ## Test Coverage
          Coverage is adequate.
        CONTENT
      end

      context "when glob pattern matches files" do
        it "expands glob and collects review reports" do
          glob_pattern = File.join(temp_dir, "cr-report-*.md")
          result = collector.collect_reports([glob_pattern])

          expect(result).to be_valid
          expect(result.reports).to contain_exactly(review_file1, review_file2)
          expect(result.error).to be_nil
        end

        it "sorts the results" do
          glob_pattern = File.join(temp_dir, "cr-report-*.md")
          result = collector.collect_reports([glob_pattern])

          expect(result.reports).to eq([review_file1, review_file2])
        end
      end

      context "when glob pattern matches no files" do
        it "returns error result" do
          no_match_pattern = File.join(temp_dir, "nonexistent-*.md")
          result = collector.collect_reports([no_match_pattern])

          expect(result).to be_invalid
          expect(result.error).to include("No files found matching pattern")
        end
      end
    end

    context "when files don't exist" do
      it "returns error for non-existent file" do
        non_existent = File.join(temp_dir, "missing.md")
        result = collector.collect_reports([non_existent])

        expect(result).to be_invalid
        expect(result.error).to include("File not found")
      end
    end

    context "when no valid review reports found" do
      let(:non_review_file) { File.join(temp_dir, "regular-doc.md") }

      before do
        File.write(non_review_file, "# Regular Documentation\n\nThis is not a review report.")
      end

      it "returns error when no review reports are found" do
        result = collector.collect_reports([non_review_file])

        expect(result).to be_invalid
        expect(result.error).to eq("No valid review report files found")
      end
    end

    context "when only one review report found" do
      let(:single_review) { File.join(temp_dir, "cr-report-single.md") }

      before do
        File.write(single_review, <<~CONTENT)
          # Code Review Report

          ## Executive Summary
          Single review report.
        CONTENT
      end

      it "returns error requiring at least 2 reports" do
        result = collector.collect_reports([single_review])

        expect(result).to be_invalid
        expect(result.error).to eq("At least 2 review reports are required for synthesis")
      end
    end

    context "with sufficient valid review reports" do
      let(:review1) { File.join(temp_dir, "cr-report-alpha.md") }
      let(:review2) { File.join(temp_dir, "review-synthesis-beta.md") }

      before do
        File.write(review1, <<~CONTENT)
          # Code Review Alpha

          ## Executive Summary
          First review report.

          ## Code Quality
          Needs improvement.
        CONTENT

        File.write(review2, <<~CONTENT)
          # Review Synthesis Beta

          ## Implementation Recommendations
          Second review report.

          ## Performance
          Good performance overall.
        CONTENT
      end

      it "returns successful result with sorted reports" do
        result = collector.collect_reports([review1, review2])

        expect(result).to be_valid
        expect(result.reports).to eq([review1, review2])
        expect(result.error).to be_nil
      end
    end
  end

  describe "private methods" do
    describe "#validate_report_files" do
      let(:valid_file) { File.join(temp_dir, "valid-report.md") }
      let(:unreadable_file) { File.join(temp_dir, "unreadable.md") }
      let(:directory_path) { File.join(temp_dir, "directory") }

      before do
        File.write(valid_file, "# Valid report content")
        File.write(unreadable_file, "# Unreadable content")
        Dir.mkdir(directory_path)
        File.chmod(0o000, unreadable_file)
      end

      after do
        File.chmod(0o644, unreadable_file) if File.exist?(unreadable_file)
      end

      it "returns success for valid files" do
        result = collector.send(:validate_report_files, [valid_file])
        expect(result).to be_valid
        expect(result.reports).to eq([valid_file])
      end

      it "returns error for unreadable files" do
        result = collector.send(:validate_report_files, [unreadable_file])
        expect(result).to be_invalid
        expect(result.error).to include("File not readable")
      end

      it "returns error when path is a directory" do
        result = collector.send(:validate_report_files, [directory_path])
        expect(result).to be_invalid
        expect(result.error).to include("Path is not a file")
      end

      it "returns error for oversized files" do
        large_file = File.join(temp_dir, "large.md")
        File.write(large_file, "Content") # Create the file first

        # Stub File.size to simulate a large file
        allow(File).to receive(:size).with(large_file).and_return(60 * 1024 * 1024) # 60MB

        result = collector.send(:validate_report_files, [large_file])
        expect(result).to be_invalid
        expect(result.error).to include("File too large")
      end
    end

    describe "#review_report_file?" do
      let(:test_file) { File.join(temp_dir, "test.md") }

      context "with different file extensions" do
        it "accepts .md files" do
          File.write(test_file, "# Code Review\n## Executive Summary\nContent")
          expect(collector.send(:review_report_file?, test_file)).to be true
        end

        it "accepts .markdown files" do
          markdown_file = File.join(temp_dir, "test.markdown")
          File.write(markdown_file, "# Review Report\n## Code Quality\nContent")
          expect(collector.send(:review_report_file?, markdown_file)).to be true
        end

        it "rejects non-markdown files" do
          txt_file = File.join(temp_dir, "test.txt")
          File.write(txt_file, "# Review Report\n## Executive Summary\nContent")
          expect(collector.send(:review_report_file?, txt_file)).to be false
        end
      end

      context "with filename pattern matching" do
        it "matches cr-report prefix" do
          cr_file = File.join(temp_dir, "cr-report-123.md")
          File.write(cr_file, "Content")
          expect(collector.send(:review_report_file?, cr_file)).to be true
        end

        it "matches review-report pattern" do
          review_file = File.join(temp_dir, "alpha-review-beta-report.md")
          File.write(review_file, "Content")
          expect(collector.send(:review_report_file?, review_file)).to be true
        end

        it "matches report-review pattern" do
          report_file = File.join(temp_dir, "gamma-report-delta-review.md")
          File.write(report_file, "Content")
          expect(collector.send(:review_report_file?, report_file)).to be true
        end

        it "matches code-review pattern" do
          code_file = File.join(temp_dir, "code-review-final.md")
          File.write(code_file, "Content")
          expect(collector.send(:review_report_file?, code_file)).to be true
        end

        it "matches review-synthesis pattern" do
          synthesis_file = File.join(temp_dir, "review-synthesis-v2.md")
          File.write(synthesis_file, "Content")
          expect(collector.send(:review_report_file?, synthesis_file)).to be true
        end

        it "matches synthesis-review pattern" do
          synthesis_file = File.join(temp_dir, "synthesis-review-complete.md")
          File.write(synthesis_file, "Content")
          expect(collector.send(:review_report_file?, synthesis_file)).to be true
        end
      end

      context "with content-based detection" do
        it "identifies files with Executive Summary header" do
          File.write(test_file, <<~CONTENT)
            # Project Documentation
            
            ## Executive Summary
            This document contains review findings.
          CONTENT
          expect(collector.send(:review_report_file?, test_file)).to be true
        end

        it "identifies files with Implementation Recommendation header" do
          File.write(test_file, <<~CONTENT)
            # Analysis Report
            
            ## Implementation Recommendation
            Follow these guidelines.
          CONTENT
          expect(collector.send(:review_report_file?, test_file)).to be true
        end

        it "identifies files with provider metadata" do
          File.write(test_file, <<~CONTENT)
            # Report
            
            provider: google
            model: gemini-pro
            
            Content here.
          CONTENT
          expect(collector.send(:review_report_file?, test_file)).to be true
        end

        it "identifies files with review timestamp" do
          File.write(test_file, <<~CONTENT)
            # Analysis
            
            review_timestamp: 2025-01-01T10:00:00Z
            
            Analysis content.
          CONTENT
          expect(collector.send(:review_report_file?, test_file)).to be true
        end

        it "rejects files without review indicators" do
          File.write(test_file, <<~CONTENT)
            # Regular Documentation
            
            This is just regular documentation.
            No review indicators here.
          CONTENT
          expect(collector.send(:review_report_file?, test_file)).to be false
        end

        it "handles file read errors gracefully" do
          # Create file and make it unreadable after creation
          File.write(test_file, "Content")
          allow(File).to receive(:read).with(test_file, 2048, encoding: "UTF-8").and_raise(StandardError)

          expect(collector.send(:review_report_file?, test_file)).to be false
        end
      end

      context "with large files" do
        it "skips content inspection for files larger than 1MB" do
          large_file = File.join(temp_dir, "large-regular.md")
          File.write(large_file, "# Regular doc")

          # Stub File.size to simulate a large file
          allow(File).to receive(:size).with(large_file).and_return(2 * 1024 * 1024) # 2MB

          # Should return false since filename doesn't match patterns and file is too large for content check
          expect(collector.send(:review_report_file?, large_file)).to be false
        end
      end
    end

    describe "#file_readable_sample?" do
      it "returns true for files under 1MB" do
        small_file = File.join(temp_dir, "small.md")
        File.write(small_file, "Small content")
        expect(collector.send(:file_readable_sample?, small_file)).to be true
      end

      it "returns false for files over 1MB" do
        large_file = File.join(temp_dir, "large.md")
        allow(File).to receive(:size).with(large_file).and_return(2 * 1024 * 1024) # 2MB
        expect(collector.send(:file_readable_sample?, large_file)).to be false
      end
    end

    describe "#review_content_indicators?" do
      let(:test_file) { File.join(temp_dir, "content_test.md") }

      it "detects review headers correctly" do
        File.write(test_file, <<~CONTENT)
          # Report
          ## Code Quality
          Good overall quality.
        CONTENT
        expect(collector.send(:review_content_indicators?, test_file)).to be true
      end

      it "detects metadata patterns correctly" do
        File.write(test_file, <<~CONTENT)
          # Analysis
          focus: code
          Some analysis content.
        CONTENT
        expect(collector.send(:review_content_indicators?, test_file)).to be true
      end

      it "returns false for files without indicators" do
        File.write(test_file, <<~CONTENT)
          # Regular Document
          This is just regular content.
        CONTENT
        expect(collector.send(:review_content_indicators?, test_file)).to be false
      end
    end
  end

  describe "edge cases and complex scenarios" do
    context "with complex glob patterns" do
      let(:review1) { File.join(temp_dir, "subdir", "cr-report-1.md") }
      let(:review2) { File.join(temp_dir, "subdir", "cr-report-2.md") }

      before do
        Dir.mkdir(File.join(temp_dir, "subdir"))
        File.write(review1, "## Executive Summary\nFirst review")
        File.write(review2, "## Code Quality\nSecond review")
      end

      it "handles recursive glob patterns" do
        recursive_pattern = File.join(temp_dir, "**", "cr-report-*.md")
        result = collector.collect_reports([recursive_pattern])

        expect(result).to be_valid
        expect(result.reports).to contain_exactly(review1, review2)
      end

      it "handles character class patterns" do
        char_class_pattern = File.join(temp_dir, "subdir", "cr-report-[12].md")
        result = collector.collect_reports([char_class_pattern])

        expect(result).to be_valid
        expect(result.reports).to contain_exactly(review1, review2)
      end

      it "handles question mark wildcards" do
        question_pattern = File.join(temp_dir, "subdir", "cr-report-?.md")
        result = collector.collect_reports([question_pattern])

        expect(result).to be_valid
        expect(result.reports).to contain_exactly(review1, review2)
      end
    end

    context "with mixed file types and validation scenarios" do
      let(:valid_review) { File.join(temp_dir, "valid-review.md") }
      let(:invalid_extension) { File.join(temp_dir, "review.txt") }
      let(:directory) { File.join(temp_dir, "not-a-file") }

      before do
        File.write(valid_review, "## Executive Summary\nValid review")
        File.write(invalid_extension, "## Executive Summary\nInvalid extension")
        Dir.mkdir(directory)
      end

      it "handles mixed file types with only valid review files being processed" do
        result = collector.collect_reports([valid_review, invalid_extension])

        expect(result).to be_invalid
        expect(result.error).to include("At least 2 review reports are required")
      end

      it "returns error when directory path included in file list" do
        # Test with a directory that matches glob pattern (e.g., ends with .md in filename)
        directory_with_md = File.join(temp_dir, "fake-report.md")
        Dir.mkdir(directory_with_md)

        result = collector.collect_reports([directory_with_md])

        expect(result).to be_invalid
        expect(result.error).to include("Path is not a file")
      end

      it "handles mixed valid and invalid paths gracefully" do
        non_existent = File.join(temp_dir, "missing.md")
        result = collector.collect_reports([valid_review, non_existent])

        expect(result).to be_invalid
        expect(result.error).to include("File not found")
      end
    end

    context "with duplicate handling" do
      let(:review_file) { File.join(temp_dir, "review-report.md") }

      before do
        File.write(review_file, "## Executive Summary\nReview content")
      end

      it "removes duplicates when same file specified multiple times" do
        result = collector.collect_reports([review_file, review_file, review_file])

        expect(result).to be_invalid # Should fail because only 1 unique file (need 2 minimum)
        expect(result.error).to include("At least 2 review reports are required")
      end
    end
  end

  describe "CollectionResult" do
    describe "#valid?" do
      it "returns true when no error and reports present" do
        result = described_class::CollectionResult.new(reports: ["report1.md"])
        expect(result).to be_valid
      end

      it "returns false when error present" do
        result = described_class::CollectionResult.new(error: "Some error")
        expect(result).to be_invalid
      end

      it "returns false when no reports present" do
        result = described_class::CollectionResult.new(reports: [])
        expect(result).to be_invalid
      end
    end
  end
end
