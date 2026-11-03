# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_project_mount"

module Ace::Lab::Auth
  class SessionProjectMountTest < Minitest::Test
    def test_invalid_project_never_reaches_mount_runner
      mount = SessionProjectMount.new(runner: ->(*) { flunk "mount executed" })
      identity = SessionLauncher::Identity.new(unit: "unit", invocation_id: "id", process: {}, pidfd: nil)
      Process.stub(:euid, 0) do
        ["/lab/../etc", "/lab/ace/child", "/etc", nil].each do |path|
          assert_raises(Error) { mount.call(identity: identity, project: path) }
        end
      end
    end

    def test_unprivileged_mount_is_refused
      Process.stub(:euid, 1000) do
        assert_raises(Error) { SessionProjectMount.new.call(identity: nil, project: "/lab/ace") }
      end
    end

    def test_command_failure_is_not_reported_as_success_and_parent_handles_stay_open
      File.open(File::NULL) do |first|
        File.open(File::NULL) do |second|
          mount = SessionProjectMount.new
          assert_raises(Error) { mount.send(:run!, ["/usr/bin/false"], namespace: first, source: second) }
          refute first.closed?
          refute second.closed?
          assert mount.send(:run!, ["/usr/bin/true"], namespace: first, source: second)
        end
      end
    end
  end
end
