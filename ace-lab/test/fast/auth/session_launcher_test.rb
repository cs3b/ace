# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_launcher"
require "pty"

module Ace::Lab::Auth
  class SessionLauncherTest < Minitest::Test
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
      unit = "ace-auth-session-worker-1234567890abcdef.service"
      invocation = "a" * 32
      platform = Object.new
      platform.define_singleton_method(:live!) { |_| true }
      platform.define_singleton_method(:exited?) { |_| false }
      manager = Object.new
      manager.define_singleton_method(:unit_for_pidfd) { |handle:| {"unit" => unit, "invocation_id" => invocation} }
      launcher = SessionLauncher.new(privileged: true, platform: platform, manager_factory: ->(_) { manager })
      sender, receiver = UNIXSocket.pair
      received = []
      PTY.open do |master, slave|
        File.open(File::NULL) do |handle|
          identity = SessionLauncher::Identity.new(unit: unit, invocation_id: invocation,
            process: {"pid" => 456}, pidfd: handle)
          assert_raises(ArgumentError) { launcher.handoff(identity, terminal: master, channel: sender, rows: 0, cols: 80) }
          assert launcher.handoff(identity, terminal: master, channel: sender, rows: 24, cols: 80)
          header, _, flags, *controls = receiver.recvmsg(4, 0, 4096, scm_rights: true)
          assert_equal 0, flags & Socket::MSG_CTRUNC
          assert_equal 1, controls.size
          received = controls.first.unix_rights
          assert_equal 2, received.size
          assert received.first.tty?
          assert_equal handle.stat.rdev, received.last.stat.rdev
          payload = JSON.parse(receiver.read(header.unpack1("N")))
          assert_equal({"protocol" => "ace.session-launch/v1", "unit" => unit,
            "invocation" => invocation, "pid" => 456, "rows" => 24, "cols" => 80}, payload)
          refute master.closed?
          refute handle.closed?
          manager.define_singleton_method(:unit_for_pidfd) { |handle:| {"unit" => unit, "invocation_id" => "b" * 32} }
          assert_raises(Error) { launcher.handoff(identity, terminal: master, channel: sender, rows: 24, cols: 80) }
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
      launcher = SessionLauncher.new(privileged: true, platform: platform, manager_factory: ->(_) { manager })
      File.open(File::NULL) do |handle|
        identity = SessionLauncher::Identity.new(unit: unit, invocation_id: invocation, process: {}, pidfd: handle)
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

    def test_stop_rejects_unprivileged_caller_and_unbound_handle
      assert_raises(Error) { SessionLauncher.new(privileged: false).stop(nil) }
      assert_raises(ArgumentError) { SessionLauncher.new(privileged: true).stop(nil) }
    end

    def test_identity_uses_service_pid_and_rejects_replaced_invocation
      unit = "ace-auth-session-worker-1234567890abcdef.service"
      state = {"ActiveState" => "active", "MainPID" => "456", "InvocationID" => "a" * 32}
      manager = Object.new
      manager.define_singleton_method(:inspect_units) { {"service" => state.dup} }
      manager.define_singleton_method(:unit_for_pidfd) { |handle:| {"unit" => unit, "invocation_id" => "a" * 32} }
      platform = Object.new
      platform.define_singleton_method(:capture) { |pid| {"pid" => pid, "uid" => 62000, "gid" => 62000, "groups" => []} }
      handles = []
      platform.define_singleton_method(:pin) { |_identity| handles << File.open(File::NULL); handles.last }
      platform.define_singleton_method(:exited?) { |_handle| false }
      launcher = SessionLauncher.new(privileged: true, platform: platform, manager_factory: ->(_) { manager })
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
