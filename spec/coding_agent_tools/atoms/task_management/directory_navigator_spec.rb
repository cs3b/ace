# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::TaskManagement::DirectoryNavigator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:current_path) { File.join(temp_dir, "dev-taskflow", "current") }
  let(:backlog_path) { File.join(temp_dir, "dev-taskflow", "backlog") }

  before do
    FileUtils.mkdir_p(current_path)
    FileUtils.mkdir_p(backlog_path)
    # Suppress warnings during tests to keep output clean
    described_class.suppress_warnings = true
  end

  after do
    FileUtils.remove_entry(temp_dir) if File.exist?(temp_dir)
    # Reset warning suppression
    described_class.suppress_warnings = false
  end

  describe ".find_release_directory" do
    before do
      # Create test release directories
      FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-migration"))
      FileUtils.mkdir_p(File.join(backlog_path, "v.0.2.0-archived"))
    end

    it "finds release directory in current path" do
      result = described_class.find_release_directory("v.0.3.0", base_path: temp_dir)
      expect(result).to be_a(Hash)
      expect(result[:version]).to eq("v.0.3.0")
      expect(result[:path]).to eq(File.join(current_path, "v.0.3.0-migration"))
    end

    it "finds release directory in backlog path when not in current" do
      result = described_class.find_release_directory("v.0.2.0", base_path: temp_dir)
      expect(result).to be_a(Hash)
      expect(result[:version]).to eq("v.0.2.0")
      expect(result[:path]).to eq(File.join(backlog_path, "v.0.2.0-archived"))
    end

    it "returns nil when release directory not found" do
      result = described_class.find_release_directory("v.1.0.0", base_path: temp_dir)
      expect(result).to be_nil
    end

    it "uses custom search paths" do
      custom_path = File.join(temp_dir, "custom")
      FileUtils.mkdir_p(File.join(custom_path, "v.1.0.0-custom"))

      result = described_class.find_release_directory("v.1.0.0", search_paths: [custom_path])
      expect(result).to be_a(Hash)
      expect(result[:version]).to eq("v.1.0.0")
      expect(result[:path]).to eq(File.join(custom_path, "v.1.0.0-custom"))
    end

    it "raises ArgumentError for nil version" do
      expect { described_class.find_release_directory(nil) }.to raise_error(ArgumentError, "version must be a string")
    end

    it "raises ArgumentError for empty version" do
      expect { described_class.find_release_directory("") }.to raise_error(ArgumentError, "version cannot be nil or empty")
    end

    it "raises ArgumentError for non-string version" do
      expect { described_class.find_release_directory(123) }.to raise_error(ArgumentError, "version must be a string")
    end

    it "handles multiple matching directories by using first one" do
      # Create duplicate directories
      FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-migration"))
      FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-alternate"))

      result = described_class.find_release_directory("v.0.3.0", base_path: temp_dir)
      expect(result).to be_a(Hash)
      expect(result[:version]).to eq("v.0.3.0")
      expect(result[:path]).to match(/v\.0\.3\.0/)
    end
  end

  describe ".get_current_release_directory" do
    it "returns nil when current directory does not exist" do
      result = described_class.get_current_release_directory(base_path: "/nonexistent")
      expect(result).to be_nil
    end

    it "returns nil when current directory is empty" do
      result = described_class.get_current_release_directory(base_path: temp_dir)
      expect(result).to be_nil
    end

    it "returns directory info when single release directory exists" do
      FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-migration"))

      result = described_class.get_current_release_directory(base_path: temp_dir)
      expect(result).to be_a(Hash)
      expect(result[:version]).to eq("v.0.3.0")
      expect(result[:path]).to eq(File.join(current_path, "v.0.3.0-migration"))
    end

    it "handles multiple directories by using first one" do
      FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-migration"))
      FileUtils.mkdir_p(File.join(current_path, "v.0.2.0-old"))

      result = described_class.get_current_release_directory(base_path: temp_dir)
      expect(result).to be_a(Hash)
      expect(result[:version]).to match(/v\.\d+\.\d+\.\d+/)
      expect(result[:path]).to match(/#{current_path}/)
    end

    it "returns nil when directory name does not match version pattern" do
      FileUtils.mkdir_p(File.join(current_path, "invalid-name"))

      result = described_class.get_current_release_directory(base_path: temp_dir)
      expect(result).to be_nil
    end
  end

  describe ".find_tasks_directory" do
    let(:release_path) { File.join(current_path, "v.0.3.0-migration") }
    let(:tasks_path) { File.join(release_path, "tasks") }

    before do
      FileUtils.mkdir_p(release_path)
    end

    it "finds existing tasks directory" do
      FileUtils.mkdir_p(tasks_path)

      result = described_class.find_tasks_directory(release_path)
      expect(result).to eq(tasks_path)
    end

    it "returns nil when tasks directory does not exist" do
      result = described_class.find_tasks_directory(release_path)
      expect(result).to be_nil
    end

    it "uses custom tasks subdirectory name" do
      custom_tasks_path = File.join(release_path, "custom-tasks")
      FileUtils.mkdir_p(custom_tasks_path)

      result = described_class.find_tasks_directory(release_path, tasks_subdir: "custom-tasks")
      expect(result).to eq(custom_tasks_path)
    end

    it "raises ArgumentError for nil release_path" do
      expect { described_class.find_tasks_directory(nil) }.to raise_error(ArgumentError, "release_path cannot be nil or empty")
    end

    it "raises ArgumentError for empty release_path" do
      expect { described_class.find_tasks_directory("") }.to raise_error(ArgumentError, "release_path cannot be nil or empty")
    end
  end

  describe ".list_release_directories" do
    before do
      FileUtils.mkdir_p(File.join(current_path, "v.0.3.0-migration"))
      FileUtils.mkdir_p(File.join(current_path, "v.0.2.0-old"))
      FileUtils.mkdir_p(File.join(current_path, "v.1.0.0-future"))
      FileUtils.mkdir_p(File.join(current_path, "invalid-name"))
    end

    it "lists all release directories" do
      result = described_class.list_release_directories(current_path)
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result.map { |r| r[:version] }).to contain_exactly("v.0.2.0", "v.0.3.0", "v.1.0.0")
    end

    it "sorts directories by version" do
      result = described_class.list_release_directories(current_path)
      versions = result.map { |r| r[:version] }
      expect(versions).to eq(["v.0.2.0", "v.0.3.0", "v.1.0.0"])
    end

    it "includes path and name in results" do
      result = described_class.list_release_directories(current_path)
      first_release = result.first
      expect(first_release[:path]).to eq(File.join(current_path, "v.0.2.0-old"))
      expect(first_release[:name]).to eq("v.0.2.0-old")
    end

    it "returns empty array for nonexistent directory" do
      result = described_class.list_release_directories("/nonexistent")
      expect(result).to eq([])
    end

    it "raises ArgumentError for nil search_path" do
      expect { described_class.list_release_directories(nil) }.to raise_error(ArgumentError, "search_path cannot be nil or empty")
    end

    it "raises ArgumentError for empty search_path" do
      expect { described_class.list_release_directories("") }.to raise_error(ArgumentError, "search_path cannot be nil or empty")
    end
  end

  describe ".safe_directory_path?" do
    it "returns true for safe paths" do
      expect(described_class.safe_directory_path?("/safe/path")).to be true
      expect(described_class.safe_directory_path?("relative/path")).to be true
      expect(described_class.safe_directory_path?("simple-name")).to be true
    end

    it "returns false for unsafe paths" do
      expect(described_class.safe_directory_path?(nil)).to be false
      expect(described_class.safe_directory_path?("")).to be false
      expect(described_class.safe_directory_path?(123)).to be false
      expect(described_class.safe_directory_path?("path\0with\0null")).to be false
      expect(described_class.safe_directory_path?("path\x01with\x01control")).to be false
      expect(described_class.safe_directory_path?("path/../traversal")).to be false
      expect(described_class.safe_directory_path?('path\\..\\traversal')).to be false
    end

    it "returns false for excessively long paths" do
      long_path = "a" * 5000
      expect(described_class.safe_directory_path?(long_path)).to be false
    end
  end

  describe ".ensure_directory_exists" do
    let(:test_dir) { File.join(temp_dir, "test-dir") }

    it "creates directory when it does not exist" do
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

    it "creates parent directories recursively by default" do
      nested_dir = File.join(temp_dir, "nested", "deep", "directory")

      result = described_class.ensure_directory_exists(nested_dir)
      expect(result).to be true
      expect(File.exist?(nested_dir)).to be true
      expect(File.directory?(nested_dir)).to be true
    end

    it "does not create parent directories when recursive is false" do
      nested_dir = File.join(temp_dir, "nonexistent", "directory")

      expect { described_class.ensure_directory_exists(nested_dir, recursive: false) }.to raise_error(SecurityError)
    end

    it "raises ArgumentError for nil path" do
      expect { described_class.ensure_directory_exists(nil) }.to raise_error(ArgumentError, "path cannot be nil or empty")
    end

    it "raises ArgumentError for empty path" do
      expect { described_class.ensure_directory_exists("") }.to raise_error(ArgumentError, "path cannot be nil or empty")
    end

    it "raises SecurityError for unsafe path" do
      expect { described_class.ensure_directory_exists("../unsafe") }.to raise_error(SecurityError, "path failed safety validation")
    end
  end

  describe ".relative_path" do
    it "returns relative path from base to target" do
      base = "/home/user/projects"
      target = "/home/user/projects/my-project/src"

      result = described_class.relative_path(target, base)
      expect(result).to eq("my-project/src")
    end

    it "handles paths at same level" do
      base = "/home/user/projects/project-a"
      target = "/home/user/projects/project-b"

      result = described_class.relative_path(target, base)
      expect(result).to eq("../project-b")
    end

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
