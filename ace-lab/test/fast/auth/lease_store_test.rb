# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"

module Ace
  module Lab
    module Auth
      class LeaseStoreTest < Minitest::Test
        def test_session_lock_is_exclusive_stable_and_invocation_scoped
          Dir.mktmpdir do |dir|
            store = LeaseStore.new(dir)
            unit = "ace-auth-session-worker-0123456789abcdef.service"
            held_path = nil
            store.with_session_lock(unit: unit, invocation: "a" * 32) do
              held_path = Dir.glob(File.join(dir, "session-*.lock")).fetch(0)
              File.open(held_path, File::RDWR) { |other| refute other.flock(File::LOCK_EX | File::LOCK_NB) }
              store.with_session_lock(unit: unit, invocation: "b" * 32) { assert_equal 2, Dir.children(dir).size }
            end
            inode = File.stat(held_path).ino
            store.with_session_lock(unit: unit, invocation: "a" * 32) { assert_equal inode, File.stat(held_path).ino }
            File.open(held_path, File::RDWR) { |other| assert other.flock(File::LOCK_EX | File::LOCK_NB) }
            assert_raises(ArgumentError) { store.with_session_lock(unit: unit, invocation: "0" * 32) {} }
          end
        end

        def test_rejects_empty_correlation_before_writing
          Dir.mktmpdir do |dir|
            store = LeaseStore.new(dir)
            options = {profile: "p", role: "r", principal: "p", task: "t", assignment: "a",
                       repos: ["repo"], use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil}
            %i[profile role principal task assignment].each do |field|
              assert_raises(Error) { store.create(**options.merge(field => "  ")) }
            end
            assert_empty store.all
          end
        end

        def test_rejects_partial_session_identity_before_writing
          Dir.mktmpdir do |dir|
            store = LeaseStore.new(dir)
            options = {profile: "p", role: "r", principal: "p", task: "t", assignment: "a",
                       repos: ["repo"], use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil}
            assert_raises(Error) { store.create(**options, issuer_invocation: "a" * 32) }
            assert_raises(Error) { store.create(**options, session_uid: 1234) }
            assert_empty store.all
            lease = store.create(**options)
            assert_raises(Error) { store.update(lease["id"]) { |record| record["session_uid"] = 1234 } }
            refute store.load(lease["id"]).key?("session_uid")
          end
        end

        def test_update_wraps_unreadable_record_errors
          Dir.mktmpdir do |dir|
            store = LeaseStore.new(dir)
            File.stub(:read, ->(*) { raise Errno::EACCES }) do
              assert_raises(Error) { store.update("lease-0123456789abcdef") {} }
            end
          end
        end

        def test_unreadable_inventory_is_not_an_empty_inventory
          store = LeaseStore.new("/unused")
          Dir.stub(:children, ->(*) { raise Errno::EACCES }) do
            error = assert_raises(Error) { store.all }
            assert_match(/inventory is unavailable/, error.message)
          end
        end

        def test_unreadable_record_and_lock_are_typed_failures
          store = LeaseStore.new("/unused")
          File.stub(:read, ->(*) { raise Errno::EACCES }) do
            error = assert_raises(Error) { store.load("lease-0123456789abcdef") }
            assert_match(/record.*unavailable/, error.message)
          end
          FileUtils.stub(:mkdir_p, ->(*) { raise Errno::EACCES }) do
            assert_raises(Error) { store.with_exec_lock("lease-0123456789abcdef") {} }
            assert_raises(Error) { store.with_write_lock("lease-0123456789abcdef") {} }
            assert_raises(Error) { store.with_correlation_lock(task: "t", assignment: "a", profile: "p", role: "r") {} }
            assert_raises(Error) { store.write({"id" => "lease-0123456789abcdef"}) }
          end
        end

        def test_errors_from_protected_work_are_not_reclassified_as_lock_errors
          Dir.mktmpdir do |dir|
            store = LeaseStore.new(dir)
            assert_raises(Errno::ENOENT) do
              store.with_exec_lock("lease-0123456789abcdef") { raise Errno::ENOENT }
            end
          end
        end

        def test_rejects_symlinked_and_hardlinked_lock_files
          Dir.mktmpdir do |dir|
            store = LeaseStore.new(dir)
            lock = File.join(dir, "lease-0123456789abcdef.exec.lock")
            other = File.join(dir, "other")
            File.write(other, "")
            File.symlink(other, lock)
            assert_raises(Error) { store.with_exec_lock("lease-0123456789abcdef") {} }
            File.unlink(lock)
            File.link(other, lock)
            assert_raises(Error) { store.with_exec_lock("lease-0123456789abcdef") {} }
          end
        end

        def test_distinct_correlations_do_not_share_a_separator_ambiguous_lock
          Dir.mktmpdir do |dir|
            store = LeaseStore.new(dir)
            store.with_correlation_lock(task: "a\eb", assignment: "c", profile: "p", role: "r") {}
            store.with_correlation_lock(task: "a", assignment: "b\ec", profile: "p", role: "r") {}
            assert_equal 2, Dir.children(dir).grep(/\Acorrelation-/).size
          end
        end
      end
    end
  end
end
