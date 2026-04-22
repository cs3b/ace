# frozen_string_literal: true

require_relative "../../test_helper"

class TmuxExecutorTest < Minitest::Test
  class FakeStatus
    def initialize(success, code)
      @success = success
      @code = code
    end

    def success?
      @success
    end

    def exitstatus
      @code
    end
  end

  def setup
    @executor = Ace::Tmux::Molecules::TmuxExecutor.new
  end

  def test_capture_returns_execution_result
    result = @executor.capture(["echo", "hello"])

    assert_instance_of Ace::Tmux::Molecules::ExecutionResult, result
    assert_equal "hello", result.stdout
    assert result.success?
    assert_equal 0, result.exit_code
  end

  def test_capture_returns_failure_for_bad_command
    result = @executor.capture(["false"])

    refute result.success?
    assert_equal 1, result.exit_code
  end

  def test_run_returns_boolean
    assert_equal true, @executor.run(["true"])
    assert_equal false, @executor.run(["false"])
  end

  def test_execution_result_attributes
    result = Ace::Tmux::Molecules::ExecutionResult.new(
      stdout: "output",
      stderr: "error",
      success: false,
      exit_code: 2
    )

    assert_equal "output", result.stdout
    assert_equal "error", result.stderr
    refute result.success?
    assert_equal 2, result.exit_code
  end

  def test_capture_targets_explicit_socket_when_tmux_tmpdir_present
    original_tmux_tmpdir = ENV["TMUX_TMPDIR"]
    original_tmux = ENV["TMUX"]
    ENV["TMUX_TMPDIR"] = "/tmp/ace-tmux"
    captured = nil
    mkdir_calls = []
    chmod_calls = []
    ENV.delete("TMUX")

    FileUtils.stub(:mkdir_p, proc { |path| mkdir_calls << path }) do
      FileUtils.stub(:chmod, proc { |mode, path| chmod_calls << [mode, path] }) do
        Open3.stub(:capture3, proc { |*cmd|
          captured = cmd
          ["ok", "", FakeStatus.new(true, 0)]
        }) do
          @executor.capture(["tmux", "list-sessions"])
        end
      end
    end

    assert_equal ["/tmp/ace-tmux/tmux-#{Process.uid}"], mkdir_calls
    assert_equal [[0o700, "/tmp/ace-tmux/tmux-#{Process.uid}"]], chmod_calls
    assert_equal ["tmux", "-S", "/tmp/ace-tmux/tmux-#{Process.uid}/default", "list-sessions"], captured
  ensure
    if original_tmux
      ENV["TMUX"] = original_tmux
    else
      ENV.delete("TMUX")
    end
    if original_tmux_tmpdir
      ENV["TMUX_TMPDIR"] = original_tmux_tmpdir
    else
      ENV.delete("TMUX_TMPDIR")
    end
  end

  def test_capture_uses_legacy_tmux_socket_when_tmux_env_present
    original_tmux_tmpdir = ENV["TMUX_TMPDIR"]
    original_tmux = ENV["TMUX"]
    ENV["TMUX_TMPDIR"] = "/tmp/ace-tmux"
    ENV["TMUX"] = "/tmp/tmux-1000/default,12345,0"
    captured = nil
    mkdir_calls = []
    chmod_calls = []

    FileUtils.stub(:mkdir_p, proc { |path| mkdir_calls << path }) do
      FileUtils.stub(:chmod, proc { |mode, path| chmod_calls << [mode, path] }) do
        Open3.stub(:capture3, proc { |*cmd|
          captured = cmd
          ["ok", "", FakeStatus.new(true, 0)]
        }) do
          @executor.capture(["tmux", "list-sessions"])
        end
      end
    end

    assert_equal [], mkdir_calls
    assert_equal [], chmod_calls
    assert_equal ["tmux", "list-sessions"], captured
  ensure
    if original_tmux
      ENV["TMUX"] = original_tmux
    else
      ENV.delete("TMUX")
    end
    if original_tmux_tmpdir
      ENV["TMUX_TMPDIR"] = original_tmux_tmpdir
    else
      ENV.delete("TMUX_TMPDIR")
    end
  end
end
