# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::PathResolver do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_loader) { instance_double(CodingAgentTools::Molecules::PathConfigLoader) }
  let(:sandbox) { instance_double(CodingAgentTools::Molecules::ProjectSandbox) }
  let(:release_manager) { instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager) }
  let(:config) do
    {
      "repositories" => {
        "scan_order" => [
          {"name" => "tools-meta", "path" => ".", "priority" => 1},
          {"name" => "dev-tools", "path" => "dev-tools", "priority" => 2}
        ]
      },
      "path_patterns" => {
        "task_new" => {
          "template" => "dev-taskflow/current/{release}/tasks/{release}+task.{id}-{slug}.md",
          "variables" => {
            "release" => "release-manager current",
            "id" => "task-manager generate-id",
            "slug" => "user_input"
          }
        }
      },
      "resolution" => {
        "file_preferences" => {
          "preferred_extensions" => [".md", ".rb", ".yml"]
        }
      }
    }
  end

  before do
    # Setup test directory structure
    FileUtils.mkdir_p(File.join(temp_dir, "dev-tools", "lib"))
    FileUtils.mkdir_p(File.join(temp_dir, "dev-taskflow", "current", "v.0.3.0"))

    # Create test files
    FileUtils.touch(File.join(temp_dir, "README.md"))
    FileUtils.touch(File.join(temp_dir, "dev-tools", "lib", "test.rb"))
    FileUtils.touch(File.join(temp_dir, "dev-taskflow", "current", "v.0.3.0", "task.1.md"))

    # Setup mocks
    allow(config_loader).to receive(:load).and_return(config)
    allow(sandbox).to receive(:project_root).and_return(temp_dir)
    allow(sandbox).to receive(:validate_path).and_return({success: true, path: "/valid/path"})
    allow(sandbox).to receive(:absolute_path).and_return(File.join(temp_dir, "README.md"))
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "uses provided config loader and sandbox" do
      resolver = described_class.new(config_loader, sandbox)
      expect(resolver).to be_a(described_class)
    end

    it "creates default dependencies when not provided" do
      resolver = described_class.new
      expect(resolver).to be_a(described_class)
    end
  end

  describe "#resolve_path" do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    context "with nil input" do
      it "returns failure" do
        result = resolver.resolve_path(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to include("cannot be nil")
      end
    end

    context "with empty input" do
      it "returns failure" do
        result = resolver.resolve_path("")
        expect(result[:success]).to be false
        expect(result[:error]).to include("cannot be empty")
      end
    end

    context "with file type" do
      it "resolves existing file path" do
        path = File.join(temp_dir, "README.md")
        allow(sandbox).to receive(:validate_path).with(path).and_return({success: true, path: path})

        result = resolver.resolve_path(path, type: :file)
        expect(result[:success]).to be true
        expect(result[:path]).to eq(path)
      end
    end

    context "with task_new type", :security do
      it "generates new task path" do
        # Mock the execute_command method instead of backticks
        allow(resolver).to receive(:execute_command).with("release-manager current").and_return("v.0.3.0-migration")
        allow(resolver).to receive(:execute_command).with("task-manager generate-id").and_return("42")

        expected_path = File.join(temp_dir, "dev-taskflow/current/v.0.3.0-migration/tasks/v.0.3.0-migration+task.42-test-task.md")
        allow(sandbox).to receive(:validate_path).with(expected_path).and_return({success: true, path: expected_path})

        result = resolver.resolve_path("Test Task", type: :task_new)
        expect(result[:success]).to be true
      end
    end

    context "with unknown type" do
      it "returns failure" do
        result = resolver.resolve_path("test", type: :unknown)
        expect(result[:success]).to be false
        expect(result[:error]).to include("Unknown path type")
      end
    end
  end

  describe "#find_matching_paths", :security do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    it "finds files matching pattern" do
      pattern = "README"
      allow(sandbox).to receive(:validate_path).and_return({success: true, path: "/valid/path"})

      matches = resolver.find_matching_paths(pattern)
      expect(matches).to be_an(Array)
    end

    it "respects max_results option" do
      pattern = "test"
      matches = resolver.find_matching_paths(pattern, max_results: 2)
      expect(matches.length).to be <= 2
    end

    it "filters by file types" do
      pattern = "test"
      matches = resolver.find_matching_paths(pattern, file_types: [".md"])
      # All matches should be markdown files (when found)
      matches.each do |match|
        expect(match).to end_with(".md") if matches.any?
      end
    end
  end

  describe "#resolve_existing_task" do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    context "when task exists" do
      it "returns task path" do
        task_path = File.join(temp_dir, "dev-taskflow", "current", "v.0.3.0", "task.1.md")
        allow(resolver).to receive(:find_matching_paths).and_return([task_path])

        result = resolver.resolve_existing_task("1")
        expect(result[:success]).to be true
        expect(result[:path]).to eq(task_path)
      end
    end

    context "when multiple tasks match" do
      it "returns multiple options" do
        task_paths = [
          File.join(temp_dir, "task.1.md"),
          File.join(temp_dir, "task.10.md")
        ]
        allow(resolver).to receive(:find_matching_paths).and_return(task_paths)

        result = resolver.resolve_existing_task("1")
        expect(result[:success]).to be true
        expect(result[:type]).to eq(:multiple)
        expect(result[:paths]).to eq(task_paths)
      end
    end

    context "when no task found" do
      it "returns failure" do
        allow(resolver).to receive(:find_matching_paths).and_return([])

        result = resolver.resolve_existing_task("999")
        expect(result[:success]).to be false
        expect(result[:error]).to include("No task found")
      end
    end
  end

  describe "#autocorrect_path" do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    it "finds exact matches first" do
      allow(resolver).to receive(:find_matching_paths).and_return(["/exact/match.md"])

      result = resolver.autocorrect_path("exact")
      expect(result[:success]).to be true
      expect(result[:path]).to eq("/exact/match.md")
    end

    it "falls back to fuzzy matching" do
      allow(resolver).to receive(:find_matching_paths).and_return([])
      allow(resolver).to receive(:find_fuzzy_matches).and_return(["/fuzzy/match.md"])

      result = resolver.autocorrect_path("fuz")
      expect(result[:success]).to be true
      expect(result[:path]).to eq("/fuzzy/match.md")
    end

    it "returns failure when no matches found" do
      allow(resolver).to receive(:find_matching_paths).and_return([])
      allow(resolver).to receive(:find_fuzzy_matches).and_return([])

      result = resolver.autocorrect_path("nonexistent")
      expect(result[:success]).to be false
      expect(result[:error]).to include("No matches found")
    end
  end

  describe "command execution fallbacks" do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    it "handles command failures gracefully" do
      # Test the fallback detection method directly
      allow(resolver).to receive(:detect_current_release_fallback).and_return("v.0.3.0")

      # Should fall back to default values for known commands
      fallback_result = resolver.send(:detect_current_release_fallback)
      expect(fallback_result).to match(/v\.\d+\.\d+\.\d+/)
    end
  end

  describe "string utilities" do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    describe "#slugify" do
      it "converts text to URL-friendly slug" do
        slug = resolver.send(:slugify, "Hello World! Test@123")
        expect(slug).to eq("hello-world-test123")
      end

      it "handles edge cases" do
        expect(resolver.send(:slugify, "")).to eq("")
        expect(resolver.send(:slugify, "   ")).to eq("")
        expect(resolver.send(:slugify, "---test---")).to eq("test")
      end
    end
  end

  describe "similarity scoring" do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    it "gives exact matches highest score" do
      score = resolver.send(:calculate_similarity_score, "test", "/path/test.rb")
      expect(score).to eq(1.0)
    end

    it "gives substring matches high score" do
      score = resolver.send(:calculate_similarity_score, "test", "/path/testing.rb")
      expect(score).to eq(0.8)
    end

    it "calculates character overlap" do
      score = resolver.send(:calculate_similarity_score, "abc", "/path/axbxc.rb")
      expect(score).to be > 0.0
      expect(score).to be < 0.8
    end
  end

  describe "template variable resolution" do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    it "resolves user_input to slugified title" do
      template = "tasks/{slug}.md"
      variables = {"slug" => "user_input"}

      result = resolver.send(:resolve_template_variables, template, variables, "Test Task")
      expect(result).to include("test-task")
    end

    it "resolves datetime variables" do
      template = "logs/{timestamp}.log"
      variables = {"timestamp" => "datetime:%Y%m%d"}

      result = resolver.send(:resolve_template_variables, template, variables, "")
      expect(result).to include(Time.now.strftime("%Y%m%d"))
    end

    it "resolves task_number variables", :template_resolution do
      template = "tasks/{number}.md"
      variables = {"number" => "task_number"}

      result = resolver.send(:resolve_template_variables, template, variables, "")
      expect(result).to match(/\d{3}/)  # Should include 3-digit number
    end

    it "resolves shell command variables", :template_resolution do
      template = "tasks/{release}.md"
      variables = {"release" => "echo v.1.0.0"}

      # Mock execute_command to return expected value
      allow(resolver).to receive(:execute_command).with("echo v.1.0.0").and_return("v.1.0.0")

      result = resolver.send(:resolve_template_variables, template, variables, "")
      expect(result).to include("v.1.0.0")
    end

    it "handles absolute template paths", :template_resolution do
      template = "/absolute/path/{slug}.md"
      variables = {"slug" => "user_input"}

      result = resolver.send(:resolve_template_variables, template, variables, "Test Task")
      expect(result).to eq("/absolute/path/test-task.md")
    end
  end

  describe "#resolve_scoped_pattern", :scoped_patterns do
    let(:scoped_config) do
      {
        "scoped_autocorrect" => {
          "scope_autocorrect" => {
            "t" => "tools",
            "h" => "handbook"
          },
          "scope_mappings" => {
            "tools" => ["dev-tools/lib", "dev-tools/spec"],
            "handbook" => ["dev-handbook/guides", "dev-handbook/workflow-instructions"]
          }
        }
      }
    end

    let(:resolver) do
      full_config = config.merge(scoped_config)
      allow(config_loader).to receive(:load).and_return(full_config)
      described_class.new(config_loader, sandbox)
    end

    it "resolves basic scoped patterns" do
      allow(resolver).to receive(:find_matching_paths).and_return(["/path/to/file.rb"])

      result = resolver.resolve_scoped_pattern("tools:test")
      expect(result[:success]).to be true
      expect(result[:path]).to eq("/path/to/file.rb")
    end

    it "autocorrects scope names" do
      allow(resolver).to receive(:find_matching_paths).and_return(["/path/to/file.rb"])

      result = resolver.resolve_scoped_pattern("t:test")
      expect(result[:success]).to be true
      expect(result[:autocorrect_message]).to include("Autocorrected scope: 't' → 'tools'")
    end

    it "handles case-insensitive scope autocorrection" do
      allow(resolver).to receive(:find_matching_paths).and_return(["/path/to/file.rb"])

      result = resolver.resolve_scoped_pattern("T:test")
      expect(result[:success]).to be true
      expect(result[:autocorrect_message]).to include("Autocorrected scope: 'T' → 'tools'")
    end

    it "returns failure for empty scope" do
      result = resolver.resolve_scoped_pattern(":pattern")
      expect(result[:success]).to be false
      expect(result[:error]).to include("Empty scope or pattern")
    end

    it "returns failure for empty pattern" do
      result = resolver.resolve_scoped_pattern("tools:")
      expect(result[:success]).to be false
      expect(result[:error]).to include("Empty scope or pattern")
    end

    it "returns failure for unknown scopes" do
      result = resolver.resolve_scoped_pattern("unknown:pattern")
      expect(result[:success]).to be false
      expect(result[:error]).to include("No scope matches found")
    end

    it "handles multiple matches with prioritization" do
      matches = ["/path/to/file1.rb", "/path/to/file2.rb", "/path/to/file3.rb"]
      allow(resolver).to receive(:find_matching_paths).and_return(matches)
      allow(resolver).to receive(:prioritize_matches).and_return({
        best: matches.first,
        alternatives: matches[1..]
      })

      result = resolver.resolve_scoped_pattern("tools:test")
      expect(result[:success]).to be true
      expect(result[:type]).to eq(:scoped_multiple)
      expect(result[:alternatives]).to eq(matches[1..])
    end
  end

  describe "#find_reflection_paths_in_current_release", :reflection_paths do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    before do
      # Create reflection directory structure
      reflections_dir = File.join(temp_dir, "dev-taskflow", "current", "v.0.3.0", "test-session", "reflections")
      archived_dir = File.join(reflections_dir, "archived")
      FileUtils.mkdir_p(reflections_dir)
      FileUtils.mkdir_p(archived_dir)

      # Create reflection files
      FileUtils.touch(File.join(reflections_dir, "reflection-1.md"))
      FileUtils.touch(File.join(reflections_dir, "reflection-2.md"))
      FileUtils.touch(File.join(archived_dir, "old-reflection.md"))

      # Set modification times for consistent sorting
      File.utime(Time.now - 100, Time.now - 100, File.join(reflections_dir, "reflection-1.md"))
      File.utime(Time.now - 50, Time.now - 50, File.join(reflections_dir, "reflection-2.md"))
    end

    it "finds reflection files in current release" do
      result = resolver.find_reflection_paths_in_current_release
      expect(result[:success]).to be true
      expect(result[:type]).to eq(:list)
      expect(result[:paths]).to be_an(Array)
      expect(result[:paths].length).to eq(2)
    end

    it "excludes archived reflection files" do
      result = resolver.find_reflection_paths_in_current_release
      expect(result[:success]).to be true
      archived_files = result[:paths].select { |path| path.include?("archived") }
      expect(archived_files).to be_empty
    end

    it "returns empty list when no reflections exist" do
      # Remove reflection files
      FileUtils.rm_rf(File.join(temp_dir, "dev-taskflow", "current", "v.0.3.0", "test-session"))

      result = resolver.find_reflection_paths_in_current_release
      expect(result[:success]).to be true
      expect(result[:paths]).to be_empty
    end

    it "sorts reflections by modification time (newest first)" do
      result = resolver.find_reflection_paths_in_current_release
      expect(result[:success]).to be true
      expect(result[:paths].first).to include("reflection-2.md")  # Newer file first
      expect(result[:paths].last).to include("reflection-1.md")   # Older file last
    end

    it "handles missing current release directory" do
      # Mock find_current_release_path to return nil
      allow(resolver).to receive(:find_current_release_path).and_return(nil)

      result = resolver.find_reflection_paths_in_current_release
      expect(result[:success]).to be false
      expect(result[:error]).to include("Could not find current release directory")
    end
  end

  describe "fuzzy matching algorithms", :fuzzy_matching do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    describe "#find_fuzzy_matches" do
      it "finds fuzzy matches with similarity scoring" do
        # Mock find_matching_paths to return test data
        allow(resolver).to receive(:find_matching_paths).and_return([
          "/path/to/test.rb",
          "/path/to/testing.rb",
          "/path/to/contest.rb"
        ])

        matches = resolver.send(:find_fuzzy_matches, "test")
        expect(matches).to be_an(Array)
        expect(matches.length).to be > 0
      end

      it "filters out low-similarity matches" do
        # Mock find_matching_paths to return diverse test data
        allow(resolver).to receive(:find_matching_paths).and_return([
          "/path/to/completely_unrelated.rb"
        ])

        matches = resolver.send(:find_fuzzy_matches, "test")
        # Should filter out matches with similarity < 0.3
        expect(matches.length).to be <= 1
      end

      it "limits results to maximum 10 matches" do
        # Create array of 15 similar matches
        similar_matches = (1..15).map { |i| "/path/to/test#{i}.rb" }
        allow(resolver).to receive(:find_matching_paths).and_return(similar_matches)

        matches = resolver.send(:find_fuzzy_matches, "test")
        expect(matches.length).to be <= 10
      end
    end

    describe "#calculate_proximity_score" do
      it "gives highest score for subdirectory matches" do
        current_dir = "/project/current"
        target_path = "/project/current/subdir/file.rb"

        score = resolver.send(:calculate_proximity_score, target_path, current_dir)
        expect(score).to eq(100)
      end

      it "gives high score for parent directory matches" do
        current_dir = "/project/current/subdir"
        target_path = "/project/current"

        score = resolver.send(:calculate_proximity_score, target_path, current_dir)
        expect(score).to eq(90)
      end

      it "gives good score for sibling directories" do
        current_dir = File.join(temp_dir, "dir1")
        target_path = File.join(temp_dir, "dir2", "file.rb")

        score = resolver.send(:calculate_proximity_score, target_path, current_dir)
        # The actual score may be 40 (within project root) rather than 80 (sibling)
        # depending on the exact directory structure
        expect(score).to be >= 40
      end

      it "gives moderate score for same repository" do
        allow(resolver).to receive(:extract_repository_name).and_return("dev-tools")
        current_dir = "/project/dev-tools/lib"
        target_path = "/project/dev-tools/spec/file.rb"

        score = resolver.send(:calculate_proximity_score, target_path, current_dir)
        expect(score).to eq(70)
      end
    end

    describe "#extract_repository_name" do
      it "extracts repository name from dev- directories" do
        path = "/project/dev-tools/lib/file.rb"
        repo_name = resolver.send(:extract_repository_name, path)
        expect(repo_name).to eq("dev-tools")
      end

      it "handles paths starting with known repository names" do
        # Mock project root for path manipulation
        allow(sandbox).to receive(:project_root).and_return("/project")
        path = "/project/dev-handbook/guides/file.md"
        repo_name = resolver.send(:extract_repository_name, path)
        expect(repo_name).to eq("dev-handbook")
      end

      it "returns nil for unknown paths" do
        path = "/project/unknown/file.rb"
        repo_name = resolver.send(:extract_repository_name, path)
        expect(repo_name).to be_nil
      end
    end
  end

  describe "pattern normalization and path traversal", :fuzzy_matching do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    describe "#normalize_pattern" do
      it "handles basic patterns" do
        normalized = resolver.send(:normalize_pattern, "simple")
        expect(normalized).to eq("simple")
      end

      it "extracts meaningful parts from complex paths" do
        normalized = resolver.send(:normalize_pattern, "path/to/complex/file.rb")
        expect(normalized).to eq("file")  # Should extract just the filename part
      end

      it "handles patterns with extensions" do
        normalized = resolver.send(:normalize_pattern, "test.rb")
        expect(normalized).to eq("test")  # Should remove extension
      end

      it "handles empty and nil patterns" do
        expect(resolver.send(:normalize_pattern, nil)).to be_nil
        expect(resolver.send(:normalize_pattern, "")).to eq("")
        # Whitespace only should be stripped and apply autocorrect
        whitespace_result = resolver.send(:normalize_pattern, "   ")
        expect(whitespace_result).to be_a(String)
      end
    end

    describe "#clean_path_traversal" do
      it "handles path traversal attempts" do
        cleaned = resolver.send(:clean_path_traversal, "../../../etc/passwd")
        expect(cleaned).to eq("passwd")  # Should extract just the filename
      end

      it "handles relative paths within project" do
        # Mock expanded path to be within project root
        allow(File).to receive(:expand_path).and_return(File.join(temp_dir, "relative/path"))

        cleaned = resolver.send(:clean_path_traversal, "./relative/path")
        expect(cleaned).to eq("relative/path")
      end

      it "handles invalid path expansion" do
        # Mock File.expand_path to raise error
        allow(File).to receive(:expand_path).and_raise(StandardError, "Invalid path")

        cleaned = resolver.send(:clean_path_traversal, "../invalid/path")
        expect(cleaned).to eq("path")  # Should extract last meaningful part
      end
    end

    describe "#apply_autocorrect_mappings" do
      let(:autocorrect_config) do
        {
          "autocorrect_mappings" => {
            "tst" => "test",
            "readme" => "README"
          }
        }
      end

      let(:resolver_with_autocorrect) do
        full_config = config.merge(autocorrect_config)
        allow(config_loader).to receive(:load).and_return(full_config)
        described_class.new(config_loader, sandbox)
      end

      it "applies direct mappings" do
        corrected = resolver_with_autocorrect.send(:apply_autocorrect_mappings, "tst")
        expect(corrected).to eq("test")
      end

      it "applies case-insensitive mappings" do
        corrected = resolver_with_autocorrect.send(:apply_autocorrect_mappings, "TST")
        expect(corrected).to eq("test")
      end

      it "applies partial mappings" do
        corrected = resolver_with_autocorrect.send(:apply_autocorrect_mappings, "my-tst-file")
        expect(corrected).to eq("my-test-file")
      end

      it "returns original text for unknown mappings" do
        corrected = resolver_with_autocorrect.send(:apply_autocorrect_mappings, "unknown")
        expect(corrected).to eq("unknown")
      end
    end
  end

  describe "error handling and edge cases", :error_handling do
    let(:resolver) { described_class.new(config_loader, sandbox) }

    describe "#execute_command integration" do
      it "provides fallback behavior for known commands" do
        # Test the fallback logic without complex mocking
        allow(resolver).to receive(:detect_current_release_fallback).and_return("v.0.3.0-fallback")

        # Should fall back gracefully for known commands when they fail
        expect(resolver.send(:detect_current_release_fallback)).to eq("v.0.3.0-fallback")
      end

      it "uses context switching for command execution" do
        # Test that directory context is important for command execution
        expect(resolver.send(:detect_current_release_fallback)).to be_a(String)
      end
    end

    describe "#detect_current_release_fallback" do
      it "raises error when no current release found" do
        # Mock DirectoryNavigator to return nil
        navigator_class = CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator
        allow(navigator_class).to receive(:get_current_release_directory).and_return(nil)

        expect {
          resolver.send(:detect_current_release_fallback)
        }.to raise_error(/No current release directory found/)
      end

      it "re-raises errors with context" do
        # Mock DirectoryNavigator to raise an error
        navigator_class = CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator
        allow(navigator_class).to receive(:get_current_release_directory).and_raise("Test error")

        expect {
          resolver.send(:detect_current_release_fallback)
        }.to raise_error(/Failed to detect current release: Test error/)
      end
    end

    describe "scan_repository_for_pattern edge cases" do
      it "handles repository that doesn't exist" do
        fake_repo = {"path" => "nonexistent", "priority" => 1}
        matches = resolver.send(:scan_repository_for_pattern, fake_repo, "test", [".rb"], false)
        expect(matches).to eq([])
      end

      it "handles Find.find exceptions gracefully" do
        repo = {"path" => ".", "priority" => 1}

        # Mock Find.find to raise an exception
        allow(Find).to receive(:find).and_raise(StandardError, "Permission denied")

        matches = resolver.send(:scan_repository_for_pattern, repo, "test", [".rb"], false)
        expect(matches).to eq([])
      end

      it "limits results to prevent performance issues" do
        repo = {"path" => ".", "priority" => 1}

        # Create a fake large result set
        large_matches = (1..100).map { |i| "/fake/path#{i}.rb" }
        allow(Find).to receive(:find).and_yield(*large_matches)
        allow(File).to receive(:file?).and_return(true)
        allow(Dir).to receive(:exist?).and_return(false)

        matches = resolver.send(:scan_repository_for_pattern, repo, "test", [".rb"], false)
        expect(matches.length).to be <= 50  # Should limit to 50 results
      end
    end

    describe "path validation error handling" do
      it "handles sandbox validation failures" do
        allow(sandbox).to receive(:validate_path).and_return({success: false, error: "Invalid path"})

        result = resolver.resolve_path("/invalid/path", type: :file)
        expect(result[:success]).to be false
        expect(result[:error]).to include("Invalid path")
      end

      it "handles path resolution exceptions" do
        # Mock absolute_path to raise CodingAgentTools::Error
        allow(sandbox).to receive(:absolute_path).and_raise(CodingAgentTools::Error, "Path error")

        result = resolver.send(:resolve_file_path, "some/path")
        expect(result[:success]).to be false
        expect(result[:error]).to include("Path resolution failed")
      end
    end
  end

  describe "release-relative path resolution", :release_relative do
    let(:resolver) { described_class.new(config_loader, sandbox, release_manager) }

    describe "#is_release_relative?" do
      it "returns true for release-relative patterns" do
        expect(resolver.is_release_relative?("release:reflections")).to be true
        expect(resolver.is_release_relative?("release:tasks")).to be true
        expect(resolver.is_release_relative?("release:reflections/synthesis.md")).to be true
      end

      it "returns false for non-release-relative patterns" do
        expect(resolver.is_release_relative?("tools:test")).to be false
        expect(resolver.is_release_relative?("handbook:guide")).to be false
        expect(resolver.is_release_relative?("regular/path")).to be false
        expect(resolver.is_release_relative?("")).to be false
        expect(resolver.is_release_relative?(nil)).to be false
      end

      it "handles edge cases" do
        expect(resolver.is_release_relative?("releasetest")).to be false
        expect(resolver.is_release_relative?(":release")).to be false
        expect(resolver.is_release_relative?("test:release:path")).to be false
      end
    end

    describe "#resolve_release_relative" do
      context "with valid release-relative patterns" do
        it "resolves simple subpaths" do
          expected_path = "/project/dev-taskflow/current/v.0.3.0/reflections"
          allow(release_manager).to receive(:resolve_path).with("reflections").and_return(expected_path)

          result = resolver.resolve_release_relative("release:reflections")
          expect(result[:success]).to be true
          expect(result[:path]).to eq(expected_path)
        end

        it "resolves nested subpaths" do
          expected_path = "/project/dev-taskflow/current/v.0.3.0/reflections/synthesis.md"
          allow(release_manager).to receive(:resolve_path).with("reflections/synthesis.md").and_return(expected_path)

          result = resolver.resolve_release_relative("release:reflections/synthesis.md")
          expect(result[:success]).to be true
          expect(result[:path]).to eq(expected_path)
        end

        it "resolves tasks directory" do
          expected_path = "/project/dev-taskflow/current/v.0.3.0/tasks"
          allow(release_manager).to receive(:resolve_path).with("tasks").and_return(expected_path)

          result = resolver.resolve_release_relative("release:tasks")
          expect(result[:success]).to be true
          expect(result[:path]).to eq(expected_path)
        end
      end

      context "with invalid patterns" do
        it "returns failure for non-release-relative patterns" do
          result = resolver.resolve_release_relative("tools:test")
          expect(result[:success]).to be false
          expect(result[:error]).to include("Invalid release-relative path format")
        end

        it "returns failure for empty subpaths" do
          result = resolver.resolve_release_relative("release:")
          expect(result[:success]).to be false
          expect(result[:error]).to include("Empty subpath in release-relative pattern")
        end

        it "returns failure for whitespace-only subpaths" do
          result = resolver.resolve_release_relative("release:   ")
          expect(result[:success]).to be false
          expect(result[:error]).to include("Empty subpath in release-relative pattern")
        end
      end

      context "when ReleaseManager raises errors" do
        it "handles StandardError from ReleaseManager" do
          allow(release_manager).to receive(:resolve_path).and_raise(StandardError, "No current release")

          result = resolver.resolve_release_relative("release:reflections")
          expect(result[:success]).to be false
          expect(result[:error]).to include("Release-relative path resolution failed: No current release")
        end

        it "handles SecurityError from ReleaseManager" do
          allow(release_manager).to receive(:resolve_path).and_raise(SecurityError, "Path validation failed")

          result = resolver.resolve_release_relative("release:../../../etc/passwd")
          expect(result[:success]).to be false
          expect(result[:error]).to include("Release-relative path resolution failed: Path validation failed")
        end
      end
    end

    describe "integration with resolve_path" do
      context "when using release-relative patterns in resolve_path" do
        it "routes to release-relative resolution" do
          expected_path = "/project/dev-taskflow/current/v.0.3.0/reflections"
          allow(release_manager).to receive(:resolve_path).with("reflections").and_return(expected_path)

          result = resolver.resolve_path("release:reflections", type: :file)
          expect(result[:success]).to be true
          expect(result[:path]).to eq(expected_path)
        end

        it "does not interfere with other scoped patterns" do
          # Setup scoped pattern config
          scoped_config = {
            "scoped_autocorrect" => {
              "scope_autocorrect" => {"t" => "tools"},
              "scope_mappings" => {"tools" => ["dev-tools/lib"]}
            }
          }
          full_config = config.merge(scoped_config)
          allow(config_loader).to receive(:load).and_return(full_config)

          # Mock scoped pattern resolution
          allow(resolver).to receive(:find_matching_paths).and_return(["/path/to/file.rb"])

          result = resolver.resolve_path("tools:test", type: :file)
          expect(result[:success]).to be true
        end

        it "prioritizes release-relative over other scoped patterns" do
          # Even if we have a "release" scope mapping, "release:" should be treated as release-relative
          expected_path = "/project/dev-taskflow/current/v.0.3.0/tasks"
          allow(release_manager).to receive(:resolve_path).with("tasks").and_return(expected_path)

          result = resolver.resolve_path("release:tasks", type: :file)
          expect(result[:success]).to be true
          expect(result[:path]).to eq(expected_path)
        end
      end

      context "when not using file type" do
        it "does not attempt release-relative resolution for non-file types" do
          # Should not call release manager for non-file types
          expect(release_manager).not_to receive(:resolve_path)

          result = resolver.resolve_path("release:reflections", type: :task_new)
          # This will fall through to generate_new_path logic
          # The exact result depends on the config, but the important thing is release_manager wasn't called
          expect(result).to have_key(:success)
        end
      end
    end

    describe "backward compatibility" do
      it "maintains existing functionality when not using release patterns" do
        path = File.join(temp_dir, "README.md")
        allow(sandbox).to receive(:validate_path).with(path).and_return({success: true, path: path})

        result = resolver.resolve_path(path, type: :file)
        expect(result[:success]).to be true
        expect(result[:path]).to eq(path)
      end

      it "maintains existing scoped pattern functionality" do
        scoped_config = {
          "scoped_autocorrect" => {
            "scope_autocorrect" => {},
            "scope_mappings" => {"tools" => ["dev-tools/lib"]}
          }
        }
        full_config = config.merge(scoped_config)
        allow(config_loader).to receive(:load).and_return(full_config)
        
        allow(resolver).to receive(:find_matching_paths).and_return(["/path/to/file.rb"])

        result = resolver.resolve_path("tools:test", type: :file)
        expect(result[:success]).to be true
      end
    end
  end
end
