# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require_relative "../../support/execution_scope_observation_fixtures"

module Ace
  module Assign
    class LaunchScopeAdmissionTest < AceAssignTestCase
      BOOT = "12345678-1234-1234-1234-123456789abc"
      class Kernel
        def live!(_identity); true; end
        def same?(left, right); left == right; end
      end
      class Observer
        attr_accessor :refusal, :lost_reply, :owner, :journal, :stop_required
        attr_reader :starts, :checks, :stops
        def initialize; @starts = 0; @checks = 0; @stops = 0; end
        def native_admission_ready!(lineage)
          @checks += 1
          raise Ace::Runtime::RuntimeUnavailableError, "network evidence unavailable" if refusal
          lineage.require_open!
          ExecutionScopeObservationFixtures::NETWORK_OUTPUT
        end
        def start_admitted_service!
          raise "authority mutex held during StartUnit" if owner.mutex.owned?
          raise "admission missing before StartUnit" unless journal.read_events("assignment").any? do |event|
            event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_service_admission"
          end
          @starts += 1
          raise Ace::Runtime::RuntimeUnavailableError, "StartUnit reply lost" if lost_reply
        end
        def complete_native_readiness!(_lineage, report)
          raise AttemptErrors::EvidenceUnavailable, "completed start lacks private report" unless report
          report
        end
        def sealed_service_stop_required?(lineage)
          raise "unsealed stop" unless lineage.sealed?
          !!stop_required
        end
        def stop_sealed_service!
          raise "authority mutex held during StopUnit" if owner.mutex.owned?
          raise "admission or seal missing before StopUnit" unless journal.read_events("assignment").any? do |event|
            event["type"] == "scope_sealed" || event.dig("payload", "operation") == "scope_service_admission"
          end
          @stops += 1
          raise Ace::Runtime::RuntimeUnavailableError, "StopUnit reply lost" if lost_reply
        end
        def closed_observation_for_proof!(lineage, events:)
          raise Ace::Runtime::RuntimeUnavailableError, "boundary unavailable" if refusal
          raise "unsealed proof" unless lineage.sealed?
          lineage.binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity").merge(
            "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "populated" => 0)
        end
        def verify_closed!(lineage)
          raise "missing canonical proof" unless lineage.proof_event && lineage.sealed?
          true
        end
      end

      def with_owner
        with_temp_cache do |cache|
          repo = File.join(cache, "repo")
          FileUtils.mkdir_p(repo)
          _out, err, status = Open3.capture3("git", "init", "-b", "main", repo)
          assert status.success?, err
          _out, err, status = Open3.capture3("git", "-C", repo, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "--allow-empty", "-m", "fixture")
          assert status.success?, err
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "checkout"))
          @peer = {"pid" => 81}
          @map = {"project_id" => "project", "authority_id" => "authority", "execution_scope" => {"slot_id" => "slot", "service_unit" => "ace-slot.service", "network_namespace_path" => "/run/netns/slot"}}
          deployment = Object.new
          map = @map
          deployment.define_singleton_method(:mapping) { |_id| map }
          deployment.define_singleton_method(:authority) { |_id| {"state_root" => File.join(cache, "state")} }
          deployment.define_singleton_method(:project) { |_id| {"inbox_contexts" => {}} }
          @observer = Observer.new
          @owner = Authority::LaunchLifecycle.new(deployment: deployment, kernel: Kernel.new,
            journals: {"project" => @journal}, scope_observer_factory: ->(_id) { @observer })
          @observer.owner, @observer.journal = @owner, @journal
          mutate("definition-assignment", "register", "register_assignment", 0, [], {"task_id" => "task"})
          @state = {"project_id" => "project", "assignment_id" => "assignment", "attempt_id" => "attempt",
            "mapping_id" => "mapping", "reservation_generation" => 1, "phase" => "reserved",
            "launcher_identity" => @peer, "launch_ticket" => "ticket"}
          mutate("attempt", "reserve", "reserve_attempt", 0, [{type: "intent", payload: {"scope" => "010"}},
            {type: "scope_provisioning", payload: {"slot_id" => "slot", "reservation_generation" => 1, "deployment_digest" => "a" * 64}}], @state)
          binding = @state.slice("project_id", "assignment_id", "attempt_id", "mapping_id", "reservation_generation").merge(
            "slot_id" => "slot", "scope_generation" => 2, "deployment_digest" => "a" * 64, "boot_id" => BOOT,
            "slice_invocation_id" => "b" * 32, "resource_mount_namespace_identity" => {"device" => 4, "inode" => 33},
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/ace-slot.slice", "mount_id" => 4, "filesystem_type" => "cgroup2", "device" => 5, "inode" => 6},
            "resource_identities" => [], "network_namespace_identity" => {"device" => 7, "inode" => 88},
            "network_installation_selection" => ExecutionScopeObservationFixtures::NETWORK_SELECTION)
          mutate("attempt", "parent", "scope_parent_binding", 1, [{type: "scope_bound", payload: binding}], @state)
          @params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
            "launch_ticket" => "ticket", "mutation_id" => "admit", "expected_generation" => 2}
          yield
        ensure
          @owner&.close
        end
      end

      def mutate(attempt, id, operation, generation, events, data)
        @journal.mutate(assignment_id: "assignment", attempt_id: attempt, mutation_id: id, operation: operation,
          parameters_digest: "c" * 64, expected_generation: generation) { {events: events, blobs: {}, data: data} }
      end

      def admit(params = @params, peer: @peer)
        @owner.admit_native_service!(params: params, peer: peer, role: :launcher)
      end

      def test_unavailable_boundary_refuses_before_canonical_admission_and_start
        with_owner do
          old = @journal.ref_value
          @observer.refusal = true
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { admit }
          assert_equal old, @journal.ref_value
          assert_equal 0, @observer.starts
          refute @journal.read_events("assignment").any? { |event| event.dig("payload", "operation") == "scope_service_admission" }
        end
      end

      def test_only_fresh_canonical_winner_starts_and_replay_keeps_original_reply
        with_owner do
          assert_raises(AttemptErrors::EvidenceUnavailable) { admit }
          fresh = admit
          assert_equal "issued_uncertain", fresh.dig(:data, "native_admission")
          assert_equal 3, fresh.dig(:data, "generation")
          assert fresh.fetch(:replayed)
          replay = admit
          assert replay.fetch(:replayed)
          assert_equal fresh.fetch(:data), replay.fetch(:data)
          assert_equal 1, @observer.starts
          assert_equal 1, @observer.checks
          assert_raises(AttemptErrors::Conflict) { admit(@params.merge("mutation_id" => "another", "expected_generation" => 3)) }
          assert_equal 1, @observer.starts
          assert_raises(AttemptErrors::UnauthorizedIdentity) { admit(peer: {"pid" => 82}) }
        end
      end

      def test_lost_manager_reply_and_authority_restart_never_retry_start
        with_owner do
          @observer.lost_reply = true
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { admit }
          old = @journal.ref_value
          deployment = @owner.instance_variable_get(:@deployment)
          @owner.close
          @owner = Authority::LaunchLifecycle.new(deployment: deployment, kernel: Kernel.new,
            journals: {"project" => @journal}, scope_observer_factory: ->(_id) { @observer })
          @observer.owner = @owner
          replay = admit
          assert replay.fetch(:replayed)
          assert_equal "issued_uncertain", replay.dig(:data, "native_admission")
          assert_equal old, @journal.ref_value
          assert_equal 1, @observer.starts
        end
      end

      def test_delayed_admitted_issuer_cannot_start_after_seal_or_publish_early_proof
        with_owner do
          admitted, resume = Queue.new, Queue.new
          original = @owner.method(:complete_native_start!)
          @owner.define_singleton_method(:complete_native_start!) do |*arguments|
            admitted << true
            resume.pop
            original.call(*arguments)
          end
          issuer = Thread.new { admit }
          Timeout.timeout(15) { admitted.pop }
          seal = close_scope("seal-delayed", 3)
          assert_equal "running", seal.dig(:data, "state")
          attempted_proof = close_scope("pending-proof", 4)
          assert_equal "running", attempted_proof.dig(:data, "state")
          assert_nil attempted_proof.dig(:data, "proof_id")
          refute @journal.read_events("assignment").any? { |event| event["type"] == "scope_closed_no_writers" }
          assert_equal 0, @observer.starts
          resume << true
          Timeout.timeout(15) { issuer.value }
          assert_equal 0, @observer.starts
          proof = close_scope("settled-proof", 5)
          assert_equal "closed_no_writers", proof.dig(:data, "state")
        ensure
          resume << true if issuer&.alive?
          issuer&.join(1)
        end
      end

      def test_owner_exit_after_admission_before_scheduling_does_not_leave_unreachable_issuer
        with_owner do
          original = @owner.method(:with_exclusion)
          @owner.define_singleton_method(:with_exclusion) do |*arguments, &block|
            original.call(*arguments, &block)
            raise IOError, "controlled exclusion return lost"
          end
          assert_raises(IOError) { admit }
          assert_empty @owner.instance_variable_get(:@native_issuers)
          assert_equal 0, @observer.starts
          assert_equal 1, @journal.read_events("assignment").count { |event| event.dig("payload", "operation") == "scope_service_admission" }
        end
      end

      def test_private_callback_cannot_select_same_attempt_id_from_another_project
        with_owner do
          params = @params.dup
          other_map = @map.merge("project_id" => "other-project")
          key = @owner.send(:native_issuer_key, params, @map)
          other_key = @owner.send(:native_issuer_key, params, other_map)
          refute_equal key, other_key
          @owner.instance_variable_get(:@native_issuers)[key] = {params: params, report: nil}
          @owner.instance_variable_get(:@journals)["other-project"] = @journal
          @owner.instance_variable_get(:@deployment).define_singleton_method(:mapping) { |_id| other_map }
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @owner.native_readiness!(mapping_id: "mapping", peer: @peer, socket: nil, codec: nil, deadline: 0)
          end
          assert_nil @owner.instance_variable_get(:@native_issuers).fetch(key)[:challenge]
          assert_equal 0, @observer.starts
        end
      end

      def test_private_admission_is_not_a_public_launch_operation
        refute_includes Authority::LaunchLifecycle::OPERATIONS, "scope_service_admission"
        refute Authority::LaunchLifecycle::MUTATIONS.key?("scope_service_admission")
      end

      def close_scope(id, generation)
        @owner.close_execution_scope!(params: @params.slice("mapping_id", "assignment_id", "attempt_id").merge(
          "mutation_id" => id, "expected_generation" => generation), peer: @peer, role: :launcher)
      end

      def test_seal_commits_before_stop_and_requires_fresh_close_to_record_proof
        with_owner do
          seal = close_scope("seal", 2)
          assert_equal "running", seal.dig(:data, "state")
          assert_nil seal.dig(:data, "proof_id")
          assert_equal 1, @observer.stops
          replay = close_scope("seal", 2)
          assert replay.fetch(:replayed)
          assert_equal seal.fetch(:data), replay.fetch(:data)
          assert_equal 1, @observer.stops
          assert_raises(AttemptErrors::Conflict) { admit(@params.merge("expected_generation" => 3)) }
          proof = close_scope("prove", 3)
          assert_equal "closed_no_writers", proof.dig(:data, "state")
          event = @journal.read_events("assignment").find { |item| item["type"] == "scope_closed_no_writers" }
          assert_equal event.fetch("digest"), proof.dig(:data, "proof_id")
          assert_equal seal.fetch(:data), close_scope("seal", 2).fetch(:data)
          assert_equal 1, @observer.stops
        end
      end

      def test_lost_stop_reply_keeps_seal_and_original_reply_without_retry
        with_owner do
          @observer.lost_reply = true
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { close_scope("seal", 2) }
          assert_equal "running", close_scope("seal", 2).dig(:data, "state")
          assert_equal 1, @observer.stops
          @observer.refusal = true
          old = @journal.ref_value
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { close_scope("prove", 3) }
          assert_equal old, @journal.ref_value
          refute @journal.read_events("assignment").any? { |event| event["type"] == "scope_closed_no_writers" }
        end
      end

      def test_fresh_close_resumes_lost_stop_without_replaying_original_io
        with_owner do
          @observer.lost_reply = true
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { close_scope("seal", 2) }
          assert_equal 1, @observer.stops
          replay = close_scope("seal", 2)
          assert replay.fetch(:replayed)
          assert_equal 1, @observer.stops
          @observer.lost_reply = false
          @observer.stop_required = true
          resumed = close_scope("resume-stop", 3)
          assert_equal "running", resumed.dig(:data, "state")
          assert_equal 2, @observer.stops
          assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "scope_sealed" }
          @observer.stop_required = false
          proof = close_scope("proof-after-stop", 4)
          assert_equal "closed_no_writers", proof.dig(:data, "state")
          assert_equal 2, @observer.stops
        end
      end

      def test_duplicate_otherwise_valid_scope_failure_is_rejected_without_mutation
        with_owner do
          close_scope("seal", 2)
          proof = close_scope("prove", 3)
          events = @journal.read_events("assignment")
          parent = events.find { |event| event["type"] == "scope_bound" }
          seal = events.find { |event| event["type"] == "scope_sealed" }
          valid = JSON.generate("kind" => "protected_scope_before_release", "scope_generation" => 2,
            "scope_binding_event_id" => parent.fetch("digest"), "seal_event_id" => seal.fetch("digest"), "proof_id" => proof.dig(:data, "proof_id"))
          duplicate = valid.sub("{", '{"scope_generation":2,')
          old = @journal.ref_value
          request = {"operation" => "abort_launch", "mutation_id" => "duplicate-abort", "params" => {
            "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt", "launch_ticket" => "ticket",
            "expected_generation" => 4, "failure_evidence" => duplicate, "failure_digest" => Digest::SHA256.hexdigest(duplicate)}}
          assert_raises(ArgumentError, JSON::ParserError) { @owner.dispatch(request: request, peer: @peer, role: :launcher) }
          assert_equal old, @journal.ref_value
        end
      end

      def test_restart_replays_guarded_abort_and_finishes_missing_private_release
        with_owner do
          close_scope("seal", 2)
          proof = close_scope("prove", 3)
          events = @journal.read_events("assignment")
          failure = JSON.generate("kind" => "protected_scope_before_release", "scope_generation" => 2,
            "scope_binding_event_id" => events.find { |event| event["type"] == "scope_bound" }.fetch("digest"),
            "seal_event_id" => events.find { |event| event["type"] == "scope_sealed" }.fetch("digest"), "proof_id" => proof.dig(:data, "proof_id"))
          request = {"operation" => "abort_launch", "mutation_id" => "abort-before-crash", "params" => {
            "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt", "launch_ticket" => "ticket",
            "expected_generation" => 4, "failure_evidence" => failure, "failure_digest" => Digest::SHA256.hexdigest(failure)}}
          @owner.stub(:release_scope_reservation_held!, ->(*) { raise IOError, "authority stopped after terminal CAS" }) do
            assert_raises(IOError) { @owner.dispatch(request: request, peer: @peer, role: :launcher) }
          end
          original = @journal.mutation_result("abort-before-crash")
          assert_equal "failed", original.fetch("data").fetch("phase")
          assert_raises(AttemptErrors::Conflict) { @owner.send(:ensure_slot_available!, @map, @journal) }
          deployment = @owner.instance_variable_get(:@deployment)
          @owner.close
          @owner = Authority::LaunchLifecycle.new(deployment: deployment, kernel: Kernel.new,
            journals: {"project" => @journal}, scope_observer_factory: ->(_id) { @observer })
          @observer.owner = @owner
          replay = @owner.dispatch(request: request, peer: @peer, role: :launcher)
          assert replay.fetch(:replayed)
          assert_equal original.fetch("data").merge("journal_commit" => original.fetch("journal_commit")), replay.fetch(:data)
          assert_equal true, @owner.send(:ensure_slot_available!, @map, @journal)
          assert_equal 1, @journal.read_events("assignment").count { |event| event.dig("payload", "operation") == "scope_reservation_release" }
        end
      end

      def test_parent_only_proof_guarded_abort_and_durable_release_are_all_required_for_reuse
        with_owner do
          close_scope("seal", 2)
          proof = close_scope("prove", 3)
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == "attempt" }
          parent = events.find { |event| event["type"] == "scope_bound" }
          seal = events.find { |event| event["type"] == "scope_sealed" }
          failure = JSON.generate("kind" => "protected_scope_before_release", "scope_generation" => 2,
            "scope_binding_event_id" => parent.fetch("digest"), "seal_event_id" => seal.fetch("digest"), "proof_id" => proof.dig(:data, "proof_id"))
          request = {"operation" => "abort_launch", "mutation_id" => "abort", "params" => {
            "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt", "launch_ticket" => "ticket",
            "expected_generation" => 4, "failure_evidence" => failure, "failure_digest" => Digest::SHA256.hexdigest(failure)}}
          result = @owner.dispatch(request: request, peer: @peer, role: :launcher)
          assert_equal "failed", result.dig(:data, "phase")
          refute @journal.read_events("assignment").any? { |event| event["type"] == "process_start" }
          releases = @journal.read_events("assignment").select { |event| event.dig("payload", "operation") == "scope_reservation_release" }
          assert_equal 1, releases.size
          assert_equal "released", releases.first.dig("payload", "data", "reservation")
          assert_equal 6, releases.first.dig("payload", "data", "generation")
          assert_equal true, @owner.send(:ensure_slot_available!, @map, @journal)
          old = @journal.ref_value
          replay = @owner.dispatch(request: request, peer: @peer, role: :launcher)
          assert replay.fetch(:replayed)
          assert_equal result.fetch(:data), replay.fetch(:data)
          assert_equal old, @journal.ref_value

        end
      end
    end
  end
end
