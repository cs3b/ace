# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::Git::PathResolver do
  let(:temp_dir) { Dir.mktmpdir }
  let(:main_repo_path) { temp_dir }
  let(:dev_tools_path) { File.join(temp_dir, "dev-tools") }
  let(:dev_taskflow_path) { File.join(temp_dir, "dev-taskflow") }
  let(:dev_handbook_path) { File.join(temp_dir, "dev-handbook") }

  let(:repositories) do
    [
      {
        name: "main",
        path: ".",
        full_path: main_repo_path,
        exists: true,
        is_git_repo: true
      },
      {
        name: "dev-tools",
        path: "dev-tools",
        full_path: dev_tools_path,
        exists: true,
        is_git_repo: true
      },
      {
        name: "dev-taskflow",
        path: "dev-taskflow",
        full_path: dev_taskflow_path,
        exists: true,
        is_git_repo: true
      },
      {
        name: "dev-handbook",
        path: "dev-handbook",
        full_path: dev_handbook_path,
        exists: true,
        is_git_repo: true
      }
    ]
  end

  let(:resolver) { described_class.new(repositories, temp_dir) }

  before do
    # Create test directory structure
    FileUtils.mkdir_p(dev_tools_path)
    FileUtils.mkdir_p(dev_taskflow_path)
    FileUtils.mkdir_p(dev_handbook_path)
    FileUtils.mkdir_p(File.join(temp_dir, ".coding-agent"))
    FileUtils.mkdir_p(File.join(dev_tools_path, "lib"))
    FileUtils.mkdir_p(File.join(dev_taskflow_path, "current"))

    # Create test files
    File.write(File.join(temp_dir, ".coding-agent", "path.yml"), "test content")
    File.write(File.join(temp_dir, "README.md"), "main readme")
    File.write(File.join(dev_tools_path, "lib", "example.rb"), "ruby code")
    File.write(File.join(dev_taskflow_path, "current", "task.md"), "task content")
    File.write(File.join(dev_handbook_path, "guide.md"), "guide content")
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe "#resolve_path" do
    context "with absolute paths" do
      it "resolves main repository files" do
        path = File.join(temp_dir, ".coding-agent", "path.yml")
        result = resolver.resolve_path(path)

        expect(result[:repository]).to eq("main")
        expect(result[:relative_path]).to eq(".coding-agent/path.yml")
        expect(result[:exists]).to be true
      end

      it "resolves submodule files" do
        path = File.join(dev_tools_path, "lib", "example.rb")
        result = resolver.resolve_path(path)

        expect(result[:repository]).to eq("dev-tools")
        expect(result[:relative_path]).to eq("lib/example.rb")
        expect(result[:exists]).to be true
      end
    end

    context "with relative paths containing repository prefixes" do
      it "resolves dev-tools prefixed paths from project root" do
        result = resolver.resolve_path("dev-tools/lib/example.rb")

        expect(result[:repository]).to eq("dev-tools")
        expect(result[:relative_path]).to eq("lib/example.rb")
        expect(result[:absolute_path]).to eq(File.join(dev_tools_path, "lib", "example.rb"))
        expect(result[:exists]).to be true
      end

      it "resolves dev-taskflow prefixed paths from project root" do
        result = resolver.resolve_path("dev-taskflow/current/task.md")

        expect(result[:repository]).to eq("dev-taskflow")
        expect(result[:relative_path]).to eq("current/task.md")
        expect(result[:absolute_path]).to eq(File.join(dev_taskflow_path, "current", "task.md"))
        expect(result[:exists]).to be true
      end

      it "resolves dev-handbook prefixed paths from project root" do
        result = resolver.resolve_path("dev-handbook/guide.md")

        expect(result[:repository]).to eq("dev-handbook")
        expect(result[:relative_path]).to eq("guide.md")
        expect(result[:absolute_path]).to eq(File.join(dev_handbook_path, "guide.md"))
        expect(result[:exists]).to be true
      end
    end

    context "with relative paths without repository prefixes" do
      context "when current directory is project root" do
        around do |example|
          Dir.chdir(temp_dir) { example.run }
        end

        it "resolves main repository files" do
          result = resolver.resolve_path(".coding-agent/path.yml")

          expect(result[:repository]).to eq("main")
          expect(result[:relative_path]).to eq(".coding-agent/path.yml")
          expect(result[:exists]).to be true
        end

        it "resolves README files to main repository" do
          result = resolver.resolve_path("README.md")

          expect(result[:repository]).to eq("main")
          expect(result[:relative_path]).to eq("README.md")
          expect(result[:exists]).to be true
        end
      end

      context "when current directory is inside a submodule" do
        it "resolves main repository files correctly (THE BUG FIX)" do
          Dir.chdir(dev_tools_path) do
            result = resolver.resolve_path(".coding-agent/path.yml")

            expect(result[:repository]).to eq("main")
            expect(result[:relative_path]).to eq(".coding-agent/path.yml")
            expect(result[:absolute_path]).to eq(File.join(temp_dir, ".coding-agent", "path.yml"))
            expect(result[:exists]).to be true
          end
        end

        it "resolves local submodule files when they exist" do
          Dir.chdir(dev_tools_path) do
            result = resolver.resolve_path("lib/example.rb")

            expect(result[:repository]).to eq("dev-tools")
            expect(result[:relative_path]).to eq("lib/example.rb")
            expect(result[:exists]).to be true
          end
        end

        it "prefers existing project root files over non-existent local files" do
          Dir.chdir(dev_tools_path) do
            # This tests the intelligent resolution logic
            result = resolver.resolve_path("README.md")

            expect(result[:repository]).to eq("main")
            expect(result[:relative_path]).to eq("README.md")
            expect(result[:absolute_path]).to eq(File.join(temp_dir, "README.md"))
            expect(result[:exists]).to be true
          end
        end

        context "when files exist in both locations" do
          before do
            # Create a README in both main and dev-tools
            File.write(File.join(dev_tools_path, "README.md"), "dev-tools readme")
          end

          it "prefers the local submodule file" do
            Dir.chdir(dev_tools_path) do
              result = resolver.resolve_path("README.md")

              expect(result[:repository]).to eq("dev-tools")
              expect(result[:relative_path]).to eq("README.md")
              # Compare real paths to handle symlink differences
              expect(File.realpath(result[:absolute_path])).to eq(File.realpath(File.join(dev_tools_path, "README.md")))
              expect(result[:exists]).to be true
            end
          end
        end

        context "with dot-prefixed paths" do
          it "prefers project root resolution for dot-prefixed paths" do
            # Create a dot file in the submodule to test the preference logic
            File.write(File.join(dev_tools_path, ".gitignore"), "local gitignore")
            File.write(File.join(temp_dir, ".gitignore"), "main gitignore")

            Dir.chdir(dev_tools_path) do
              result = resolver.resolve_path(".gitignore")

              # Should prefer the main repository for dot files even when local exists
              expect(result[:repository]).to eq("main")
              expect(result[:relative_path]).to eq(".gitignore")
              expect(result[:absolute_path]).to eq(File.join(temp_dir, ".gitignore"))
            end
          end
        end
      end
    end

    context "error handling" do
      it "raises error for nil path" do
        expect {
          resolver.resolve_path(nil)
        }.to raise_error(CodingAgentTools::Atoms::Git::PathResolutionError, /cannot be nil/)
      end

      it "raises error for empty path" do
        expect {
          resolver.resolve_path("")
        }.to raise_error(CodingAgentTools::Atoms::Git::PathResolutionError, /cannot be nil/)
      end

      it "handles non-existent files gracefully" do
        result = resolver.resolve_path("non-existent-file.txt")

        expect(result[:exists]).to be false
        expect(result[:repository]).to eq("main") # Should default to main
      end
    end
  end

  describe "#group_paths_by_repository" do
    context "with mixed repository paths (the original bug scenario)" do
      let(:test_paths) do
        [
          ".coding-agent/path.yml",
          "dev-tools/lib/example.rb",
          "dev-taskflow/current/task.md",
          "dev-handbook/guide.md"
        ]
      end

      it "correctly groups files by their actual repositories when working from submodule" do
        Dir.chdir(dev_tools_path) do
          grouped = resolver.group_paths_by_repository(test_paths)

          expect(grouped).to eq({
            "main" => [".coding-agent/path.yml"],
            "dev-tools" => ["lib/example.rb"],
            "dev-taskflow" => ["current/task.md"],
            "dev-handbook" => ["guide.md"]
          })
        end
      end
    end

    context "with paths from current working directory" do
      it "groups relative paths correctly from project root" do
        Dir.chdir(temp_dir) do
          paths = [".coding-agent/path.yml", "README.md"]
          grouped = resolver.group_paths_by_repository(paths)

          expect(grouped).to eq({
            "main" => [".coding-agent/path.yml", "README.md"]
          })
        end
      end
    end

    it "returns empty hash for empty paths" do
      expect(resolver.group_paths_by_repository([])).to eq({})
    end

    it "handles nil paths" do
      expect(resolver.group_paths_by_repository(nil)).to eq({})
    end
  end

  describe "#resolve_paths" do
    it "resolves multiple paths correctly" do
      paths = [".coding-agent/path.yml", "dev-tools/lib/example.rb"]

      results = resolver.resolve_paths(paths)

      expect(results.length).to eq(2)
      expect(results[0][:repository]).to eq("main")
      expect(results[1][:repository]).to eq("dev-tools")
    end
  end

  describe "#path_contains_repository_prefix?" do
    it "detects repository prefixes" do
      expect(resolver.send(:path_contains_repository_prefix?, "dev-tools/lib/file.rb")).to be true
      expect(resolver.send(:path_contains_repository_prefix?, "dev-taskflow/task.md")).to be true
      expect(resolver.send(:path_contains_repository_prefix?, "dev-handbook/guide.md")).to be true
      expect(resolver.send(:path_contains_repository_prefix?, "main/file.rb")).to be true
    end

    it "rejects non-repository prefixes" do
      expect(resolver.send(:path_contains_repository_prefix?, "lib/file.rb")).to be false
      expect(resolver.send(:path_contains_repository_prefix?, ".coding-agent/path.yml")).to be false
      expect(resolver.send(:path_contains_repository_prefix?, "README.md")).to be false
    end
  end

  describe "#find_repository_for_path" do
    it "finds repository by path containment" do
      path = File.join(dev_tools_path, "lib", "example.rb")
      repo = resolver.send(:find_repository_for_path, path)

      expect(repo[:name]).to eq("dev-tools")
    end

    it "defaults to main repository for unmatched paths" do
      path = "/some/external/path.rb"
      repo = resolver.send(:find_repository_for_path, path)

      expect(repo[:name]).to eq("main")
    end

    it "chooses most specific repository (longest path first)" do
      # Test that nested repositories are handled correctly
      nested_path = File.join(dev_tools_path, "nested", "file.rb")
      FileUtils.mkdir_p(File.dirname(nested_path))

      repo = resolver.send(:find_repository_for_path, nested_path)
      expect(repo[:name]).to eq("dev-tools")
    end
  end

  describe "intelligent path resolution" do
    it "handles files that exist in project root but not locally when working from submodule" do
      Dir.chdir(dev_tools_path) do
        result = resolver.resolve_path(".coding-agent/path.yml")

        expect(result[:repository]).to eq("main")
        expect(result[:exists]).to be true
      end
    end

    it "handles files that exist locally but not in project root when working from submodule" do
      Dir.chdir(dev_tools_path) do
        result = resolver.resolve_path("lib/example.rb")

        expect(result[:repository]).to eq("dev-tools")
        expect(result[:exists]).to be true
      end
    end

    it "chooses existing file over non-existing when both paths are valid" do
      # Create a file that exists in project root but not locally
      File.write(File.join(temp_dir, "project-file.txt"), "content")

      Dir.chdir(dev_tools_path) do
        result = resolver.resolve_path("project-file.txt")

        expect(result[:repository]).to eq("main")
        expect(result[:exists]).to be true
      end
    end
  end
end
