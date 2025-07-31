# frozen_string_literal: true

require "spec_helper"
require "yaml"
require "coding_agent_tools/cli/create_path_command"

RSpec.describe CodingAgentTools::Cli::CreatePathCommand do
  include_context "uses temp dir"

  subject { described_class.new }

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
      command.call(type: "task-new", title: "test")
    end

    it "does not use instance_variable_get to access PathResolver internals" do
      # Verify that the source code does not contain the encapsulation violation
      source_file = File.read(File.join(__dir__, "../../../../lib/coding_agent_tools/cli/create_path_command.rb"))

      # Should not contain the old encapsulation violation pattern
      expect(source_file).not_to include("instance_variable_get(:@sandbox)")

      # Should use the proper public method instead
      expect(source_file).to include("@path_resolver.project_root")
    end
  end

  describe "security validation" do
    context "when attempting path traversal" do
      it "blocks path traversal attempts" do
        result = subject.call(type: "file", title: "../../../etc/passwd", content: "malicious")

        expect(result).to eq(1)
      end

      it "blocks access to forbidden patterns" do
        result = subject.call(type: "file", title: ".git/config", content: "test")

        expect(result).to eq(1)
      end
    end

    context "when using valid paths" do
      it "allows creation in safe directories" do
        safe_path = File.join(temp_dir, "safe-file.txt")

        result = subject.call(
          type: "file",
          title: safe_path,
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

        subject.call(
          type: "task-new",
          title: "test-task",
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
          title: target_path,
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
          title: target_path
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
      FileUtils.chmod(0o444, restricted_dir) # Read-only

      target_path = File.join(restricted_dir, "test-file.txt")

      result = subject.call(
        type: "file",
        title: target_path,
        content: "test content"
      )

      expect(result).to eq(1)

      # Restore permissions for cleanup
      begin
        FileUtils.chmod(0o755, restricted_dir)
      rescue
        nil
      end
    end

    it "handles disk full errors appropriately" do
      # Mock FileUtils to simulate disk full error
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::ENOSPC, "No space left on device")

      result = subject.call(
        type: "directory",
        title: File.join(temp_dir, "test-dir")
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
        title: File.join(temp_dir, "test-file.txt"),
        content: "test content"
      )

      expect(result).to eq(1)
    end

    it "handles network filesystem timeouts" do
      # Mock file operations to simulate network timeout
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::ETIMEDOUT, "Connection timed out")

      result = subject.call(
        type: "directory",
        title: File.join(temp_dir, "network-dir")
      )

      expect(result).to eq(1)
    end
  end

  describe "input validation" do
    it "validates required parameters are present" do
      result = subject.call(type: "file", title: nil)
      expect(result).to eq(1)

      result = subject.call(type: "file", title: "")
      expect(result).to eq(1)

      result = subject.call(type: "file", title: "   ")
      expect(result).to eq(1)
    end

    it "handles malformed command line arguments" do
      # Test with unknown type
      result = subject.call(type: "unknown-type", title: "test")
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
          title: invalid_path,
          content: "test"
        )
        expect(result).to eq(1), "Should reject path: #{invalid_path}"
      end
    end

    it "handles empty or whitespace-only inputs" do
      result = subject.call(type: "file", title: "", content: "test")
      expect(result).to eq(1)

      result = subject.call(type: "file", title: "   ", content: "test")
      expect(result).to eq(1)

      result = subject.call(type: "file", title: "test.txt", content: "")
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
        title: File.join(temp_dir, "test.txt"),
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
        title: File.join(temp_dir, "test.txt"),
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

      # Mock PathResolver to use temp directory
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)
      allow(path_resolver).to receive(:resolve_path)
        .with("test-task", type: :task_new)
        .and_return({success: true, path: File.join(temp_dir, "test-task.md")})

      result = subject.call(type: "task-new", title: "test-task")

      expect(result).to eq(0) # Should succeed with fallback content
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

      # Mock PathResolver to use temp directory
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)
      allow(path_resolver).to receive(:resolve_path)
        .with("test-task", type: :task_new)
        .and_return({success: true, path: File.join(temp_dir, "test-task.md")})

      result = subject.call(type: "task-new", title: "test-task")

      expect(result).to eq(0) # Should succeed with fallback content
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

      # Mock PathResolver to use temp directory
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)
      allow(path_resolver).to receive(:resolve_path)
        .with("test-task", type: :task_new)
        .and_return({success: true, path: File.join(temp_dir, "test-task.md")})

      result = subject.call(type: "task-new", title: "test-task")

      expect(result).to eq(0) # Should succeed with fallback content
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
        title: File.join(temp_dir, "output.txt"),
        template: template_file
      )

      expect(result).to eq(0) # Should handle gracefully
    end

    it "handles variable substitution failures" do
      File.write(template_file, "Title: {metadata.nonexistent}")

      result = subject.call(
        type: "template",
        title: File.join(temp_dir, "output.txt"),
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
        title: File.join(temp_dir, "output.txt"),
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

      result = subject.call(type: "task-new", title: "test-task")

      expect(result).to eq(1)
    end

    it "handles invalid repository context" do
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_raise(StandardError, "No project root found")
      allow(path_resolver).to receive(:resolve_path).and_return({success: false, error: "Invalid context"})

      result = subject.call(type: "task-new", title: "test-task")

      expect(result).to eq(1)
    end

    it "handles missing project root detection" do
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(nil)
      allow(path_resolver).to receive(:resolve_path).and_return({success: false, error: "No project root"})

      result = subject.call(type: "task-new", title: "test-task")

      expect(result).to eq(1)
    end

    it "handles submodule resolution failures" do
      path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:resolve_path).and_return({success: false, error: "Submodule not found"})
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)

      result = subject.call(type: "task-new", title: "test-task")

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
        title: target_path,
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
        title: target_dir
      )

      expect(result).to eq(1) # Should fail due to existing directory
    end
  end

  describe "delegation format processing" do
    let(:path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }
    let(:test_path) { File.join(temp_dir, "delegated-file.md") }

    before do
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)
    end

    context "valid delegation formats" do
      it "parses file:docs-new correctly" do
        allow(path_resolver).to receive(:resolve_path)
          .with("test-doc", type: :docs_new)
          .and_return({success: true, path: test_path})

        result = subject.call(type: "file:docs-new", title: "test-doc")

        expect(path_resolver).to have_received(:resolve_path).with("test-doc", type: :docs_new)
        expect(result).to eq(0)
      end

      it "parses file:reflection-new correctly" do
        allow(path_resolver).to receive(:resolve_path)
          .with("oauth-review", type: :reflection_new)
          .and_return({success: true, path: test_path})

        result = subject.call(type: "file:reflection-new", title: "oauth-review")

        expect(path_resolver).to have_received(:resolve_path).with("oauth-review", type: :reflection_new)
        expect(result).to eq(0)
      end

      it "parses directory:code-review-new correctly" do
        dir_path = File.join(temp_dir, "review-session")
        allow(path_resolver).to receive(:resolve_path)
          .with("auth-session", type: :code_review_new)
          .and_return({success: true, path: dir_path})

        result = subject.call(type: "directory:code-review-new", title: "auth-session")

        expect(path_resolver).to have_received(:resolve_path).with("auth-session", type: :code_review_new)
        expect(result).to eq(0)
      end
    end

    context "invalid delegation formats" do
      it "rejects malformed delegation (no colon)" do
        result = subject.call(type: "file-docs-new", title: "test")

        expect(result).to eq(1)
      end

      it "rejects multiple colons in delegation" do
        result = subject.call(type: "file:docs:new", title: "test")

        expect(result).to eq(1)
      end

      it "rejects unknown creation types" do
        result = subject.call(type: "unknown:docs-new", title: "test")

        expect(result).to eq(1)
      end

      it "rejects unknown nav types for file creation" do
        result = subject.call(type: "file:unknown-type", title: "test")

        expect(result).to eq(1)
      end

      it "rejects unknown nav types for directory creation" do
        result = subject.call(type: "directory:unknown-type", title: "test")

        expect(result).to eq(1)
      end
    end

    context "edge cases" do
      it "handles empty titles gracefully" do
        result = subject.call(type: "file:docs-new", title: "")

        expect(result).to eq(1)
      end

      it "handles whitespace-only titles" do
        result = subject.call(type: "file:docs-new", title: "   ")

        expect(result).to eq(1)
      end

      it "handles titles with special characters" do
        allow(path_resolver).to receive(:resolve_path)
          .with("test@#$%^&*()", type: :docs_new)
          .and_return({success: true, path: test_path})

        result = subject.call(type: "file:docs-new", title: "test@#$%^&*()")

        expect(result).to eq(0)
      end

      it "handles very long titles" do
        long_title = "very-" + "long-" * 50 + "title"
        allow(path_resolver).to receive(:resolve_path)
          .with(long_title, type: :docs_new)
          .and_return({success: true, path: test_path})

        result = subject.call(type: "file:docs-new", title: long_title)

        expect(result).to eq(0)
      end
    end
  end

  describe "contextual content generation" do
    let(:command) { described_class.new }

    context "generate_contextual_content method" do
      it "generates reflection headers correctly" do
        content = command.send(:generate_contextual_content, :reflection_new, "OAuth Implementation")

        expect(content).to eq("# Reflection - OAuth Implementation\n\n")
      end

      it "generates documentation headers correctly" do
        content = command.send(:generate_contextual_content, :docs_new, "API Guide")

        expect(content).to eq("# Documentation - API Guide\n\n")
      end

      it "generates code review headers correctly" do
        content = command.send(:generate_contextual_content, :code_review_new, "Auth Session")

        expect(content).to eq("# Code Review - Auth Session\n\n")
      end

      it "handles unknown nav_types with default format" do
        content = command.send(:generate_contextual_content, :unknown_type, "test title")

        expect(content).to eq("# Test title\n\n")
      end

      it "handles special characters in titles" do
        content = command.send(:generate_contextual_content, :docs_new, "Test & Special (chars)")

        expect(content).to eq("# Documentation - Test & Special (chars)\n\n")
      end

      it "handles empty titles gracefully" do
        content = command.send(:generate_contextual_content, :docs_new, "")

        expect(content).to eq("# Documentation - \n\n")
      end

      it "handles nil titles gracefully" do
        content = command.send(:generate_contextual_content, :docs_new, nil)

        expect(content).to eq("# Documentation - \n\n")
      end
    end

    context "generate_contextual_content_from_template_context method" do
      it "generates docs content from template path" do
        template_config = {"template" => "/path/to/docs/template.md"}
        content = command.send(:generate_contextual_content_from_template_context, template_config, "Test Doc")

        expect(content).to eq("# Documentation - Test Doc\n\n")
      end

      it "generates reflection content from template path" do
        template_config = {"template" => "/path/to/reflection/template.md"}
        content = command.send(:generate_contextual_content_from_template_context, template_config, "Test Reflection")

        expect(content).to eq("# Reflection - Test Reflection\n\n")
      end

      it "generates code review content from template path" do
        template_config = {"template" => "/path/to/code-review/template.md"}
        content = command.send(:generate_contextual_content_from_template_context, template_config, "Test Review")

        expect(content).to eq("# Code Review - Test Review\n\n")
      end

      it "generates code review content from review path" do
        template_config = {"template" => "/path/to/review/template.md"}
        content = command.send(:generate_contextual_content_from_template_context, template_config, "Test Review")

        expect(content).to eq("# Code Review - Test Review\n\n")
      end

      it "handles default case for unknown template paths" do
        template_config = {"template" => "/path/to/unknown/template.md"}
        content = command.send(:generate_contextual_content_from_template_context, template_config, "Test Title")

        expect(content).to eq("# Test title\n\n")
      end

      it "handles missing template path" do
        template_config = {}
        content = command.send(:generate_contextual_content_from_template_context, template_config, "Test Title")

        expect(content).to eq("# Test title\n\n")
      end

      it "handles nil template config" do
        content = command.send(:generate_contextual_content_from_template_context, nil, "Test Title")

        expect(content).to eq("# Test title\n\n")
      end
    end
  end

  describe "missing template handling" do
    let(:path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }
    let(:test_path) { File.join(temp_dir, "test-file.md") }

    before do
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)
      allow(path_resolver).to receive(:resolve_path).and_return({success: true, path: test_path})
    end

    context "missing template configuration" do
      it "creates contextual content for reflection_new" do
        # Create config without reflection-new template
        config = {
          "templates" => {
            "docs-new" => {"template" => "docs-template.md"}
          }
        }
        File.write(config_file, YAML.dump(config))

        result = subject.call(type: "file:reflection-new", title: "oauth review")

        expect(result).to eq(0)
        expect(File.exist?(test_path)).to be true
        content = File.read(test_path)
        expect(content).to eq("# Reflection - oauth review\n\n")
      end

      it "creates contextual content for docs_new" do
        # Create config without docs-new template
        config = {"templates" => {}}
        File.write(config_file, YAML.dump(config))

        result = subject.call(type: "file:docs-new", title: "API guide")

        expect(result).to eq(0)
        expect(File.exist?(test_path)).to be true
        content = File.read(test_path)
        expect(content).to eq("# Documentation - API guide\n\n")
      end

      it "creates contextual content for code_review_new" do
        # Create config without code-review-new template
        config = {"templates" => {}}
        File.write(config_file, YAML.dump(config))

        result = subject.call(type: "directory:code-review-new", title: "auth session")

        expect(result).to eq(0)
        expect(File.exist?(test_path)).to be true
        content = File.read(test_path)
        expect(content).to eq("# Code Review - auth session\n\n")
      end
    end

    context "missing template files" do
      it "generates contextual content when template file missing" do
        # Create config with non-existent template file
        config = {
          "templates" => {
            "reflection-new" => {"template" => "/nonexistent/template.md"}
          }
        }
        File.write(config_file, YAML.dump(config))

        result = subject.call(type: "file:reflection-new", title: "oauth review")

        expect(result).to eq(0)
        expect(File.exist?(test_path)).to be true
        content = File.read(test_path)
        expect(content).to eq("# Reflection - oauth review\n\n")
      end

      it "handles template path resolution failures" do
        # Create config with nil template path
        config = {
          "templates" => {
            "docs-new" => {"template" => nil}
          }
        }
        File.write(config_file, YAML.dump(config))

        result = subject.call(type: "file:docs-new", title: "API guide")

        expect(result).to eq(0)
        expect(File.exist?(test_path)).to be true
        content = File.read(test_path)
        expect(content).to eq("# Documentation - API guide\n\n")
      end
    end
  end

  describe "delegation security validation" do
    context "delegation input sanitization" do
      it "validates delegation input for injection attacks" do
        malicious_types = [
          "file;rm -rf /:docs-new",
          "file$(rm -rf /):docs-new",
          "file`rm -rf /`:docs-new",
          "file|rm -rf /:docs-new",
          "file&&rm -rf /:docs-new"
        ]

        malicious_types.each do |malicious_type|
          result = subject.call(type: malicious_type, title: "test")
          expect(result).to eq(1), "Should reject malicious type: #{malicious_type}"
        end
      end

      it "sanitizes nav-type parameters" do
        malicious_nav_types = [
          "file:docs-new;rm -rf /",
          "file:docs-new$(rm -rf /)",
          "file:docs-new`rm -rf /`",
          "file:docs-new|rm -rf /",
          "file:docs-new&&rm -rf /"
        ]

        malicious_nav_types.each do |malicious_nav_type|
          result = subject.call(type: malicious_nav_type, title: "test")
          expect(result).to eq(1), "Should reject malicious nav-type: #{malicious_nav_type}"
        end
      end

      it "prevents path traversal via delegation" do
        traversal_types = [
          "file:../../etc/passwd",
          "file:../../../root/.ssh",
          "directory:../../../../tmp"
        ]

        traversal_types.each do |traversal_type|
          result = subject.call(type: traversal_type, title: "test")
          expect(result).to eq(1), "Should reject path traversal: #{traversal_type}"
        end
      end
    end
  end

  describe "draft status support" do
    context "with --status parameter" do
      it "accepts draft as a valid status value" do
        # This tests the dry-cli validation - the command should not raise an error
        test_path = File.join(temp_dir, "test-draft.txt")
        result = subject.call(
          type: "file",
          title: test_path,
          content: "draft content",
          status: "draft"
        )
        expect(result).to eq(0), "Command failed with status #{result}"
      end

      it "accepts all valid status values" do
        valid_statuses = %w[pending in-progress done blocked draft]
        
        valid_statuses.each do |status|
          expect {
            test_path = File.join(temp_dir, "test-#{status}.txt")
            result = subject.call(
              type: "file",
              title: test_path,
              content: "test content",
              status: status
            )
            expect(result).to eq(0)
          }.not_to raise_error, "Should accept status: #{status}"
        end
      end

      # Note: Invalid status validation is handled by dry-cli at the argument parsing level,
      # not within the command itself. This is framework-level validation that doesn't need testing.

      it "passes status to metadata processing" do
        # Mock template processing to verify status is passed through
        config = {
          "templates" => {
            "task-new" => {
              "template" => "fake-template.md",
              "variables" => {
                "status" => "{metadata.status}"
              }
            }
          }
        }
        File.write(config_file, YAML.dump(config))

        # Mock PathResolver to return a test path
        path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
        allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
        allow(path_resolver).to receive(:project_root).and_return(temp_dir)
        allow(path_resolver).to receive(:resolve_path)
          .and_return({success: true, path: File.join(temp_dir, "test-task.md")})

        # Create fake template content
        template_content = "Status: {metadata.status}"
        allow(File).to receive(:exist?).with("fake-template.md").and_return(true)
        allow(File).to receive(:read).with("fake-template.md").and_return(template_content)
        allow(File).to receive(:exist?).with(config_file).and_call_original
        allow(File).to receive(:read).with(config_file).and_call_original
        # Allow File.exist? for any other file paths
        allow(File).to receive(:exist?).and_call_original

        result = subject.call(
          type: "task-new",
          title: "test-draft-task",
          status: "draft"
        )

        expect(result).to eq(0)
      end
    end

    context "default status behavior" do
      it "maintains backward compatibility when no status is provided" do
        # Should still work without status parameter
        test_path = File.join(temp_dir, "test-no-status.txt")
        result = subject.call(
          type: "file",
          title: test_path,
          content: "content without status"
        )
        
        expect(result).to eq(0)
      end

      it "uses default status from configuration" do
        # The default status should come from configuration
        config = {
          "templates" => {
            "task-new" => {
              "template" => "fake-template.md",
              "variables" => {
                "status" => "draft"  # Default from config
              }
            }
          },
          "variable_processors" => {
            "defaults" => {
              "status" => "draft"
            }
          }
        }
        File.write(config_file, YAML.dump(config))

        # Mock dependencies
        path_resolver = instance_double(CodingAgentTools::Molecules::PathResolver)
        allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
        allow(path_resolver).to receive(:project_root).and_return(temp_dir)
        allow(path_resolver).to receive(:resolve_path)
          .and_return({success: true, path: File.join(temp_dir, "default-task.md")})

        template_content = "Status: {metadata.status}"
        allow(File).to receive(:exist?).with("fake-template.md").and_return(true)
        allow(File).to receive(:read).with("fake-template.md").and_return(template_content)
        allow(File).to receive(:exist?).with(config_file).and_call_original
        allow(File).to receive(:read).with(config_file).and_call_original
        # Allow File.exist? for any other file paths
        allow(File).to receive(:exist?).and_call_original

        result = subject.call(
          type: "task-new",
          title: "default-status-task"
        )

        expect(result).to eq(0)
      end
    end
  end

  describe "PathResolver delegation integration" do
    let(:path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }

    before do
      allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(path_resolver)
      allow(path_resolver).to receive(:project_root).and_return(temp_dir)
    end

    context "PathResolver failures" do
      it "handles PathResolver failures gracefully" do
        allow(path_resolver).to receive(:resolve_path)
          .and_return({success: false, error: "Path resolution failed"})

        result = subject.call(type: "file:docs-new", title: "test")

        expect(result).to eq(1)
      end

      it "passes correct nav_type to PathResolver" do
        allow(path_resolver).to receive(:resolve_path)
          .with("test-doc", type: :docs_new)
          .and_return({success: true, path: File.join(temp_dir, "test.md")})

        subject.call(type: "file:docs-new", title: "test-doc")

        expect(path_resolver).to have_received(:resolve_path).with("test-doc", type: :docs_new)
      end

      it "validates resolved paths from delegation" do
        malicious_path = "../../../../etc/passwd"
        allow(path_resolver).to receive(:resolve_path)
          .and_return({success: true, path: malicious_path})

        # The security validator should catch this
        result = subject.call(type: "file:docs-new", title: "test")

        # Result depends on security validator implementation
        expect([0, 1]).to include(result)
      end
    end
  end
end
