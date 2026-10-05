# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/molecules/execution_scope_lineage"

module Ace
  module Assign
    class ExecutionScopeLineageTest < AceAssignTestCase
      Reader = Molecules::ExecutionScopeLineage
      BOOT = "12345678-1234-1234-1234-123456789abc"

      def setup
        @events = []
        @server = {"pid" => 90, "uid" => 13001, "gid" => 13001, "groups" => [13001], "parent_pid" => 1,
          "started_at" => "linux:#{BOOT}:999", "host" => "fixture"}
        child = @server.merge("pid" => 91, "parent_pid" => 90, "started_at" => "linux:#{BOOT}:1000")
        socket = [20, 30, 13001]
        @binding = {"project_id" => "project", "assignment_id" => "assignment", "attempt_id" => "attempt",
          "mapping_id" => "mapping", "slot_id" => "slot", "reservation_generation" => 1, "scope_generation" => 2,
          "deployment_digest" => "a" * 64, "boot_id" => BOOT, "slice_invocation_id" => "b" * 32,
          "service_invocation_id" => "c" * 32, "cgroup_identity" => {"path" => "/sys/fs/cgroup/ace-slot.slice",
            "mount_id" => 44, "filesystem_type" => "cgroup2", "device" => 27, "inode" => 111},
          "server_identity" => @server, "socket_identity" => socket, "workspace_id" => "w1",
          "original_process_binding" => {"runtime" => "herdr", "session" => "w1", "pane" => "w1:p2", "terminal_id" => "t2",
            "process_identity" => child, "shell_identity" => child,
            "native_origin" => {"workspace" => "w1", "tab" => "w1:t2", "pane" => "w1:p2", "server_identity" => @server,
              "socket_identity" => socket, "command" => ["/usr/libexec/ace-worker-gate", "mapping", "ticket"], "cwd" => "/scratch"}},
          "resource_identities" => [{"host_path" => "/var/lib/ace-slot/scratch", "view_path" => "/scratch",
            "mount_id" => 22, "filesystem_type" => "ext4", "device" => 24, "inode" => 500, "uid" => 13001, "gid" => 13001}]}
        append("intent", {})
        append("authority_mutation", {"operation" => "reserve_attempt"})
      end

      def append(type, payload)
        event = Models::EvidenceEvent.build(type: type, payload: payload, attempt_id: "attempt",
          previous_digest: @events.last&.fetch("digest"))
        @events << event
        event
      end

      def reader
        Reader.new(events: @events, project_id: "project", assignment_id: "assignment", attempt_id: "attempt", mapping_id: "mapping")
      end

      def bound
        append("scope_bound", @binding)
      end

      def seal
        append("scope_sealed", {"scope_generation" => 2, "scope_binding_event_id" => @events.find { |e| e["type"] == "scope_bound" }.fetch("digest")})
      end

      def proof_payload
        @binding.slice("scope_generation", "boot_id", "slice_invocation_id", "service_invocation_id", "cgroup_identity").merge(
          "scope_binding_event_id" => @events.find { |e| e["type"] == "scope_bound" }.fetch("digest"),
          "seal_event_id" => @events.find { |e| e["type"] == "scope_sealed" }.fetch("digest"), "populated" => 0)
      end

      def test_binding_seal_and_empty_observation_are_exact_chain_lineage
        binding = bound
        append("authority_mutation", {"operation" => "record_launch"})
        assert reader.require_open!
        sealed = seal
        assert reader.sealed?
        assert_raises(AttemptErrors::Conflict) { reader.require_open! }
        assert_nil reader.proof_id
        empty = append("scope_closed_no_writers", proof_payload)
        value = reader
        assert_equal empty.fetch("digest"), value.proof_id
        assert_equal proof_payload, value.require_positive!(scope_generation: 2,
          scope_binding_event_id: binding.fetch("digest"), seal_event_id: sealed.fetch("digest"), proof_id: empty.fetch("digest"))
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          value.require_positive!(scope_generation: 3, scope_binding_event_id: binding.fetch("digest"),
            seal_event_id: sealed.fetch("digest"), proof_id: empty.fetch("digest"))
        end
      end

      def test_missing_binding_never_admits_new_effect_or_positive_proof
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader.require_open! }
        assert_nil reader.proof_id
        append("scope_sealed", {"scope_generation" => 2, "scope_binding_event_id" => "a" * 64})
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
      end

      def test_positive_proof_without_seal_or_for_other_object_boot_or_population_refuses
        bound
        append("scope_closed_no_writers", {})
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
        @events.pop
        seal
        {"populated" => 1, "scope_generation" => 3, "scope_binding_event_id" => "d" * 64,
         "seal_event_id" => "e" * 64, "boot_id" => "another", "slice_invocation_id" => "f" * 32,
         "cgroup_identity" => @binding["cgroup_identity"].merge("inode" => 222)}.each do |field, value|
          append("scope_closed_no_writers", proof_payload.merge(field => value))
          assert_raises(AttemptErrors::EvidenceUnavailable, field) { reader }
          @events.pop
        end
      end

      def test_duplicate_binding_seal_or_proof_cannot_replace_original_generation
        bound
        append("scope_bound", @binding)
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
        @events.pop
        seal
        seal
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
        @events.pop
        append("scope_closed_no_writers", proof_payload)
        append("scope_closed_no_writers", proof_payload)
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
      end

      def test_binding_uses_original_full_native_child_and_canonical_mutation_generation
        [->(v) { v["scope_generation"] = 3 }, ->(v) { v["mapping_id"] = "foreign" },
         ->(v) { v["original_process_binding"]["native_origin"]["pane"] = "foreign" },
         ->(v) { v["server_identity"]["parent_pid"] = 2 },
         ->(v) { v["resource_identities"] << v["resource_identities"].first.dup },
         ->(v) { v["cgroup_identity"]["filesystem_type"] = "cgroup" },
         ->(v) { v["unexpected"] = true }].each do |change|
          value = JSON.parse(JSON.generate(@binding))
          change.call(value)
          append("scope_bound", value)
          assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
          @events.pop
        end
      end

      def test_digest_corruption_and_foreign_attempt_chain_refuse
        bound
        @events.last["payload"]["slot_id"] = "changed"
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
        @events.pop
        event = Models::EvidenceEvent.build(type: "scope_bound", payload: @binding, attempt_id: "foreign",
          previous_digest: @events.last.fetch("digest"))
        @events << event
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
      end

      def test_read_projection_is_immutable_independent_of_caller_objects
        bound
        value = reader
        @binding["slot_id"] = "changed"
        assert_equal "slot", value.binding.fetch("slot_id")
        assert value.binding.frozen?
        assert value.binding.fetch("server_identity").frozen?
      end
    end
  end
end
