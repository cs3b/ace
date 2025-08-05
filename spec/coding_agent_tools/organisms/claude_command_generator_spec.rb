# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/claude_command_generator"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Organisms::ClaudeCommandGenerator do
  let(:tmpdir) { Dir.mktmpdir }
  let(:generator) { described_class.new(tmpdir) }

  before do
    # Create necessary directory structure
    FileUtils.mkdir_p(File.join(tmpdir, "dev-handbook/workflow-instructions"))
    FileUtils.mkdir_p(File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_custom"))
    FileUtils.mkdir_p(File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated"))
    FileUtils.mkdir_p(File.join(tmpdir, "dev-handbook/.integrations/claude"))
    FileUtils.mkdir_p(File.join(tmpdir, "dev-handbook/.integrations/claude/templates"))
    
    # Create template file
    template_path = File.join(tmpdir, "dev-handbook/.integrations/claude/templates/command.md.tmpl")
    File.write(template_path, <<~TEMPLATE)
      ---
      description: \#{description}
      \#{allowed_tools ? "allowed-tools: \#{allowed_tools}" : ""}
      \#{argument_hint ? "argument-hint: \"\#{argument_hint}\"" : ""}
      \#{model ? "model: \#{model}" : ""}
      ---

      read whole file and follow @dev-handbook/workflow-instructions/\#{workflow_name}.wf.md

      read and run @.claude/commands/commit.md
    TEMPLATE

    # Create some workflow files
    ["test-workflow", "another-workflow", "custom-workflow"].each do |workflow|
      File.write(
        File.join(tmpdir, "dev-handbook/workflow-instructions/#{workflow}.wf.md"),
        "# #{workflow} workflow content"
      )
    end

    # Create a custom command (should never be overwritten)
    File.write(
      File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_custom/custom-workflow.md"),
      "Custom command content"
    )
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe "#generate" do
    context "with dry-run" do
      it "does not create any files" do
        result = generator.generate(dry_run: true)
        
        expect(result.success).to be true
        expect(result.stats[:generated]).to eq(0)
        expect(result.stats[:skipped]).to eq(2) # test-workflow and another-workflow
        
        # Verify no files were created
        generated_dir = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated")
        expect(Dir.glob(File.join(generated_dir, "*.md"))).to be_empty
      end
    end

    context "without dry-run" do
      it "creates missing command files" do
        result = generator.generate
        
        expect(result.success).to be true
        expect(result.stats[:generated]).to eq(2)
        expect(result.stats[:errors]).to be_empty
        
        # Verify files were created with correct content
        test_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/test-workflow.md")
        expect(File.exist?(test_file)).to be true
        content = File.read(test_file)
        expect(content).to include("@dev-handbook/workflow-instructions/test-workflow.wf.md")
        expect(content).to include("@.claude/commands/commit.md")
        expect(content).to include("---")
        expect(content).to include("description: Test Workflow")
      end

      it "skips existing generated commands by default" do
        # Create an existing generated command
        existing_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/test-workflow.md")
        File.write(existing_file, "Existing content")
        
        result = generator.generate
        
        expect(result.stats[:generated]).to eq(1) # Only another-workflow
        expect(result.stats[:skipped]).to eq(2) # test-workflow (existing generated) + custom-workflow (custom)
        expect(File.read(existing_file)).to eq("Existing content") # Not overwritten
      end

      it "overwrites existing generated commands with --force" do
        # Create an existing generated command
        existing_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/test-workflow.md")
        File.write(existing_file, "Old content")
        
        result = generator.generate(force: true)
        
        expect(result.stats[:generated]).to eq(2)
        expect(File.read(existing_file)).to include("@dev-handbook/workflow-instructions/test-workflow.wf.md")
      end

      it "never overwrites custom commands even with --force" do
        custom_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_custom/custom-workflow.md")
        
        result = generator.generate(force: true)
        
        expect(result.stats[:generated]).to eq(2) # Only test-workflow and another-workflow
        expect(File.read(custom_file)).to eq("Custom command content") # Unchanged
      end
    end

    context "with specific workflow" do
      it "generates only the specified workflow" do
        result = generator.generate(workflow: "test-workflow")
        
        expect(result.stats[:generated]).to eq(1)
        expect(result.missing_workflows).to eq(["test-workflow"])
        
        test_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/test-workflow.md")
        another_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/another-workflow.md")
        
        expect(File.exist?(test_file)).to be true
        expect(File.exist?(another_file)).to be false
      end

      it "supports glob patterns" do
        result = generator.generate(workflow: "*-workflow")
        
        expect(result.stats[:generated]).to eq(2)
        expect(result.missing_workflows).to match_array(["test-workflow", "another-workflow"])
      end

      it "returns empty result for non-existent workflow" do
        result = generator.generate(workflow: "non-existent")
        
        expect(result.success).to be true
        expect(result.stats[:generated]).to eq(0)
        expect(result.missing_workflows).to be_empty
      end
    end

    context "error handling" do
      it "handles missing template gracefully" do
        # Remove template file
        template_path = File.join(tmpdir, "dev-handbook/.integrations/claude/templates/command.md.tmpl")
        FileUtils.rm(template_path)
        
        result = generator.generate
        
        # Should still work with fallback template
        expect(result.success).to be true
        expect(result.stats[:generated]).to eq(2)
      end

      it "handles missing workflow directory" do
        # Remove workflow directory
        FileUtils.rm_rf(File.join(tmpdir, "dev-handbook/workflow-instructions"))
        
        result = generator.generate
        
        expect(result.success).to be true
        expect(result.stats[:generated]).to eq(0)
        expect(result.missing_workflows).to be_empty
      end
    end
  end

  describe "#generate_command_content" do
    it "includes YAML front-matter" do
      # Create capture-idea workflow
      File.write(
        File.join(tmpdir, "dev-handbook/workflow-instructions/capture-idea.wf.md"),
        "# capture-idea workflow content"
      )
      
      result = generator.generate(workflow: "capture-idea")
      
      expect(result.stats[:generated]).to eq(1)
      content_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/capture-idea.md")
      content = File.read(content_file)
      expect(content).to start_with("---")
      expect(content).to include("description: Capture Idea")
    end

    it "adds allowed-tools for git workflows" do
      # Create git-commit workflow
      File.write(
        File.join(tmpdir, "dev-handbook/workflow-instructions/git-commit.wf.md"),
        "# git-commit workflow content"
      )
      
      result = generator.generate(workflow: "git-commit")
      
      expect(result.stats[:generated]).to eq(1)
      content_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/git-commit.md")
      content = File.read(content_file)
      expect(content).to include("allowed-tools: Bash(git *), Read, Write")
    end

    it "adds argument-hint for parameterized workflows" do
      # Create work-on-task workflow
      File.write(
        File.join(tmpdir, "dev-handbook/workflow-instructions/work-on-task.wf.md"),
        "# work-on-task workflow content"
      )
      
      result = generator.generate(workflow: "work-on-task")
      
      expect(result.stats[:generated]).to eq(1)
      content_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/work-on-task.md")
      content = File.read(content_file)
      expect(content).to include('argument-hint: "[task-id]"')
    end

    it "generates valid YAML" do
      result = generator.generate(workflow: "test-workflow")
      
      expect(result.stats[:generated]).to eq(1)
      content_file = File.join(tmpdir, "dev-handbook/.integrations/claude/commands/_generated/test-workflow.md")
      content = File.read(content_file)
      
      # Extract YAML front-matter
      yaml_match = content.match(/\A---\n(.*?)\n---/m)
      expect(yaml_match).not_to be_nil
      
      # Should be valid YAML
      expect { YAML.safe_load(yaml_match[1]) }.not_to raise_error
    end
  end

  describe "#initialize" do
    it "finds project root based on dev-handbook directory" do
      # Create a nested structure
      nested_dir = File.join(tmpdir, "some/nested/path")
      FileUtils.mkdir_p(nested_dir)
      FileUtils.mkdir_p(File.join(tmpdir, "dev-handbook"))
      
      Dir.chdir(nested_dir) do
        generator = described_class.new
        expect(generator.workflow_dir.to_s).to include(tmpdir)
      end
    end

    it "uses current directory if dev-handbook not found" do
      Dir.mktmpdir do |empty_dir|
        Dir.chdir(empty_dir) do
          generator = described_class.new
          expect(generator.workflow_dir.to_s).to include(empty_dir)
        end
      end
    end
  end
end