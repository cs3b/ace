# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/atoms/taskflow_management/file_system_scanner"

RSpec.describe CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner do
  let(:test_dir) { Dir.mktmpdir("file_system_scanner_test") }

  before do
    # Create test directory structure
    FileUtils.mkdir_p(File.join(test_dir, "subdir1"))
    FileUtils.mkdir_p(File.join(test_dir, "subdir2", "nested"))

    # Create test files
    File.write(File.join(test_dir, "file1.txt"), "content1")
    File.write(File.join(test_dir, "file2.rb"), "content2")
    File.write(File.join(test_dir, "README.md"), "readme content")
    File.write(File.join(test_dir, "subdir1", "nested_file.txt"), "nested content")
    File.write(File.join(test_dir, "subdir2", "another.rb"), "ruby content")
    File.write(File.join(test_dir, "subdir2", "nested", "deep_file.py"), "python content")
  end

  after do
    FileUtils.rm_rf(test_dir)
  end

  describe ".scan_directory" do
    context "with basic parameters" do
      it "scans directory with default patterns" do
        result = described_class.scan_directory(test_dir)

        expect(result).to be_an(Array)
        expect(result.length).to be >= 3
        expect(result).to include("file1.txt", "file2.rb", "README.md")
      end

      it "returns relative paths" do
        result = described_class.scan_directory(test_dir)

        result.each do |path|
          expect(path).not_to start_with("/")
          expect(path).not_to include(test_dir)
        end
      end
    end

    context "with custom patterns" do
      it "filters files by patterns" do
        result = described_class.scan_directory(test_dir, patterns: ["*.rb"])

        expect(result).to include("file2.rb")
        expect(result).not_to include("file1.txt", "README.md")
      end

      it "supports multiple patterns" do
        result = described_class.scan_directory(test_dir, patterns: ["*.rb", "*.md"])

        expect(result).to include("file2.rb", "README.md")
        expect(result).not_to include("file1.txt")
      end
    end

    context "with recursive scanning" do
      it "finds files in subdirectories when recursive is true" do
        result = described_class.scan_directory(test_dir, recursive: true)

        expect(result).to include("subdir1/nested_file.txt")
        expect(result).to include("subdir2/another.rb")
        expect(result).to include("subdir2/nested/deep_file.py")
      end

      it "respects max_depth parameter" do
        result = described_class.scan_directory(test_dir, recursive: true, max_depth: 1)

        expect(result).to include("subdir1/nested_file.txt")
        expect(result).to include("subdir2/another.rb")
        expect(result).not_to include("subdir2/nested/deep_file.py")
      end

      it "does not scan subdirectories when recursive is false" do
        result = described_class.scan_directory(test_dir, recursive: false)

        expect(result).not_to include("subdir1/nested_file.txt")
        expect(result).not_to include("subdir2/another.rb")
      end
    end

    context "with limits" do
      it "respects max_files limit" do
        result = described_class.scan_directory(test_dir, recursive: true, max_files: 2)

        expect(result.length).to eq(2)
      end
    end

    context "with invalid parameters" do
      it "raises ArgumentError for nil base_path" do
        expect { described_class.scan_directory(nil) }.to raise_error(ArgumentError, /base_path cannot be nil/)
      end

      it "raises ArgumentError for empty base_path" do
        expect { described_class.scan_directory("") }.to raise_error(ArgumentError, /base_path cannot be nil/)
      end

      it "raises ArgumentError for non-array patterns" do
        expect { described_class.scan_directory(test_dir, patterns: "*.rb") }.to raise_error(ArgumentError, /patterns must be an array/)
      end

      it "raises ArgumentError for non-positive max_depth" do
        expect { described_class.scan_directory(test_dir, max_depth: 0) }.to raise_error(ArgumentError, /max_depth must be positive/)
      end

      it "raises ArgumentError for non-positive max_files" do
        expect { described_class.scan_directory(test_dir, max_files: -1) }.to raise_error(ArgumentError, /max_files must be positive/)
      end

      it "raises ArgumentError for non-existent directory" do
        expect { described_class.scan_directory("/nonexistent/path") }.to raise_error(ArgumentError, /Directory does not exist/)
      end
    end

    context "with security concerns" do
      it "raises SecurityError for unsafe paths" do
        expect { described_class.scan_directory("../../../etc") }.to raise_error(SecurityError, /Path failed safety validation/)
      end

      it "raises SecurityError for paths with null bytes" do
        expect { described_class.scan_directory("path\0with\0nulls") }.to raise_error(SecurityError, /Path failed safety validation/)
      end

      it "raises SecurityError for overly long paths" do
        long_path = "a" * 5000
        expect { described_class.scan_directory(long_path) }.to raise_error(SecurityError, /Path too long/)
      end
    end

    context "with access errors" do
      let(:unreadable_dir) { File.join(test_dir, "unreadable") }

      before do
        FileUtils.mkdir_p(unreadable_dir)
        FileUtils.chmod(0o000, unreadable_dir)
      end

      after do
        FileUtils.chmod(0o755, unreadable_dir)
      end

      it "handles directory access errors gracefully" do
        # This test may not work on all systems due to permissions handling
        # Skip on systems where chmod doesn't prevent access

        described_class.scan_directory(unreadable_dir, recursive: true)
        skip "Directory permissions not enforced on this system"
      rescue SecurityError => e
        expect(e.message).to match(/Directory access error/)
      end
    end
  end

  describe ".find_files_by_name" do
    it "finds files by exact name" do
      result = described_class.find_files_by_name(test_dir, "file1.txt")

      expect(result).to include("file1.txt")
      expect(result).not_to include("file2.rb")
    end

    it "finds files recursively by default" do
      result = described_class.find_files_by_name(test_dir, "nested_file.txt")

      expect(result).to include("subdir1/nested_file.txt")
    end

    it "respects recursive parameter" do
      result = described_class.find_files_by_name(test_dir, "nested_file.txt", recursive: false)

      expect(result).to be_empty
    end

    it "raises ArgumentError for nil filename" do
      expect { described_class.find_files_by_name(test_dir, nil) }.to raise_error(ArgumentError, /filename cannot be nil/)
    end

    it "raises ArgumentError for empty filename" do
      expect { described_class.find_files_by_name(test_dir, "") }.to raise_error(ArgumentError, /filename cannot be nil/)
    end
  end

  describe ".find_files_by_extension" do
    it "finds files by extension" do
      result = described_class.find_files_by_extension(test_dir, ".rb")

      expect(result).to include("subdir2/another.rb")
    end

    it "finds files by extension without dot" do
      result = described_class.find_files_by_extension(test_dir, "rb")

      expect(result).to include("subdir2/another.rb")
    end

    it "finds files recursively by default" do
      result = described_class.find_files_by_extension(test_dir, ".py")

      expect(result).to include("subdir2/nested/deep_file.py")
    end

    it "respects recursive parameter" do
      result = described_class.find_files_by_extension(test_dir, ".py", recursive: false)

      expect(result).to be_empty
    end

    it "raises ArgumentError for nil extension" do
      expect { described_class.find_files_by_extension(test_dir, nil) }.to raise_error(ArgumentError, /extension cannot be nil/)
    end

    it "raises ArgumentError for empty extension" do
      expect { described_class.find_files_by_extension(test_dir, "") }.to raise_error(ArgumentError, /extension cannot be nil/)
    end
  end

  describe ".safe_path?" do
    it "returns true for safe paths" do
      expect(described_class.safe_path?("/safe/path")).to be true
      expect(described_class.safe_path?("relative/path")).to be true
      expect(described_class.safe_path?("simple")).to be true
    end

    it "returns false for unsafe paths" do
      expect(described_class.safe_path?(nil)).to be false
      expect(described_class.safe_path?("")).to be false
      expect(described_class.safe_path?("path\0with\0nulls")).to be false
      expect(described_class.safe_path?("path/with/../traversal")).to be false
      expect(described_class.safe_path?("path\\with\\..\\traversal")).to be false
    end

    it "returns false for paths with control characters" do
      expect(described_class.safe_path?("path\x01with\x02control")).to be false
      expect(described_class.safe_path?("path\x7fwith\x1fcontrol")).to be false
    end
  end

  describe ".find_files_with_pattern" do
    context "with glob patterns" do
      it "finds files using glob patterns" do
        result = described_class.find_files_with_pattern(test_dir, "*.rb")

        expect(result[:success]).to be true
        expect(result[:files]).to include("file2.rb")
        expect(result[:error]).to be_nil
      end

      it "handles recursive glob patterns" do
        result = described_class.find_files_with_pattern(test_dir, "**/*.py")

        expect(result[:success]).to be true
        expect(result[:files]).to include("subdir2/nested/deep_file.py")
      end
    end

    context "with directory patterns" do
      it "finds all files in a directory path" do
        result = described_class.find_files_with_pattern(test_dir, "subdir1")

        expect(result[:success]).to be true
        expect(result[:files]).to include("subdir1/nested_file.txt")
      end

      it "handles non-existent directory paths" do
        result = described_class.find_files_with_pattern(test_dir, "nonexistent")

        expect(result[:success]).to be false
        expect(result[:error]).to include("Directory does not exist")
      end
    end

    context "with invalid parameters" do
      it "handles nil base_path" do
        result = described_class.find_files_with_pattern(nil, "*.rb")
        expect(result[:success]).to be false
        expect(result[:error]).to include("Unexpected error")
      end

      it "handles empty pattern" do
        result = described_class.find_files_with_pattern(test_dir, "")
        expect(result[:success]).to be false
        expect(result[:error]).to include("Unexpected error")
      end

      it "handles unsafe base_path" do
        result = described_class.find_files_with_pattern("../../../etc", "*.conf")

        expect(result[:success]).to be false
        expect(result[:error]).to include("Path failed safety validation")
      end

      it "handles non-existent base directory" do
        result = described_class.find_files_with_pattern("/nonexistent", "*.rb")

        expect(result[:success]).to be false
        expect(result[:error]).to include("Base directory does not exist")
      end
    end

    context "with file limits" do
      it "respects max_files limit" do
        result = described_class.find_files_with_pattern(test_dir, "*", max_files: 2)

        expect(result[:success]).to be true
        expect(result[:files].length).to be <= 2
      end
    end
  end

  describe ".directory_stats" do
    it "returns comprehensive directory statistics" do
      stats = described_class.directory_stats(test_dir)

      expect(stats[:total_files]).to be >= 6
      expect(stats[:total_directories]).to be >= 3
      expect(stats[:total_size]).to be > 0
      expect(stats[:max_depth_reached]).to be >= 2
      expect(stats[:file_types]).to be_a(Hash)
      expect(stats[:file_types][".txt"]).to be > 0
      expect(stats[:file_types][".rb"]).to be > 0
    end

    it "respects max_depth parameter" do
      stats = described_class.directory_stats(test_dir, max_depth: 1)

      expect(stats[:max_depth_reached]).to be <= 1
    end

    it "handles empty directories" do
      empty_dir = File.join(test_dir, "empty")
      FileUtils.mkdir_p(empty_dir)

      stats = described_class.directory_stats(empty_dir)

      expect(stats[:total_files]).to eq(0)
      expect(stats[:total_directories]).to eq(0)
    end

    it "tracks file extensions correctly" do
      stats = described_class.directory_stats(test_dir)

      expect(stats[:file_types][".txt"]).to be >= 2
      expect(stats[:file_types][".rb"]).to be >= 2
      expect(stats[:file_types][".md"]).to be >= 1
      expect(stats[:file_types][".py"]).to be >= 1
    end

    it "handles files without extensions" do
      no_ext_file = File.join(test_dir, "no_extension")
      File.write(no_ext_file, "content")

      stats = described_class.directory_stats(test_dir)

      expect(stats[:file_types]["[no extension]"]).to be >= 1
    end

    it "raises ArgumentError for invalid parameters" do
      expect { described_class.directory_stats(nil) }.to raise_error(ArgumentError, /base_path cannot be nil/)
      expect { described_class.directory_stats("") }.to raise_error(ArgumentError, /base_path cannot be nil/)
      expect { described_class.directory_stats("/nonexistent") }.to raise_error(ArgumentError, /Directory does not exist/)
    end

    it "handles security validation" do
      expect { described_class.directory_stats("../../../etc") }.to raise_error(SecurityError, /Path failed safety validation/)
    end
  end

  describe "private methods" do
    describe ".make_relative_path" do
      it "converts absolute paths to relative paths" do
        abs_path = File.join(test_dir, "subdir1", "file.txt")
        relative = described_class.send(:make_relative_path, abs_path, test_dir)

        expect(relative).to eq("subdir1/file.txt")
      end
    end

    describe ".filter_by_depth" do
      let(:files) {
        [
          File.join(test_dir, "file1.txt"),
          File.join(test_dir, "subdir1", "file2.txt"),
          File.join(test_dir, "subdir2", "nested", "file3.txt")
        ]
      }

      it "filters files by depth when recursive is true" do
        filtered = described_class.send(:filter_by_depth, files, test_dir, true, 1)

        expect(filtered).to include(File.join(test_dir, "file1.txt"))
        expect(filtered).to include(File.join(test_dir, "subdir1", "file2.txt"))
        expect(filtered).not_to include(File.join(test_dir, "subdir2", "nested", "file3.txt"))
      end

      it "returns empty array when recursive is false" do
        filtered = described_class.send(:filter_by_depth, files, test_dir, false, 1)

        expect(filtered).to be_empty
      end
    end
  end
end
