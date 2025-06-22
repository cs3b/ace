# frozen_string_literal: true

require "open3"
require "timeout"
require "shellwords"

# Shared helpers for process execution in integration tests
module ProcessHelpers
  # Default timeout for process execution (seconds)
  DEFAULT_TIMEOUT = 30

  # Execute a command and return stdout, stderr, and status
  # @param command [String, Array] Command to execute
  # @param env [Hash] Environment variables
  # @param timeout [Integer] Timeout in seconds
  # @param input [String] Input to send to stdin
  # @return [Array<String, String, Process::Status>] stdout, stderr, status
  def execute_command(command, env: {}, timeout: DEFAULT_TIMEOUT, input: nil)
    stdout = ""
    stderr = ""
    status = nil

    begin
      Timeout.timeout(timeout) do
        if input
          stdout, stderr, status = Open3.capture3(env, *Array(command), stdin_data: input)
        else
          stdout, stderr, status = Open3.capture3(env, *Array(command))
        end
      end
    rescue Timeout::Error
      raise "Command timed out after #{timeout} seconds: #{Array(command).join(" ")}"
    end

    [stdout, stderr, status]
  end

  # Execute a command and expect it to succeed
  # @param command [String, Array] Command to execute
  # @param env [Hash] Environment variables
  # @param timeout [Integer] Timeout in seconds
  # @param input [String] Input to send to stdin
  # @return [String] stdout content
  def execute_successfully(command, env: {}, timeout: DEFAULT_TIMEOUT, input: nil)
    stdout, stderr, status = execute_command(command, env: env, timeout: timeout, input: input)
    expect_process_success(status, stdout, stderr)
    stdout
  end

  # Execute a command and expect it to fail
  # @param command [String, Array] Command to execute
  # @param env [Hash] Environment variables
  # @param timeout [Integer] Timeout in seconds
  # @param expected_status [Integer] Expected exit code (nil means any non-zero)
  # @return [Array<String, String>] stdout, stderr
  def execute_with_failure(command, env: {}, timeout: DEFAULT_TIMEOUT, expected_status: nil)
    stdout, stderr, status = execute_command(command, env: env, timeout: timeout)

    expect(status).not_to be_success, "Expected command to fail, but it succeeded"

    if expected_status
      expect(status.exitstatus).to eq(expected_status),
        "Expected exit status #{expected_status}, but got #{status.exitstatus}"
    end

    [stdout, stderr]
  end

  # Check process status with meaningful error messages
  # @param status [Process::Status] Process status
  # @param stdout [String] Standard output
  # @param stderr [String] Standard error
  def expect_process_success(status, stdout, stderr)
    return if status.success?

    error_message = ["Command failed with status #{status.exitstatus}"]
    error_message << "STDOUT: #{stdout}" unless stdout.empty?
    error_message << "STDERR: #{stderr}" unless stderr.empty?

    expect(status).to be_success, error_message.join("\n")
  end

  # Create environment for VCR subprocess execution
  # @param cassette_name [String] Name of the VCR cassette
  # @param base_env [Hash] Base environment variables
  # @return [Hash] Environment hash for subprocess
  def vcr_subprocess_env(cassette_name, base_env = {})
    vcr_setup_path = File.expand_path("../vcr_setup.rb", __dir__)

    # Include bundler environment to ensure subprocess has access to gems
    bundler_env = {
      "BUNDLE_GEMFILE" => ENV["BUNDLE_GEMFILE"],
      "BUNDLE_PATH" => ENV["BUNDLE_PATH"],
      "BUNDLE_BIN_PATH" => ENV["BUNDLE_BIN_PATH"],
      "RACK_ENV" => ENV["RACK_ENV"] || "test",
      "RUBYOPT" => "-rbundler/setup -r#{Shellwords.escape(vcr_setup_path)}",
      "VCR_CASSETTE_NAME" => cassette_name,
      # Ensure proper encoding for Unicode handling in CI
      "LANG" => ENV["LANG"] || "en_US.UTF-8",
      "LC_ALL" => ENV["LC_ALL"] || "en_US.UTF-8",
      "LC_CTYPE" => ENV["LC_CTYPE"] || "en_US.UTF-8"
    }.compact # Remove nil values

    base_env.merge(bundler_env)
  end

  # Execute a Ruby script with proper bundler setup
  # @param script_path [String] Path to the Ruby script
  # @param args [Array] Arguments to pass to the script
  # @param env [Hash] Environment variables
  # @param timeout [Integer] Timeout in seconds
  # @param input [String] Input to send to stdin
  # @return [Array<String, String, Process::Status>] stdout, stderr, status
  def execute_ruby_script(script_path, args = [], env: {}, timeout: DEFAULT_TIMEOUT, input: nil)
    ruby_path = RbConfig.ruby
    command = [ruby_path, script_path] + args
    execute_command(command, env: env, timeout: timeout, input: input)
  end

  # Execute a gem executable with proper bundler setup
  # @param exe_name [String] Name of the executable (without path)
  # @param args [Array] Arguments to pass to the executable
  # @param env [Hash] Environment variables
  # @param timeout [Integer] Timeout in seconds
  # @param input [String] Input to send to stdin
  # @return [Array<String, String, Process::Status>] stdout, stderr, status
  def execute_gem_executable(exe_name, args = [], env: {}, timeout: DEFAULT_TIMEOUT, input: nil)
    exe_path = File.expand_path("../../exe/#{exe_name}", __dir__)
    execute_ruby_script(exe_path, args, env: env, timeout: timeout, input: input)
  end

  # Create a temporary file with content and return its path
  # @param content [String] Content to write to the file
  # @param extension [String] File extension (with dot)
  # @param prefix [String] Filename prefix
  # @return [String] Path to the temporary file
  def create_temp_file(content, extension: ".tmp", prefix: "test_")
    require "tempfile"

    file = Tempfile.new([prefix, extension])
    file.write(content)
    file.close

    # Store for cleanup
    @temp_files ||= []
    @temp_files << file

    file.path
  end

  # Clean up temporary files created during tests
  def cleanup_temp_files
    return unless @temp_files

    @temp_files.each do |file|
      file.unlink
    rescue => e
      # Ignore cleanup errors
      warn "Failed to cleanup temp file: #{e.message}" if ENV["TEST_DEBUG"]
    end

    @temp_files.clear
  end

  # Execute command with input piped to stdin
  # @param command [String, Array] Command to execute
  # @param input [String] Input to send to stdin
  # @param env [Hash] Environment variables
  # @param timeout [Integer] Timeout in seconds
  # @return [Array<String, String, Process::Status>] stdout, stderr, status
  def execute_with_input(command, input, env: {}, timeout: DEFAULT_TIMEOUT)
    execute_command(command, env: env, timeout: timeout, input: input)
  end

  # Check if command exists in PATH
  # @param command [String] Command name
  # @return [Boolean] true if command exists
  def command_exists?(command)
    system("which #{command} > /dev/null 2>&1")
  end

  # Skip test if required command is not available
  # @param command [String] Required command
  # @param message [String] Skip message
  def skip_unless_command_available(command, message = nil)
    unless command_exists?(command)
      skip message || "Command '#{command}' not available"
    end
  end

  # Get environment variable with fallback
  # @param key [String] Environment variable name
  # @param default [String] Default value if not set
  # @return [String] Environment variable value or default
  def env_with_default(key, default = nil)
    ENV[key] || default
  end

  # Check if we're running in CI environment
  # @return [Boolean] true if running in CI
  def ci_environment?
    !ENV["CI"].nil?
  end

  # Get test timeout from environment or use default
  # @return [Integer] Timeout in seconds
  def test_timeout
    env_with_default("TEST_TIMEOUT", DEFAULT_TIMEOUT.to_s).to_i
  end

  # Check if debug mode is enabled
  # @return [Boolean] true if debug mode is enabled
  def debug_mode?
    ENV["TEST_DEBUG"] == "true" || ENV["TEST_DEBUG"] == "1"
  end

  # Print debug message if debug mode is enabled
  # @param message [String] Debug message
  def debug_puts(message)
    puts "[DEBUG] #{message}" if debug_mode?
  end
end

# Include helpers in RSpec
RSpec.configure do |config|
  config.include ProcessHelpers, type: :integration

  # Cleanup temp files after each test
  config.after(:each) do
    cleanup_temp_files if respond_to?(:cleanup_temp_files)
  end
end
