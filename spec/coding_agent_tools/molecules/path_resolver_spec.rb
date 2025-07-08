# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::PathResolver do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_loader) { instance_double(CodingAgentTools::Molecules::PathConfigLoader) }
  let(:sandbox) { instance_double(CodingAgentTools::Molecules::ProjectSandbox) }
  let(:config) do
    {
      "repositories" => {
        "scan_order" => [
          { "name" => "tools-meta", "path" => ".", "priority" => 1 },
          { "name" => "dev-tools", "path" => "dev-tools", "priority" => 2 }
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
    allow(sandbox).to receive(:validate_path).and_return({ success: true, path: "/valid/path" })
    allow(sandbox).to receive(:absolute_path).and_return(File.join(temp_dir, "README.md"))
  end

  after do
    FileUtils.remove_entry(temp_dir)
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
        allow(sandbox).to receive(:validate_path).with(path).and_return({ success: true, path: path })
        
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
        allow(sandbox).to receive(:validate_path).with(expected_path).and_return({ success: true, path: expected_path })

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
      allow(sandbox).to receive(:validate_path).and_return({ success: true, path: "/valid/path" })
      
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
      # Create a new resolver instance to test the actual execute_command method
      real_resolver = described_class.new(config_loader, sandbox)
      
      # Mock the backtick execution to simulate command failure
      allow(real_resolver).to receive(:`).with("release-manager current 2>/dev/null").and_return("")
      
      # Mock the $? global variable properly
      process_status = double("Process::Status")
      allow(process_status).to receive(:exitstatus).and_return(1)
      allow(real_resolver).to receive(:$?).and_return(process_status)
      
      # Should fall back to default values for known commands
      fallback_result = real_resolver.send(:execute_command, "release-manager current")
      expect(fallback_result).to eq("v.0.3.0-migration")
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
      variables = { "slug" => "user_input" }
      
      result = resolver.send(:resolve_template_variables, template, variables, "Test Task")
      expect(result).to include("test-task")
    end

    it "resolves datetime variables" do
      template = "logs/{timestamp}.log"
      variables = { "timestamp" => "datetime:%Y%m%d" }
      
      result = resolver.send(:resolve_template_variables, template, variables, "")
      expect(result).to include(Time.now.strftime("%Y%m%d"))
    end
  end
end