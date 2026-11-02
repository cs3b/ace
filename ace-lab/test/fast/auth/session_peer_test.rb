# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "ace/lab/auth/session_peer"

module Ace
  module Lab
    module Auth
      class SessionPeerTest < Minitest::Test
        UNIT = "ace-auth-session-worker-0123456789abcdef.service"
        GROUP = "/ace.slice/ace-auth.slice/ace-auth-sessions.slice/#{UNIT}"
        INVOCATION = "a" * 32
        Account = Struct.new(:name, :uid, :gid)

        class FakePlatform
          attr_accessor :exited, :groups
          def supported! = true
          def peer(_socket) = {"pid" => 123, "uid" => 62_000, "gid" => 62_000, "groups" => groups || [62_000]}
          def live!(_peer) = true
          def exited?(_handle) = !!exited
        end

        class FakeManager
          attr_accessor :properties, :invocation
          def initialize
            @invocation = INVOCATION
            @properties = {"User" => "ace-worker", "DynamicUser" => true,
                           "NoNewPrivileges" => true, "CapabilityBoundingSet" => 0,
                           "KillMode" => "control-group", "Delegate" => true,
                           "RuntimeDirectory" => ["ace-auth-0123456789abcdef"],
                           "RuntimeDirectoryPreserve" => "no"}
          end
          def unit_for_pidfd(handle:) = {"unit" => UNIT, "invocation_id" => invocation}
          def inspect_units = {"service" => {"ActiveState" => "active", "ControlGroup" => GROUP,
                                             "Slice" => SessionPeer::SLICE, "InvocationID" => INVOCATION}}
          def typed_properties(**) = properties
        end

        class FakeSocket
          def getsockopt(_level, _option)
            Struct.new(:int).new(IO.sysopen("/dev/null", "r"))
          end
        end

        def setup
          @root = Dir.mktmpdir
          @proc = File.join(@root, "proc")
          @runtime = File.join(@root, "run")
          @etc = File.join(@root, "etc")
          FileUtils.mkdir_p(@etc)
          File.write(File.join(@etc, "nsswitch.conf"), "passwd: files systemd\ngroup: files systemd\n")
          File.write(File.join(@etc, "passwd"), "root:x:0:0:root:/root:/bin/sh\n")
          File.write(File.join(@etc, "group"), "root:x:0:\n")
          FileUtils.mkdir_p(File.join(@proc, "123"))
          FileUtils.mkdir_p(File.join(@runtime, "ace-auth-0123456789abcdef"))
          File.write(File.join(@proc, "123", "cgroup"), "0::#{GROUP}\n")
          File.symlink(@root, File.join(@proc, "123", "cwd"))
          File.chmod(0o711, File.join(@runtime, "ace-auth-0123456789abcdef"))
          @platform, @manager = FakePlatform.new, FakeManager.new
          @peer = SessionPeer.new(platform: @platform, manager_factory: ->(_unit) { @manager },
            proc_root: @proc, runtime_root: @runtime, etc_root: @etc, owner_uid: Process.uid,
            account_lookup: ->(_uid) { Account.new("ace-worker", 62_000, 62_000) })
        end

        def teardown = FileUtils.remove_entry(@root)

        def test_returns_os_bound_identity_and_open_lifetime_handle
          identity = @peer.authenticate(FakeSocket.new)
          assert_equal 62_000, identity.uid
          assert_equal "worker", identity.role
          assert_equal INVOCATION, identity.invocation_id
          assert_equal File.realpath(@root), identity.cwd
          refute identity.pidfd.closed?
          identity.close
          assert identity.pidfd.closed?
        end

        def test_refuses_a_reused_unit_or_unsafe_runtime_policy
          @manager.invocation = "b" * 32
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          @manager.invocation = INVOCATION
          @manager.properties["RuntimeDirectoryPreserve"] = "yes"
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          @manager.properties["RuntimeDirectoryPreserve"] = "no"
          @manager.properties["Delegate"] = false
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_dead_peer_and_foreign_unit
          @platform.exited = true
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          @platform.exited = false
          File.write(File.join(@proc, "123", "cgroup"), "0::/user.slice/other.service\n")
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_supplementary_groups_outside_the_session
          @platform.groups = [62_000, 0]
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_static_identity_and_uncontrolled_name_services
          File.write(File.join(@etc, "passwd"), "ace-worker:x:62000:62000::/tmp:/bin/sh\n")
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          File.write(File.join(@etc, "passwd"), "root:x:0:0::/root:/bin/sh\n")
          File.write(File.join(@etc, "group"), "other:x:62000:\n")
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          File.write(File.join(@etc, "group"), "root:x:0:\n")
          File.write(File.join(@etc, "nsswitch.conf"), "passwd: files ldap systemd\ngroup: files systemd\n")
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_missing_dynamic_account
          peer = SessionPeer.new(platform: @platform, manager_factory: ->(_unit) { @manager },
            proc_root: @proc, runtime_root: @runtime, etc_root: @etc, owner_uid: Process.uid,
            account_lookup: ->(_uid) { raise ArgumentError, "not found" })
          assert_raises(Error) { peer.authenticate(FakeSocket.new) }
        end
      end
    end
  end
end
