# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator do
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Suppress warnings during tests
    described_class.suppress_warnings = true
  end

  after do
    described_class.suppress_warnings = false
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "constants" do
    it "defines expected default paths" do
      expect(described_class::DEFAULT_BASE_PATH).to eq("dev-taskflow")
      expect(described_class::DEFAULT_CURRENT_PATH).to eq("dev-taskflow/current")
      expect(described_class::DEFAULT_BACKLOG_PATH).to eq("dev-taskflow/backlog")
      expect(described_class::DEFAULT_TASKS_SUBDIR).to eq("tasks")
    end

    it "defines release directory pattern" do
      expect(described_class::RELEASE_DIR_PATTERN).to eq(/^v\.\d+\.\d+\.\d+/)
      expect(described_class::VERSION_EXTRACTION_REGEX).to eq(/^(v\.\d+\.\d+\.\d+)/)
    end
  end

  describe ".find_release_directory" do
    let(:current_path) { File.join(temp_dir, "dev-taskflow", "current") }
    let(:backlog_path) { File.join(temp_dir, "dev-taskflow", "backlog") }

    before do
      FileUtils.mkdir_p(current_path)
      FileUtils.mkdir_p(backlog_path)
    end

    context "with valid version and existing directories" do
      before do
        FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-migration"))
        FileUtils.mkdir_p(File.join(backlog_path, "v.0.4.0-features"))
      end

      it "finds release directory in current path" do
        result = described_class.find_release_directory("v.0.3.0", base_path: temp_dir)

        expect(result).not_to be_nil
        expect(result[:version]).to eq("v.0.3.0")
        expect(result[:path]).to eq(File.join(current_path, "v.0.3.0-migration"))
      end

      it "finds release directory in backlog path when not in current" do
        result = described_class.find_release_directory("v.0.4.0", base_path: temp_dir)

        expect(result).not_to be_nil
        expect(result[:version]).to eq("v.0.4.0")
        expect(result[:path]).to eq(File.join(backlog_path, "v.0.4.0-features"))
      end

      it "prefers current path over backlog path" do
        # Create same version in both paths
        FileUtils.mkdir_p(File.join(backlog_path, "v.0.3.0-other"))

        result = described_class.find_release_directory("v.0.3.0", base_path: temp_dir)

        expect(result[:path]).to eq(File.join(current_path, "v.0.3.0-migration"))
      end
    end

    context "with custom search paths" do
      let(:custom_path) { File.join(temp_dir, "custom") }

      before do
        FileUtils.mkdir_p(custom_path)
        FileUtils.mkdir_p(File.join(custom_path, "v.1.0.0-custom"))
      end

      it "searches in custom paths" do
        result = described_class.find_release_directory("v.1.0.0", search_paths: [custom_path])

        expect(result).not_to be_nil
        expect(result[:version]).to eq("v.1.0.0")
        expect(result[:path]).to eq(File.join(custom_path, "v.1.0.0-custom"))
      end
    end

    context "with multiple matching directories" do
      before do
        FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-first"))
        FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-second"))
      end

      it "returns the first matching directory and logs warning" do
        expect { 
          result = described_class.find_release_directory("v.0.3.0", base_path: temp_dir)
          expect(result).not_to be_nil
          expect(result[:version]).to eq("v.0.3.0")
          expect(File.basename(result[:path])).to be_in(["v.0.3.0-first", "v.0.3.0-second"])
        }.not_to output.to_stderr # Warnings suppressed in tests
      end
    end

    context "with non-existent version" do
      it "returns nil" do
        result = described_class.find_release_directory("v.9.9.9", base_path: temp_dir)
        expect(result).to be_nil
      end
    end

    context "with non-existent search paths" do
      it "returns nil when search paths don't exist" do
        result = described_class.find_release_directory("v.0.3.0", base_path: "/non/existent/path")
        expect(result).to be_nil
      end
    end

    context "with invalid arguments" do
      it "raises ArgumentError for non-string version" do
        expect { described_class.find_release_directory(123) }.to raise_error(ArgumentError, "version must be a string")
      end

      it "raises ArgumentError for nil version" do
        expect { described_class.find_release_directory(nil) }.to raise_error(ArgumentError, "version cannot be nil or empty")
      end

      it "raises ArgumentError for empty version" do
        expect { described_class.find_release_directory("") }.to raise_error(ArgumentError, "version cannot be nil or empty")
      end
    end
  end

  describe ".get_current_release_directory" do
    let(:current_path) { File.join(temp_dir, "dev-taskflow", "current") }

    context "with single release directory" do
      before do
        FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-migration"))
      end

      it "returns the current release directory" do
        result = described_class.get_current_release_directory(base_path: temp_dir)

        expect(result).not_to be_nil
        expect(result[:version]).to eq("v.0.3.0")
        expect(result[:path]).to eq(File.join(current_path, "v.0.3.0-migration"))
      end
    end

    context "with multiple release directories" do
      before do
        FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-first"))
        FileUtils.mkdir_p(File.join(current_path, "v.0.4.0-second"))
      end

      it "returns the first directory and logs warning" do
        expect { 
          result = described_class.get_current_release_directory(base_path: temp_dir)
          expect(result).not_to be_nil
          expect(["v.0.3.0", "v.0.4.0"]).to include(result[:version])
        }.not_to output.to_stderr # Warnings suppressed in tests
      end
    end

    context "with no release directories" do
      before do
        FileUtils.mkdir_p(current_path)
      end

      it "returns nil" do
        result = described_class.get_current_release_directory(base_path: temp_dir)
        expect(result).to be_nil
      end
    end

    context "with non-existent current path" do
      it "returns nil" do
        result = described_class.get_current_release_directory(base_path: temp_dir)
        expect(result).to be_nil
      end
    end

    context "with invalid directory names" do
      before do
        FileUtils.mkdir_p(File.join(current_path, "invalid-name"))
        FileUtils.mkdir_p(File.join(current_path, "another-invalid"))
      end

      it "returns nil when no valid version directories exist" do
        result = described_class.get_current_release_directory(base_path: temp_dir)
        expect(result).to be_nil
      end
    end

    context "with mixed valid and invalid directories" do
      before do
        FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-valid"))
        FileUtils.mkdir_p(File.join(current_path, "invalid-name"))
      end

      it "returns the valid directory" do
        result = described_class.get_current_release_directory(base_path: temp_dir)

        expect(result).not_to be_nil
        expect(result[:version]).to eq("v.0.3.0")
        expect(result[:path]).to eq(File.join(current_path, "v.0.3.0-valid"))
      end
    end
  end

  describe ".find_tasks_directory" do
    let(:release_path) { File.join(temp_dir, "v.0.3.0-release") }
    let(:tasks_path) { File.join(release_path, "tasks") }

    context "with existing tasks directory" do
      before do
        FileUtils.mkdir_p(tasks_path)
      end

      it "returns the tasks directory path" do
        result = described_class.find_tasks_directory(release_path)
        expect(result).to eq(tasks_path)
      end
    end

    context "with custom tasks subdirectory" do
      let(:custom_tasks_path) { File.join(release_path, "custom_tasks") }

      before do
        FileUtils.mkdir_p(custom_tasks_path)
      end

      it "returns the custom tasks directory path" do
        result = described_class.find_tasks_directory(release_path, tasks_subdir: "custom_tasks")
        expect(result).to eq(custom_tasks_path)
      end
    end

    context "with non-existent tasks directory" do
      before do
        FileUtils.mkdir_p(release_path)
      end

      it "returns nil" do
        result = described_class.find_tasks_directory(release_path)
        expect(result).to be_nil
      end
    end

    context "with non-existent release path" do
      it "returns nil" do
        result = described_class.find_tasks_directory("/non/existent/path")
        expect(result).to be_nil
      end
    end

    context "with invalid arguments" do
      it "raises ArgumentError for nil release_path" do
        expect { described_class.find_tasks_directory(nil) }.to raise_error(ArgumentError, "release_path cannot be nil or empty")
      end

      it "raises ArgumentError for empty release_path" do
        expect { described_class.find_tasks_directory("") }.to raise_error(ArgumentError, "release_path cannot be nil or empty")
      end
    end

    context "with file instead of directory" do
      before do
        FileUtils.mkdir_p(release_path)
        File.write(File.join(release_path, "tasks"), "this is a file")
      end

      it "returns nil when tasks is a file, not directory" do
        result = described_class.find_tasks_directory(release_path)
        expect(result).to be_nil
      end
    end
  end

  describe ".list_release_directories" do
    let(:search_path) { File.join(temp_dir, "releases") }

    context "with multiple release directories" do
      before do
        FileUtils.mkdir_p(search_path)
        FileUtils.mkdir_p(File.join(search_path, "v.0.1.0-first"))
        FileUtils.mkdir_p(File.join(search_path, "v.0.3.0-third"))
        FileUtils.mkdir_p(File.join(search_path, "v.0.2.0-second"))
        FileUtils.mkdir_p(File.join(search_path, "invalid-dir"))
      end

      it "returns sorted list of release directories" do
        result = described_class.list_release_directories(search_path)

        expect(result.length).to eq(3)
        expect(result[0][:version]).to eq("v.0.1.0")
        expect(result[1][:version]).to eq("v.0.2.0")
        expect(result[2][:version]).to eq("v.0.3.0")

        result.each do |dir|
          expect(dir).to have_key(:path)
          expect(dir).to have_key(:version)
          expect(dir).to have_key(:name)
        end
      end

      it "includes name in the result" do
        result = described_class.list_release_directories(search_path)

        expect(result[0][:name]).to eq("v.0.1.0-first")
        expect(result[1][:name]).to eq("v.0.2.0-second")
        expect(result[2][:name]).to eq("v.0.3.0-third")
      end
    end

    context "with no release directories" do
      before do
        FileUtils.mkdir_p(search_path)
        FileUtils.mkdir_p(File.join(search_path, "invalid-dir"))
        File.write(File.join(search_path, "file.txt"), "not a directory")
      end

      it "returns empty array" do
        result = described_class.list_release_directories(search_path)
        expect(result).to eq([])
      end
    end

    context "with non-existent search path" do
      it "returns empty array" do
        result = described_class.list_release_directories("/non/existent/path")
        expect(result).to eq([])
      end
    end

    context "with invalid arguments" do
      it "raises ArgumentError for nil search_path" do
        expect { described_class.list_release_directories(nil) }.to raise_error(ArgumentError, "search_path cannot be nil or empty")
      end

      it "raises ArgumentError for empty search_path" do
        expect { described_class.list_release_directories("") }.to raise_error(ArgumentError, "search_path cannot be nil or empty")
      end
    end

    context "with complex version sorting" do
      before do
        FileUtils.mkdir_p(search_path)
        FileUtils.mkdir_p(File.join(search_path, "v.1.10.0-latest"))
        FileUtils.mkdir_p(File.join(search_path, "v.1.2.0-older"))
        FileUtils.mkdir_p(File.join(search_path, "v.1.9.0-middle"))
        FileUtils.mkdir_p(File.join(search_path, "v.2.0.0-newest"))
      end

      it "sorts versions correctly (numeric, not lexicographic)" do
        result = described_class.list_release_directories(search_path)

        expect(result.map { |r| r[:version] }).to eq([
          "v.1.2.0",
          "v.1.9.0",
          "v.1.10.0",
          "v.2.0.0"
        ])
      end
    end
  end

  describe ".safe_directory_path?" do
    context "with valid paths" do
      valid_paths = [
        "valid/path",
        "path/with/subdirs",
        "path-with-dashes",
        "path_with_underscores",
        "path.with.dots",
        "123numeric456",
        "UPPERCASE",
        "mixedCase"
      ]

      valid_paths.each do |path|
        it "returns true for valid path: #{path}" do
          expect(described_class.safe_directory_path?(path)).to be true
        end
      end
    end

    context "with invalid paths" do
      it "returns false for non-string input" do
        expect(described_class.safe_directory_path?(123)).to be false
        expect(described_class.safe_directory_path?(nil)).to be false
        expect(described_class.safe_directory_path?([])).to be false
      end

      it "returns false for nil or empty paths" do
        expect(described_class.safe_directory_path?(nil)).to be false
        expect(described_class.safe_directory_path?("")).to be false
      end

      it "returns false for paths with null bytes" do
        expect(described_class.safe_directory_path?("path\0with\0null")).to be false
      end

      it "returns false for paths with control characters" do
        expect(described_class.safe_directory_path?("path\x01with\x1fcontrol")).to be false
        expect(described_class.safe_directory_path?("path\x7fwith\x0bcontrol")).to be false
      end

      it "returns false for directory traversal attempts" do
        expect(described_class.safe_directory_path?("../etc/passwd")).to be false
        expect(described_class.safe_directory_path?("path/../traversal")).to be false
        expect(described_class.safe_directory_path?("..\\windows\\traversal")).to be false
      end

      it "returns false for excessively long paths" do
        long_path = "a" * 5000
        expect(described_class.safe_directory_path?(long_path)).to be false
      end
    end

    context "with edge cases" do
      it "returns true for paths at maximum length" do
        max_length_path = "a" * 4096
        expect(described_class.safe_directory_path?(max_length_path)).to be true
      end

      it "returns false for paths just over maximum length" do
        over_max_path = "a" * 4097
        expect(described_class.safe_directory_path?(over_max_path)).to be false
      end
    end
  end

  describe ".ensure_directory_exists" do
    context "with valid paths" do
      let(:test_dir) { File.join(temp_dir, "test_directory") }

      it "creates directory when it doesn't exist" do
        expect(File.exist?(test_dir)).to be false

        result = described_class.ensure_directory_exists(test_dir)

        expect(result).to be true
        expect(File.exist?(test_dir)).to be true
        expect(File.directory?(test_dir)).to be true
      end

      it "returns true when directory already exists" do
        FileUtils.mkdir_p(test_dir)

        result = described_class.ensure_directory_exists(test_dir)

        expect(result).to be true
      end

      it "creates parent directories when recursive is true" do
        nested_dir = File.join(temp_dir, "level1", "level2", "level3")

        result = described_class.ensure_directory_exists(nested_dir, recursive: true)

        expect(result).to be true
        expect(File.exist?(nested_dir)).to be true
        expect(File.directory?(nested_dir)).to be true
      end

      it "fails to create nested directories when recursive is false" do
        nested_dir = File.join(temp_dir, "level1", "level2", "level3")

        expect { described_class.ensure_directory_exists(nested_dir, recursive: false) }.to raise_error(SecurityError, /Failed to create directory/)
      end
    end

    context "with invalid arguments" do
      it "raises ArgumentError for nil path" do
        expect { described_class.ensure_directory_exists(nil) }.to raise_error(ArgumentError, "path cannot be nil or empty")
      end

      it "raises ArgumentError for empty path" do
        expect { described_class.ensure_directory_exists("") }.to raise_error(ArgumentError, "path cannot be nil or empty")
      end

      it "raises SecurityError for unsafe path" do
        expect { described_class.ensure_directory_exists("../unsafe/path") }.to raise_error(SecurityError, "path failed safety validation")
      end
    end

    context "with file system errors" do
      it "raises SecurityError when directory creation fails" do
        # Try to create directory with invalid characters (platform-dependent)
        if Gem.win_platform?
          invalid_path = File.join(temp_dir, "invalid:path")
        else
          # On Unix-like systems, try to create in a non-existent directory without recursive
          invalid_path = "/non/existent/base/directory"
        end

        # Mock FileUtils to simulate failure
        allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES, "Permission denied")

        expect { described_class.ensure_directory_exists(File.join(temp_dir, "test"), recursive: true) }.to raise_error(SecurityError, /Failed to create directory/)
      end
    end
  end

  describe ".relative_path" do
    context "with valid paths" do
      it "returns relative path from base to target" do
        base = "/home/user/project"
        target = "/home/user/project/subdirectory/file"

        result = described_class.relative_path(target, base)
        expect(result).to eq("subdirectory/file")
      end

      it "handles paths going up from base" do
        base = "/home/user/project/subdirectory"
        target = "/home/user/other_project"

        result = described_class.relative_path(target, base)
        expect(result).to eq("../../other_project")
      end

      it "handles same paths" do
        path = "/home/user/project"

        result = described_class.relative_path(path, path)
        expect(result).to eq(".")
      end
    end

    context "with invalid arguments" do
      it "raises ArgumentError for nil target_path" do
        expect { described_class.relative_path(nil, "/base") }.to raise_error(ArgumentError, "target_path cannot be nil or empty")
      end

      it "raises ArgumentError for empty target_path" do
        expect { described_class.relative_path("", "/base") }.to raise_error(ArgumentError, "target_path cannot be nil or empty")
      end

      it "raises ArgumentError for nil base_path" do
        expect { described_class.relative_path("/target", nil) }.to raise_error(ArgumentError, "base_path cannot be nil or empty")
      end

      it "raises ArgumentError for empty base_path" do
        expect { described_class.relative_path("/target", "") }.to raise_error(ArgumentError, "base_path cannot be nil or empty")
      end
    end
  end

  describe "private methods" do
    describe ".find_matching_directories" do
      let(:search_path) { File.join(temp_dir, "search") }

      before do
        FileUtils.mkdir_p(search_path)
        FileUtils.mkdir_p(File.join(search_path, "v.0.3.0-migration"))
        FileUtils.mkdir_p(File.join(search_path, "v.0.3.0-hotfix"))
        FileUtils.mkdir_p(File.join(search_path, "v.0.4.0-features"))
        File.write(File.join(search_path, "v.0.3.0-file"), "not a directory")
      end

      it "finds directories matching version prefix" do
        result = described_class.send(:find_matching_directories, search_path, "v.0.3.0")

        expect(result.length).to eq(2)
        expect(result).to include(File.join(search_path, "v.0.3.0-migration"))
        expect(result).to include(File.join(search_path, "v.0.3.0-hotfix"))
      end

      it "excludes files with matching names" do
        result = described_class.send(:find_matching_directories, search_path, "v.0.3.0")

        expect(result).not_to include(File.join(search_path, "v.0.3.0-file"))
      end

      it "returns empty array when no matches found" do
        result = described_class.send(:find_matching_directories, search_path, "v.9.9.9")

        expect(result).to eq([])
      end
    end

    describe ".extract_version_from_directory_name" do
      it "extracts version from valid directory names" do
        expect(described_class.send(:extract_version_from_directory_name, "v.0.3.0-migration")).to eq("v.0.3.0")
        expect(described_class.send(:extract_version_from_directory_name, "v.1.2.3")).to eq("v.1.2.3")
        expect(described_class.send(:extract_version_from_directory_name, "v.10.20.30-feature")).to eq("v.10.20.30")
      end

      it "returns nil for invalid directory names" do
        expect(described_class.send(:extract_version_from_directory_name, "invalid-name")).to be_nil
        expect(described_class.send(:extract_version_from_directory_name, "v.0.3-incomplete")).to be_nil
        expect(described_class.send(:extract_version_from_directory_name, "0.3.0-no-prefix")).to be_nil
      end

      it "handles edge cases" do
        expect(described_class.send(:extract_version_from_directory_name, "")).to be_nil
        expect(described_class.send(:extract_version_from_directory_name, "v.")).to be_nil
        expect(described_class.send(:extract_version_from_directory_name, "v.0")).to be_nil
      end
    end

    describe ".compare_versions" do
      it "compares versions correctly" do
        expect(described_class.send(:compare_versions, "v.0.1.0", "v.0.2.0")).to eq(-1)
        expect(described_class.send(:compare_versions, "v.0.2.0", "v.0.1.0")).to eq(1)
        expect(described_class.send(:compare_versions, "v.0.1.0", "v.0.1.0")).to eq(0)
      end

      it "handles different length versions" do
        expect(described_class.send(:compare_versions, "v.1.0", "v.1.0.0")).to eq(0)
        expect(described_class.send(:compare_versions, "v.1.0.1", "v.1.0")).to eq(1)
        expect(described_class.send(:compare_versions, "v.1.0", "v.1.0.1")).to eq(-1)
      end

      it "handles major version differences" do
        expect(described_class.send(:compare_versions, "v.1.0.0", "v.2.0.0")).to eq(-1)
        expect(described_class.send(:compare_versions, "v.2.0.0", "v.1.9.9")).to eq(1)
      end

      it "sorts correctly for numeric ordering" do
        versions = ["v.1.10.0", "v.1.2.0", "v.1.9.0"]
        sorted = versions.sort { |a, b| described_class.send(:compare_versions, a, b) }

        expect(sorted).to eq(["v.1.2.0", "v.1.9.0", "v.1.10.0"])
      end
    end

    describe ".log_warning" do
      it "outputs warning when warnings are not suppressed" do
        described_class.suppress_warnings = false

        expect { described_class.send(:log_warning, "Test warning") }.to output(/Warning: Test warning/).to_stderr
      end

      it "does not output warning when warnings are suppressed" do
        described_class.suppress_warnings = true

        expect { described_class.send(:log_warning, "Test warning") }.not_to output.to_stderr
      end
    end
  end

  describe "comprehensive edge cases and error handling" do
    context "with Unicode and special characters" do
      let(:unicode_dir) { File.join(temp_dir, "unicode", "v.0.3.0-文档") }

      before do
        FileUtils.mkdir_p(unicode_dir)
      end

      it "handles Unicode in directory names" do
        result = described_class.find_release_directory("v.0.3.0", search_paths: [File.dirname(unicode_dir)])

        expect(result).not_to be_nil
        expect(result[:path]).to eq(unicode_dir)
      end

      it "validates Unicode paths as safe" do
        expect(described_class.safe_directory_path?("path/with/文档/unicode")).to be true
      end
    end

    context "with symlinks and special files" do
      before do
        FileUtils.mkdir_p(File.join(temp_dir, "real_dir"))
      end

      it "handles symbolic links if platform supports them" do
        symlink_path = File.join(temp_dir, "v.0.3.0-symlink")

        begin
          File.symlink(File.join(temp_dir, "real_dir"), symlink_path)

          search_path = temp_dir
          result = described_class.find_release_directory("v.0.3.0", search_paths: [search_path])

          expect(result).not_to be_nil
          expect(result[:path]).to eq(symlink_path)
        rescue NotImplementedError
          # Skip on platforms that don't support symlinks
          skip "Symlinks not supported on this platform"
        ensure
          File.unlink(symlink_path) if File.exist?(symlink_path)
        end
      end
    end

    context "with permission issues" do
      let(:restricted_dir) { File.join(temp_dir, "restricted") }

      before do
        FileUtils.mkdir_p(restricted_dir)
      end

      it "handles permission denied errors gracefully" do
        # Make directory non-readable (if possible on current platform)
        begin
          FileUtils.chmod(0000, restricted_dir)

          result = described_class.list_release_directories(restricted_dir)
          expect(result).to eq([])
        ensure
          FileUtils.chmod(0755, restricted_dir) rescue nil
        end
      end
    end

    context "with very large directory structures" do
      let(:large_search_path) { File.join(temp_dir, "large") }

      before do
        FileUtils.mkdir_p(large_search_path)

        # Create many directories
        100.times do |i|
          if i % 10 == 0
            FileUtils.mkdir_p(File.join(large_search_path, "v.0.#{i}.0-release"))
          else
            FileUtils.mkdir_p(File.join(large_search_path, "invalid-dir-#{i}"))
          end
        end
      end

      it "handles large directory structures efficiently" do
        start_time = Time.now
        result = described_class.list_release_directories(large_search_path)
        end_time = Time.now

        expect(result.length).to eq(10)
        expect(end_time - start_time).to be < 1.0
      end
    end
  end

  describe "algorithm correctness verification" do
    context "version extraction accuracy" do
      test_cases = [
        ["v.0.3.0-migration", "v.0.3.0"],
        ["v.1.2.3", "v.1.2.3"],
        ["v.10.20.30-feature-branch", "v.10.20.30"],
        ["invalid-v.0.3.0", nil],
        ["v.0.3-incomplete", nil],
        ["", nil]
      ]

      test_cases.each do |input, expected|
        it "correctly extracts '#{expected}' from '#{input}'" do
          result = described_class.send(:extract_version_from_directory_name, input)
          expect(result).to eq(expected)
        end
      end
    end

    context "version comparison accuracy" do
      comparison_cases = [
        ["v.0.1.0", "v.0.2.0", -1],
        ["v.0.2.0", "v.0.1.0", 1],
        ["v.1.0.0", "v.0.9.9", 1],
        ["v.1.9.0", "v.1.10.0", -1],
        ["v.2.0.0", "v.1.999.999", 1],
        ["v.1.0.0", "v.1.0.0", 0]
      ]

      comparison_cases.each do |version_a, version_b, expected|
        it "correctly compares #{version_a} <=> #{version_b} = #{expected}" do
          result = described_class.send(:compare_versions, version_a, version_b)
          expect(result).to eq(expected)
        end
      end
    end

    context "path safety validation accuracy" do
      unsafe_paths = [
        "../etc/passwd",
        "path/../traversal",
        "path\0null",
        "path\x01control",
        "a" * 5000
      ]

      safe_paths = [
        "valid/path",
        "path.with.dots",
        "path_with_underscores",
        "a" * 4096
      ]

      unsafe_paths.each do |path|
        it "correctly identifies '#{path[0..20]}...' as unsafe" do
          expect(described_class.safe_directory_path?(path)).to be false
        end
      end

      safe_paths.each do |path|
        it "correctly identifies '#{path[0..20]}...' as safe" do
          expect(described_class.safe_directory_path?(path)).to be true
        end
      end
    end
  end

  describe "performance considerations" do
    it "performs directory operations efficiently" do
      # Create a reasonable number of directories for performance testing
      search_path = File.join(temp_dir, "performance")
      FileUtils.mkdir_p(search_path)

      50.times do |i|
        FileUtils.mkdir_p(File.join(search_path, "v.0.#{i}.0-release"))
      end

      start_time = Time.now

      # Perform multiple operations
      result = described_class.list_release_directories(search_path)
      described_class.find_release_directory("v.0.25.0", search_paths: [search_path])

      end_time = Time.now

      expect(result.length).to eq(50)
      expect(end_time - start_time).to be < 1.0
    end
  end
end