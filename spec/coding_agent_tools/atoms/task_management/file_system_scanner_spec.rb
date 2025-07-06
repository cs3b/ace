# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::TaskManagement::FileSystemScanner do
  let(:scanner) { described_class }

  describe ".scan_directory" do
    let(:test_dir) { Dir.mktmpdir("scanner_test") }

    before do
      # Create test directory structure
      FileUtils.mkdir_p(File.join(test_dir, "subdir1"))
      FileUtils.mkdir_p(File.join(test_dir, "subdir2", "nested"))

      # Create test files
      File.write(File.join(test_dir, "file1.txt"), "content1")
      File.write(File.join(test_dir, "file2.rb"), "content2")
      File.write(File.join(test_dir, "file3.md"), "content3")
      File.write(File.join(test_dir, "subdir1", "nested_file.txt"), "nested content")
      File.write(File.join(test_dir, "subdir2", "nested", "deep_file.rb"), "deep content")
    end

    after do
      FileUtils.rm_rf(test_dir)
    end

    context "with valid parameters" do
      it "scans directory with default pattern" do
        files = scanner.scan_directory(test_dir)

        expect(files).to be_an(Array)
        expect(files).to include("file1.txt", "file2.rb", "file3.md")
        expect(files).not_to include("subdir1", "subdir2")
      end

      it "scans directory with specific patterns" do
        files = scanner.scan_directory(test_dir, patterns: ["*.txt"])

        expect(files).to include("file1.txt")
        expect(files).not_to include("file2.rb", "file3.md")
      end

      it "scans directory with multiple patterns" do
        files = scanner.scan_directory(test_dir, patterns: ["*.txt", "*.rb"])

        expect(files).to include("file1.txt", "file2.rb")
        expect(files).not_to include("file3.md")
      end

      it "scans recursively when requested" do
        files = scanner.scan_directory(test_dir, recursive: true)

        expect(files).to include("file1.txt", "file2.rb", "file3.md")
        expect(files).to include("subdir1/nested_file.txt")
        expect(files).to include("subdir2/nested/deep_file.rb")
      end

      it "respects max_depth when scanning recursively" do
        files = scanner.scan_directory(test_dir, recursive: true, max_depth: 1)

        expect(files).to include("subdir1/nested_file.txt")
        expect(files).not_to include("subdir2/nested/deep_file.rb")
      end

      it "respects max_files limit" do
        files = scanner.scan_directory(test_dir, max_files: 2)

        expect(files.length).to eq(2)
      end

      it "returns relative paths" do
        files = scanner.scan_directory(test_dir, recursive: true)

        files.each do |file|
          expect(file).not_to start_with("/")
          expect(Pathname.new(file)).to be_relative
        end
      end
    end

    context "with invalid parameters" do
      it "raises ArgumentError for nil base_path" do
        expect { scanner.scan_directory(nil) }.to raise_error(ArgumentError, "base_path cannot be nil or empty")
      end

      it "raises ArgumentError for empty base_path" do
        expect { scanner.scan_directory("") }.to raise_error(ArgumentError, "base_path cannot be nil or empty")
      end

      it "raises ArgumentError for non-array patterns" do
        expect { scanner.scan_directory(test_dir, patterns: "*.txt") }.to raise_error(ArgumentError, "patterns must be an array")
      end

      it "raises ArgumentError for non-existent directory" do
        expect { scanner.scan_directory("/non/existent/path") }.to raise_error(ArgumentError, /Directory does not exist/)
      end

      it "raises ArgumentError for negative max_depth" do
        expect { scanner.scan_directory(test_dir, max_depth: -1) }.to raise_error(ArgumentError, "max_depth must be positive")
      end

      it "raises ArgumentError for negative max_files" do
        expect { scanner.scan_directory(test_dir, max_files: -1) }.to raise_error(ArgumentError, "max_files must be positive")
      end
    end

    context "with security concerns" do
      it "raises SecurityError for paths with null bytes" do
        expect { scanner.scan_directory("test\0path") }.to raise_error(SecurityError, /Path failed safety validation/)
      end

      it "raises SecurityError for paths with control characters" do
        expect { scanner.scan_directory("test\x01path") }.to raise_error(SecurityError, /Path failed safety validation/)
      end

      it "raises SecurityError for paths with traversal attempts" do
        expect { scanner.scan_directory("../../../etc") }.to raise_error(SecurityError, /Path failed safety validation/)
      end

      it "raises SecurityError for extremely long paths" do
        long_path = "a" * 5000
        expect { scanner.scan_directory(long_path) }.to raise_error(SecurityError, /Path too long/)
      end
    end
  end

  describe ".find_files_by_name" do
    let(:test_dir) { Dir.mktmpdir("scanner_test") }

    before do
      FileUtils.mkdir_p(File.join(test_dir, "subdir"))
      File.write(File.join(test_dir, "target.txt"), "content")
      File.write(File.join(test_dir, "other.txt"), "content")
      File.write(File.join(test_dir, "subdir", "target.txt"), "content")
    end

    after do
      FileUtils.rm_rf(test_dir)
    end

    it "finds files by exact name" do
      files = scanner.find_files_by_name(test_dir, "target.txt")

      expect(files).to include("target.txt", "subdir/target.txt")
      expect(files).not_to include("other.txt")
    end

    it "finds files non-recursively when requested" do
      files = scanner.find_files_by_name(test_dir, "target.txt", recursive: false)

      expect(files).to include("target.txt")
      expect(files).not_to include("subdir/target.txt")
    end

    it "raises ArgumentError for empty filename" do
      expect { scanner.find_files_by_name(test_dir, "") }.to raise_error(ArgumentError, "filename cannot be nil or empty")
    end
  end

  describe ".find_files_by_extension" do
    let(:test_dir) { Dir.mktmpdir("scanner_test") }

    before do
      FileUtils.mkdir_p(File.join(test_dir, "subdir"))
      File.write(File.join(test_dir, "file1.txt"), "content")
      File.write(File.join(test_dir, "file2.rb"), "content")
      File.write(File.join(test_dir, "subdir", "file3.txt"), "content")
    end

    after do
      FileUtils.rm_rf(test_dir)
    end

    it "finds files by extension with dot" do
      files = scanner.find_files_by_extension(test_dir, ".txt")

      expect(files).to include("file1.txt", "subdir/file3.txt")
      expect(files).not_to include("file2.rb")
    end

    it "finds files by extension without dot" do
      files = scanner.find_files_by_extension(test_dir, "txt")

      expect(files).to include("file1.txt", "subdir/file3.txt")
      expect(files).not_to include("file2.rb")
    end

    it "raises ArgumentError for empty extension" do
      expect { scanner.find_files_by_extension(test_dir, "") }.to raise_error(ArgumentError, "extension cannot be nil or empty")
    end
  end

  describe ".safe_path?" do
    it "returns true for safe paths" do
      expect(scanner.safe_path?("/tmp/test")).to be true
      expect(scanner.safe_path?("./test")).to be true
      expect(scanner.safe_path?("test/file.txt")).to be true
    end

    it "returns false for unsafe paths" do
      expect(scanner.safe_path?(nil)).to be false
      expect(scanner.safe_path?("")).to be false
      expect(scanner.safe_path?("test\0file")).to be false
      expect(scanner.safe_path?("test\x01file")).to be false
      expect(scanner.safe_path?("../../../etc")).to be false
      expect(scanner.safe_path?("test\\..\\file")).to be false
    end
  end

  describe ".directory_stats" do
    let(:test_dir) { Dir.mktmpdir("scanner_test") }

    before do
      FileUtils.mkdir_p(File.join(test_dir, "subdir1"))
      FileUtils.mkdir_p(File.join(test_dir, "subdir2", "nested"))

      File.write(File.join(test_dir, "file1.txt"), "content1")
      File.write(File.join(test_dir, "file2.rb"), "content2")
      File.write(File.join(test_dir, "subdir1", "nested.md"), "content3")
    end

    after do
      FileUtils.rm_rf(test_dir)
    end

    it "returns comprehensive directory statistics" do
      stats = scanner.directory_stats(test_dir)

      expect(stats).to be_a(Hash)
      expect(stats[:total_files]).to be > 0
      expect(stats[:total_directories]).to be > 0
      expect(stats[:total_size]).to be > 0
      expect(stats[:max_depth_reached]).to be >= 0
      expect(stats[:file_types]).to be_a(Hash)

      expect(stats[:file_types]).to have_key(".txt")
      expect(stats[:file_types]).to have_key(".rb")
      expect(stats[:file_types]).to have_key(".md")
    end

    it "respects max_depth parameter" do
      stats = scanner.directory_stats(test_dir, max_depth: 1)

      expect(stats[:max_depth_reached]).to be <= 1
    end

    it "raises ArgumentError for non-existent directory" do
      expect { scanner.directory_stats("/non/existent") }.to raise_error(ArgumentError, /Directory does not exist/)
    end
  end
end
