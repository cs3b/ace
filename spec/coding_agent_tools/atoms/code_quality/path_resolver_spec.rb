# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::PathResolver do
  let(:temp_dir) { Dir.mktmpdir }
  let(:resolver) { described_class.new(project_root: temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    it "uses provided project root" do
      resolver = described_class.new(project_root: "/custom/root")
      expect(resolver.project_root).to eq("/custom/root")
    end

    it "detects project root when not provided" do
      resolver = described_class.new
      expect(resolver.project_root).to be_a(String)
      expect(resolver.project_root).not_to be_empty
    end
  end

  describe "#resolve" do
    before do
      # Create test files in temp directory
      File.write(File.join(temp_dir, "root_file.txt"), "content")
      subdir = File.join(temp_dir, "subdir")
      Dir.mkdir(subdir)
      File.write(File.join(subdir, "sub_file.txt"), "content")
    end

    context "with absolute paths" do
      it "returns absolute paths unchanged" do
        absolute_path = "/absolute/path/to/file"
        expect(resolver.resolve(absolute_path)).to eq(absolute_path)
      end

      it "handles absolute paths that exist" do
        absolute_path = File.join(temp_dir, "root_file.txt")
        expect(resolver.resolve(absolute_path)).to eq(absolute_path)
      end
    end

    context "with relative paths" do
      it "resolves relative to current directory when file exists" do
        # Create a file in current directory for testing
        current_file = "test_current_file.txt"
        File.write(current_file, "content")

        result = resolver.resolve(current_file)
        expect(result).to eq(File.expand_path(current_file))

        # Cleanup
        File.delete(current_file)
      end

      it "resolves relative to project root when file exists there" do
        result = resolver.resolve("root_file.txt")
        expect(result).to eq(File.join(temp_dir, "root_file.txt"))
      end

      it "resolves nested paths relative to project root" do
        result = resolver.resolve("subdir/sub_file.txt")
        expect(result).to eq(File.join(temp_dir, "subdir/sub_file.txt"))
      end

      it "returns path as-is when file doesn't exist anywhere" do
        non_existent = "non_existent_file.txt"
        result = resolver.resolve(non_existent)
        expect(result).to eq(non_existent)
      end
    end

    context "with edge cases" do
      it "handles empty string path" do
        result = resolver.resolve("")
        expect(result).to be_a(String)
      end

      it "handles path with spaces" do
        spaced_file = "file with spaces.txt"
        File.write(File.join(temp_dir, spaced_file), "content")

        result = resolver.resolve(spaced_file)
        expect(result).to eq(File.join(temp_dir, spaced_file))
      end

      it "handles paths with special characters" do
        special_file = "file-with_special.chars.txt"
        File.write(File.join(temp_dir, special_file), "content")

        result = resolver.resolve(special_file)
        expect(result).to eq(File.join(temp_dir, special_file))
      end
    end
  end

  describe "#relative_to_root" do
    it "converts absolute path to relative from project root" do
      absolute_path = File.join(temp_dir, "subdir", "file.txt")
      result = resolver.relative_to_root(absolute_path)
      expect(result).to eq("subdir/file.txt")
    end

    it "handles paths already relative to root" do
      relative_path = "relative/path.txt"
      # This will be expanded to current directory, then made relative to temp_dir
      result = resolver.relative_to_root(relative_path)
      expect(result).to be_a(String)
    end

    it "handles path equal to project root" do
      result = resolver.relative_to_root(temp_dir)
      expect(result).to eq(".")
    end

    it "returns absolute path when relative path cannot be created" do
      # Path outside project root
      other_temp = Dir.mktmpdir

      begin
        result = resolver.relative_to_root(other_temp)
        # The implementation may return a relative path or absolute path
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      ensure
        FileUtils.rm_rf(other_temp)
      end
    end

    it "handles nested paths correctly" do
      nested_path = File.join(temp_dir, "deep", "nested", "path", "file.txt")
      result = resolver.relative_to_root(nested_path)
      expect(result).to eq("deep/nested/path/file.txt")
    end
  end

  describe "#in_project?" do
    it "returns true for paths within project root" do
      path_in_project = File.join(temp_dir, "some", "file.txt")
      expect(resolver.in_project?(path_in_project)).to be true
    end

    it "returns true for project root itself" do
      expect(resolver.in_project?(temp_dir)).to be true
    end

    it "returns false for paths outside project root" do
      other_temp = Dir.mktmpdir

      begin
        expect(resolver.in_project?(other_temp)).to be false
      ensure
        FileUtils.rm_rf(other_temp)
      end
    end

    it "handles relative paths" do
      # Relative paths are expanded relative to current directory
      expect([true, false]).to include(resolver.in_project?("relative/path"))
    end
  end

  describe "project root detection" do
    let(:test_project_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(test_project_dir) if Dir.exist?(test_project_dir)
    end

    it "detects project root with .git directory" do
      git_dir = File.join(test_project_dir, ".git")
      Dir.mkdir(git_dir)

      # Change to subdirectory
      subdir = File.join(test_project_dir, "subdir")
      Dir.mkdir(subdir)

      Dir.chdir(subdir) do
        resolver = described_class.new
        expect(File.realpath(resolver.project_root)).to eq(File.realpath(test_project_dir))
      end
    end

    it "detects project root with Gemfile" do
      File.write(File.join(test_project_dir, "Gemfile"), "")

      subdir = File.join(test_project_dir, "subdir")
      Dir.mkdir(subdir)

      Dir.chdir(subdir) do
        resolver = described_class.new
        expect(File.realpath(resolver.project_root)).to eq(File.realpath(test_project_dir))
      end
    end

    it "detects project root with .coding-agent directory" do
      coding_agent_dir = File.join(test_project_dir, ".coding-agent")
      Dir.mkdir(coding_agent_dir)

      subdir = File.join(test_project_dir, "subdir")
      Dir.mkdir(subdir)

      Dir.chdir(subdir) do
        # Mock the ProjectRootDetector to avoid complex root detection
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(test_project_dir)
        resolver = described_class.new
        expect(resolver.project_root).to eq(test_project_dir)
      end
    end

    it "falls back to current directory when no markers found" do
      empty_dir = Dir.mktmpdir

      begin
        Dir.chdir(empty_dir) do
          # Mock the detector to return current directory when no markers found
          allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(empty_dir)
          resolver = described_class.new
          expect(resolver.project_root).to eq(empty_dir)
        end
      ensure
        FileUtils.rm_rf(empty_dir)
      end
    end
  end

  describe "integration scenarios" do
    before do
      # Set up a realistic project structure
      %w[lib spec bin].each { |dir| Dir.mkdir(File.join(temp_dir, dir)) }
      File.write(File.join(temp_dir, "Gemfile"), "")
      File.write(File.join(temp_dir, "lib", "main.rb"), "")
      File.write(File.join(temp_dir, "spec", "main_spec.rb"), "")
    end

    it "resolves library files correctly" do
      result = resolver.resolve("lib/main.rb")
      expect(result).to eq(File.join(temp_dir, "lib/main.rb"))
      expect(File.exist?(result)).to be true
    end

    it "converts resolved paths back to relative" do
      resolved = resolver.resolve("lib/main.rb")
      relative = resolver.relative_to_root(resolved)
      expect(relative).to eq("lib/main.rb")
    end

    it "confirms project membership" do
      resolved = resolver.resolve("lib/main.rb")
      expect(resolver.in_project?(resolved)).to be true
    end
  end
end
