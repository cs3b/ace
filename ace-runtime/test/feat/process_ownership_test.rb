# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class ProcessOwnershipTest < AceRuntimeTestCase
  def test_dead_owner_with_live_writing_descendant_is_unknown_and_preserves_files
    Dir.mktmpdir("runtime-writer") do |dir|
      path = File.join(dir, "work.txt")
      File.write(path, "preserved work\n")
      reader, writer = IO.pipe
      child = nil
      owner = fork do
        reader.close
        descendant = fork do
          writer.close
          loop do
            File.open(path, "a") { |file| file.puts("writer alive") }
            sleep 0.01
          end
        end
        writer.puts(descendant)
        writer.close
        exit! 0
      end
      writer.close
      child = Integer(reader.gets)
      reader.close
      Process.wait(owner)
      observer = Ace::Runtime::Molecules::ProcessIdentity.new
      assert_nil observer.owner(shell_pid: Process.pid, caller_pid: child)
      identity = observer.capture(child)
      assert_equal "live", observer.observe(identity)["liveness"]
      start_size = File.size(path)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 1
      until File.size(path) > start_size || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        sleep 0.01
      end
      assert_operator File.size(path), :>, start_size
      assert File.read(path).start_with?("preserved work")
    ensure
      Process.kill("TERM", child) if child
    end
  end
end
