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
          attr_accessor :exited, :groups, :main_uid, :main_exited
          def supported! = true
          def peer(_socket) = {"pid" => 123, "uid" => 62_000, "gid" => 62_000, "groups" => groups || [62_000]}
          def capture(pid) = {"pid" => pid, "uid" => main_uid || 62_000, "gid" => 62_000, "groups" => groups || [62_000]}
          def pin(_identity) = (@main_handle = File.open(File::NULL))
          def same?(left, right) = left == right
          def live!(_peer) = true
          def exited?(handle) = !!exited || (handle == @main_handle && !!main_exited)
        end

        class FakeManager
          attr_accessor :properties, :invocation, :main_pid
          def initialize
            @invocation = INVOCATION
            @main_pid = "123"
            @properties = {"User" => "ace-worker", "DynamicUser" => true,
                           "NoNewPrivileges" => true, "CapabilityBoundingSet" => 0,
                           "KillMode" => "control-group", "Delegate" => false,
                           "RuntimeDirectory" => ["ace-auth-0123456789abcdef"],
                           "RuntimeDirectoryPreserve" => "no", "RemainAfterExit" => true,
                           "BindsTo" => [SessionPeer::ISSUER_UNIT], "After" => [SessionPeer::ISSUER_UNIT], "Environment" => ["ACE_TOOLCHAIN=installed",
                             "ACE_LAB_SESSION=1", "ACE_LAB_PROJECT_ROOT=/lab/ace",
                             "PATH=/opt/ace/runtime/bin:/usr/bin:/bin", "GEM_HOME=/opt/ace/runtime", "GEM_PATH=/opt/ace/runtime"]}
          end
          def unit_for_pidfd(handle:) = {"unit" => UNIT, "invocation_id" => invocation}
          def inspect_units = {"service" => {"ActiveState" => "active", "ControlGroup" => GROUP,
                                             "Slice" => SessionPeer::SLICE, "InvocationID" => INVOCATION,
                                             "MainPID" => main_pid}}
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
          @namespace_matches = true
          @peer = SessionPeer.new(platform: @platform, manager_factory: ->(_unit) { @manager },
            proc_root: @proc, runtime_root: @runtime, etc_root: @etc, owner_uid: Process.uid,
            account_lookup: ->(_uid) { Account.new("ace-worker", 62_000, 62_000) },
            namespace_factory: ->(_pid) { @captured_namespace = File.open(File::NULL) },
            namespace_matcher: ->(_namespace, _pid) { @namespace_matches }, privileged: -> { true })
        end

        def teardown = FileUtils.remove_entry(@root)

        def test_isolation_properties_cross_the_real_manager_boundary
          command = Object.new
          values = @manager.properties
          command.define_singleton_method(:call) do |argv, timeout:|
            argv.drop(argv.index("org.freedesktop.systemd1.Service") + 1).map do |key|
              JSON.generate("type" => SessionPeer::PROPERTIES.fetch(key), "data" => values.fetch(key))
            end.join("\n")
          end
          manager = Ace::Runtime::Molecules::SystemdScopeManager.new(
            slice_unit: SessionPeer::SLICE, service_unit: UNIT, command: command)
          assert_equal values.slice(*SessionPeer::PROPERTIES.keys), manager.typed_properties(
            unit: UNIT, interface: "Service", signatures: SessionPeer::PROPERTIES)
        end

        def test_root_target_observation_reuses_complete_session_policy
          expected = @platform.capture(123)
          identity = @peer.authenticate_process(expected)
          assert_equal UNIT, identity.unit
          assert_equal INVOCATION, identity.invocation_id
          assert_equal 123, identity.main_pid
          identity.close
          @manager.properties["Delegate"] = true
          assert_raises(Error) { @peer.authenticate_process(expected) }
        end

        def test_target_observation_rejects_changed_process_and_nonmain_child
          expected = @platform.capture(123)
          assert_raises(Error) { @peer.authenticate_process(expected.merge("uid" => 62_001)) }
          @manager.main_pid = "124"
          assert_raises(Error) { @peer.authenticate_process(expected) }
          assert @captured_namespace.closed?
        end

        def test_target_observation_is_not_available_to_an_unprivileged_caller
          peer = SessionPeer.new(privileged: -> { false })
          assert_raises(Error) { peer.authenticate_process(@platform.capture(123)) }
        end

        def test_returns_os_bound_identity_and_open_lifetime_handle
          identity = @peer.authenticate(FakeSocket.new)
          assert_equal 62_000, identity.uid
          assert_equal "worker", identity.role
          assert_equal INVOCATION, identity.invocation_id
          assert_equal File.realpath(@root), identity.cwd
          refute identity.pidfd.closed?
          refute identity.main_pidfd.closed?
          refute identity.mount_namespace.closed?
          identity.close
          assert identity.pidfd.closed?
          assert identity.main_pidfd.closed?
          assert identity.mount_namespace.closed?
        end

        def test_runtime_environment_is_bound_to_the_authenticated_systemd_unit
          identity = @peer.authenticate(FakeSocket.new)
          assert_equal({"ACE_TOOLCHAIN" => "installed", "PATH" => "/opt/ace/runtime/bin:/usr/bin:/bin",
            "GEM_HOME" => "/opt/ace/runtime", "GEM_PATH" => "/opt/ace/runtime"}, identity.runtime_environment)
          assert identity.runtime_environment.frozen?
          assert identity.runtime_environment.values.all?(&:frozen?)
        ensure
          identity&.close
        end

        def test_refuses_missing_or_ambiguous_runtime_environment
          original = @manager.properties.fetch("Environment").dup
          [original.reject { |item| item.start_with?("PATH=") }, original + ["PATH=/tmp/bin"]].each do |environment|
            @manager.properties["Environment"] = environment
            assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          end
        end

        def test_refuses_a_reused_unit_or_unsafe_runtime_policy
          @manager.invocation = "b" * 32
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          @manager.invocation = INVOCATION
          @manager.properties["RuntimeDirectoryPreserve"] = "yes"
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          @manager.properties["RuntimeDirectoryPreserve"] = "no"
          @manager.properties["Delegate"] = true
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_dead_peer_and_foreign_unit
          @platform.exited = true
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          @platform.exited = false
          File.write(File.join(@proc, "123", "cgroup"), "0::/user.slice/other.service\n")
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_unavailable_peer_kernel_support_is_a_typed_error
          socket = Object.new
          def socket.getsockopt(*) = raise(Errno::ENOPROTOOPT)
          error = assert_raises(Error) { @peer.authenticate(socket) }
          assert_match(/identity could not be verified/, error.message)
        end

        def test_manager_identity_failures_are_typed_auth_errors
          @manager.define_singleton_method(:unit_for_pidfd) { |handle:| raise Ace::Runtime::RuntimeUnavailableError }
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_supplementary_groups_outside_the_session
          @platform.groups = [62_000, 0]
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_main_process_owned_by_another_identity
          @platform.main_uid = 62_001
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_refuses_a_namespace_changed_during_authentication
          @namespace_matches = false
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          assert @captured_namespace.closed?
        end

        def test_distinct_exited_main_process_is_rejected_even_if_peer_is_alive
          @manager.main_pid = "124"
          @platform.main_exited = true
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

        def test_runtime_directory_emptiness_uses_pinned_inode
          skip "descriptor-based directory support unavailable" unless Dir.respond_to?(:for_fd)
          path = File.join(@root, "pinned")
          FileUtils.mkdir_p(path)
          File.open(path) do |directory|
            File.rename(path, path + ".old")
            FileUtils.mkdir_p(path)
            File.write(File.join(path + ".old", "unexpected"), "x")
            refute @peer.send(:empty_directory?, directory)
          end
        end

        def test_terminal_binding_is_read_from_systemd_and_rejects_ambiguous_or_invalid_values
          environment = @manager.properties.fetch("Environment")
          environment << "ACE_LAB_TERMINAL_ID=term_abcdef12"
          identity = @peer.authenticate(FakeSocket.new)
          assert_equal "term_abcdef12", identity.terminal_id
          identity.close
          environment << "ACE_LAB_TERMINAL_ID=term_abcdef13"
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          environment.pop
          environment[-1] = "ACE_LAB_TERMINAL_ID=w1:p1"
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end

        def test_project_binding_comes_from_systemd_and_ambiguous_environment_is_refused
          identity = @peer.authenticate(FakeSocket.new)
          assert_equal "/lab/ace", identity.project_root
          identity.close
          @manager.properties["Environment"] << "ACE_LAB_PROJECT_ROOT=/lab/other"
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
          @manager.properties["Environment"] = ["ACE_TOOLCHAIN=auto", "ACE_LAB_SESSION=1", "ACE_LAB_PROJECT_ROOT=/lab/ace"]
          assert_raises(Error) { @peer.authenticate(FakeSocket.new) }
        end
      end
    end
  end
end
