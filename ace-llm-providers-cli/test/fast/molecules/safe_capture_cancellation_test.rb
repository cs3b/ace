# frozen_string_literal: true
require_relative "../../test_helper"
require "tmpdir"
require "timeout"
require "rbconfig"

class SafeCaptureCancellationTest < Minitest::Test
  def test_worker_interrupt_terminates_child_before_unwinding_open3
    capture = Ace::LLM::Providers::CLI::Molecules::SafeCapture
    Dir.mktmpdir do |root|
      marker = File.join(root, "pid")
      worker = Thread.new do
        Thread.current.report_on_exception = false
        capture.call([RbConfig.ruby, "-e", 'File.write(ARGV[0] + ".tmp", Process.pid); File.rename(ARGV[0] + ".tmp", ARGV[0]); sleep 60', marker], timeout: 60)
      rescue Interrupt
        :cancelled
      end
      begin
        Timeout.timeout(5) { sleep 0.01 until File.file?(marker) }
        pid = Integer(File.read(marker))
        worker.raise(Interrupt)
        assert_equal :cancelled, Timeout.timeout(8) { worker.value }
        assert_raises(Errno::ESRCH) { Process.kill(0, pid) }
      ensure
        Process.kill("KILL", pid) if pid && process_alive?(pid)
        worker.kill if worker.alive?
        worker.join(1)
      end
    end
  end
  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end
