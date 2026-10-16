# frozen_string_literal: true
require_relative "../../test_helper"
require "rbconfig"
class RuntimeTest < DesignTest
  def runtime(node = "node")
    Ace::Design::Molecules::Runtime.new({"node" => node, "runtime_dir" => "/missing"})
  end
  def test_missing_executable_is_actionable_and_doctor_is_not_ready
    result = runtime("/missing/ace-design-node").doctor
    refute result["ready"]
    assert_includes result["error"], "Command executable unavailable: /missing/ace-design-node"
  end
  def test_capture_drains_both_streams_and_limits_retained_output
    result = runtime.capture(RbConfig.ruby, "-e", '$stdout.write("a" * 300000); $stderr.write("b" * 300000); exit 7', timeout: 5)
    assert_equal 7, result["exit_code"]
    assert_equal 262144, result["stdout"].bytesize
    assert_equal 262144, result["stderr"].bytesize
  end
  def test_capture_terminates_a_hung_process
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    error = assert_raises(Ace::Design::Error) { runtime.capture(RbConfig.ruby, "-e", 'sleep 20', timeout: 0.1) }
    assert_match(/timed out/, error.message)
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 3
  end
  def test_missing_script_is_a_child_process_error_not_missing_executable
    result = runtime.capture(RbConfig.ruby, "/missing/design-script.rb", timeout: 5)
    refute_equal 0, result["exit_code"]
    assert_includes result["stderr"], "design-script.rb"
  end
end
