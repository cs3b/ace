# frozen_string_literal: true

require_relative "../test_helper"

class AggExecutorTest < AceDemoTestCase
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
    @executor = Ace::Demo::Molecules::AggExecutor.new
  end

  def test_agg_available_false_when_binary_missing
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      refute @executor.agg_available?
    end
  end

  def test_run_returns_execution_result_on_success
    Open3.stub(:capture3, proc { |_a, *_rest|
      ["ok", "", FakeStatus.new(true, 0)]
    }) do
      result = @executor.run(["agg", "demo.cast", "demo.gif"])
      assert result.success?
      assert_equal "ok", result.stdout
    end
  end

  def test_run_raises_agg_not_found
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      error = assert_raises(Ace::Demo::AggNotFoundError) { @executor.run(["agg", "demo.cast", "demo.gif"]) }
      assert_includes error.message, "Install:"
    end
  end

  def test_run_raises_agg_not_found_with_configured_binary_name
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      error = assert_raises(Ace::Demo::AggNotFoundError) { @executor.run(["agg-custom", "demo.cast", "demo.gif"]) }
      assert_includes error.message, "(agg-custom)"
    end
  end

  def test_run_raises_execution_error_on_non_zero
    Open3.stub(:capture3, proc { |_a, *_rest|
      ["", "boom", FakeStatus.new(false, 1)]
    }) do
      error = assert_raises(Ace::Demo::AggExecutionError) { @executor.run(["agg", "demo.cast", "demo.gif"]) }
      assert_includes error.message, "boom"
    end
  end
end
