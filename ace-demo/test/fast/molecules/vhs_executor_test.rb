# frozen_string_literal: true

require_relative "../../test_helper"

class VhsExecutorTest < AceDemoTestCase
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
    super
    @executor = Ace::Demo::Molecules::VhsExecutor.new
  end

  def test_vhs_available_false_when_binary_missing
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      refute @executor.vhs_available?
    end
  end

  def test_run_returns_execution_result_on_success
    calls = []
    Open3.stub(:capture3, proc { |*args|
      calls << args
      if args[0] == "bash"
        ["/usr/bin/chromium\n", "", FakeStatus.new(true, 0)]
      else
        ["ok", "", FakeStatus.new(true, 0)]
      end
    }) do
      result = @executor.run(["vhs", "demo.tape", "--output", "demo.gif"])
      assert result.success?
      assert_equal "ok", result.stdout
    end

    env = calls.last[0]
    assert_equal "/usr/bin/chromium", env["BROWSER"]
    assert_equal "/usr/bin/chromium", env["CHROME_BIN"]
  end

  def test_run_raises_vhs_not_found
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      error = assert_raises(Ace::Demo::VhsNotFoundError) { @executor.run(["vhs", "demo.tape"]) }
      assert_includes error.message, "Install:"
    end
  end

  def test_run_raises_execution_error_on_non_zero
    Open3.stub(:capture3, proc { |*args|
      if args[0] == "bash"
        ["/usr/bin/chromium\n", "", FakeStatus.new(true, 0)]
      else
        ["", "boom", FakeStatus.new(false, 1)]
      end
    }) do
      error = assert_raises(Ace::Demo::VhsExecutionError) { @executor.run(["vhs", "demo.tape"]) }
      assert_includes error.message, "boom"
    end
  end

  def test_run_uses_empty_browser_env_when_no_browser_found
    captured_env = nil

    Open3.stub(:capture3, proc { |*args|
      if args[0] == "bash"
        ["", "", FakeStatus.new(false, 1)]
      else
        captured_env = args[0]
        ["ok", "", FakeStatus.new(true, 0)]
      end
    }) do
      @executor.run(["vhs", "demo.tape"])
    end

    assert_equal({}, captured_env)
  end
end
