# frozen_string_literal: true
require_relative "../test_helper"
require "rbconfig"
require "timeout"

class RuntimeCaptureTest < DesignTest
  def runtime
    Ace::Design::Molecules::Runtime.new({"node" => "unused-node", "runtime_dir" => "/missing"})
  end

  def test_exited_child_preserves_status_and_output_and_terminates_pipe_owning_descendant
    Dir.mktmpdir do |root|
      marker = File.join(root, "descendant-terminated")
      script = <<~'CODE'
        $stdout.sync = $stderr.sync = true
        reader, writer = IO.pipe
        fork do
          reader.close
          trap("TERM") { File.write(ARGV.fetch(0), "terminated"); exit! 0 }
          puts "descendant stdout"
          warn "descendant stderr"
          writer.write("ready")
          writer.close
          sleep 20
        end
        writer.close
        reader.read
        reader.close
        puts "parent stdout"
        exit 7
      CODE
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = runtime.capture(RbConfig.ruby, "-e", script, marker, timeout: 2)
      assert_equal 7, result.fetch("exit_code")
      assert_includes result.fetch("stdout"), "parent stdout"
      assert_includes result.fetch("stdout"), "descendant stdout"
      assert_includes result.fetch("stderr"), "descendant stderr"
      assert_equal "terminated", File.read(marker)
      assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 3
    end
  end

  def test_interruption_cleans_the_command_before_open3_waiter_unwinds
    Dir.mktmpdir do |root|
      marker = File.join(root, "started")
      capture = Thread.new do
        runtime.capture(RbConfig.ruby, "-e", 'File.write(ARGV.fetch(0) + ".tmp", Process.pid); File.rename(ARGV.fetch(0) + ".tmp", ARGV.fetch(0)); sleep 20', marker, timeout: 30)
      rescue Interrupt
        :interrupted
      end
      capture.report_on_exception = false
      Timeout.timeout(5) { sleep 0.01 until File.file?(marker) }
      pid = Integer(File.read(marker))
      capture.raise(Interrupt)
      assert capture.join(3), "capture must clean up before Open3's waiter can block"
      assert_equal :interrupted, capture.value
      assert_raises(Errno::ESRCH) { Process.kill(0, pid) }
    ensure
      begin
        Process.kill("KILL", pid) if pid
      rescue Errno::ESRCH
        nil
      end
      capture&.kill if capture&.alive?
      capture&.join(1)
    end
  end

  def test_missing_non_browser_executable_identifies_the_actual_command
    error = assert_raises(Ace::Design::Error) { runtime.capture("/missing/design-git", timeout: 1) }
    assert_includes error.message, "/missing/design-git"
    refute_includes error.message, "Node"
    error = assert_raises(Ace::Design::Error) { runtime.capture(RbConfig.ruby, "-e", "sleep 20", timeout: 0.1) }
    assert_includes error.message, RbConfig.ruby
    refute_includes error.message, "inspection"
  end
end
