# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/molecules/canonical_attempt_state"
require "ace/assign/authority/launch_lifecycle"
require_relative "../../support/execution_scope_native_owner_fixture"

module Ace
  module Assign
    class CanonicalAttemptStateTest < AceAssignTestCase
      def setup
        @events = []
        @tuple = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt"}
        @commit = "a" * 40
        @descriptor = "d" * 64
        append("intent", @tuple)
        append("scope_provisioning", {"descriptor_sha256" => @descriptor})
        append("authority_mutation", {"operation" => "reserve_attempt", "data" => @tuple.merge("reservation_generation" => 1,
          "generation" => 1, "launch_ticket" => "ticket")})
        owner = ExecutionScopeNativeOwnerFixture.new({"project_id" => "project"}, nil, nil, owner: nil)
        binding = owner.activate_parent!(@tuple.merge("reservation_generation" => 1, "scope_generation" => 2))
        parent = append("scope_bound", binding)
        admission = append("authority_mutation", {"operation" => "scope_service_admission", "data" => @tuple.merge(
          "generation" => 2, "scope_generation" => 2, "scope_binding_event_id" => parent.fetch("digest"),
          "native_admission" => "issued_uncertain", "network_installation" => ExecutionScopeObservationFixtures::NETWORK_OUTPUT)})
        server = {"pid" => 90, "parent_pid" => 1, "uid" => 13001, "gid" => 13001, "groups" => [13001],
          "host" => "fixture", "started_at" => "linux:#{binding.fetch('boot_id')}:999"}
        native = append("scope_native_bound", {"scope_generation" => 2, "scope_binding_event_id" => parent.fetch("digest"),
          "service_invocation_id" => "c" * 32, "server_identity" => server, "socket_identity" => [1, 2, 13001], "workspace_id" => "w1",
          "mount_namespace_identity" => {"device" => 4, "inode" => 22}, "resource_observer_identity" => server.merge("pid" => 92),
          "resource_identities" => [], "network_namespace_identity" => binding.fetch("network_namespace_identity"),
          "network_admission_event_id" => admission.fetch("digest")})
        child = server.merge("pid" => 91, "parent_pid" => 90)
        append("scope_child_bound", {"scope_generation" => 2, "scope_binding_event_id" => parent.fetch("digest"),
          "native_binding_event_id" => native.fetch("digest"), "original_process_binding" => {"runtime" => "herdr", "session" => "w1",
            "pane" => "w1:p2", "terminal_id" => "t2", "process_identity" => child, "shell_identity" => child,
            "native_origin" => {"workspace" => "w1", "tab" => "w1:t2", "pane" => "w1:p2", "server_identity" => server,
              "socket_identity" => [1, 2, 13001], "command" => ["/usr/libexec/ace-worker-gate", "mapping", "ticket"], "cwd" => "/scratch"}}})
        append("process_start", {})
        seal = append("scope_sealed", {"scope_generation" => 2, "scope_binding_event_id" => parent.fetch("digest")})
        append("authority_mutation", {"operation" => "close_execution_scope", "data" => {"state" => "running", "proof_id" => nil}})
        proof = append("scope_closed_no_writers", binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity").merge(
          "scope_binding_event_id" => parent.fetch("digest"), "seal_event_id" => seal.fetch("digest"), "populated" => 0))
        append("authority_mutation", {"operation" => "close_execution_scope", "data" => {"state" => "closed_no_writers", "proof_id" => proof.fetch("digest")}})
        @selection = @tuple.merge("descriptor_sha256" => @descriptor, "scope_binding_event_id" => parent.fetch("digest"),
          "seal_event_id" => seal.fetch("digest"), "closed_proof_event_id" => proof.fetch("digest"))
      end

      def append(type, payload)
        event = Models::EvidenceEvent.build(type: type, payload: payload, attempt_id: "attempt", previous_digest: @events.last&.fetch("digest"))
        @events << event
        event
      end

      def plan(selection: @selection, services: {"commit" => @commit, "services" => []}, inboxes: {"commit" => @commit, "inboxes" => []})
        Organisms::AttemptCoordinator.stopped_transition_plan(events: @events, selection: selection,
          service_evidence: services, inbox_evidence: inboxes, commit: @commit)
      end

      def accept(plan)
        event = append("attempt_stopped", plan.fetch(:events).fetch(0).fetch(:payload))
        append("authority_mutation", {"operation" => "stop_attempt", "assignment_id" => "assignment", "attempt_id" => "attempt",
          "data" => {"attempt_id" => "attempt", "generation" => @events.count { |entry| entry["type"] == "authority_mutation" } + 1,
            "state" => "stopped", "proof_id" => @selection.fetch("closed_proof_event_id"), "required_action" => nil}})
        event
      end

      def test_stop_owned_proof_accepts_only_its_uncertain_reply_shape
        prior = @events[0...-1]
        data = {"attempt_id" => "attempt", "generation" => prior.count { |event| event["type"] == "authority_mutation" } + 1,
          "state" => "uncertain", "proof_id" => @selection.fetch("closed_proof_event_id"), "required_action" => "reconcile_scope"}
        [nil, ["state", "closed_no_writers"], ["required_action", "settle_services"], ["proof_id", "f" * 64],
          ["generation", 4.0], ["generation", 999]].each do |invalid|
          @events = prior.dup
          value = invalid ? data.merge(invalid[0] => invalid[1]) : data
          append("authority_mutation", {"operation" => "stop_attempt", "assignment_id" => "assignment", "attempt_id" => "attempt", "data" => value})
          accept(plan)
          if invalid
            assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::CanonicalAttemptState.derive(@events) }
          else
            assert_equal "stopped", Molecules::CanonicalAttemptState.derive(@events)
          end
        end
      end

      def test_pure_coordinator_and_journal_project_running_and_uncertain_stopped_without_generic_bypass
        [false, true].each do |uncertain|
          original = @events.dup
          append("transition", {"to" => "uncertain"}) if uncertain
          accepted = accept(plan)
          assert_equal "stopped", Molecules::CanonicalAttemptState.derive(@events)
          assert_equal "stopped", Molecules::EvidenceJournal.allocate.send(:derive_state, @events)
          lifecycle = Authority::LaunchLifecycle.allocate
          assert lifecycle.send(:terminal_events?, @events)
          refute lifecycle.send(:active_events?, @events)
          journal = Object.new
          retained = @events
          journal.define_singleton_method(:read_events) { |_id| retained }
          attempt = Struct.new(:attempt_id, :binding).new("attempt", Struct.new(:assignment_id).new("assignment"))
          attempt.define_singleton_method(:managed?) { true }
          observer = Object.new
          observer.define_singleton_method(:observe) { |_| raise "accepted terminal projection must not probe native/process liveness" }
          assert_equal :stopped, Molecules::AttemptReconciler.new(journal: journal, observer: observer).classify(attempt)
          assert_equal @selection, accepted.fetch("payload").slice(*Molecules::CanonicalAttemptState::SELECTION_FIELDS)
          assert_empty accepted.dig("payload", "service_settlement_event_digests")
          assert_empty accepted.dig("payload", "inbox_settlement_event_digests")
          refute Atoms::AttemptStateMachine.can_transition?("uncertain", "stopped")
          @events = original
        end
      end

      def test_stopped_cannot_be_resurrected_or_replace_terminal_receipt
        baseline = @events.dup
        accept(plan)
        %w[process_start transition receipt_accepted reconciliation].each do |type|
          @events = @events.take(baseline.length + 2)
          append(type, {"to" => "running", "resolution" => "running", "receipt" => {"verdict" => "succeeded"}})
          assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::CanonicalAttemptState.derive(@events) }
        end
        @events = baseline
        append("receipt_accepted", {"receipt" => {"verdict" => "failed"}})
        assert_raises(AttemptErrors::InvalidTransition) { plan }
      end

      def test_stopped_reply_is_closed_and_typed_and_malformed_shape_is_unavailable
        accept(plan)
        receipt = @events.last
        original = receipt.fetch("payload").fetch("data")
        [original.reject { |key, _| key == "required_action" }, original.merge("generation" => original.fetch("generation").to_f),
          original.merge("proof_id" => "e" * 64), original.merge("required_action" => "settle_services"),
          original.merge("extra" => true), nil, []].each do |invalid|
          replacement = receipt.fetch("payload").merge("data" => invalid)
          @events[-1] = Models::EvidenceEvent.build(type: "authority_mutation", payload: replacement, attempt_id: "attempt",
            previous_digest: receipt.fetch("previous_digest"), recorded_at: Time.parse(receipt.fetch("recorded_at")))
          assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::CanonicalAttemptState.derive(@events) }
        end
      end

      def test_structural_reader_refuses_unaccepted_stopped_event_and_changed_original_selectors
        pending = plan
        append("attempt_stopped", pending.fetch(:events).fetch(0).fetch(:payload))
        assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::CanonicalAttemptState.derive(@events) }
        @events.pop
        %w[descriptor_sha256 scope_binding_event_id seal_event_id closed_proof_event_id].each do |field|
          assert_raises(AttemptErrors::EvidenceUnavailable) { plan(selection: @selection.merge(field => "e" * 64)) }
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) { plan(selection: @selection.merge("extra" => true)) }
        assert_raises(AttemptErrors::EvidenceUnavailable) { plan(services: {"commit" => "b" * 40, "services" => []}) }
      end
    end
  end
end
