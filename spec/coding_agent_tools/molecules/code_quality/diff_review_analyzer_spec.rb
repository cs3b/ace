# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "tempfile"

RSpec.describe CodingAgentTools::Molecules::CodeQuality::DiffReviewAnalyzer do
  let(:analyzer) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir("diff_review_analyzer_test") }

  before do
    # Mock system commands to focus on unit testing
    allow(analyzer).to receive(:system).and_return(true)
    allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#analyze_changes" do
    context "with before and after snapshots" do
      let(:before_snapshot) do
        {
          timestamp: Time.now - 3600,
          files: {
            "file1.rb" => {content: "class Test\nend", mtime: Time.now - 3600, size: 15},
            "file2.rb" => {content: "def hello\n  puts 'world'\nend", mtime: Time.now - 3600, size: 25}
          }
        }
      end

      let(:after_snapshot) do
        {
          timestamp: Time.now,
          files: {
            "file1.rb" => {content: "class Test\n  attr_accessor :name\nend", mtime: Time.now, size: 35},
            "file3.rb" => {content: "module New\nend", mtime: Time.now, size: 15}
          }
        }
      end

      it "analyzes snapshot differences" do
        expect(analyzer).to receive(:analyze_snapshots).with(before_snapshot, after_snapshot)
        analyzer.analyze_changes(before_snapshot: before_snapshot, after_snapshot: after_snapshot)
      end
    end

    context "without snapshots" do
      it "analyzes git changes" do
        expect(analyzer).to receive(:analyze_git_changes)
        analyzer.analyze_changes
      end
    end

    context "with only one snapshot" do
      let(:snapshot) { {timestamp: Time.now, files: {}} }

      it "analyzes git changes when only before_snapshot provided" do
        expect(analyzer).to receive(:analyze_git_changes)
        analyzer.analyze_changes(before_snapshot: snapshot)
      end

      it "analyzes git changes when only after_snapshot provided" do
        expect(analyzer).to receive(:analyze_git_changes)
        analyzer.analyze_changes(after_snapshot: snapshot)
      end
    end
  end

  describe "#create_snapshot" do
    let(:mock_files) { ["file1.rb", "file2.md"] }
    let(:file1_content) { "class Test\nend" }
    let(:file2_content) { "# Documentation" }

    before do
      allow(analyzer).to receive(:relevant_files).and_return(mock_files)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with("file1.rb").and_return(file1_content)
      allow(File).to receive(:read).with("file2.md").and_return(file2_content)
      allow(File).to receive(:mtime).and_return(Time.now)
      allow(File).to receive(:size).and_return(15)
    end

    it "creates a snapshot with timestamp" do
      snapshot = analyzer.create_snapshot
      expect(snapshot[:timestamp]).to be_a(Time)
    end

    it "includes all relevant files in snapshot" do
      snapshot = analyzer.create_snapshot
      expect(snapshot[:files]).to have_key("file1.rb")
      expect(snapshot[:files]).to have_key("file2.md")
    end

    it "captures file content, mtime, and size" do
      snapshot = analyzer.create_snapshot
      file_data = snapshot[:files]["file1.rb"]
      expect(file_data[:content]).to eq(file1_content)
      expect(file_data[:mtime]).to be_a(Time)
      expect(file_data[:size]).to eq(15)
    end

    context "when files don't exist" do
      before do
        allow(File).to receive(:exist?).with("file1.rb").and_return(false)
        allow(File).to receive(:exist?).with("file2.md").and_return(true)
      end

      it "skips non-existent files" do
        snapshot = analyzer.create_snapshot
        expect(snapshot[:files]).not_to have_key("file1.rb")
        expect(snapshot[:files]).to have_key("file2.md")
      end
    end

    context "when file read fails" do
      before do
        allow(File).to receive(:read).with("file1.rb").and_raise(Errno::EACCES, "Permission denied")
      end

      it "raises the original error" do
        expect { analyzer.create_snapshot }.to raise_error(Errno::EACCES)
      end
    end
  end

  describe "#format_review" do
    let(:analysis) do
      {
        summary: {
          files_modified: 2,
          lines_added: 10,
          lines_removed: 5
        },
        changes: {
          "file1.rb" => {
            lines_added: 5,
            lines_removed: 2,
            diff: "@@ -1,2 +1,5 @@\n class Test\n+  attr_accessor :name\n end"
          },
          "file2.rb" => {
            lines_added: 5,
            lines_removed: 3,
            status: "modified"
          }
        }
      }
    end

    it "generates a formatted review with header" do
      review = analyzer.format_review(analysis)
      expect(review).to include("# Code Quality Changes Review")
      expect(review).to include("Generated at:")
    end

    it "includes summary information" do
      review = analyzer.format_review(analysis)
      expect(review).to include("Files modified: 2")
      expect(review).to include("Lines added: 10")
      expect(review).to include("Lines removed: 5")
    end

    it "includes file changes section" do
      review = analyzer.format_review(analysis)
      expect(review).to include("## File Changes")
      expect(review).to include("### file1.rb")
      expect(review).to include("### file2.rb")
    end

    it "formats each file's changes" do
      expect(analyzer).to receive(:format_file_changes).twice.and_return("formatted changes")
      analyzer.format_review(analysis)
    end

    context "with empty analysis" do
      let(:empty_analysis) { {} }

      it "generates review without summary or changes" do
        review = analyzer.format_review(empty_analysis)
        expect(review).to include("# Code Quality Changes Review")
        expect(review).not_to include("## Summary")
        expect(review).not_to include("## File Changes")
      end
    end

    context "with no changes" do
      let(:no_changes_analysis) { {summary: {files_modified: 0}, changes: {}} }

      it "includes summary but no file changes" do
        review = analyzer.format_review(no_changes_analysis)
        expect(review).to include("## Summary")
        expect(review).not_to include("## File Changes")
      end
    end
  end

  describe "private methods" do
    describe "#relevant_files" do
      before do
        allow(Dir).to receive(:glob).with("**/*.rb").and_return(["lib/test.rb", "spec/test_spec.rb", "vendor/gem.rb"])
        allow(Dir).to receive(:glob).with("**/*.md").and_return(["README.md", "vendor/docs.md"])
      end

      it "includes Ruby files excluding spec and vendor" do
        files = analyzer.send(:relevant_files)
        expect(files).to include("lib/test.rb")
        expect(files).not_to include("spec/test_spec.rb")
        expect(files).not_to include("vendor/gem.rb")
      end

      it "includes Markdown files excluding vendor" do
        files = analyzer.send(:relevant_files)
        expect(files).to include("README.md")
        expect(files).not_to include("vendor/docs.md")
      end
    end

    describe "#analyze_git_changes" do
      context "when not in a git repository" do
        before do
          allow(analyzer).to receive(:system).and_return(false)
        end

        it "returns error message" do
          result = analyzer.send(:analyze_git_changes)
          expect(result[:error]).to eq("Not in a git repository")
        end
      end

      context "when in a git repository" do
        let(:git_diff_output) { "5\t2\tfile1.rb\n3\t1\tfile2.rb\n" }

        before do
          allow(analyzer).to receive(:system).and_return(true)
          allow(Open3).to receive(:capture3).with("git diff --numstat").and_return([git_diff_output, "", double(success?: true)])
          allow(analyzer).to receive(:parse_git_diff).and_return({success: true})
        end

        it "parses git diff output" do
          expect(analyzer).to receive(:parse_git_diff).with(git_diff_output)
          analyzer.send(:analyze_git_changes)
        end
      end

      context "when git diff fails" do
        before do
          allow(analyzer).to receive(:system).and_return(true)
          allow(Open3).to receive(:capture3).and_return(["", "git error", double(success?: false)])
        end

        it "returns error with stderr message" do
          result = analyzer.send(:analyze_git_changes)
          expect(result[:error]).to include("Failed to get git diff: git error")
        end
      end
    end

    describe "#parse_git_diff" do
      let(:diff_output) do
        "5\t2\tfile1.rb\n3\t1\tfile2.rb\n0\t0\tfile3.rb\n"
      end

      before do
        allow(Open3).to receive(:capture3).and_return(["diff content", "", double(success?: true)])
      end

      it "parses numstat output correctly" do
        result = analyzer.send(:parse_git_diff, diff_output)
        expect(result[:summary][:files_modified]).to eq(3)
        expect(result[:summary][:lines_added]).to eq(8)
        expect(result[:summary][:lines_removed]).to eq(3)
      end

      it "includes individual file changes" do
        result = analyzer.send(:parse_git_diff, diff_output)
        expect(result[:changes]["file1.rb"][:lines_added]).to eq(5)
        expect(result[:changes]["file1.rb"][:lines_removed]).to eq(2)
        expect(result[:changes]["file2.rb"][:lines_added]).to eq(3)
        expect(result[:changes]["file2.rb"][:lines_removed]).to eq(1)
      end

      it "fetches diff content for each file" do
        expect(Open3).to receive(:capture3).with("git diff file1.rb")
        expect(Open3).to receive(:capture3).with("git diff file2.rb")
        expect(Open3).to receive(:capture3).with("git diff file3.rb")
        analyzer.send(:parse_git_diff, diff_output)
      end

      context "with malformed lines" do
        let(:malformed_output) { "invalid\tline\n5\t2\tfile.rb\n" }

        it "skips malformed lines" do
          result = analyzer.send(:parse_git_diff, malformed_output)
          expect(result[:summary][:files_modified]).to eq(1)
          expect(result[:changes]).to have_key("file.rb")
        end
      end

      context "with empty output" do
        it "returns empty analysis" do
          result = analyzer.send(:parse_git_diff, "")
          expect(result[:summary][:files_modified]).to eq(0)
          expect(result[:changes]).to be_empty
        end
      end
    end

    describe "#analyze_snapshots" do
      let(:before_snapshot) do
        {
          files: {
            "existing.rb" => {content: "old content"},
            "modified.rb" => {content: "original content"},
            "removed.rb" => {content: "removed content"}
          }
        }
      end

      let(:after_snapshot) do
        {
          files: {
            "existing.rb" => {content: "old content"},
            "modified.rb" => {content: "new content"},
            "added.rb" => {content: "new file content"}
          }
        }
      end

      before do
        allow(analyzer).to receive(:calculate_diff).and_return({lines_added: 1, lines_removed: 1})
      end

      it "detects modified files" do
        result = analyzer.send(:analyze_snapshots, before_snapshot, after_snapshot)
        expect(result[:summary][:files_modified]).to eq(1)
        expect(result[:changes]).to have_key("modified.rb")
      end

      it "detects added files" do
        result = analyzer.send(:analyze_snapshots, before_snapshot, after_snapshot)
        expect(result[:summary][:files_added]).to eq(1)
        expect(result[:changes]["added.rb"][:status]).to eq("added")
      end

      it "detects removed files" do
        result = analyzer.send(:analyze_snapshots, before_snapshot, after_snapshot)
        expect(result[:summary][:files_removed]).to eq(1)
        expect(result[:changes]["removed.rb"][:status]).to eq("removed")
      end

      it "ignores unchanged files" do
        result = analyzer.send(:analyze_snapshots, before_snapshot, after_snapshot)
        expect(result[:changes]).not_to have_key("existing.rb")
      end

      it "calculates line counts for modifications" do
        expect(analyzer).to receive(:calculate_diff).with("original content", "new content", "modified.rb")
        analyzer.send(:analyze_snapshots, before_snapshot, after_snapshot)
      end
    end

    describe "#calculate_diff" do
      let(:before_content) { "line1\nline2\n" }
      let(:after_content) { "line1\nmodified line2\nline3\n" }
      let(:filename) { "test.rb" }

      before do
        allow(Open3).to receive(:capture3).and_return(["diff output", "", double(success?: true)])
        allow(analyzer).to receive(:parse_unified_diff).and_return({lines_added: 2, lines_removed: 1, diff: "diff output"})
      end

      it "creates temporary files for diff calculation" do
        expect(Tempfile).to receive(:new).with(["before", ".rb"]).and_call_original
        expect(Tempfile).to receive(:new).with(["after", ".rb"]).and_call_original
        analyzer.send(:calculate_diff, before_content, after_content, filename)
      end

      it "writes content to temporary files" do
        before_file = instance_double(Tempfile)
        after_file = instance_double(Tempfile)
        
        allow(Tempfile).to receive(:new).with(["before", ".rb"]).and_return(before_file)
        allow(Tempfile).to receive(:new).with(["after", ".rb"]).and_return(after_file)
        
        expect(before_file).to receive(:write).with(before_content)
        expect(before_file).to receive(:flush)
        expect(before_file).to receive(:path).and_return("/tmp/before")
        expect(before_file).to receive(:close)
        expect(before_file).to receive(:unlink)
        
        expect(after_file).to receive(:write).with(after_content)
        expect(after_file).to receive(:flush)
        expect(after_file).to receive(:path).and_return("/tmp/after")
        expect(after_file).to receive(:close)
        expect(after_file).to receive(:unlink)

        analyzer.send(:calculate_diff, before_content, after_content, filename)
      end

      it "parses unified diff output" do
        expect(analyzer).to receive(:parse_unified_diff).with("diff output")
        analyzer.send(:calculate_diff, before_content, after_content, filename)
      end

      it "ensures temporary files are cleaned up" do
        before_file = instance_double(Tempfile)
        after_file = instance_double(Tempfile)
        
        allow(Tempfile).to receive(:new).and_return(before_file, after_file)
        allow(before_file).to receive(:write)
        allow(before_file).to receive(:flush)
        allow(before_file).to receive(:path).and_return("/tmp/before")
        allow(after_file).to receive(:write)
        allow(after_file).to receive(:flush)
        allow(after_file).to receive(:path).and_return("/tmp/after")

        expect(before_file).to receive(:close)
        expect(before_file).to receive(:unlink)
        expect(after_file).to receive(:close)
        expect(after_file).to receive(:unlink)

        analyzer.send(:calculate_diff, before_content, after_content, filename)
      end
    end

    describe "#parse_unified_diff" do
      let(:diff_output) do
        <<~DIFF
          --- before.rb
          +++ after.rb
          @@ -1,3 +1,4 @@
           line1
          -old line2
          +new line2
          +added line3
           line3
        DIFF
      end

      it "counts added lines correctly" do
        result = analyzer.send(:parse_unified_diff, diff_output)
        expect(result[:lines_added]).to eq(2)
      end

      it "counts removed lines correctly" do
        result = analyzer.send(:parse_unified_diff, diff_output)
        expect(result[:lines_removed]).to eq(1)
      end

      it "includes original diff output" do
        result = analyzer.send(:parse_unified_diff, diff_output)
        expect(result[:diff]).to eq(diff_output)
      end

      it "ignores header lines" do
        header_only = "--- before.rb\n+++ after.rb\n"
        result = analyzer.send(:parse_unified_diff, header_only)
        expect(result[:lines_added]).to eq(0)
        expect(result[:lines_removed]).to eq(0)
      end

      context "with empty diff" do
        it "returns zero counts" do
          result = analyzer.send(:parse_unified_diff, "")
          expect(result[:lines_added]).to eq(0)
          expect(result[:lines_removed]).to eq(0)
        end
      end
    end

    describe "#format_file_changes" do
      context "with status field" do
        let(:changes) { {status: "added", lines_added: 10, lines_removed: 0} }

        it "displays the specified status" do
          result = analyzer.send(:format_file_changes, changes)
          expect(result).to include("**Status:** added")
        end
      end

      context "without status field" do
        let(:changes) { {lines_added: 5, lines_removed: 2} }

        it "defaults to modified status" do
          result = analyzer.send(:format_file_changes, changes)
          expect(result).to include("**Status:** modified")
        end
      end

      it "includes line counts" do
        changes = {lines_added: 5, lines_removed: 2}
        result = analyzer.send(:format_file_changes, changes)
        expect(result).to include("**Lines added:** 5")
        expect(result).to include("**Lines removed:** 2")
      end

      context "with small diff" do
        let(:changes) { {lines_added: 1, lines_removed: 1, diff: "small diff content"} }

        it "includes diff content in code block" do
          result = analyzer.send(:format_file_changes, changes)
          expect(result).to include("```diff")
          expect(result).to include("small diff content")
          expect(result).to include("```")
        end
      end

      context "with large diff" do
        let(:large_diff) { "x" * 1001 }
        let(:changes) { {lines_added: 100, lines_removed: 50, diff: large_diff} }

        it "excludes large diff content" do
          result = analyzer.send(:format_file_changes, changes)
          expect(result).not_to include("```diff")
          expect(result).not_to include(large_diff)
        end
      end

      context "without diff" do
        let(:changes) { {lines_added: 5, lines_removed: 2} }

        it "does not include diff section" do
          result = analyzer.send(:format_file_changes, changes)
          expect(result).not_to include("```diff")
        end
      end
    end
  end

  # Edge cases and error conditions
  describe "edge cases" do
    describe "file system errors" do
      before do
        allow(analyzer).to receive(:relevant_files).and_return(["test.rb"])
        allow(File).to receive(:exist?).with("test.rb").and_return(true)
      end

      it "handles file read permission errors" do
        allow(File).to receive(:read).and_raise(Errno::EACCES, "Permission denied")
        expect { analyzer.create_snapshot }.to raise_error(Errno::EACCES)
      end

      it "handles file stat errors" do
        allow(File).to receive(:read).and_return("content")
        allow(File).to receive(:mtime).and_raise(Errno::ENOENT, "File not found")
        expect { analyzer.create_snapshot }.to raise_error(Errno::ENOENT)
      end
    end

    describe "git command failures" do
      before do
        allow(analyzer).to receive(:system).and_return(true)
      end

      it "handles git diff timeout" do
        allow(Open3).to receive(:capture3).and_raise(Timeout::Error)
        expect { analyzer.send(:analyze_git_changes) }.to raise_error(Timeout::Error)
      end

      it "handles git command not found" do
        allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
        expect { analyzer.send(:analyze_git_changes) }.to raise_error(Errno::ENOENT)
      end
    end

    describe "diff calculation edge cases" do
      it "handles binary files" do
        binary_before = "\x00\x01\x02"
        binary_after = "\x00\x01\x03"
        
        allow(Open3).to receive(:capture3).and_return(["Binary files differ", "", double(success?: true)])
        allow(analyzer).to receive(:parse_unified_diff).and_return({lines_added: 0, lines_removed: 0, diff: "Binary files differ"})
        
        result = analyzer.send(:calculate_diff, binary_before, binary_after, "binary.dat")
        expect(result[:diff]).to eq("Binary files differ")
      end

      it "handles empty file content" do
        result = analyzer.send(:calculate_diff, "", "", "empty.rb")
        expect(result).to have_key(:lines_added)
        expect(result).to have_key(:lines_removed)
      end
    end

    describe "snapshot comparison edge cases" do
      it "handles snapshots with no files" do
        empty_before = {files: {}}
        empty_after = {files: {}}
        
        result = analyzer.send(:analyze_snapshots, empty_before, empty_after)
        expect(result[:summary][:files_modified]).to eq(0)
        expect(result[:changes]).to be_empty
      end

      it "handles malformed snapshot structure" do
        malformed_before = {}
        malformed_after = {files: {"test.rb" => {content: "test"}}}
        
        expect { analyzer.send(:analyze_snapshots, malformed_before, malformed_after) }.to raise_error
      end
    end
  end

  # Integration scenarios
  describe "integration scenarios" do
    it "can perform end-to-end snapshot-based analysis" do
      # Mock file system for snapshot creation
      allow(analyzer).to receive(:relevant_files).and_return(["test.rb"])
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return("test content")
      allow(File).to receive(:mtime).and_return(Time.now)
      allow(File).to receive(:size).and_return(12)

      before_snapshot = analyzer.create_snapshot
      
      # Simulate file change
      allow(File).to receive(:read).and_return("modified test content")
      allow(File).to receive(:size).and_return(20)
      
      after_snapshot = analyzer.create_snapshot
      
      analysis = analyzer.analyze_changes(before_snapshot: before_snapshot, after_snapshot: after_snapshot)
      review = analyzer.format_review(analysis)
      
      expect(review).to include("# Code Quality Changes Review")
      expect(analysis).to have_key(:summary)
      expect(analysis).to have_key(:changes)
    end

    it "can perform end-to-end git-based analysis" do
      allow(analyzer).to receive(:system).and_return(true)
      allow(Open3).to receive(:capture3).with("git diff --numstat").and_return(["1\t1\ttest.rb", "", double(success?: true)])
      allow(Open3).to receive(:capture3).with("git diff test.rb").and_return(["diff content", "", double(success?: true)])

      analysis = analyzer.analyze_changes
      review = analyzer.format_review(analysis)
      
      expect(review).to include("# Code Quality Changes Review")
      expect(analysis).to have_key(:summary)
      expect(analysis).to have_key(:changes)
    end
  end
end