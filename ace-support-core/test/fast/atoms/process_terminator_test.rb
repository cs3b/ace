# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/atoms/process_terminator"

class ProcessTerminatorTest < Minitest::Test
  def setup
    @terminator = Ace::Core::Atoms::ProcessTerminator
  end

  def test_returns_false_for_nil_pid
    result = @terminator.terminate(nil)
    refute result
  end

  def test_returns_true_when_termination_attempted
    # Spawn a process that we can terminate
    pid = spawn("sleep", "60")

    # Verify process is running
    assert Process.kill(0, pid), "Process should be running"

    result = @terminator.terminate(pid)

    assert result

    # Verify process is gone (may need to wait and reap zombie)
    # Process.wait handles the zombie reaping
    begin
      Process.wait(pid, Process::WNOHANG)
    rescue Errno::ECHILD
      # Already reaped, that's fine
    end

    # Now check if process is gone
    begin
      Process.kill(0, pid)
      flunk "Process should have been terminated"
    rescue Errno::ESRCH
      pass # Expected - process is gone
    end
  ensure
    # Clean up in case test fails
    begin
      Process.kill("KILL", pid) if pid
      Process.wait(pid, Process::WNOHANG)
    rescue Errno::ESRCH, Errno::EPERM, Errno::ECHILD
      # Already dead, that's fine
    end
  end

  def test_handles_already_terminated_process
    # Spawn and immediately terminate a process
    pid = spawn("echo", "done")
    Process.wait(pid)

    # Should not raise, should return true
    result = @terminator.terminate(pid)
    assert result
  end

  def test_respects_custom_grace_period
    pid = spawn("sleep", "60")

    start_time = Time.now
    @terminator.terminate(pid, grace_period: 0.01)
    elapsed = Time.now - start_time

    # Should complete quickly with shorter grace period
    assert elapsed < 0.5, "Should complete quickly with short grace period"
  ensure
    begin
      Process.kill("KILL", pid) if pid
    rescue Errno::ESRCH, Errno::EPERM
      # Already dead
    end
  end
end
