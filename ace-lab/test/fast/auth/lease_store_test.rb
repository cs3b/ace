# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"

module Ace
  module Lab
    module Auth
      class LeaseStoreTest < Minitest::Test
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
      end
    end
  end
end
