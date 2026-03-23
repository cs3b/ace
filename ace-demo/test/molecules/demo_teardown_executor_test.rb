# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class DemoTeardownExecutorTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_teardown")
    @sandbox = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(@sandbox)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_cleanup_removes_sandbox
    executor = Ace::Demo::Molecules::DemoTeardownExecutor.new
    executor.execute(steps: ["cleanup"], sandbox_path: @sandbox)
    refute File.exist?(@sandbox)
  end

  def test_run_directive_executes_inside_sandbox
    executor = Ace::Demo::Molecules::DemoTeardownExecutor.new
    executor.execute(
      steps: [{"run" => "echo cleaned > teardown.txt"}],
      sandbox_path: @sandbox
    )

    assert_equal "cleaned\n", File.read(File.join(@sandbox, "teardown.txt"))
  end

  def test_unknown_directive_raises_argument_error
    executor = Ace::Demo::Molecules::DemoTeardownExecutor.new
    error = assert_raises(ArgumentError) do
      executor.execute(steps: ["unknown"], sandbox_path: @sandbox)
    end

    assert_includes error.message, "Unknown teardown directive"
  end
end
