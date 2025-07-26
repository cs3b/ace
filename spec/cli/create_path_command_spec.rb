# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "yaml"
require_relative "../../lib/coding_agent_tools/cli/create_path_command"

RSpec.describe CodingAgentTools::Cli::CreatePathCommand do
  subject { described_class.new }

  let(:temp_dir) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_dir, ".coding-agent") }
  let(:config_file) { File.join(config_dir, "create-path.yml") }

  before do
    FileUtils.mkdir_p(config_dir)
    
    # Create basic config
    config = {
      "templates" => {
        "file" => {},
        "directory" => {"type" => "directory"}
      },
      "variable_processors" => {
        "defaults" => {
          "priority" => "medium",
          "status" => "pending"
        }
      }
    }
    
    File.write(config_file, YAML.dump(config))
    
    # Mock the project root detection
    allow_any_instance_of(CodingAgentTools::Molecules::PathResolver)
      .to receive_message_chain(:instance_variable_get, :project_root)
      .and_return(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "security validation" do
    context "when attempting path traversal" do
      it "blocks path traversal attempts" do
        result = subject.call(type: "file", target: "../../../etc/passwd", content: "malicious")
        
        expect(result).to eq(1)
      end

      it "blocks access to forbidden patterns" do
        result = subject.call(type: "file", target: ".git/config", content: "test")
        
        expect(result).to eq(1)
      end
    end

    context "when using valid paths" do
      it "allows creation in safe directories" do
        safe_path = File.join(temp_dir, "safe-file.txt")
        
        result = subject.call(
          type: "file", 
          target: safe_path, 
          content: "safe content"
        )
        
        expect(result).to eq(0)
        expect(File.exist?(safe_path)).to be true
        expect(File.read(safe_path)).to eq("safe content")
      end
    end

    context "command injection protection" do
      it "prevents command injection in template variable commands" do
        command = described_class.new
        
        # Mock config that has a malicious command
        malicious_source = "date; rm -rf /"
        
        # Test that execute_command safely handles malicious input
        result = command.send(:execute_command, malicious_source)
        
        # Should return "unknown" instead of executing malicious command
        expect(result).to eq("unknown")
      end

      it "safely handles shell metacharacters in commands" do
        command = described_class.new
        
        # Test various shell metacharacters
        dangerous_commands = [
          "echo test; rm -rf /",
          "echo test && rm -rf /",
          "echo test | rm -rf /",
          "echo test$(rm -rf /)",
          "echo test`rm -rf /`",
          "echo test > /etc/passwd"
        ]
        
        dangerous_commands.each do |dangerous_cmd|
          result = command.send(:execute_command, dangerous_cmd)
          # All should return "unknown" instead of executing
          expect(result).to eq("unknown"), "Failed for command: #{dangerous_cmd}"
        end
      end

      it "handles invalid commands gracefully" do
        command = described_class.new
        
        # Test non-existent commands
        result = command.send(:execute_command, "nonexistent_command_12345")
        expect(result).to eq("unknown")
      end

      it "allows safe commands to execute properly" do
        command = described_class.new
        
        # Test a safe command that should work
        result = command.send(:execute_command, "echo safe_test")
        expect(result).to eq("safe_test")
      end

      it "prevents command injection via file paths in template variables" do
        command = described_class.new
        
        # Mock the config loader
        allow(command).to receive(:load_create_path_config).and_return({})
        
        # Test template with malicious command in metadata
        template_content = "Value: {variable}"
        metadata = {"title" => "test"}
        template_variables = {"variable" => "echo test; rm -rf /"}
        
        result = command.send(:apply_variable_substitution, template_content, "test", {}, template_variables)
        
        # Should contain "unknown" instead of executing the command
        expect(result).to include("unknown")
        expect(result).not_to include("rm -rf")
      end
    end
  end

  describe "path resolution" do
    context "when using PathResolver integration" do
      let(:path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }

      before do
        allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      end

      it "delegates path generation to PathResolver" do
        expected_path = File.join(temp_dir, "generated-task.md")
        
        allow(path_resolver).to receive(:resolve_path)
          .with("test-task", type: :task_new)
          .and_return({success: true, path: expected_path})
        
        allow(path_resolver).to receive_message_chain(:instance_variable_get, :project_root)
          .and_return(temp_dir)

        # Mock file reading for template
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(nil).and_return(false)
        allow(File).to receive(:read).and_call_original

        result = subject.call(
          type: "task-new",
          target: "test-task",
          priority: "high"
        )

        expect(path_resolver).to have_received(:resolve_path).with("test-task", type: :task_new)
      end
    end
  end

  describe "content injection" do
    context "when creating files with direct content" do
      it "creates files with correct content from various sources" do
        target_path = File.join(temp_dir, "content-test.txt")
        test_content = "This is test content"

        result = subject.call(
          type: "file",
          target: target_path,
          content: test_content
        )

        expect(result).to eq(0)
        expect(File.exist?(target_path)).to be true
        expect(File.read(target_path)).to eq(test_content)
      end
    end

    context "when creating directories" do
      it "creates directories successfully" do
        target_path = File.join(temp_dir, "test-directory")

        result = subject.call(
          type: "directory",
          target: target_path
        )

        expect(result).to eq(0)
        expect(Dir.exist?(target_path)).to be true
      end
    end
  end

  describe "variable substitution" do
    it "applies metadata to template variables" do
      command = described_class.new
      
      # Mock the config loader to avoid nil error
      allow(command).to receive(:load_create_path_config).and_return({
        "variable_processors" => {
          "defaults" => {
            "priority" => "medium",
            "status" => "pending"
          }
        }
      })
      
      template_content = "Priority: {metadata.priority}\nTitle: {metadata.title}"
      options = {priority: "high"}
      
      result = command.send(:apply_variable_substitution, template_content, "Test Title", options)
      
      expect(result).to include("Priority: high")
      expect(result).to include("Title: Test Title")
    end

    it "applies built-in timestamp variables" do
      command = described_class.new
      
      template_content = "Created: {timestamp}\nDate: {date}"
      
      result = command.send(:apply_built_in_variables, template_content)
      
      expect(result).to match(/Created: \d{8}-\d{6}/)
      expect(result).to match(/Date: \d{4}-\d{2}-\d{2}/)
    end
  end
end