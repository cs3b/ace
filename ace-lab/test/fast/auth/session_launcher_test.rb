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
