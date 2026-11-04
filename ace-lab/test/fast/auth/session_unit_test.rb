# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_unit"

module Ace::Lab::Auth
  class SessionUnitTest < Minitest::Test
    def build(**changes)
      SessionUnit.new(**{role: "worker", id: "1234567890abcdef", command: ["/opt/ace/bin/pi"], directory: "/lab/ace"}.merge(changes))
    end

    def test_unit_matches_authenticated_peer_contract_and_enforces_installed_mode
      unit = build
      assert SessionPeer::UNIT.match?(unit.name)
      %w[DynamicUser=yes NoNewPrivileges=yes CapabilityBoundingSet= Delegate=no KillMode=control-group
        RemainAfterExit=yes BindsTo=ace-lab-auth.service After=ace-lab-auth.service TimeoutStopSec=10s
        RuntimeDirectory=ace-auth-1234567890abcdef RuntimeDirectoryPreserve=no].each do |property|
        assert_includes unit.argv, "--property=#{property}"
      end
      assert_includes unit.argv, "--setenv=ACE_TOOLCHAIN=installed"
      assert_includes unit.argv, "--setenv=ACE_LAB_SESSION=1"
      assert_includes unit.argv, "--setenv=ACE_LAB_PROJECT_ROOT=/lab/ace"
      assert_equal ["--", "/opt/ace/bin/pi"], unit.argv.last(2)
      refute unit.argv.any? { |arg| arg.include?("WorkingDirectory=") }, "cwd must be selected after mount preparation"
    end

    def test_worktree_entry_keeps_canonical_project_authority
      unit = build(directory: "/lab/ace/.ace-wt/task-1", project_root: "/lab/ace")
      prepared = unit.with_preparation_entry(ruby: "/opt/ruby", entry: "/opt/entry")
      assert_equal "/lab/ace/.ace-wt/task-1", prepared.directory
      assert_includes prepared.argv, "--setenv=ACE_LAB_PROJECT_ROOT=/lab/ace"
      assert_equal ["--directory", "/lab/ace/.ace-wt/task-1", "--", "/opt/ace/bin/pi"], prepared.argv.last(4)
      assert_raises(ArgumentError) { build(directory: "/lab/other", project_root: "/lab/ace") }
    end

    def test_host_terminal_binding_survives_preparation_and_cannot_be_injected_via_environment
      unit = build(terminal_id: "term_abcdef12")
      prepared = unit.with_preparation_entry(ruby: "/opt/ruby", entry: "/opt/entry")
      assert_includes prepared.argv, "--setenv=ACE_LAB_TERMINAL_ID=term_abcdef12"
      assert_includes prepared.argv, "--setenv=HERDR_ENV=1"
      assert_includes prepared.argv, "--setenv=HERDR_PANE_ID=term_abcdef12"
      assert_includes prepared.argv, "--setenv=HERDR_SOCKET_PATH=#{IssuerClient::SOCKET}"
      assert_raises(ArgumentError) { build(environment: {"HERDR_SOCKET_PATH" => "/tmp/native.sock"}) }
      assert_raises(ArgumentError) { build(terminal_id: "w1:p1") }
      assert_raises(ArgumentError) { build(terminal_id: "term_abc\n") }
      assert_raises(ArgumentError) { build(environment: {"ACE_LAB_TERMINAL_ID" => "term_abcdef12"}) }
    end

    def test_rejects_identity_and_environment_injection
      assert_raises(ArgumentError) { build(role: "root") }
      assert_raises(ArgumentError) { build(id: "../other") }
      assert_raises(ArgumentError) { build(command: ["pi"]) }
      assert_raises(ArgumentError) { build(directory: "../project") }
      assert_raises(ArgumentError) { build(directory: "/lab/../etc") }
      assert_raises(ArgumentError) { build(environment: {"ACE_TOOLCHAIN" => "auto"}) }
      assert_raises(ArgumentError) { build(environment: {"ACE_LAB_PROJECT_ROOT" => "/lab/other"}) }
      assert_raises(ArgumentError) { build(environment: {"LD_PRELOAD" => "/tmp/inject.so"}) }
    end
  end
end
