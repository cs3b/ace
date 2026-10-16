# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../../ace-assign/lib", __dir__)
require_relative "../test_helper"
require "open3"
require "rbconfig"
require "base64"
class CommandExecutorKernelTest < Minitest::Test
  def setup
    skip "requires disposable Linux root environment" unless RUBY_PLATFORM.include?("linux") && Process.uid.zero?
  end
  def probe(mode)
    source = File.expand_path("../support/command_executor_probe.rb", __dir__)
    output, error, status = Open3.capture3(RbConfig.ruby, "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), source, mode, stdin_data: "")
    assert status.success?, error
    assert_empty error, "single-thread helper must not emit unsafe-fork warnings"
    JSON.parse(output)
  end
  def output(result)
    result.fetch("frames").select { |frame| frame["type"] == "output" }.map { |frame| Base64.strict_decode64(frame.fetch("data")) }.join
  end
  def test_owned_double_fork_setsid_descendant_is_killed_and_reaped_after_normal_exit
    result = probe("detached")
    assert_nil result["error"], result["error_details"].inspect
    assert_equal 17, result.dig("result", "exit_status")
    refute result.dig("detached", "survived_cleanup"), "detached descendant outlived command cleanup"
  end
  def test_owned_detached_descendant_is_killed_and_reaped_after_transport_loss
    result = probe("detached_disconnect")
    assert_equal "IOError", result["error"]
    assert_nil result["result"], "lost transport must not produce canonical success"
    refute result.dig("detached", "survived_cleanup"), "detached descendant outlived disconnected command"
  end
  def test_real_nonroot_operator_and_trusted_filesystem_context
    result = probe("policy")
    assert_equal "operator", result.fetch("kind")
    assert_equal Etc.getpwnam("nobody").uid, result.fetch("caller_uid")
    assert_equal Etc.getpwnam("daemon").uid, result.fetch("executor_uid")
    assert_equal %w[requester_owned_alias writable_source changed_executable], result.fetch("denied")
  end
  def test_real_identity_pipes_eof_and_nonzero
    result = probe("pipes")
    assert_nil result["error"], result["error_details"].inspect
    actual = JSON.parse(output(result))
    assert_equal Etc.getpwnam("nobody").uid, actual.fetch("uid")
    assert_equal Etc.getpwnam("nobody").gid, actual.fetch("gid")
    assert_equal [], actual.fetch("groups")
    refute actual.fetch("tty")
    assert_equal "hello", actual.fetch("data")
    assert_equal 17, result.dig("result", "exit_status")
    assert_equal 1, result.dig("child", "no_new_privs")
    assert_equal ["0000000000000000"], result.dig("child", "capabilities").values.uniq
  end
  def test_lost_bind_and_claim_replay_never_execute
    result = probe("lost_bind")
    assert_empty result.fetch("frames")
    assert_equal "SecurityError", result["error"]
    refute_nil result["child"]
    assert_raises(Errno::ESRCH) { Process.kill(0, result.dig("child", "pid")) }
    replay = probe("replay_claim")
    assert_nil replay["child"]
    assert_equal %w[command_status command_claim], replay["events"]
    assert_empty replay.fetch("frames")
  end
  def test_real_pty_and_signal
    result = probe("pty")
    assert_nil result["error"], result["error_details"].inspect
    assert_includes output(result), "TTY=True"
    assert_equal 15, result.dig("result", "signal")
  end
  def test_getpass_no_echo_and_exact_resize
    result = probe("getpass")
    assert_nil result["error"], result["error_details"].inspect
    bytes = output(result)
    assert_includes bytes, "GOT=6"
    assert_includes bytes, "SIZE=(31, 97)"
    refute_includes bytes, "123456"
    assert_equal 0, result.dig("result", "exit_status")
  end
end
