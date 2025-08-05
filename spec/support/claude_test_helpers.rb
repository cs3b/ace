# frozen_string_literal: true

# Test helpers for Claude command specs
module ClaudeTestHelpers
  # Sets up a temporary test environment for Claude commands
  # Creates necessary directory structure and returns the temp directory path
  def setup_claude_test_environment
    @temp_dir = Dir.mktmpdir("claude_test")
    @handbook_dir = File.join(@temp_dir, "dev-handbook")
    @claude_dir = File.join(@handbook_dir, ".integrations/claude")
    @workflow_dir = File.join(@handbook_dir, "workflow-instructions")
    
    FileUtils.mkdir_p(@claude_dir)
    FileUtils.mkdir_p(@workflow_dir)
    FileUtils.mkdir_p(File.join(@claude_dir, "commands"))
    
    @temp_dir
  end

  # Tears down the test environment, safely cleaning up temporary directories
  def teardown_claude_test_environment
    # Use safe_directory_cleanup from spec_helper
    safe_directory_cleanup(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  # Helper to execute Claude commands directly (performance optimization)
  # @param command_name [String] The command name (e.g., "generate-commands")
  # @param options [Hash] Command options
  # @return [Object] Result of the command execution
  def execute_claude_command(command_name, options = {})
    command_class = case command_name
    when "generate-commands"
      CodingAgentTools::Cli::Commands::Handbook::Claude::GenerateCommands
    when "validate"
      CodingAgentTools::Cli::Commands::Handbook::Claude::Validate
    when "integrate"
      CodingAgentTools::Cli::Commands::Handbook::Claude::Integrate
    when "list"
      CodingAgentTools::Cli::Commands::Handbook::Claude::List
    else
      raise ArgumentError, "Unknown Claude command: #{command_name}"
    end
    
    command_class.new.call(**options)
  end

  # Helper to create sample workflow files for testing
  # @param name [String] Workflow name (without extension)
  # @param content [String, nil] Optional workflow content
  def create_sample_workflow(name, content = nil)
    content ||= <<~MARKDOWN
      # #{name.capitalize.gsub("-", " ")} Workflow

      ## Goal
      Test workflow for #{name}

      ## Steps
      1. First step
      2. Second step
      3. Third step

      ## Validation
      - [ ] Check first thing
      - [ ] Check second thing
    MARKDOWN
    
    File.write(File.join(@workflow_dir, "#{name}.wf.md"), content)
  end

  # Helper to create a Claude command file for testing
  # @param workflow_name [String] The workflow name
  # @param content [String, nil] Optional command content
  def create_claude_command(workflow_name, content = nil)
    content ||= <<~MARKDOWN
      # #{workflow_name} Command

      Execute the #{workflow_name} workflow.

      ## Usage
      handbook #{workflow_name}

      ## Generated from
      workflow-instructions/#{workflow_name}.wf.md
    MARKDOWN
    
    command_file = File.join(@claude_dir, "commands", "#{workflow_name}.md")
    FileUtils.mkdir_p(File.dirname(command_file))
    File.write(command_file, content)
  end

  # Commands.json functionality has been removed
  # The create_command_registry method is no longer needed

  # Helper to verify command generation
  # @param workflow_name [String] The workflow name to check
  def expect_command_generated(workflow_name)
    command_file = File.join(@claude_dir, "commands", "#{workflow_name}.md")
    expect(File.exist?(command_file)).to be true
  end

  # Helper to capture output from a command
  # @yield Block that executes the command
  # @return [String] The captured output
  def capture_output(&block)
    original_stdout = $stdout
    captured = StringIO.new
    $stdout = captured
    
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    
    captured.string
  end

  # Helper to capture both stdout and stderr
  # @yield Block that executes the command
  # @return [Array<String, String>] Captured stdout and stderr
  def capture_output_and_errors(&block)
    original_stdout = $stdout
    original_stderr = $stderr
    stdout_capture = StringIO.new
    stderr_capture = StringIO.new
    $stdout = stdout_capture
    $stderr = stderr_capture
    
    begin
      yield
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
    
    [stdout_capture.string, stderr_capture.string]
  end
end