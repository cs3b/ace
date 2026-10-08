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

      def participant_descriptor(base)
        roles = %w[launcher_uids reviewer_uids worker_uids service_executor_uids supervisor_uids]
        project = roles.each_with_index.to_h { |key, index| [key, [base + index]] }
        project["service_receivers"] = {"receiver" => {"executor_uid" => base + 5}}
        project["inbox_contexts"] = {"context" => {"owner_credentials" => {"uid" => base + 6}}}
        owner = Object.new
        owner.define_singleton_method(:data) do
          {"projects" => {"project" => project}, "authorities" => {"authority" => {"uid" => base + 7}},
            "launch_mappings" => {"mapping" => {"launcher_uid" => base + 8, "worker_uid" => base + 9}}}
        end
        owner
      end

      def test_all_current_and_retained_installed_accounts_are_protected_without_granting_a_role
        current, original = participant_descriptor(13000), participant_descriptor(14000)
        (13000..13009).each do |uid|
          assert context(current: current, retained: [original], uid: uid).protected_participant?, "current account #{uid}"
        end
        (14000..14009).each do |uid|
          assert context(current: current, retained: [original], uid: uid).protected_participant?, "retained account #{uid}"
        end
        [13010, 13011, 14010, 14011].each { |uid| refute context(current: current, retained: [original], uid: uid).protected_participant? }
        refute context(current: current, retained: [original], uid: 15000).protected_participant?
        refute Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, uid: 13000).protected_participant?
        invalid = context(current: descriptor([13000]), retained: [], uid: 13000)
        assert_raises(AttemptErrors::EvidenceUnavailable) { invalid.protected_participant? }
      end

      def test_installed_transport_selection_requires_admitted_original_mapping_and_project
        current = descriptor([13001])
        current.define_singleton_method(:mapping) { |_| {"project_id" => "project"} }
        owner = context(current: current, retained: [], uid: 13001,
          env: {"ACE_ASSIGN_LAUNCH_MAPPING" => "mapping"})
        assert owner.mapping_hint?
        input = Struct.new(:descriptor).new({"mapping_id" => "mapping", "project_id" => "project"})
        selected = owner.with_installed_selection(options: {mapping: "mapping"}, input: input) { |deployment, kernel, mapping| [deployment, kernel, mapping] }
        assert_same current, selected.first
        assert_equal "mapping", selected.last
        [{"mapping_id" => "foreign", "project_id" => "project"}, {"mapping_id" => "mapping", "project_id" => "foreign"}].each do |bad|
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            owner.with_installed_selection(options: {mapping: "mapping"}, input: Struct.new(:descriptor).new(bad)) { flunk "no transport effect" }
          end
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          owner.with_installed_selection(options: {mapping: "replacement"}, input: input) { flunk "hint mismatch" }
        end
        ordinary = Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, env: {})
        refute ordinary.mapping_hint?
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          ordinary.with_installed_selection(options: {mapping: "mapping"}, input: input) { flunk "no installed owner" }
        end
      end

      def test_absent_installed_mapping_and_project_are_typed_unavailable_without_yield
        current = descriptor([13001])
        owner = context(current: current, retained: [], uid: 13001)
        input = Struct.new(:descriptor).new({"mapping_id" => "mapping", "project_id" => "project"})
        current.define_singleton_method(:mapping) { |_| raise KeyError, "missing mapping" }
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          owner.with_installed_selection(options: {mapping: "mapping"}, input: input) { flunk "absent mapping has no transport" }
        end
        current.define_singleton_method(:mapping) { |_| {} }
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          owner.with_installed_selection(options: {mapping: "mapping"}, input: input) { flunk "missing project has no transport" }
        end
      end

      def test_inbox_workflow_holds_installed_references_and_yields_selected_mapping
        references = [{"path" => "/fixed/descriptor"}, {"path" => "/fixed/history"}]
        map = {"project_id" => "project", "authority_id" => "authority"}
        current = Object.new
        current.define_singleton_method(:artifact_reference) { references.first }
        current.define_singleton_method(:mapping) { |id| raise KeyError unless id == "mapping"; map }
        current.define_singleton_method(:inbox_context) do |mapping, id|
          raise KeyError unless [mapping, id] == ["mapping", "context"]
          {"control_socket_path" => "/fixed/context.sock", "owner_credentials" => {"uid" => 20}, "native_mapping_id" => mapping}
        end
        current.define_singleton_method(:authority) { |_| {"socket_path" => "/fixed/authority.sock", "uid" => 21, "gid" => 21, "groups" => []} }
        history = Object.new
        history.define_singleton_method(:artifact_reference) { references.last }
        history.define_singleton_method(:selects?) { |owner| owner.equal?(current) }
        calls = []
        held = Object.new
        held.define_singleton_method(:read!) { |ref| calls << ref }
        held.define_singleton_method(:verify_unchanged!) { calls << :verified }
        artifacts = Object.new
        artifacts.define_singleton_method(:with) do |&block|
          calls << :opened
          block.call(held)
        ensure
          calls << :closed
        end
        kernel = Object.new
        owner = Authority::ProtectedAssignmentContext.new(deployment: current, history: history, kernel: kernel,
          env: {"ACE_ASSIGN_LAUNCH_MAPPING" => "mapping"}, artifacts_factory: -> { artifacts })
        owner.with_inbox_workflow(options: {project: "project", mapping: "mapping", inbox_context: "context"}) do |deployment, selected_kernel, selected_map|
          assert_same current, deployment
          assert_same kernel, selected_kernel
          assert_same map, selected_map
          assert_equal [:opened, *references, :verified], calls
          calls << :effect
        end
        assert_equal [:opened, *references, :verified, :effect, :verified, :closed], calls
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          owner.with_inbox_workflow(options: {project: "foreign", mapping: "mapping", inbox_context: "context"}) { flunk "foreign project has no effect" }
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          owner.with_inbox_workflow(options: {project: "project", mapping: "foreign", inbox_context: "context"}) { flunk "hint mismatch has no effect" }
        end
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
