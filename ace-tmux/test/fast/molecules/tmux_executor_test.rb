# frozen_string_literal: true

require_relative "../../test_helper"

class TmuxExecutorTest < Minitest::Test
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
end
