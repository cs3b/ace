# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "date"

RSpec.describe CodingAgentTools::Molecules::Reflection::TimestampInferrer do
  let(:inferrer) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#infer_timestamp_range" do
    context "when no reflection files provided" do
      it "returns failure with empty array" do
        result = inferrer.infer_timestamp_range([])

        expect(result).to be_failure
        expect(result.error).to include("No dates found in reflection files")
      end
    end

    context "when files contain valid dates" do
      let(:file1) { File.join(temp_dir, "20250101-120000-reflection.md") }
      let(:file2) { File.join(temp_dir, "20250115-143000-reflection.md") }
      let(:file3) { File.join(temp_dir, "20250110-reflection.md") }

      before do
        File.write(file1, <<~CONTENT)
          # Daily Reflection
          **Date**: 2025-01-01
          ## What Went Well
          Good progress today
        CONTENT

        File.write(file2, <<~CONTENT)
          # Project Reflection
          **Date**: 2025-01-15
          ## What Could Be Improved
          Better time management
        CONTENT

        File.write(file3, <<~CONTENT)
          # Sprint Reflection
          Date: 2025-01-10
          ## Key Learnings
          Important insights gained
        CONTENT
      end

      it "returns success with correct date range" do
        result = inferrer.infer_timestamp_range([file1, file2, file3])

        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 1, 1))
        expect(result.data[:to_date]).to eq(Date.new(2025, 1, 15))
        expect(result.data[:days_covered]).to eq(15) # Jan 1 to Jan 15 inclusive
        expect(result.data[:total_dates]).to be >= 3
      end

      it "handles files with multiple dates correctly" do
        File.write(file1, <<~CONTENT)
          # Reflection with multiple dates
          **Date**: 2025-01-01
          ## What Went Well
          Good progress on 2025-01-02
          ## Key Learnings
          Date: 2025-01-03
        CONTENT

        result = inferrer.infer_timestamp_range([file1])

        expect(result).to be_success
        expect(result.data[:total_dates]).to be >= 3
      end
    end

    context "when files have dates only in filenames" do
      let(:file1) { File.join(temp_dir, "2025-01-05-team-reflection.md") }
      let(:file2) { File.join(temp_dir, "reflection-20250110.md") }

      before do
        File.write(file1, <<~CONTENT)
          # Team Reflection
          ## What Went Well
          Great collaboration
        CONTENT

        File.write(file2, <<~CONTENT)
          # Sprint Reflection
          ## What Could Be Improved
          Better planning
        CONTENT
      end

      it "extracts dates from filenames successfully" do
        result = inferrer.infer_timestamp_range([file1, file2])

        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 1, 5))
        expect(result.data[:to_date]).to eq(Date.new(2025, 1, 10))
        expect(result.data[:days_covered]).to eq(6)
      end
    end

    context "when files have mixed date formats" do
      let(:file1) { File.join(temp_dir, "20250101-reflection.md") }
      let(:file2) { File.join(temp_dir, "general-reflection.md") }

      before do
        File.write(file1, <<~CONTENT)
          # Reflection
          ## What Went Well
          Good progress
        CONTENT

        File.write(file2, <<~CONTENT)
          # General Reflection
          **Date**: 2025-01-20
          # Another date reference: 2025-01-25
          ## What Could Be Improved
          Better communication
        CONTENT
      end

      it "handles mixed date sources correctly" do
        result = inferrer.infer_timestamp_range([file1, file2])

        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 1, 1))
        expect(result.data[:to_date]).to eq(Date.new(2025, 1, 25))
        expect(result.data[:days_covered]).to eq(25)
      end
    end

    context "when files contain no recognizable dates" do
      let(:file1) { File.join(temp_dir, "reflection-general.md") }
      let(:file2) { File.join(temp_dir, "notes.md") }

      before do
        File.write(file1, <<~CONTENT)
          # General Reflection
          ## What Went Well
          Good things happened
        CONTENT

        File.write(file2, <<~CONTENT)
          # Project Notes
          ## What Could Be Improved
          Various improvements needed
        CONTENT
      end

      it "returns failure when no dates found" do
        result = inferrer.infer_timestamp_range([file1, file2])

        expect(result).to be_failure
        expect(result.error).to include("No dates found in reflection files")
      end
    end

    context "when files are unreadable" do
      let(:readable_file) { File.join(temp_dir, "20250101-readable.md") }
      let(:unreadable_file) { File.join(temp_dir, "20250102-unreadable.md") }

      before do
        File.write(readable_file, "# Reflection\n**Date**: 2025-01-01")
        File.write(unreadable_file, "# Reflection\n**Date**: 2025-01-02")
        File.chmod(0o000, unreadable_file)
      end

      after do
        File.chmod(0o644, unreadable_file) # Restore for cleanup
      end

      it "uses filename dates when content is unreadable" do
        result = inferrer.infer_timestamp_range([readable_file, unreadable_file])

        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 1, 1))
        expect(result.data[:to_date]).to eq(Date.new(2025, 1, 2))
      end
    end

    context "when single file provided" do
      let(:single_file) { File.join(temp_dir, "20250301-single.md") }

      before do
        File.write(single_file, <<~CONTENT)
          # Single Reflection
          **Date**: 2025-03-01
          ## What Went Well
          Solo reflection
        CONTENT
      end

      it "handles single file correctly" do
        result = inferrer.infer_timestamp_range([single_file])

        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 3, 1))
        expect(result.data[:to_date]).to eq(Date.new(2025, 3, 1))
        expect(result.data[:days_covered]).to eq(1)
      end
    end
  end

  describe "date extraction patterns" do
    let(:test_file) { File.join(temp_dir, "test-file.md") }

    describe "filename pattern recognition" do
      it "recognizes YYYY-MM-DD format" do
        filename_file = File.join(temp_dir, "2025-01-15-reflection.md")
        File.write(filename_file, "# Test")

        result = inferrer.infer_timestamp_range([filename_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 1, 15))
      end

      it "recognizes YYYYMMDD format" do
        filename_file = File.join(temp_dir, "20250115-reflection.md")
        File.write(filename_file, "# Test")

        result = inferrer.infer_timestamp_range([filename_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 1, 15))
      end

      it "recognizes YYYYMMDD without separators" do
        filename_file = File.join(temp_dir, "reflection-20250115.md")
        File.write(filename_file, "# Test")

        result = inferrer.infer_timestamp_range([filename_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 1, 15))
      end
    end

    describe "content pattern recognition" do
      it "recognizes **Date**: pattern" do
        File.write(test_file, <<~CONTENT)
          # Test Reflection
          **Date**: 2025-02-10
          ## Content
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 2, 10))
      end

      it "recognizes Date: pattern" do
        File.write(test_file, <<~CONTENT)
          # Test Reflection
          Date: 2025-02-11
          ## Content
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 2, 11))
      end

      it "recognizes header with dates" do
        File.write(test_file, <<~CONTENT)
          # Daily Reflection 2025-02-12
          ## Content
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 2, 12))
      end

      it "recognizes case variations" do
        File.write(test_file, <<~CONTENT)
          # Test Reflection
          **date**: 2025-02-13
          ## Content
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 2, 13))
      end
    end
  end

  describe "edge cases and validation" do
    let(:test_file) { File.join(temp_dir, "edge-case.md") }

    describe "date validation" do
      it "rejects invalid dates" do
        File.write(test_file, <<~CONTENT)
          # Test
          **Date**: 2025-13-40  # Invalid month and day
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_failure
      end

      it "rejects dates outside reasonable range" do
        File.write(test_file, <<~CONTENT)
          # Test  
          **Date**: 1999-01-01  # Too old
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_failure
      end

      it "rejects dates too far in future" do
        File.write(test_file, <<~CONTENT)
          # Test
          **Date**: 2031-01-01  # Too far in future
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_failure
      end

      it "accepts edge case valid dates" do
        File.write(test_file, <<~CONTENT)
          # Test
          **Date**: 2000-01-01  # Minimum year
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2000, 1, 1))
      end

      it "accepts leap year dates" do
        File.write(test_file, <<~CONTENT)
          # Test
          **Date**: 2024-02-29  # Leap year
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2024, 2, 29))
      end
    end

    describe "duplicate date handling" do
      it "handles duplicate dates correctly" do
        File.write(test_file, <<~CONTENT)
          # Test Reflection  
          **Date**: 2025-03-15
          ## Content
          Date: 2025-03-15  # Same date repeated
          More content on 2025-03-15
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:total_dates]).to eq(1) # Should deduplicate
      end
    end

    describe "malformed content handling" do
      it "handles empty files gracefully" do
        File.write(test_file, "")

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_failure
      end

      it "handles files with only whitespace" do
        File.write(test_file, "   \n\n  \t  \n")

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_failure
      end

      it "handles binary files gracefully" do
        # Write some binary content
        File.binwrite(test_file, "\x00\x01\x02\x03")

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_failure
      end
    end

    describe "unicode and encoding" do
      it "handles unicode content correctly" do
        File.write(test_file, <<~CONTENT, encoding: "utf-8")
          # Reflection with émojis 📝
          **Date**: 2025-04-01
          ## What Went Well ✅
          Unicode content with àccents
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 4, 1))
      end
    end

    describe "multiple patterns in single line" do
      it "extracts first date when multiple dates in single line" do
        File.write(test_file, <<~CONTENT)
          # Test
          **Date**: 2025-05-01 and reference to 2025-05-15
          ## Content
          Some content
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 5, 1))
        expect(result.data[:to_date]).to eq(Date.new(2025, 5, 1))
        expect(result.data[:total_dates]).to eq(1)
      end

      it "extracts dates from different lines" do
        File.write(test_file, <<~CONTENT)
          # Test
          **Date**: 2025-05-01
          ## Content
          Reference to date: 2025-05-15
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 5, 1))
        expect(result.data[:to_date]).to eq(Date.new(2025, 5, 15))
        expect(result.data[:total_dates]).to eq(2)
      end
    end

    describe "partial date matches" do
      it "ignores incomplete date patterns" do
        File.write(test_file, <<~CONTENT)
          # Test
          Year 2025 and month 01 but no complete date
          ## Content  
          **Date**: 2025-06-01  # This should be found
        CONTENT

        result = inferrer.infer_timestamp_range([test_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 6, 1))
        expect(result.data[:total_dates]).to eq(1)
      end
    end
  end

  describe "file system edge cases" do
    context "when non-existent files provided" do
      it "handles missing files gracefully" do
        missing_file = File.join(temp_dir, "missing.md")

        # Should not raise an error, but use empty content
        result = inferrer.infer_timestamp_range([missing_file])
        expect(result).to be_failure
      end
    end

    context "when symlinks provided" do
      let(:target_file) { File.join(temp_dir, "target.md") }
      let(:symlink_file) { File.join(temp_dir, "symlink.md") }

      before do
        File.write(target_file, "# Test\n**Date**: 2025-07-01")
        if File.respond_to?(:symlink)
          begin
            File.symlink(target_file, symlink_file)
          rescue NotImplementedError
            skip "Symlinks not supported"
          end
        else
          skip "Symlinks not available"
        end
      end

      it "follows symlinks correctly" do
        result = inferrer.infer_timestamp_range([symlink_file])
        expect(result).to be_success
        expect(result.data[:from_date]).to eq(Date.new(2025, 7, 1))
      end
    end
  end

  describe "performance considerations" do
    it "handles large number of files efficiently" do
      # Create many small files
      files = []
      50.times do |i|
        file_path = File.join(temp_dir, "reflection-#{i + 1}.md")
        File.write(file_path, "# Reflection #{i + 1}\n**Date**: 2025-01-#{(i % 28) + 1}")
        files << file_path
      end

      start_time = Time.now
      result = inferrer.infer_timestamp_range(files)
      end_time = Time.now

      expect(result).to be_success
      expect(end_time - start_time).to be < 5.0 # Should complete within 5 seconds
    end

    it "handles files with large content efficiently" do
      large_content = "# Large Reflection\n**Date**: 2025-08-01\n" + ("Content line\n" * 10_000)
      large_file = File.join(temp_dir, "large.md")
      File.write(large_file, large_content)

      start_time = Time.now
      result = inferrer.infer_timestamp_range([large_file])
      end_time = Time.now

      expect(result).to be_success
      expect(end_time - start_time).to be < 2.0 # Should complete within 2 seconds
    end
  end
end
