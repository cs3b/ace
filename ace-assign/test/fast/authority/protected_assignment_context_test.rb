# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/protected_assignment_context"

module Ace
  module Assign
    class ProtectedAssignmentContextTest < AceAssignTestCase
      def descriptor(uids)
        owner = Object.new
        owner.define_singleton_method(:data) { {"projects" => {"project" => {"worker_uids" => uids}}} }
        owner
      end

      def context(current:, retained:, uid:, env: {})
        history = Object.new
        history.define_singleton_method(:descriptors) { retained }
        Authority::ProtectedAssignmentContext.new(deployment: current, history: history,
          uid: uid, env: env, kernel: Object.new)
      end

      def test_retained_worker_principal_cannot_restore_ordinary_mode_after_current_mapping_removal
        owner = context(current: descriptor([13006]), retained: [descriptor([13001])], uid: 13001)
        assert owner.protected_worker?
        assert_raises(AttemptErrors::EvidenceUnavailable) { owner.resolve(options: {}, assignment_id: nil, scope: nil) }
        assert_raises(AttemptErrors::EvidenceUnavailable) { owner.resolve(options: {}, assignment_id: "assignment", scope: "010") }
        ordinary = context(current: descriptor([13006]), retained: [descriptor([13001])], uid: 14000)
        refute ordinary.protected_worker?
        assert_nil ordinary.resolve(options: {}, assignment_id: "local", scope: nil)
      end

      def test_untrusted_selector_hints_must_agree_before_any_client_or_queue_effect
        owner = context(current: descriptor([13001]), retained: [], uid: 13001,
          env: {"ACE_ASSIGN_LAUNCH_MAPPING" => "original", "ACE_ASSIGN_ATTEMPT_ID" => "launch-original"})
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          owner.resolve(options: {mapping: "replacement", attempt: "launch-original"}, assignment_id: "assignment", scope: "010")
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          owner.resolve(options: {mapping: "original", attempt: "launch-replacement"}, assignment_id: "assignment", scope: "010")
        end
      end

      def test_only_absent_fixed_installation_is_ordinary_and_invalid_installed_owner_never_falls_back
        # Fixed filesystem/descriptor admission is completely injected. Any
        # unexpected path would fail this test instead of probing the host.
        paths = [Authority::Deployment::PATH, Authority::DeploymentHistory::PATH]
        missing = ->(path) { raise "unexpected filesystem boundary" unless paths.include?(path); raise Errno::ENOENT, path }
        Ace::Runtime::Molecules::ProtectedLinux.stub(:new, Object.new) do
          File.stub(:lstat, missing) { refute Authority::ProtectedAssignmentContext.load.protected_worker? }
        end
        present = ->(path) { raise "unexpected filesystem boundary" unless paths.include?(path); Object.new }
        File.stub(:lstat, present) do
          Authority::Deployment.stub(:load, -> { raise ArgumentError, "invalid installed owner" }) do
            assert_raises(ArgumentError) { Authority::ProtectedAssignmentContext.load }
          end
        end
      end

      def test_create_select_and_fork_session_refuse_retained_principal_before_owner_effects
        owner = context(current: descriptor([13006]), retained: [descriptor([13001])], uid: 13001)
        [CLI::Commands::Create.new, CLI::Commands::Select.new].each do |command|
          command.instance_variable_set(:@protected_assignment_context, owner)
          assert_raises(AttemptErrors::EvidenceUnavailable) { command.call }
        end
        forbidden = Object.new
        forbidden.define_singleton_method(:launch_provider_session) { |**_| raise "provider boundary must not execute" }
        command = CLI::Commands::ForkSession.new(launcher: forbidden)
        command.instance_variable_set(:@protected_assignment_context, owner)
        _, error = capture_io { assert_equal 1, command.call(assignment: "assignment", root: "010") }
        assert_includes error, "reviewed new prepared version and attempt"
      end
    end
  end
end
