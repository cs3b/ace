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
      unit = SessionUnit.new(role: "worker", id: "1234567890abcdef", command: ["/opt/ace/bin/pi"])
      PTY.open do |master, slave|
        result = launcher.start(unit: unit, terminal: slave)
        assert_equal unit.name, result.unit
        assert_equal 123, result.transport_pid
        assert_equal ["/usr/bin/systemd-run", "/opt/ace/bin/pi"], verified
        assert_equal unit.argv, observed.first.drop(1)
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
  end
end
