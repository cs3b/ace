# frozen_string_literal: true

require_relative "../test_helper"

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
    Open3.stub(:capture3, proc { |_a, *_rest|
      ["ok", "", FakeStatus.new(true, 0)]
    }) do
      result = @executor.run(["vhs", "demo.tape", "--output", "demo.gif"])
      assert result.success?
      assert_equal "ok", result.stdout
    end
  end

  def test_run_raises_vhs_not_found
    Open3.stub(:capture3, proc { raise Errno::ENOENT }) do
      error = assert_raises(Ace::Demo::VhsNotFoundError) { @executor.run(["vhs", "demo.tape"]) }
      assert_includes error.message, "Install:"
    end
  end

  def test_run_raises_execution_error_on_non_zero
    Open3.stub(:capture3, proc { |_a, *_rest|
      ["", "boom", FakeStatus.new(false, 1)]
    }) do
      error = assert_raises(Ace::Demo::VhsExecutionError) { @executor.run(["vhs", "demo.tape"]) }
      assert_includes error.message, "boom"
    end
  end
end
