# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_project_mount"

module Ace::Lab::Auth
  class SessionProjectMountTest < Minitest::Test
    def test_invalid_project_never_reaches_mount_runner
      mount = SessionProjectMount.new(runner: ->(*) { flunk "mount executed" })
      identity = SessionLauncher::Identity.new(unit: "ace-auth-session-worker-#{'a' * 16}.service", invocation_id: "id", process: {}, pidfd: nil)
      Process.stub(:euid, 0) do
        ["/lab", "/lab/../etc", "/lab/ace/child", "/etc", nil].each do |path|
          assert_raises(Error) { mount.call(identity: identity, project: path) }
        end
      end
    end

    def test_coordinator_root_requires_lab_role_before_process_or_mount_access
      reached = false
      platform = Object.new
      platform.define_singleton_method(:live!) { |_| reached = true; raise Error, "stop at identity validation" }
      mount = SessionProjectMount.new(platform: platform, runner: ->(*) { flunk "mount executed" })
      Process.stub(:euid, 0) do
        %w[worker verifier integrator project-overseer lab-overseer].each do |role|
          reached = false
          identity = SessionLauncher::Identity.new(unit: "ace-auth-session-#{role}-#{'a' * 16}.service",
            invocation_id: "id", process: {}, pidfd: nil)
          assert_raises(Error) { mount.call(identity: identity, project: "/lab") }
          assert_equal role == "lab-overseer", reached
        end
      end
    end

    def test_unprivileged_mount_is_refused
      Process.stub(:euid, 1000) do
        assert_raises(Error) { SessionProjectMount.new.call(identity: nil, project: "/lab/ace") }
      end
    end

    def test_coordinator_mount_checks_root_ancestor_and_reuses_lab_mountpoint
      commands, guards = [], []
      platform = Object.new
      platform.define_singleton_method(:live!) { |_| true }
      platform.define_singleton_method(:exited?) { |_| false }
      source = Object.new
      source.define_singleton_method(:stat) { Struct.new(:uid, :gid, :mode) { def directory? = true }.new(1000, 1000, 0o755) }
      source.define_singleton_method(:close) { true }
      namespace = File.open(File::NULL)
      identity = SessionLauncher::Identity.new(unit: "ace-auth-session-lab-overseer-#{'a' * 16}.service",
        invocation_id: "b" * 32, process: {"pid" => 123, "uid" => 62000, "gid" => 62000}, pidfd: namespace)
      mount = SessionProjectMount.new(platform: platform, runner: ->(argv, **) { commands << argv })
      Process.stub(:euid, 0) do
        SessionNamespace.stub(:capture, namespace) do
          SessionNamespace.stub(:matches?, true) do
            File.stub(:open, source) do
              File.stub(:realpath, ->(path) { path }) do
                Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, ->(path, **options) { guards << [path, options] }) do
                  assert mount.call(identity: identity, project: "/lab")
                end
              end
            end
          end
        end
      end
      assert_includes guards, ["/", {directory: true, owner: 0}]
      refute commands.any? { |argv| argv.include?("/bin/mkdir") && argv.last == "/lab" }
      assert commands.any? { |argv| argv.include?("X-mount.idmap=u:1000:62000:1 g:1000:62000:1") && argv.last == "/lab" }
    ensure
      namespace&.close unless namespace&.closed?
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
