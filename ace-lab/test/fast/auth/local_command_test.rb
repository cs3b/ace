# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/local_command"
require "rbconfig"

module Ace::Lab::Auth
  class LocalCommandTest < Minitest::Test
    def test_child_receives_only_explicit_environment_and_real_exit_status
      Dir.mktmpdir do |dir|
        output = File.join(dir, "environment.json")
        script = 'require "json"; File.write(ARGV.fetch(0), JSON.generate(ENV.to_h)); exit 23'
        result = LocalCommand.new.call([RbConfig.ruby, "-e", script, output],
          {"ACE_TOOLCHAIN" => "installed", "ONLY_SECRET" => "fixture-value"}, deadline: Time.now + 5)
        assert_equal 23, result
        received = JSON.parse(File.read(output))
        # Ruby on macOS adds its own CoreFoundation text encoding variable.
        received.delete("__CF_USER_TEXT_ENCODING")
        assert_equal({"ACE_TOOLCHAIN" => "installed", "ONLY_SECRET" => "fixture-value"}, received)
      end
    end

    def test_expired_command_does_not_start
      assert_raises(Refusal) do
        LocalCommand.new.call([RbConfig.ruby, "-e", "exit 0"], {}, deadline: Time.now - 1)
      end
    end

    def test_deadline_stops_child_and_returns_timeout
      Dir.mktmpdir do |dir|
        marker = File.join(dir, "late")
        script = 'sleep 0.4; File.write(ARGV.fetch(0), "escaped")'
        assert_equal 124, LocalCommand.new.call([RbConfig.ruby, "-e", script, marker], {}, deadline: Time.now + 0.1)
        sleep 0.5
        refute File.exist?(marker)
      end
    end

    def test_descendants_are_stopped_when_main_command_exits
      Dir.mktmpdir do |dir|
        marker = File.join(dir, "late")
        script = 'fork { sleep 0.4; File.write(ARGV.fetch(0), "escaped") }; exit 0'
        assert_equal 0, LocalCommand.new.call([RbConfig.ruby, "-e", script, marker], {}, deadline: Time.now + 5)
        sleep 0.5
        refute File.exist?(marker)
      end
    end

    def test_stopping_the_launcher_terminates_its_command
      Dir.mktmpdir do |dir|
        ready, late = File.join(dir, "ready"), File.join(dir, "late")
        launcher = fork do
          script = 'File.write(ARGV.fetch(0), "ready"); sleep 0.5; File.write(ARGV.fetch(1), "escaped")'
          LocalCommand.new.call([RbConfig.ruby, "-e", script, ready, late], {}, deadline: Time.now + 5)
          exit! 0
        rescue SignalException
          exit! 143
        end
        Timeout.timeout(3) { sleep 0.01 until File.file?(ready) }
        Process.kill("TERM", launcher)
        _, status = Timeout.timeout(3) { Process.wait2(launcher) }
        launcher = nil
        assert_equal 143, status.exitstatus
        sleep 0.6
        refute File.exist?(late)
      ensure
        if launcher
          Process.kill("KILL", launcher) rescue nil
          Process.wait(launcher) rescue nil
        end
      end
    end
  end
end
