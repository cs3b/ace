# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/molecules/command_owner_admission"

module Ace
  module Lab
    class CommandOwnerAdmissionTest < Minitest::Test
      def test_trusted_directory_reuses_real_system_path_ownership_and_refuses_user_storage
        assert Molecules::GrantResolver.trusted_directory!("/usr/bin")
        Dir.mktmpdir("command-untrusted-") do |directory|
          assert_raises(Ace::Lab::InvalidConfigurationError) { Molecules::GrantResolver.trusted_directory!(directory) }
        end
      end
      def test_noncommand_operations_keep_the_existing_authorizer
        base = Object.new
        calls = []
        base.define_singleton_method(:authorize!) { |**options| calls << options; :supervisor }
        admission = Molecules::CommandOwnerAdmission.new(base: base, project: "ace",
          policy_loader: -> { flunk "ordinary task must not load command policy" })
        request = {"operation" => "register_assignment", "project_id" => "ace"}
        assert_equal :supervisor, admission.authorize!(request: request, peer: {"uid" => Process.uid}, deadline: 1)
        assert_equal request, calls.first.fetch(:request)
      end
      def test_command_route_cannot_change_project_before_policy_or_peer_observation
        admission = Molecules::CommandOwnerAdmission.new(base: Object.new, project: "ace",
          policy_loader: -> { flunk "foreign project must not load policy" })
        assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
          admission.authorize!(request: {"operation" => "command_admit", "project_id" => "other"}, peer: {}, deadline: 1)
        end
      end
      def test_original_requester_can_inspect_after_grant_revocation_without_effect_authority
        admission = Molecules::CommandOwnerAdmission.new(base: Object.new, project: "ace",
          policy_loader: -> { flunk "original nonroot inspection must not depend on a live execution grant" })
        skip "nonroot reconciliation fixture" if Process.uid.zero?
        left, right = UNIXSocket.pair
        captured = Ace::Assign::Authority::OrdinaryPeer.new.capture(left)
        assert admission.command_reader!(peer: captured, definition: {"requester" => {"uid" => Process.uid}},
          deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
        assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
          admission.command_reader!(peer: captured, definition: {"requester" => {"uid" => Process.uid + 1}},
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
        end
      ensure
        left&.close
        right&.close
      end
      def test_actual_nonroot_process_cannot_claim_installed_root_launcher
        skip "requires a nonroot caller" if Process.uid.zero?
        base = Object.new
        admission = Molecules::CommandOwnerAdmission.new(base: base, project: "ace",
          policy_loader: -> { Struct.new(:launcher).new({"identity_path" => "/absent-command-launcher"}) })
        peer = Ace::Assign::Authority::OrdinaryPeer.new
        left, right = UNIXSocket.pair
        captured = peer.capture(left)
        assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
          admission.command_launcher!(peer: captured, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
        end
      ensure
        left&.close
        right&.close
      end
    end
  end
end
