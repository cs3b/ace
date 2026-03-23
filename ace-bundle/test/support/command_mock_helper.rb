# frozen_string_literal: true

require "ostruct"

# Helper module for mocking shell commands in ace-bundle tests
# Intercepts CommandExecutor.execute calls to provide deterministic test results
module CommandMockHelper
  # Store original method and mock data
  @@original_execute = nil
  @@original_capture3 = nil
  @@command_mocks = {}
  @@mocking_enabled = false
  @@default_mocks = {}

  # Enable command mocking globally
  def self.enable_mocking!
    return if @@mocking_enabled

    # Store original execute method
    @@original_execute = Ace::Core::Atoms::CommandExecutor.method(:execute)
    @@mocking_enabled = true

    # Override CommandExecutor.execute
    Ace::Core::Atoms::CommandExecutor.define_singleton_method(:execute) do |command, options = {}|
      CommandMockHelper.intercept_command_execution(command, options)
    end

    # Keep command execution deterministic for callers that bypass CommandExecutor.
    @@original_capture3 = Open3.method(:capture3)
    Open3.singleton_class.define_singleton_method(:capture3) do |command, *args|
      CommandMockHelper.intercept_capture3(command, *args)
    end

    # Setup default mocks for common commands
    setup_default_mocks!
  end

  # Disable command mocking (restore original)
  def self.disable_mocking!
    return unless @@mocking_enabled

    if @@original_execute
      Ace::Core::Atoms::CommandExecutor.define_singleton_method(:execute, @@original_execute)
    end
    if @@original_capture3
      Open3.singleton_class.define_singleton_method(:capture3, @@original_capture3)
    end

    @@mocking_enabled = false
    @@original_execute = nil
    clear_mocks!
  end

  # Check if mocking is enabled
  def self.mocking_enabled?
    @@mocking_enabled
  end

  # Register a mock command response
  def self.mock_command(command_pattern, response = nil, &block)
    @@command_mocks[command_pattern] = if block_given?
      block
    else
      response
    end
  end

  # Remove all mocks
  def self.clear_mocks!
    @@command_mocks.clear
  end

  # Remove specific mock
  def self.remove_mock(command_pattern)
    @@command_mocks.delete(command_pattern)
  end

  # Setup default mocks for common commands
  def self.setup_default_mocks!
    clear_mocks!

    # Default test command
    mock_command(/test|spec/) do |command, options|
      {
        success: true,
        stdout: "Running tests...\n✓ All tests passed (12 tests)\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # Default lint command
    mock_command(/lint|flake8|eslint|rubocop/) do |command, options|
      {
        success: true,
        stdout: "Linting complete.\n✓ No issues found\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # Default security/audit command
    mock_command(/audit|security|safety|snyk/) do |command, options|
      {
        success: true,
        stdout: "Security audit complete.\n✓ No vulnerabilities found\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # Default build command
    mock_command(/build|compile/) do |command, options|
      {
        success: true,
        stdout: "Build complete.\n✓ Build successful\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # npm list command (for dependency checking)
    mock_command(/npm.*list|npm.*ls/) do |command, options|
      {
        success: true,
        stdout: "test-lib@1.0.0\nexample-lib@2.1.0\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # npm outdated command
    mock_command(/npm.*outdated/) do |command, options|
      {
        success: true,
        stdout: "All packages are up to date\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # Echo command
    mock_command(/^echo\s+(.+)$/) do |command, options|
      message = command.match(/^echo\s+(.+)$/)[1]
      {
        success: true,
        stdout: "#{message}\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # pwd command
    mock_command(/^pwd$/) do |command, options|
      {
        success: true,
        stdout: "/test/project\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # ls command
    mock_command(/^ls.*$/) do |command, options|
      {
        success: true,
        stdout: "README.md\npackage.json\nsrc/\ntest/\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # Custom security script
    mock_command(/custom.*security.*script/) do |command, options|
      {
        success: true,
        stdout: "Running custom security checks...\n✓ Security analysis complete\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end

    # Default fallback for any command
    mock_command(/.*/) do |command, options|
      {
        success: true,
        stdout: "Command executed: #{command}\n",
        stderr: "",
        exitstatus: 0,
        signal: nil
      }
    end
  end

  # Intercept command execution and provide mock response
  def self.intercept_command_execution(command, options = {})
    return @@original_execute.call(command, options) unless @@mocking_enabled

    # Find matching mock
    mock_response = find_mock_response(command)

    if mock_response
      if mock_response.respond_to?(:call)
        # Mock is a proc/lambda - call it with command and options
        result = mock_response.call(command, options)
        # Ensure result has all required keys
        ensure_complete_result(result)
      else
        # Mock is a static response
        ensure_complete_result(mock_response)
      end
    else
      # No mock found - use original method
      @@original_execute.call(command, options)
    end
  end

  def self.intercept_capture3(command, *args)
    command_str = if command.is_a?(Array)
      command.map(&:to_s).join(" ")
    else
      command.to_s
    end

    result = Ace::Core::Atoms::CommandExecutor.execute(command_str)
    exit_code = result[:exit_code] || result[:status] || 0
    status = Struct.new(:success?, :exitstatus).new(result[:success], exit_code)

    [result[:stdout].to_s, result[:stderr] || result[:error] || "", status]
  end

  # Find mock response for a command
  def self.find_mock_response(command)
    @@command_mocks.each do |pattern, response|
      if pattern.is_a?(Regexp) && command.match(pattern)
        return response
      elsif pattern.is_a?(String) && command.include?(pattern)
        return response
      end
    end
    nil
  end

  # Ensure result has all required keys
  def self.ensure_complete_result(result)
    {
      success: result[:success] || true,
      stdout: result[:stdout] || "",
      stderr: result[:stderr] || "",
      exitstatus: result[:exitstatus] || 0,
      signal: result[:signal] || nil,
      command: result[:command],
      timeout: result[:timeout]
    }
  end

  # Helper methods for test configuration
  def self.mock_success(command, output = "Command completed successfully")
    mock_command(command, {
      success: true,
      stdout: output + "\n",
      stderr: "",
      exitstatus: 0,
      signal: nil
    })
  end

  def self.mock_failure(command, error = "Command failed", exit_code = 1)
    mock_command(command, {
      success: false,
      stdout: "",
      stderr: error + "\n",
      exitstatus: exit_code,
      signal: nil
    })
  end

  def self.mock_timeout(command)
    mock_command(command, {
      success: false,
      stdout: "",
      stderr: "Command timed out\n",
      exitstatus: nil,
      signal: nil,
      timeout: true
    })
  end
end

# Auto-enable mocking only for ace-bundle tests
# This prevents global leakage into other package test suites
if defined?(Minitest) && ENV["RAILS_ENV"] != "production" && ENV["ENABLE_ACE_BUNDLE_MOCKS"]
  CommandMockHelper.enable_mocking!
end
