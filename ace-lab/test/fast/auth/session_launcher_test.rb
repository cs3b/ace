# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_launcher"
require "pty"

module Ace::Lab::Auth
  class SessionLauncherTest < Minitest::Test
    class Cgroups
      attr_accessor :retired
      attr_reader :handles
      def initialize
        @retired = false
        @handles = []
      end
      def pin(path)
        @handles << File.open(File::NULL)
        {handle: @handles.last, identity: {"path" => path}}
      end
      def member!(*, **) = true
      def retired?(_) = retired
    end

    def setup
      @cgroups = Cgroups.new
    end

    def teardown
      @cgroups.handles.each { |handle| handle.close unless handle.closed? }
    end

    def test_launch_passes_terminal_and_discards_ambient_environment
      observed = nil
      verified = []
      platform = Object.new
      platform.define_singleton_method(:supported!) { true }
      launcher = SessionLauncher.new(privileged: true, platform: platform,
        verify_path: ->(path) { verified << path },
        spawn: ->(*args, **options) { observed = [args, options]; 123 })
      unit = SessionUnit.new(role: "worker", id: "1234567890abcdef", command: ["/opt/ace/bin/pi"], directory: "/lab/ace")
      PTY.open do |master, slave|
        result = launcher.start(unit: unit, terminal: slave)
        assert_equal unit.name, result.unit
        assert_equal 123, result.transport_pid
        assert_equal ["/usr/bin/systemd-run", "/opt/ace/bin/pi", RbConfig.ruby, SessionLauncher::ENTRY], verified
        assert_equal unit.with_preparation_entry(ruby: RbConfig.ruby, entry: SessionLauncher::ENTRY).argv, observed.first.drop(1)
        assert File.file?(SessionLauncher::ENTRY)
        assert_equal true, observed.last[:unsetenv_others]
        assert_equal true, observed.last[:close_others]
        assert_equal slave, observed.last[:in]
        refute slave.closed?
      end
    end

    def test_unprivileged_launch_cannot_spawn
      launcher = SessionLauncher.new(privileged: false, spawn: ->(*) { flunk "spawned" })
      assert_raises(Error) { launcher.start(unit: nil, terminal: nil) }
    end

    def test_handoff_transfers_both_handles_with_exact_identity
      assert_handoff(role: "worker", directory: "/lab/ace")
    end

    def test_coordinator_handoff_transfers_root_only_for_lab_role
      assert_handoff(role: "lab-overseer", directory: "/lab")
    end

    def assert_handoff(role:, directory:)
      unit = "ace-auth-session-#{role}-1234567890abcdef.service"
      invocation = "a" * 32
      platform = Object.new
      platform.define_singleton_method(:live!) { |_| true }
      platform.define_singleton_method(:exited?) { |_| false }
      manager = Object.new
      manager.define_singleton_method(:unit_for_pidfd) { |handle:| {"unit" => unit, "invocation_id" => invocation} }
      launcher = SessionLauncher.new(privileged: true, platform: platform, cgroups: @cgroups, manager_factory: ->(_) { manager })
      # Socket activation wraps fd 3 as Socket; accept therefore returns
      # Socket, not UNIXSocket. Exercise the production descriptor class.
      sender, receiver = Socket.pair(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
      received = []
      PTY.open do |master, slave|
        File.open(File::NULL) do |handle|
          identity = SessionLauncher::Identity.new(unit: unit, invocation_id: invocation,
            process: {"pid" => 456}, pidfd: handle, cgroup: {handle: handle})
          assert_raises(ArgumentError) { launcher.handoff(identity, terminal: master, channel: sender, directory: directory, rows: 0, cols: 80) }
          if role == "worker"
            assert_raises(ArgumentError) { launcher.handoff(identity, terminal: master, channel: sender, directory: "/lab", rows: 24, cols: 80) }
          end
          assert launcher.handoff(identity, terminal: master, channel: sender, directory: directory, rows: 24, cols: 80)
          header, _, flags, *controls = receiver.recvmsg(4, 0, 4096, scm_rights: true)
          assert_equal 0, flags & Socket::MSG_CTRUNC
          assert_equal 1, controls.size
          received = controls.first.unix_rights
          assert_equal 2, received.size
          assert received.first.tty?
          assert_equal handle.stat.rdev, received.last.stat.rdev
          payload = JSON.parse(receiver.read(header.unpack1("N")))
          assert_equal({"protocol" => "ace.session-launch/v1", "unit" => unit,
            "invocation" => invocation, "pid" => 456, "rows" => 24, "cols" => 80, "directory" => directory}, payload)
          refute master.closed?
          refute handle.closed?
          manager.define_singleton_method(:unit_for_pidfd) { |handle:| {"unit" => unit, "invocation_id" => "b" * 32} }
          assert_raises(Error) { launcher.handoff(identity, terminal: master, channel: sender, directory: directory, rows: 24, cols: 80) }
          assert_nil IO.select([receiver], nil, nil, 0)
        end
      end
    ensure
      received&.each(&:close)
      sender&.close
      receiver&.close
    end

    def test_stop_uses_verified_unit_and_requires_confirmed_process_exit
      unit = "ace-auth-session-worker-1234567890abcdef.service"
      invocation = "a" * 32
      state = {"ActiveState" => "active", "MainPID" => "456", "InvocationID" => invocation}
      stopped = 0
      exited = false
      manager = Object.new
      manager.define_singleton_method(:inspect_units) { {"service" => state.dup} }
      manager.define_singleton_method(:unit_for_pidfd) { |handle:| {"unit" => unit, "invocation_id" => invocation} }
      manager.define_singleton_method(:stop_service) do
        stopped += 1
        state.merge!("ActiveState" => "inactive", "MainPID" => "0")
      end
      platform = Object.new
      platform.define_singleton_method(:exited?) { |_| exited }
      launcher = SessionLauncher.new(privileged: true, platform: platform, cgroups: @cgroups, manager_factory: ->(_) { manager })
      File.open(File::NULL) do |handle|
        identity = SessionLauncher::Identity.new(unit: unit, invocation_id: invocation, process: {}, pidfd: handle, cgroup: {handle: handle})
        assert_raises(Error) { launcher.stop(identity) }
        assert_equal 1, stopped
        exited = true
        assert launcher.stop(identity)
        assert_equal 2, stopped
        state["InvocationID"] = "b" * 32
        assert_raises(Error) { launcher.stop(identity) }
        assert_equal 2, stopped
        refute handle.closed?
      end
    end

    def test_collected_unit_requires_both_retired_pinned_group_and_exited_process
      exited = false
      platform = Object.new
      platform.define_singleton_method(:exited?) { |_| exited }
      inspections = 0
      manager = Object.new
      manager.define_singleton_method(:inspect_units) do
        inspections += 1
        raise Ace::Runtime::RuntimeUnavailableError, "unit collected"
      end
      launcher = SessionLauncher.new(privileged: true, platform: platform,
        cgroups: @cgroups, manager_factory: ->(_) { manager })
      File.open(File::NULL) do |handle|
        identity = SessionLauncher::Identity.new(unit: "ace-auth-session-worker-1234567890abcdef.service",
          invocation_id: "a" * 32, process: {}, pidfd: handle, cgroup: {handle: handle})
        assert_raises(Error) { launcher.stop(identity) }
        exited = true
        assert_raises(Error) { launcher.stop(identity) }
        @cgroups.retired = true
        assert launcher.stop(identity)
        assert_equal 2, inspections, "a retired original group must not stop a replacement unit"
        exited = false
        assert_raises(Error) { launcher.stop(identity) }
      end
    end

    def test_collection_racing_the_initial_observation_rechecks_original_group
      platform = Object.new
      platform.define_singleton_method(:exited?) { |_| true }
      cgroups = @cgroups
      manager = Object.new
      manager.define_singleton_method(:inspect_units) do
        cgroups.retired = true
        raise Ace::Runtime::RuntimeUnavailableError, "unit collected after initial observation"
      end
      launcher = SessionLauncher.new(privileged: true, platform: platform,
        cgroups: @cgroups, manager_factory: ->(_) { manager })
      File.open(File::NULL) do |handle|
        identity = SessionLauncher::Identity.new(unit: "ace-auth-session-worker-1234567890abcdef.service",
          invocation_id: "a" * 32, process: {}, pidfd: handle, cgroup: {handle: handle})
        assert launcher.stop(identity)
      end
    end

    def test_stop_rejects_unprivileged_caller_and_unbound_handle
      assert_raises(Error) { SessionLauncher.new(privileged: false).stop(nil) }
      assert_raises(ArgumentError) { SessionLauncher.new(privileged: true).stop(nil) }
    end

    def test_identity_uses_service_pid_and_rejects_replaced_invocation
      unit = "ace-auth-session-worker-1234567890abcdef.service"
      state = {"ActiveState" => "active", "MainPID" => "456", "InvocationID" => "a" * 32, "ControlGroup" => "/#{SessionPeer::SLICE}/#{unit}"}
      manager = Object.new
      manager.define_singleton_method(:inspect_units) { {"service" => state.dup} }
      manager.define_singleton_method(:unit_for_pidfd) { |handle:| {"unit" => unit, "invocation_id" => "a" * 32} }
      platform = Object.new
      platform.define_singleton_method(:capture) { |pid| {"pid" => pid, "uid" => 62000, "gid" => 62000, "groups" => []} }
      handles = []
      platform.define_singleton_method(:pin) { |_identity| handles << File.open(File::NULL); handles.last }
      platform.define_singleton_method(:exited?) { |_handle| false }
      launcher = SessionLauncher.new(privileged: true, platform: platform, cgroups: @cgroups, manager_factory: ->(_) { manager })
      launch = SessionLauncher::Launch.new(unit: unit, transport_pid: 123)
      identity = launcher.identify(launch)
      assert_equal 456, identity.process.fetch("pid")
      refute identity.pidfd.closed?
      state["InvocationID"] = "b" * 32
      assert_raises(Error) { launcher.identify(launch) }
      assert handles.last.closed?
    ensure
      handles&.each { |handle| handle.close unless handle.closed? }
    end
  end
end
