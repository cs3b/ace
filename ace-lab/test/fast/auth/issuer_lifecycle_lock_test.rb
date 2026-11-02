# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "timeout"

module Ace
  module Lab
    module Auth
      class IssuerLifecycleLockTest < Minitest::Test
        def test_startup_recovery_waits_for_an_active_issuer
          parent = Process.euid.zero? && RUBY_PLATFORM.include?("linux") ? "/run" : nil
          Dir.mktmpdir("ace-issuer-lock-", parent) do |directory|
            store = LeaseStore.new(directory)
            entered = Queue.new
            release = Queue.new
            issuer = Thread.new do
              store.with_issuer_lifecycle_lock(exclusive: false) do
                entered << :issuer
                release.pop
              end
            end
            assert_equal :issuer, Timeout.timeout(2) { entered.pop }
            recovery = Thread.new do
              store.with_issuer_lifecycle_lock(exclusive: true) { entered << :recovery }
            end
            assert_nil recovery.join(0.05), "recovery must not overlap a live issuer"
            release << true
            assert issuer.join(2)
            assert recovery.join(2)
            assert_equal :recovery, entered.pop
          ensure
            release << true if issuer&.alive?
            issuer&.join(2)
            recovery&.join(2)
          end
        end

        def test_rejects_a_symlinked_lifecycle_lock
          parent = Process.euid.zero? && RUBY_PLATFORM.include?("linux") ? "/run" : nil
          Dir.mktmpdir("ace-issuer-lock-", parent) do |directory|
            File.symlink(File::NULL, File.join(directory, "issuer-lifecycle.lock"))
            assert_raises(Error) { LeaseStore.new(directory).with_issuer_lifecycle_lock(exclusive: true) {} }
          end
        end
      end
    end
  end
end
