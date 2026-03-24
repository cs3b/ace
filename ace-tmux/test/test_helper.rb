# frozen_string_literal: true

require "ace/tmux"

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "yaml"

module TmuxTestHelper
  # MockExecutor records commands without executing them
  class MockExecutor
    attr_reader :captured_commands, :run_commands, :exec_commands

    def initialize(capture_responses: {})
      @captured_commands = []
      @run_commands = []
      @exec_commands = []
      @capture_responses = capture_responses
    end

    def capture(cmd)
      @captured_commands << cmd
      key = cmd.join(" ")
      response = @capture_responses[key] || @capture_responses[:default]

      response || Ace::Tmux::Molecules::ExecutionResult.new(
        stdout: "",
        stderr: "",
        success: true,
        exit_code: 0
      )
    end

    def run(cmd)
      @run_commands << cmd
      true
    end

    def exec(cmd)
      @exec_commands << cmd
      # Don't actually exec in tests
    end

    # All commands in order (for sequence assertions)
    def all_commands
      @run_commands + @exec_commands
    end

    def tmux_available?(tmux: "tmux")
      true
    end
  end

  # Create a temporary directory with preset files
  def create_temp_preset_dir
    dir = Dir.mktmpdir("ace_tmux_test")
    FileUtils.mkdir_p(File.join(dir, ".ace-defaults", "tmux", "sessions"))
    FileUtils.mkdir_p(File.join(dir, ".ace-defaults", "tmux", "windows"))
    FileUtils.mkdir_p(File.join(dir, ".ace-defaults", "tmux", "panes"))
    dir
  end

  # Write a preset YAML file
  def write_preset(dir, type, name, content)
    path = File.join(dir, ".ace-defaults", "tmux", type, "#{name}.yml")
    File.write(path, content.is_a?(Hash) ? content.to_yaml : content)
    path
  end

  # Clean up temp directory
  def cleanup_temp_dir(dir)
    FileUtils.rm_rf(dir) if dir && Dir.exist?(dir)
  end

  # Create a mock execution result
  def mock_result(stdout: "", stderr: "", success: true, exit_code: 0)
    Ace::Tmux::Molecules::ExecutionResult.new(
      stdout: stdout, stderr: stderr, success: success, exit_code: exit_code
    )
  end
end

class Minitest::Test
  include TmuxTestHelper
end
