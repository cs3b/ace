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
