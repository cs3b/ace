# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/session_runner"

module Ace
  module Lab
    module Auth
      class SessionRunnerTest < Minitest::Test
        class FakeAttachment
          Prepared = Struct.new(:procs, :kill, :events) do
            def close = [procs, kill, events].each { |io| io.close unless io.closed? }
            def terminate! = true
          end
          def prepare = Prepared.new(File.open(File::NULL, "w"), File.open(File::NULL, "w"), File.open(File::NULL))
          def verify_child!(_pid) = false
        end

        def test_requires_a_root_issuer
          skip "root-to-session behavior is exercised separately on Linux" if Process.euid.zero?

          error = assert_raises(ArgumentError) { SessionRunner.new(uid: Process.uid, cwd: Dir.pwd) }
          assert_match(/root issuer/, error.message)
        end

        def test_refuses_to_run_a_session_as_root
          Process.stub(:euid, 0) { assert_raises(ArgumentError) { SessionRunner.new(uid: 0, cwd: Dir.pwd) } }
        end

        def test_refuses_execution_without_attested_session_lifetime
          skip "requires a non-root account" if Process.uid.zero?

          Process.stub(:euid, 0) do
            runner = SessionRunner.new(uid: Process.uid, cwd: Dir.pwd)
            error = assert_raises(ArgumentError) { runner.call(["true"], {}) }
            assert_match(/session lifetime/, error.message)
          end
        end

        def test_false_attachment_never_releases_the_child
          skip "requires a Linux root test process" unless RUBY_PLATFORM.include?("linux") && Process.euid.zero?

          account = Etc.getpwnam("nobody")
          Dir.mktmpdir do |dir|
            File.chmod(0o777, dir)
            marker = File.join(dir, "executed")
            namespace = File.open(File::NULL)
            runner = SessionRunner.new(uid: account.uid, cwd: dir, attach: FakeAttachment.new,
              namespace: namespace, namespace_joiner: ->(_namespace) {})
            error = assert_raises(ArgumentError) { runner.call(["/usr/bin/touch", marker], {}) }
            assert_match(/attachment failed/, error.message)
            refute File.exist?(marker)
            namespace.close
          end
        end

        def test_cancellation_stops_the_launched_process_group
          skip "requires a Linux root test process" unless RUBY_PLATFORM.include?("linux") && Process.euid.zero?

          account = Etc.getpwnam("nobody")
          Dir.mktmpdir do |dir|
            File.chmod(0o777, dir)
            marker = File.join(dir, "children")
            attachment = FakeAttachment.new
            def attachment.verify_child!(_pid) = true
            namespace = File.open(File::NULL)
            runner = SessionRunner.new(uid: account.uid, cwd: dir, attach: attachment,
              namespace: namespace, namespace_joiner: ->(_namespace) {})
            main = Thread.current
            interrupter = Thread.new do
              deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
              sleep 0.01 until File.file?(marker) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
              main.raise(Interrupt, "cancel test")
            end
            begin
              assert_raises(Interrupt) do
                runner.call(["/bin/sh", "-c", 'sleep 60 & echo "$$ $!" > "$1.tmp"; mv "$1.tmp" "$1"; wait', "runner", marker], {})
              end
              assert File.file?(marker), "session command did not start"
              pids = File.read(marker).split.map { |value| Integer(value) }
              assert_equal 2, pids.length
              pids.each do |pid|
                deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
                loop do
                  stat = File.read("/proc/#{pid}/stat") rescue nil
                  break if !stat || stat.match?(/\) Z /) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
                  sleep 0.01
                end
                stat = File.read("/proc/#{pid}/stat") rescue nil
                assert(!stat || stat.match?(/\) Z /), "process #{pid} survived cancellation")
              end
            ensure
              interrupter.kill
              interrupter.join
              namespace.close
            end
          end
        end

        def test_returns_the_real_command_exit_status
          skip "requires a Linux root test process" unless RUBY_PLATFORM.include?("linux") && Process.euid.zero?

          account = Etc.getpwnam("nobody")
          Dir.mktmpdir do |dir|
            File.chmod(0o777, dir)
            attachment = FakeAttachment.new
            def attachment.verify_child!(_pid) = true
            namespace = File.open(File::NULL)
            runner = SessionRunner.new(uid: account.uid, cwd: dir, attach: attachment,
              namespace: namespace, namespace_joiner: ->(_namespace) {})
            assert_equal 0, runner.call(["/bin/sh", "-c", "exit 0"], {})
            assert_equal 7, runner.call(["/bin/sh", "-c", "exit 7"], {})
          ensure
            namespace&.close
          end
        end

        def test_refuses_execution_without_a_pinned_mount_namespace
          skip "requires a non-root account" if Process.uid.zero?
          Process.stub(:euid, 0) do
            runner = SessionRunner.new(uid: Process.uid, cwd: Dir.pwd, attach: FakeAttachment.new)
            error = assert_raises(ArgumentError) { runner.call(["true"], {}) }
            assert_match(/mount namespace/, error.message)
          end
        end

        def test_rejects_invalid_arguments_before_forking
          skip "requires a non-root account" if Process.uid.zero?
          Process.stub(:euid, 0) do
            runner = SessionRunner.new(uid: Process.uid, cwd: Dir.pwd)
            assert_raises(ArgumentError) { runner.call(["valid", "bad\0argument"], {}) }
            assert_raises(ArgumentError) { runner.call(["valid"], {"BAD=KEY" => "value"}) }
            assert_raises(ArgumentError) { runner.call(["valid"], nil) }
          end
        end
      end
    end
  end
end
