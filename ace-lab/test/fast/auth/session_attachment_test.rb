# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "ace/lab/auth/session_attachment"

module Ace
  module Lab
    module Auth
      class SessionAttachmentTest < Minitest::Test
        UNIT = "ace-auth-session-worker-0123456789abcdef.service"
        INVOCATION = "a" * 32
        GROUP = "/ace.slice/ace-auth.slice/ace-auth-sessions.slice/#{UNIT}"

        def setup
          @peer, @main, @namespace = 3.times.map { File.open(File::NULL) }
          @namespace_matches = true
          @identity = SessionPeer::Identity.new(uid: 62_000, gid: 62_000, unit: UNIT, invocation_id: INVOCATION,
            pidfd: @peer, main_pidfd: @main, main_pid: 123, mount_namespace: @namespace)
          @platform = Object.new
          class << @platform
            attr_accessor :dead_handle, :parent_pid
          end
          def @platform.capture(pid) = {"pid" => pid, "uid" => 62_000, "gid" => 62_000, "groups" => [], "parent_pid" => parent_pid || Process.pid}
          def @platform.pin(_identity) = File.open(File::NULL)
          def @platform.exited?(handle) = handle == dead_handle
          @manager = Object.new
          class << @manager
            attr_accessor :invocation, :group
            def unit_for_pidfd(handle:) = {"unit" => UNIT, "invocation_id" => invocation || INVOCATION}
            def inspect_units = {"service" => {"ActiveState" => "active", "Slice" => SessionPeer::SLICE,
              "InvocationID" => invocation || INVOCATION, "ControlGroup" => group || GROUP}}
          end
          @opened = nil
        end

        def teardown
          [@peer, @main, @namespace, @opened, @kill].compact.each { |io| io.close unless io.closed? }
        end

        def attachment(opener: ->(_group) { @opened = File.open(File::NULL, "w"); @kill = File.open(File::NULL, "w"); SessionAttachment::Prepared.new(procs: @opened, kill: @kill) })
          SessionAttachment.new(identity: @identity, platform: @platform, manager: @manager,
            cgroup_opener: opener, namespace_matcher: ->(_namespace, _pid) { @namespace_matches })
        end

        def test_prepares_descriptor_and_verifies_the_child_without_migrating_a_pid
          Process.stub(:euid, 0) do
            owner = attachment
            descriptor = owner.prepare
            assert_same @opened, descriptor.procs
            assert_same @kill, descriptor.kill
            assert owner.verify_child!(1234)
          end
        end

        def test_refuses_changed_namespace_or_invocation_before_opening
          Process.stub(:euid, 0) do
            @namespace_matches = false
            assert_raises(Error) { attachment.prepare }
            assert_nil @opened
            @namespace_matches = true
            @manager.invocation = "b" * 32
            assert_raises(Error) { attachment.prepare }
            assert_nil @opened
          end
        end

        def test_closes_descriptor_if_invocation_changes_during_open
          opener = ->(_group) { @opened = File.open(File::NULL, "w"); @kill = File.open(File::NULL, "w"); @manager.invocation = "b" * 32; SessionAttachment::Prepared.new(procs: @opened, kill: @kill) }
          Process.stub(:euid, 0) { assert_raises(Error) { attachment(opener: opener).prepare } }
          assert @opened.closed?
          assert @kill.closed?
        end

        def test_refuses_a_child_with_a_different_parent
          @platform.parent_pid = Process.pid + 1
          Process.stub(:euid, 0) { assert_raises(Error) { attachment.verify_child!(1234) } }
        end

        def test_reports_a_vanished_cgroup_as_a_typed_error
          opener = ->(_group) { raise Errno::ENOENT }
          Process.stub(:euid, 0) { assert_raises(Error) { attachment(opener: opener).prepare } }
        end

        def test_session_verification_refuses_an_exited_main_process
          @platform.dead_handle = @main
          Process.stub(:euid, 0) { assert_raises(Error) { attachment.verify_session! } }
        end
      end
    end
  end
end
