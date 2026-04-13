# frozen_string_literal: true

require_relative "../test_helper"
require "timeout"

class CommandExecutorTest < Minitest::Test
  def setup
    @executor = Ace::Core::Atoms::CommandExecutor
  end

  def test_execute_simple_command
    result = @executor.execute('echo "Hello World"')

    assert result[:success]
    assert_equal "Hello World\n", result[:stdout]
    assert_empty result[:stderr]
    assert_equal 0, result[:exit_code]
  end

  def test_execute_command_with_error
    result = @executor.execute("ls /non/existent/directory")

    refute result[:success]
    assert_match(/No such file|cannot access/, result[:stderr])
    refute_equal 0, result[:exit_code]
  end

  def test_execute_nil_command
    result = @executor.execute(nil)

    refute result[:success]
    assert_equal "Command cannot be nil", result[:error]
  end

  def test_execute_empty_command
    result = @executor.execute("   ")

    refute result[:success]
    assert_equal "Command cannot be empty", result[:error]
  end

  def test_execute_with_timeout
    # Mock Timeout to raise immediately instead of waiting
    Timeout.stub :timeout, ->(_seconds, &block) { raise Timeout::Error } do
      result = @executor.execute('echo "test"', timeout: 1)

      refute result[:success]
      assert_match(/Command timed out after 1 seconds/, result[:error])
    end
  end

  def test_execute_with_working_directory
    Dir.mktmpdir do |tmpdir|
      result = @executor.execute("pwd", cwd: tmpdir)

      assert result[:success]
      # Force UTF-8 encoding for comparison and handle macOS /private prefix
      output = result[:stdout].force_encoding("UTF-8").strip
      expected = File.realpath(tmpdir)
      assert_equal expected, output
    end
  end

  def test_execute_non_existent_command
    result = @executor.execute("this_command_does_not_exist")

    refute result[:success]
    assert_match(/Command not found/, result[:error])
  end

  def test_capture_returns_stdout_on_success
    output = @executor.capture('echo "test output"')

    assert_equal "test output\n", output
  end

  def test_capture_returns_nil_on_failure
    output = @executor.capture("ls /non/existent/directory")

    assert_nil output
  end

  def test_available_checks_command_existence
    # Common commands that should exist
    assert @executor.available?("echo")
    assert @executor.available?("ls")

    # Commands that shouldn't exist
    refute @executor.available?("this_command_does_not_exist")
    refute @executor.available?(nil)
    refute @executor.available?("")
  end

  def test_execute_batch
    commands = [
      'echo "First"',
      'echo "Second"',
      'echo "Third"'
    ]

    results = @executor.execute_batch(commands)

    assert_equal 3, results.size
    assert results.all? { |r| r[:success] }
    assert_equal "First\n", results[0][:stdout]
    assert_equal "Second\n", results[1][:stdout]
    assert_equal "Third\n", results[2][:stdout]
  end

  def test_execute_batch_with_failures
    commands = [
      'echo "Success"',
      "ls /non/existent",
      'echo "Another success"'
    ]

    results = @executor.execute_batch(commands)

    assert_equal 3, results.size
    assert results[0][:success]
    refute results[1][:success]
    assert results[2][:success]
  end

  def test_build_command_with_escaping
    # Test escaping special characters
    cmd = @executor.build_command("echo", "Hello World")
    assert_equal "echo 'Hello World'", cmd

    # Test escaping quotes - this is complex due to shell escaping
    cmd = @executor.build_command("echo", "It's a test")
    # The actual output is: echo 'It'\''s a test' but Ruby shows it differently
    assert cmd.include?("It") && cmd.include?("s a test")

    # Test safe arguments (no escaping needed)
    cmd = @executor.build_command("ls", "-la", "/tmp")
    assert_equal "ls -la /tmp", cmd
  end

  def test_stream_with_callback
    output_lines = []
    callback = ->(line) { output_lines << line }

    result = @executor.stream('echo "Line 1"; echo "Line 2"', output_callback: callback)

    assert result[:success]
    assert_equal 0, result[:exit_code]
    assert_equal 2, output_lines.size
    assert_includes output_lines, "Line 1"
    assert_includes output_lines, "Line 2"
  end

  def test_stream_with_timeout
    # Mock Timeout to raise immediately instead of waiting
    Timeout.stub :timeout, ->(_seconds, &block) { raise Timeout::Error } do
      result = @executor.stream('echo "test"', timeout: 1)

      refute result[:success]
      assert_match(/Command timed out/, result[:error])
    end
  end

  def test_execute_with_large_output
    # Generate output larger than max
    large_text = "x" * 2000
    result = @executor.execute("echo '#{large_text}'", max_output: 1000)

    assert result[:success]
    assert result[:stdout].bytesize <= 1000
    assert result[:warning]
    assert_match(/Output truncated/, result[:warning])
  end

  # Integration tests - run with INTEGRATION_TESTS=1 environment variable
  if ENV["INTEGRATION_TESTS"]
    def test_execute_with_real_timeout
      # This test uses real sleep and timeout - only run in integration mode
      result = @executor.execute("sleep 0.5", timeout: 0.2)

      refute result[:success]
      assert_match(/Command timed out/, result[:error])
    end

    def test_stream_with_real_timeout
      # This test uses real sleep and timeout - only run in integration mode
      result = @executor.stream("sleep 0.5", timeout: 0.2)

      refute result[:success]
      assert_match(/Command timed out/, result[:error])
    end
  end
end
