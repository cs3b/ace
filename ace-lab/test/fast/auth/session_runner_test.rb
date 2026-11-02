# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/session_runner"

module Ace
  module Lab
    module Auth
      class SessionRunnerTest < Minitest::Test
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
            runner = SessionRunner.new(uid: account.uid, cwd: dir, attach: ->(_pid) { false })
            error = assert_raises(ArgumentError) { runner.call(["/usr/bin/touch", marker], {}) }
            assert_match(/attachment failed/, error.message)
            refute File.exist?(marker)
          end
        end
      end
    end
  end
end
