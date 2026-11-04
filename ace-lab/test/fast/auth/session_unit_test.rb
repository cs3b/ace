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
        RuntimeDirectory=ace-auth-1234567890abcdef RuntimeDirectoryPreserve=no].each do |property|
        assert_includes unit.argv, "--property=#{property}"
      end
      assert_includes unit.argv, "--setenv=ACE_TOOLCHAIN=installed"
      assert_includes unit.argv, "--setenv=ACE_LAB_SESSION=1"
      assert_includes unit.argv, "--setenv=ACE_LAB_PROJECT_ROOT=/lab/ace"
      assert_equal ["--", "/opt/ace/bin/pi"], unit.argv.last(2)
      refute unit.argv.any? { |arg| arg.include?("WorkingDirectory=") }, "cwd must be selected after mount preparation"
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
