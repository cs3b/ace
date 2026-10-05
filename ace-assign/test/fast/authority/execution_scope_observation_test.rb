# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/execution_scope_observation"
require_relative "../../support/execution_scope_observation_fixtures"

module Ace
  module Assign
    # Controlled native-owner observations exercise the production join. These
    # fixtures do not execute systemd, mount, proc, ACL or installed-host probes.
    class ExecutionScopeObservationTest < AceAssignTestCase
      BOOT = ExecutionScopeObservationFixtures::BOOT
      Files = ExecutionScopeObservationFixtures::Files
      Manager = ExecutionScopeObservationFixtures::Manager
      Cgroups = ExecutionScopeObservationFixtures::Cgroups

      def test_missing_installed_namespace_refuses_before_parent_activation
        @files.network = nil
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        assert_equal 0, @manager.service_starts
      end

      def test_selection_shape_and_namespace_replacement_cannot_be_adopted
        original = @files.manifest.fetch("network_installation")
        @files.manifest["network_installation"] = original.merge("unknown" => {})
        assert_raises(AttemptErrors::EvidenceUnavailable) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        @files.manifest["network_installation"] = original
        binding = @observer.activate_parent!(@context)
        append("scope_bound", binding)
        @files.network["inode"] += 1
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
        assert_equal 0, @manager.service_starts
      end

      def setup
        super
        @files, @manager, @cgroups = Files.new, Manager.new, Cgroups.new
        @map = {"project_id" => "project", "authority_id" => "authority", "worker_uid" => 13001, "launcher_uid" => 13002,
          "execution_scope" => {"slot_id" => "slot", "slice_unit" => "ace-slot.slice",
          "service_unit" => "ace-slot.service", "runtime_directory" => "/run/slot/native", "network_namespace_path" => "/run/netns/slot"}}
        deployment = Object.new
        mapping = @map
        deployment.define_singleton_method(:mapping) { |_id| mapping }
        deployment.define_singleton_method(:verify!) { |*_args, **_options| true }
        deployment.define_singleton_method(:authority) { |_id| {"uid" => 13000} }
        deployment.define_singleton_method(:project) { |_id| {"supervisor_uids" => [13003]} }
        @observer = Authority::ExecutionScopeObservation.new(mapping_id: "mapping", deployment: deployment, kernel: Object.new,
          manager: @manager, cgroups: @cgroups, files: @files)
        @events = []
        @context = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
          "reservation_generation" => 1, "scope_generation" => 2}
        append("intent", {})
        append("authority_mutation", {"operation" => "reserve_attempt", "data" => @context.reject { |key, _| key == "scope_generation" }.merge(
          "generation" => 1, "launch_ticket" => "ticket")})
      end

      def append(type, payload)
        @events << Models::EvidenceEvent.build(type: type, attempt_id: "attempt", payload: payload, previous_digest: @events.last&.fetch("digest"))
      end

      def lineage
        Molecules::ExecutionScopeLineage.new(events: @events, project_id: "project", assignment_id: "assignment", attempt_id: "attempt", mapping_id: "mapping")
      end

      def bind_parent
        @binding = @observer.activate_parent!(@context)
        append("scope_bound", @binding)
        append("authority_mutation", {"operation" => "scope_parent_binding", "data" => {}})
      end

      def seal_parent
        append("scope_sealed", {"scope_generation" => 2, "scope_binding_event_id" => lineage.binding_event.fetch("digest")})
        append("authority_mutation", {"operation" => "close_execution_scope", "data" => {}})
      end

      def test_fresh_owner_activation_observes_only_existing_parent_resources
        bind_parent
        assert_equal 1, @manager.starts
        assert_equal 0, @manager.service_starts
        assert_equal @files.namespace, @binding.fetch("resource_mount_namespace_identity")
        assert_equal 2, @binding.fetch("resource_identities").size
        assert_equal 99, @binding.dig("resource_identities", 1, "inode")
        assert @cgroups.handles.all?(&:closed)
        assert_equal 0, @observer.observe(lineage).fetch("populated")
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.native_admission_ready!(lineage) }
        assert_equal 0, @manager.service_starts
      end

      def test_never_admitted_sealed_parent_can_prove_empty_without_network_readiness
        bind_parent
        seal_parent
        proof = @observer.closed_observation_for_proof!(lineage, events: @events)
        assert_equal 0, proof.fetch("populated")
        assert_equal @binding.fetch("cgroup_identity"), proof.fetch("cgroup_identity")
        append("scope_closed_no_writers", proof)
        assert @observer.verify_closed!(lineage)
        @manager.service["ControlPID"] = 90
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.verify_closed!(lineage) }
        @manager.service["ControlPID"] = 0
        @manager.service["Job"] = [1, "/job/1"]
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.verify_closed!(lineage) }
      end

      def test_absent_native_binding_does_not_erase_canonical_admission
        bind_parent
        append("authority_mutation", {"operation" => "scope_service_admission", "data" => @context.slice("project_id", "assignment_id", "attempt_id", "mapping_id").merge(
          "generation" => 3, "scope_generation" => 2, "scope_binding_event_id" => @events.find { |event| event["type"] == "scope_bound" }.fetch("digest"),
          "native_admission" => "issued_uncertain", "network_installation" => ExecutionScopeObservationFixtures::NETWORK_OUTPUT)})
        seal_parent
        error = assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
        assert_match(/admitted native/, error.message)
      end

      def test_resource_namespace_mount_object_and_parent_replacement_refuse
        bind_parent
        seal_parent
        %w[inode mount_id].each do |key|
          original = @files.resource.fetch(key)
          @files.resource[key] += 1
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
          @files.resource[key] = original
        end
        @files.namespace["inode"] += 1
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
        @files.namespace["inode"] -= 1
        @cgroups.inode += 1
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
        assert @cgroups.handles.all?(&:closed)
      end

      def test_lost_parent_start_reply_cannot_adopt_or_restart_same_name
        @manager.lost_start = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 1, @manager.starts
      end

      def test_public_traversal_or_outside_writable_alias_refuses_before_start
        @files.outside_acl = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        @files.outside_acl = false
        @files.outside_alias = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
      end

      def test_outside_worker_uid_process_refuses_never_admitted_proof
        bind_parent
        seal_parent
        @files.outside_worker = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
      end

      def test_retirement_requires_the_exact_closed_released_parent
        bind_parent
        seal_parent
        append("scope_closed_no_writers", @observer.closed_observation_for_proof!(lineage, events: @events))
        assert_equal "retired", @observer.retire_released_parent!([lineage]).fetch("state")
        assert_equal 1, @manager.slice_stops
        assert_equal "already_retired", @observer.retire_released_parent!([lineage]).fetch("state")
        assert_equal 1, @manager.slice_stops
      end
    end
  end
end
