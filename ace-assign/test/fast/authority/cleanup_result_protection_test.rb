# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/authority/cleanup_result_protection"

module Ace
  module Assign
    class CleanupResultProtectionTest < Minitest::Test
      Protection = Authority::CleanupResultProtection
      Stat = Struct.new(:uid, :gid, :mode, :kind) do
        def directory? = kind == :directory
        def file? = kind == :file
      end
      Handle = Struct.new(:stat)

      def policy(acl_error: false)
        mounts = Object.new
        mounts.define_singleton_method(:mount_identity) { |_| {"filesystem_type" => "tmpfs"} }
        reads = []
        acl = Object.new
        acl.define_singleton_method(:absent!) do |handle, name|
          reads << [handle, name]
          raise Ace::Runtime::RuntimeUnavailableError, "controlled ACL observation unavailable" if acl_error
        end
        [Protection.new(result_path: "/results/request.json", authority_gid: 13000, mounts: mounts, acl: acl), reads]
      end

      def test_exact_group_modes_and_acl_absence_at_held_result_and_parent
        selected, reads = policy
        parent = Handle.new(Stat.new(0, 13000, 0o2750, :directory))
        file = Handle.new(Stat.new(0, 13000, 0o640, :file))
        selected.verify!("/results", parent, directory: true)
        selected.verify!("/results/request.json", file, directory: false)
        assert_equal [[parent, "system.posix_acl_access"], [parent, "system.posix_acl_default"],
          [file, "system.posix_acl_access"]], reads
      end

      def test_wrong_group_world_read_parent_read_absence_and_acl_failure_refuse
        selected, = policy
        [[0, 13001, 0o640, :file], [0, 13000, 0o644, :file], [13000, 13000, 0o640, :file]].each do |values|
          assert_raises(Ace::Runtime::RuntimeUnavailableError) do
            selected.verify!("/results/request.json", Handle.new(Stat.new(*values)), directory: false)
          end
        end
        [0o2710, 0o2755, 0o2770].each do |mode|
          assert_raises(Ace::Runtime::RuntimeUnavailableError) do
            selected.verify!("/results", Handle.new(Stat.new(0, 13000, mode, :directory)), directory: true)
          end
        end
        unavailable, = policy(acl_error: true)
        assert_raises(Ace::Runtime::RuntimeUnavailableError) do
          unavailable.verify!("/results/request.json", Handle.new(Stat.new(0, 13000, 0o640, :file)), directory: false)
        end
        [0, 13000.0, false].each do |gid|
          assert_raises(ArgumentError) { Protection.new(result_path: "/results/request.json", authority_gid: gid) }
        end
      end
    end
  end
end
