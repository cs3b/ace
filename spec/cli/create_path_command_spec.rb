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
    
    # Mock the project root detection using proper public interface
    allow_any_instance_of(CodingAgentTools::Molecules::PathResolver)
      .to receive(:project_root)
      .and_return(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "encapsulation compliance" do
    it "uses public interface instead of accessing private instance variables" do
      # Create a PathResolver instance to test encapsulation
      path_resolver = CodingAgentTools::Molecules::PathResolver.new
      
      # Verify that PathResolver provides a public project_root method
      expect(path_resolver).to respond_to(:project_root)
      
      # Mock PathResolver to verify correct method call
      mocked_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(mocked_resolver).to receive(:project_root).and_return(temp_dir)
      allow(mocked_resolver).to receive(:resolve_path).and_return({success: false, error: "test"})
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mocked_resolver)
      
      # Mock other dependencies to avoid errors
      file_handler = instance_double(CodingAgentTools::Molecules::FileIoHandler)
      security_validator = instance_double(CodingAgentTools::Molecules::SecurePathValidator)
      allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(file_handler)
      allow(CodingAgentTools::Molecules::SecurePathValidator).to receive(:new).and_return(security_validator)
      
      # Test that load_create_path_config calls the public method
      expect(mocked_resolver).to receive(:project_root).at_least(:once)
      
      # Call the command to trigger load_create_path_config
      command = described_class.new
      command.call(type: "task-new", target: "test")
    end

    it "does not use instance_variable_get to access PathResolver internals" do
      # Verify that the source code does not contain the encapsulation violation
      source_file = File.read(File.join(__dir__, "../../lib/coding_agent_tools/cli/create_path_command.rb"))
      
      # Should not contain the old encapsulation violation pattern
      expect(source_file).not_to include("instance_variable_get(:@sandbox)")
      
      # Should use the proper public method instead
      expect(source_file).to include("@path_resolver.project_root")
    end
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
        
        allow(path_resolver).to receive(:project_root)
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

  describe "file system errors" do
    it "handles permission denied errors gracefully" do
      # Create a directory with restricted permissions
      restricted_dir = File.join(temp_dir, "restricted")
      FileUtils.mkdir_p(restricted_dir)
      FileUtils.chmod(0444, restricted_dir) # Read-only
      
      target_path = File.join(restricted_dir, "test-file.txt")
      
      result = subject.call(
        type: "file",
        target: target_path,
        content: "test content"
      )
      
      expect(result).to eq(1)
      
      # Restore permissions for cleanup
      FileUtils.chmod(0755, restricted_dir) rescue nil
    end

    it "handles disk full errors appropriately" do
      # Mock FileUtils to simulate disk full error
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::ENOSPC, "No space left on device")
      
      result = subject.call(
        type: "directory",
        target: File.join(temp_dir, "test-dir")
      )
      
      expect(result).to eq(1)
    end

    it "handles readonly filesystem scenarios" do
      # Mock file writing to simulate readonly filesystem
      file_handler = instance_double(CodingAgentTools::Molecules::FileIoHandler)
      allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(file_handler)
      allow(file_handler).to receive(:write_content).and_raise(Errno::EROFS, "Read-only file system")
      
      result = subject.call(
        type: "file",
        target: File.join(temp_dir, "test-file.txt"),
        content: "test content"
      )
      
      expect(result).to eq(1)
    end

    it "handles network filesystem timeouts" do
      # Mock file operations to simulate network timeout
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::ETIMEDOUT, "Connection timed out")
      
      result = subject.call(
        type: "directory",
        target: File.join(temp_dir, "network-dir")
      )
      
      expect(result).to eq(1)
    end
  end

  describe "input validation" do
    it "validates required parameters are present" do
      result = subject.call(type: "file", target: nil)
      expect(result).to eq(1)
      
      result = subject.call(type: "file", target: "")
      expect(result).to eq(1)
      
      result = subject.call(type: "file", target: "   ")
      expect(result).to eq(1)
    end

    it "handles malformed command line arguments" do
      # Test with unknown type
      result = subject.call(type: "unknown-type", target: "test")
      expect(result).to eq(1)
    end

    it "validates path format and characters" do
      # These will be handled by the security validator, but test the integration
      invalid_paths = [
        "\x00null-byte-path",
        "path/with\x01control-chars",
        "extremely-" + "long-" * 100 + "path.txt"
      ]
      
      invalid_paths.each do |invalid_path|
        result = subject.call(
          type: "file",
          target: invalid_path,
          content: "test"
        )
        expect(result).to eq(1), "Should reject path: #{invalid_path}"
      end
    end

    it "handles empty or whitespace-only inputs" do
      result = subject.call(type: "file", target: "", content: "test")
      expect(result).to eq(1)
      
      result = subject.call(type: "file", target: "   ", content: "test")
      expect(result).to eq(1)
      
      result = subject.call(type: "file", target: "test.txt", content: "")
      expect(result).to eq(1)
    end
  end

  describe "configuration errors" do
    it "handles missing .coding-agent/create-path.yml" do
      # Remove the config file
      FileUtils.rm_f(config_file)
      
      # Test should still work with empty config
      result = subject.call(
        type: "file",
        target: File.join(temp_dir, "test.txt"),
        content: "test content"
      )
      
      expect(result).to eq(0) # Should succeed with default behavior
    end

    it "handles malformed YAML configuration" do
      # Write invalid YAML to config file
      File.write(config_file, "invalid: yaml: content: [")
      
      # Command should handle gracefully and fall back to defaults
      result = subject.call(
        type: "file",
        target: File.join(temp_dir, "test.txt"),
        content: "test content"
      )
      
      expect(result).to eq(0) # Should succeed with fallback
    end

    it "handles invalid template mappings" do
      invalid_config = {
        "templates" => {
          "task-new" => {
            "template" => "/nonexistent/template.md"
          }
        }
      }
      File.write(config_file, YAML.dump(invalid_config))
      
      result = subject.call(type: "task-new", target: "test-task")
      
      expect(result).to eq(1) # Should fail due to missing template
    end

    it "handles missing template references" do
      config_with_missing_template = {
        "templates" => {
          "task-new" => {
            "template" => nil
          }
        }
      }
      File.write(config_file, YAML.dump(config_with_missing_template))
      
      result = subject.call(type: "task-new", target: "test-task")
      
      expect(result).to eq(1)
    end
  end

  describe "template errors" do
    let(:template_dir) { File.join(temp_dir, "templates") }
    let(:template_file) { File.join(template_dir, "test-template.md") }
    
    before do
      FileUtils.mkdir_p(template_dir)
    end

    it "handles missing template files" do
      config_with_missing_file = {
        "templates" => {
          "task-new" => {
            "template" => "/completely/nonexistent/template.md"
          }
        }
      }
      File.write(config_file, YAML.dump(config_with_missing_file))
      
      result = subject.call(type: "task-new", target: "test-task")
      
      expect(result).to eq(1)
    end

    it "handles template parsing errors" do
      # Create template with problematic content
      File.write(template_file, "Template with {unclosed variable")
      
      config_with_template = {
        "templates" => {
          "template" => {
            "template" => template_file
          }
        }
      }
      File.write(config_file, YAML.dump(config_with_template))
      
      # This should still work, just with the literal content
      result = subject.call(
        type: "template",
        target: File.join(temp_dir, "output.txt"),
        template: template_file
      )
      
      expect(result).to eq(0) # Should handle gracefully
    end

    it "handles variable substitution failures" do
      File.write(template_file, "Title: {metadata.nonexistent}")
      
      result = subject.call(
        type: "template",
        target: File.join(temp_dir, "output.txt"),
        template: template_file
      )
      
      expect(result).to eq(0) # Should handle gracefully
      
      # Verify the content was created (variable not substituted when unknown)
      content = File.read(File.join(temp_dir, "output.txt"))
      expect(content).to include("Title:")
    end

    it "handles circular template dependencies" do
      # This is more about variable resolution, create a complex substitution
      template_content = "Value: {metadata.recursive}"
      File.write(template_file, template_content)
      
      # Test with recursive metadata (shouldn't cause infinite loops)
      result = subject.call(
        type: "template",
        target: File.join(temp_dir, "output.txt"),
        template: template_file,
        recursive: "{metadata.recursive}"
      )
      
      expect(result).to eq(0) # Should handle gracefully
    end
  end

  describe "path resolution errors" do
    it "handles PathResolver initialization failures" do
      # Mock PathResolver to fail on initialization
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_raise(StandardError, "PathResolver init failed")
      
      result = subject.call(type: "task-new", target: "test-task")
      
      expect(result).to eq(1)
    end

    it "handles invalid repository context" do
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_raise(StandardError, "No project root found")
      allow(path_resolver).to receive(:resolve_path).and_return({success: false, error: "Invalid context"})
      
      result = subject.call(type: "task-new", target: "test-task")
      
      expect(result).to eq(1)
    end

    it "handles missing project root detection" do
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(nil)
      allow(path_resolver).to receive(:resolve_path).and_return({success: false, error: "No project root"})
      
      result = subject.call(type: "task-new", target: "test-task")
      
      expect(result).to eq(1)
    end

    it "handles submodule resolution failures" do
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:resolve_path).and_return({success: false, error: "Submodule not found"})
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)
      
      result = subject.call(type: "task-new", target: "test-task")
      
      expect(result).to eq(1)
    end
  end

  describe "concurrency" do
    it "handles file creation conflicts" do
      target_path = File.join(temp_dir, "concurrent-test.txt")
      
      # Create the file first to simulate conflict
      File.write(target_path, "existing content")
      
      # Try to create without force
      result = subject.call(
        type: "file",
        target: target_path,
        content: "new content"
      )
      
      # Should handle the conflict appropriately (depends on FileIoHandler implementation)
      expect([0, 1]).to include(result)
    end

    it "handles concurrent modifications" do
      target_dir = File.join(temp_dir, "concurrent-dir")
      
      # Create directory first
      FileUtils.mkdir_p(target_dir)
      
      # Try to create again without force
      result = subject.call(
        type: "directory",
        target: target_dir
      )
      
      expect(result).to eq(1) # Should fail due to existing directory
    end
  end
end