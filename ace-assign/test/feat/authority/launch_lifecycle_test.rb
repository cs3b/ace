# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/launch_driver"
require_relative "../../support/execution_scope_observation_fixtures"

module Ace
  module Assign
    class ProtectedLaunchLifecycleTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket
      class Kernel
        Handle = Struct.new(:identity, :closed) { def close; self.closed = true; end }
        attr_accessor :dead
        attr_reader :handles
        def initialize; @dead = []; @handles = []; end
        def capture(pid)
          {"pid" => pid, "uid" => pid == Process.pid ? 13002 : 13001, "gid" => pid == Process.pid ? 13002 : 13001,
            "groups" => [pid == Process.pid ? 13002 : 13001], "started_at" => "linux:#{ExecutionScopeObservationFixtures::BOOT}:#{pid}", "host" => "fixture",
            "parent_pid" => pid.between?(91, 99) ? 90 : 1}
        end
        def live!(identity)
          raise Ace::Runtime::RuntimeUnavailableError, "dead" if dead.include?(identity["pid"])
          true
        end
        def pin(identity); live!(identity); handle = Handle.new(identity, false); @handles << handle; handle; end
        def exited?(handle, **); dead.include?(handle.identity.fetch("pid")); end
        def same?(left, right); left == right; end
      end

      # Controlled fixed native-owner stages; no installed/native readiness is
      # established by this 09j lifecycle fixture.
      class ScopeObserver
        def initialize(map, journal, kernel)
          @map, @journal, @kernel = map, journal, kernel
        end
        def retire_released_parent!(_lineages); true; end
        def activate_parent!(context)
          context.merge("slot_id" => "slot", "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(canonical(@map))),
            "boot_id" => ExecutionScopeObservationFixtures::BOOT, "slice_invocation_id" => "b" * 32,
            "resource_mount_namespace_identity" => {"device" => 4, "inode" => 11}, "resource_identities" => [],
            "network_namespace_identity" => {"device" => 7, "inode" => 88}, "network_installation_selection" => ExecutionScopeObservationFixtures::NETWORK_SELECTION,
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/ace-slot.slice", "mount_id" => 4, "filesystem_type" => "cgroup2", "device" => 5, "inode" => 6})
        end
        def observe(_lineage); {"populated" => 0}; end
        def native_admission_ready!(lineage)
          @lineage = lineage
          ExecutionScopeObservationFixtures::NETWORK_OUTPUT
        end
        def start_admitted_service!
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @lineage.binding.fetch("attempt_id") }
          admission = events.find { |event| event.dig("payload", "operation") == "scope_service_admission" }
          payload = {"scope_generation" => 2, "scope_binding_event_id" => @lineage.binding_event.fetch("digest"),
            "service_invocation_id" => "c" * 32, "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001], "workspace_id" => "w1",
            "mount_namespace_identity" => {"device" => 4, "inode" => 22}, "resource_observer_identity" => @kernel.capture(92), "resource_identities" => [],
            "network_namespace_identity" => {"device" => 7, "inode" => 88}, "network_admission_event_id" => admission.fetch("digest")}
          @journal.mutate(assignment_id: "assignment", attempt_id: @lineage.binding.fetch("attempt_id"),
            mutation_id: "native-#{@lineage.binding.fetch('attempt_id')}", operation: "scope_native_binding", parameters_digest: "a" * 64,
            expected_generation: @journal.authority_generation(events)) { {events: [{type: "scope_native_bound", payload: payload}], blobs: {}, data: {}} }
        end
        def canonical(value)
          case value
          when Hash then value.keys.sort.to_h { |key| [key, canonical(value[key])] }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end
      end

      def with_authority
        with_temp_cache do |cache|
          repo = File.join(cache, "journal")
          FileUtils.mkdir_p(repo)
          out, error, result = Open3.capture3("git", "init", "-b", "main", repo)
          assert result.success?, error
          out, error, result = Open3.capture3("git", "-C", repo, "-c", "user.name=test", "-c", "user.email=test@localhost",
            "commit", "--allow-empty", "-m", "candidate")
          assert result.success?, error
          @kernel = Kernel.new
          @peer = @kernel.capture(Process.pid)
          @map = {"project_id" => "project", "authority_id" => "authority", "worker_uid" => 13001, "worker_gid" => 13001,
            "execution_scope" => {"slot_id" => "slot", "service_unit" => "ace-slot.service", "network_namespace_path" => "/run/netns/slot"},
            "worker_groups" => [13001], "bootstrap" => "/usr/libexec/ace-worker-gate", "bootstrap_sha256" => "a" * 64, "worker_cwd" => "/home/worker", "worker_actor" => "worker", "native" => {"workspace_id" => "w1"}}
          deployment = Object.new
          mapping = @map
          deployment.define_singleton_method(:mapping) { |_id| mapping }
          deployment.define_singleton_method(:authority) { |_id| {"state_root" => File.join(cache, "authority-state")} }
          deployment.define_singleton_method(:project) { |_id| {"assignment_root" => File.join(cache, "assignments")} }
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "checkout"))
          @authority = Authority::LaunchLifecycle.new(deployment: deployment, kernel: @kernel, journals: {"project" => @journal}, scope_observer_factory: ->(_id) { ScopeObserver.new(@map, @journal, @kernel) })
          bytes = JSON.generate("session_id" => "assignment", "name" => "test", "created_at" => "2026-10-05T00:00:00Z",
            "source_config" => "job.yaml", "task_id" => "09j", "project_id" => "project")
          registered = call("register_assignment", {"definition_bytes" => bytes,
            "definition_digest" => Digest::SHA256.hexdigest(bytes), "expected_generation" => 0}, id: "register").fetch(:data)
          @reserve_params = {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => "a" * 40,
            "launcher_process_binding" => @peer, "expected_generation" => registered.fetch("definition_generation")}
          yield
        end
      end

      def call(operation, params, id:, role: :launcher)
        request = {"version" => 1, "operation" => operation, "mutation_id" => id, "project_id" => "project",
          "params" => params.merge("mapping_id" => "mapping", "assignment_id" => "assignment")}
        response = @authority.dispatch(request: request, peer: @peer, role: role)
        @ticket = response.dig(:data, "launch_ticket") if operation == "reserve_attempt"
        response
      end

      def binding(pid = 91)
        child = @kernel.capture(pid)
        {"runtime" => "herdr", "session" => "w1", "pane" => "w1:p2", "terminal_id" => "3",
          "process_identity" => child, "shell_identity" => child, "native_origin" => {"workspace" => "w1", "tab" => "w1:t2",
            "pane" => "w1:p2", "command" => ["/usr/libexec/ace-worker-gate", "mapping", @ticket], "cwd" => "/home/worker", "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001]}}
      end

      def params(state, child = binding)
        generation = if state["phase"] == "reserved"
          call("inspect_launch", state.slice("attempt_id"), id: nil).dig(:data, "generation")
        else
          state.fetch("generation")
        end
        state.slice("attempt_id", "launch_ticket").merge("process_binding" => child, "expected_generation" => generation)
      end

      def test_launcher_pidfd_refusal_cannot_commit_or_wedge_reservation
        with_authority do
          old = @journal.ref_value
          @kernel.stub(:pin, ->(*) { raise Ace::Runtime::RuntimeUnavailableError, "pidfd refused" }) do
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { call("reserve_attempt", @reserve_params, id: "reserve") }
          end
          assert_equal old, @journal.ref_value
          refute @journal.read_events("assignment").any? { |event| event["type"] == "intent" }
          assert_empty @kernel.handles
          assert_equal "reserved", call("reserve_attempt", @reserve_params, id: "reserve").dig(:data, "phase")
        end
      end

      def test_exact_child_exit_projects_uncertainty_without_releasing_ownership
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          state = call("bind_process", params(state), id: "bind").fetch(:data)
          old = @journal.ref_value
          @kernel.dead << 91
          observed = call("attempt_status", {"attempt_id" => state.fetch("attempt_id")}, id: nil, role: :supervisor).fetch(:data)
          assert_equal "uncertain", observed.fetch("phase")
          assert_equal "supervisor_inspect_exact_child_and_release_uncertainty", observed.fetch("required_action")
          assert_equal old, @journal.ref_value
          assert @kernel.handles.none?(&:closed)
          assert_raises(AttemptErrors::Conflict) { call("reserve_attempt", @reserve_params, id: "blocked") }
        end
      end

      def test_reservation_replay_and_plan_refusal_open_no_additional_handles
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          original = @kernel.handles.fetch(0)
          replay = call("reserve_attempt", @reserve_params, id: "reserve")
          assert replay.fetch(:replayed)
          assert_equal state, replay.fetch(:data)
          assert_equal [original], @kernel.handles
          assert_raises(AttemptErrors::Conflict) { call("reserve_attempt", @reserve_params, id: "blocked") }
          refute original.closed
          assert_equal [original], @kernel.handles
        end
      end

      def test_competing_reservation_acceptance_replays_and_closes_local_handle
        with_authority do
          calls = 0
          replace = lambda do |commit, old|
            calls += 1
            tree, error, ok = Open3.capture3("git", "-C", @journal.repo_root, "rev-parse", "#{commit}^{tree}")
            assert ok.success?, error
            accepted, error, ok = Open3.capture3("git", "-C", @journal.repo_root, "-c", "user.name=other-owner",
              "-c", "user.email=other@localhost", "commit-tree", tree.strip, "-p", old, "-m", "competing acceptance")
            assert ok.success?, error
            _, error, ok = Open3.capture3("git", "-C", @journal.repo_root, "update-ref", "refs/ace/execution", accepted.strip, old)
            assert ok.success?, error
            false
          end
          reply = @journal.stub(:update_ref_cas, replace) { call("reserve_attempt", @reserve_params, id: "reserve") }
          assert reply.fetch(:replayed)
          assert_equal 1, calls
          assert_equal 1, @kernel.handles.size
          assert @kernel.handles.all?(&:closed)
          state = reply.fetch(:data)
          projected = call("attempt_status", {"attempt_id" => state.fetch("attempt_id")}, id: nil, role: :supervisor)
          assert_equal "uncertain", projected.dig(:data, "phase")
          assert_raises(AttemptErrors::Conflict) { call("reserve_attempt", @reserve_params, id: "blocked") }
        end
      end

      def test_shared_assignment_context_uses_canonical_registration_and_one_mutex
        with_authority do
          [false, true].each do |exclusive|
            @authority.with_assignment(params: {"assignment_id" => "assignment"}, map: @map, exclusive: exclusive) do |journal, registration|
              assert_same @journal, journal
              assert @authority.mutex.owned?
              assert_equal "09j", registration.fetch("task_id")
              assert registration.fetch("definition_ref").start_with?("execution/definitions/")
              registration["task_id"] = "forged"
            end
          end
          @authority.with_assignment(params: {"assignment_id" => "assignment"}, map: @map) do |_journal, registration|
            assert_equal "09j", registration.fetch("task_id")
          end
        end
      end

      def test_uncertainty_retains_exact_handles_until_completed_shutdown
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          assert_equal 2, @kernel.handles.size
          evidence = "native close observed"
          abort_params = state.slice("attempt_id", "launch_ticket").merge("expected_generation" => state.fetch("generation"),
            "failure_evidence" => evidence, "failure_digest" => Digest::SHA256.hexdigest(evidence))
          uncertain = call("abort_launch", abort_params, id: "uncertain").fetch(:data)
          assert_equal "uncertain", uncertain.fetch("phase")
          assert @kernel.handles.none?(&:closed)
          @authority.close
          assert @kernel.handles.all?(&:closed)
        end

      end

      def test_reservation_replay_and_overlap_never_create_another_intent
        with_authority do
          first = call("reserve_attempt", @reserve_params, id: "reserve")
          refute first.fetch(:replayed)
          retry_reply = call("reserve_attempt", @reserve_params, id: "reserve")
          assert retry_reply.fetch(:replayed)
          assert_equal first.fetch(:data), retry_reply.fetch(:data)
          assert_raises(AttemptErrors::Conflict) { call("reserve_attempt", @reserve_params, id: "another-reserve") }
          events = @journal.read_events("assignment")
          assert_equal 1, events.count { |event| event["type"] == "intent" }
          assert_equal 0, events.count { |event| event["type"] == "process_start" }
          assert_equal "reserved", @journal.derived_attempts("assignment").first.state
          assert_equal "worker", @journal.derived_attempts("assignment").first.binding.actor
        end
      end

      def test_worker_cannot_mutate_origin_and_changed_child_cannot_bind
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          old = @journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("record_launch", params(state), id: "worker-forgery", role: :worker) }
          assert_equal old, @journal.ref_value
          state = call("record_launch", params(state), id: "record").fetch(:data)
          assert_raises(AttemptErrors::Conflict) { call("bind_process", params(state, binding(92)), id: "changed-bind") }
          assert_equal 0, @journal.read_events("assignment").count { |event| event["type"] == "process_start" }
        end
      end

      def test_bind_precedes_single_durable_release_and_replay_never_resends
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          server, worker = UNIXSocket.pair
          request = {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}}
          gate = Thread.new { @authority.gate_ready(request: request, peer: @kernel.capture(91), socket: server, deadline: WIRE.deadline(5)) }
          ready = WIRE.read(worker, deadline: WIRE.deadline(5))
          assert_equal "ready", ready.dig("data", "phase")
          assert_nil IO.select([worker], nil, nil, 0.01), "ready does not grant release"
          bound = call("bind_process", params(state), id: "bind").fetch(:data)
          assert_equal "running", @journal.derived_attempts("assignment").first.state
          assert_nil IO.select([worker], nil, nil, 0.01), "canonical bind does not grant release"
          issued = call("release_launch", params(bound), id: "release").fetch(:data)
          permission = WIRE.read(worker, deadline: WIRE.deadline(5))
          assert_equal "release", permission.fetch("operation")
          assert_equal issued.fetch("journal_commit"), permission.fetch("journal_commit")
          assert_equal "issued", @journal.mutation_result("release").dig("data", "phase")
          assert_equal issued, call("release_launch", params(bound), id: "release").fetch(:data)
          gate.join(2)
          refute gate.alive?
          assert_nil IO.select([worker], nil, nil, 0.01), "exact replay never sends another frame"
        ensure
          server&.close; worker&.close
          gate&.kill if gate&.alive?
        end
      end

      def test_child_exit_closes_exact_handles_but_does_not_release_parent_reservation
        with_authority do
          1.times do |index|
            state = call("reserve_attempt", @reserve_params, id: "reserve-#{index}").fetch(:data)
            child = binding(91 + index)
            state = call("record_launch", params(state, child), id: "record-#{index}").fetch(:data)
            @kernel.dead << child.dig("process_identity", "pid")
            evidence = "exact exited child #{index}"
            result = call("abort_launch", state.slice("attempt_id", "launch_ticket").merge(
              "expected_generation" => state.fetch("generation"), "failure_evidence" => evidence,
              "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "abort-#{index}").fetch(:data)
            assert_equal "failed", result.fetch("phase")
            assert @kernel.handles.all?(&:closed), "completed cycle cannot retain previous exact handles"
          end
          assert_equal 2, @kernel.handles.size
          assert_raises(AttemptErrors::Conflict) { call("reserve_attempt", @reserve_params, id: "next-cycle") }
        end
      end

      def test_launcher_loss_closes_admission_and_established_gate_never_reconnects
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          server, worker = UNIXSocket.pair
          request = {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}}
          gate = Thread.new { @authority.gate_ready(request: request, peer: @kernel.capture(91), socket: server, deadline: WIRE.deadline(2)) }
          assert_equal "ready", WIRE.read(worker, deadline: WIRE.deadline(2)).dig("data", "phase")
          @kernel.dead << Process.pid
          assert gate.join(1), "exact launcher death must end pre-release gate admission"
          status = call("attempt_status", {"attempt_id" => state.fetch("attempt_id")}, id: nil, role: :supervisor).fetch(:data)
          assert_equal "uncertain", status.fetch("phase")
          assert_equal "reserved", @journal.derived_attempts("assignment").first.state
          assert_nil IO.select([worker], nil, nil, 0.01), "launcher loss cannot issue permission"
          @kernel.dead.clear
          assert_raises(AttemptErrors::Conflict) do
            @authority.gate_ready(request: request, peer: @kernel.capture(91), socket: server, deadline: WIRE.deadline(0.1))
          end
        ensure
          server&.close; worker&.close
          gate&.kill if gate&.alive?
        end
      end

      def test_lost_release_frame_remains_issued_and_exact_exit_cannot_fabricate_no_execution
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          server, worker = UNIXSocket.pair
          request = {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}}
          gate = Thread.new { @authority.gate_ready(request: request, peer: @kernel.capture(91), socket: server, deadline: WIRE.deadline(5)) }
          WIRE.read(worker, deadline: WIRE.deadline(5))
          bound = call("bind_process", params(state), id: "bind").fetch(:data)
          writes = 0
          WIRE.stub(:write, proc { |*args, **options| writes += 1; raise IOError, "lost permission reply" }) do
            issued = call("release_launch", params(bound), id: "release").fetch(:data)
            assert_equal "issued", issued.fetch("phase")
            replay = call("release_launch", params(bound), id: "release")
            assert replay.fetch(:replayed)
            assert_equal issued, replay.fetch(:data)
            assert_equal 1, writes
            @kernel.dead << 91
            evidence = "child exited after issuance"
            uncertain = call("abort_launch", issued.slice("attempt_id", "launch_ticket").merge(
              "expected_generation" => issued.fetch("generation"), "failure_evidence" => evidence,
              "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "abort").fetch(:data)
            assert_equal "uncertain", uncertain.fetch("phase")
            assert_nil uncertain["abort_observation"]
            again = call("abort_launch", uncertain.slice("attempt_id", "launch_ticket").merge(
              "expected_generation" => uncertain.fetch("generation"), "failure_evidence" => evidence,
              "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "later-abort").fetch(:data)
            assert_equal "uncertain", again.fetch("phase"), "prior canonical issuance remains authoritative after an uncertain abort"
            assert_nil again["abort_observation"]
            assert @kernel.handles.none?(&:closed), "issued uncertainty keeps exact termination observations"
          end
          assert gate.join(1)
        ensure
          server&.close; worker&.close
          gate&.kill if gate&.alive?
        end
      end

      def test_uncertain_recovery_without_retained_handle_cannot_infer_exit
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          evidence = "inconclusive observation"
          state = call("abort_launch", state.slice("attempt_id", "launch_ticket").merge(
            "expected_generation" => state.fetch("generation"), "failure_evidence" => evidence,
            "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "uncertain").fetch(:data)
          @authority.close
          @kernel.dead << 91
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            call("abort_launch", state.slice("attempt_id", "launch_ticket").merge(
              "expected_generation" => state.fetch("generation"), "failure_evidence" => evidence,
              "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "missing-observation")
          end
          assert_equal before, @journal.ref_value
          assert_equal "uncertain", @journal.derived_attempts("assignment").first.state
        end
      end

      def test_inconclusive_abort_can_resolve_only_with_exact_retained_exit_and_no_issuance
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          evidence = "child still alive"
          state = call("abort_launch", state.slice("attempt_id", "launch_ticket").merge(
            "expected_generation" => state.fetch("generation"), "failure_evidence" => evidence,
            "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "inconclusive").fetch(:data)
          assert_equal "uncertain", state.fetch("phase")
          assert @kernel.handles.none?(&:closed)
          @kernel.dead << 91
          evidence = "exact retained child pidfd exited; no release ever issued"
          state = call("abort_launch", state.slice("attempt_id", "launch_ticket").merge(
            "expected_generation" => state.fetch("generation"), "failure_evidence" => evidence,
            "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "positive-recovery").fetch(:data)
          assert_equal "failed", state.fetch("phase")
          assert_equal "failed", @journal.derived_attempts("assignment").first.state
          assert @kernel.handles.all?(&:closed)
          assert_raises(AttemptErrors::Conflict) { call("reserve_attempt", @reserve_params, id: "replacement") }
        end
      end

      def test_public_termination_uses_retained_exit_without_native_close_or_repinnning
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          @kernel.dead.concat([90, 91])
          state = call("inspect_launch", {"attempt_id" => state.fetch("attempt_id")}, id: nil, role: :supervisor).fetch(:data)
          assert_equal "exited", state.dig("termination_observation", "status")
          native = Object.new
          native.define_singleton_method(:terminate) { |*args, **options| raise "an already exited child needs no native close" }
          result = driver(native).terminate(state: state, binding: state.fetch("process_binding"), evidence: "retained exact gate exit")
          assert_equal "failed", result.fetch("phase")
          assert_equal 2, @kernel.handles.size, "inspection/termination must not repin an exited process"
          assert @kernel.handles.all?(&:closed)
        end
      end

      def test_oversized_and_deep_scope_or_oversized_result_refuse_before_commit
        with_authority do
          before = @journal.ref_value
          ["1" * 17_000, Array.new(17, "010").join(".")].each_with_index do |scope, index|
            assert_raises(ArgumentError) { call("reserve_attempt", @reserve_params.merge("scope" => scope), id: "oversized-#{index}") }
            assert_equal before, @journal.ref_value
          end
          @map["worker_actor"] = "a" * 17_000
          assert_raises(ArgumentError) { call("reserve_attempt", @reserve_params, id: "oversized-reply") }
          assert_equal before, @journal.ref_value
          assert_empty @journal.derived_attempts("assignment")
          assert_empty @kernel.handles, "a rejected reservation cannot acquire launch authority"
        end
      end

      def test_pre_release_exact_child_exit_is_required_for_abort
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          @kernel.dead << 91
          evidence = "native close observed and exact pre-acquired child pidfd exited"
          aborted = call("abort_launch", state.slice("attempt_id", "launch_ticket").merge(
            "expected_generation" => state.fetch("generation"), "failure_evidence" => evidence,
            "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: "abort").fetch(:data)
          assert_equal "failed", aborted.fetch("phase")
          assert @kernel.handles.all?(&:closed)
          assert_equal "failed", @journal.derived_attempts("assignment").first.state
        end
      end
    end
  end
end

module Ace
  module Assign
    class ProtectedLaunchLifecycleTest
      class ClientAdapter
        def initialize(authority, peer)
          @authority, @peer = authority, peer
        end
        def call(operation, params, mutation_id: nil, **)
          response = @authority.dispatch(request: {"version" => 1, "operation" => operation,
            "mutation_id" => mutation_id, "project_id" => "project", "params" => params.merge("mapping_id" => "mapping")},
            peer: @peer, role: :launcher)
          Authority::Client::Reply.new(data: response.fetch(:data), replayed: response.fetch(:replayed))
        end
      end
      class LostNative
        attr_reader :creations
        def initialize; @creations = 0; end
        def preflight!; true; end
        def create(**)
          @creations += 1
          raise Ace::Runtime::RuntimeUnavailableError, "create reply lost"
        end
      end

      def driver(native)
        map = @map
        deployment = Object.new
        deployment.define_singleton_method(:mapping) { |_id| map }
        deployment.define_singleton_method(:verify!) { |*_args, **_kwargs| map }
        Authority::LaunchDriver.new(mapping_id: "mapping", deployment: deployment, kernel: @kernel,
          client: ClientAdapter.new(@authority, @peer), native: native)
      end

      def registered_bytes
        registration = @journal.mutation_result("register").fetch("data")
        @journal.blob(registration.fetch("definition_ref"))
      end

      def test_driver_never_repeats_creation_after_lost_response_and_reservation_replay
        with_authority do
          native = LostNative.new
          launch = driver(native)
          first = launch.launch(assignment_id: "assignment", definition_bytes: registered_bytes,
            scope: "010", base_head: "a" * 40, mutation_id: "invocation")
          assert_equal "uncertain", first.fetch("phase")
          second = launch.launch(assignment_id: "assignment", definition_bytes: registered_bytes,
            scope: "010", base_head: "a" * 40, mutation_id: "invocation")
          assert_equal "inspect_retained_reservation_no_creation_permission", second.fetch("required_action")
          assert_equal 1, native.creations
          assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "intent" }
        end
      end

      def test_driver_losing_cas_to_same_id_acceptance_never_creates_native_child
        with_authority do
          journal, repo = @journal, @journal.repo_root
          original = journal.method(:update_ref_cas)
          lost = false
          journal.define_singleton_method(:update_ref_cas) do |new_commit, old|
            unless lost
              lost = true
              competing, error, status = Open3.capture3("git", "-c", "user.name=competitor", "-c", "user.email=competitor@localhost",
                "commit-tree", "#{new_commit}^{tree}", "-p", old, "-m", "same-ID competing reservation", chdir: repo, stdin_data: "")
              raise error unless status.success?
              _out, error, status = Open3.capture3("git", "update-ref", ref, competing.strip, old, chdir: repo, stdin_data: "")
              raise error unless status.success?
              next false
            end
            original.call(new_commit, old)
          end
          native = LostNative.new
          result = driver(native).launch(assignment_id: "assignment", definition_bytes: registered_bytes,
            scope: "010", base_head: "a" * 40, mutation_id: "invocation")
          assert_equal "inspect_retained_reservation_no_creation_permission", result.fetch("required_action")
          assert_equal 0, native.creations
          assert_equal @journal.ref_value, result.fetch("journal_commit")
        end
      end
    end
  end
end

module Ace
  module Assign
    class ProtectedLaunchLifecycleTest
      def abort_child(state, id: "abort")
        @kernel.dead << 91
        evidence = "exact pre-acquired child pidfd exited before any release"
        call("abort_launch", state.slice("attempt_id", "launch_ticket").merge(
          "expected_generation" => state.fetch("generation"), "failure_evidence" => evidence,
          "failure_digest" => Digest::SHA256.hexdigest(evidence)), id: id).fetch(:data)
      end

      def test_child_only_abort_cannot_authorize_another_reservation
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          assert_equal "failed", abort_child(state).fetch("phase")
          assert_raises(AttemptErrors::Conflict) { call("reserve_attempt", @reserve_params, id: "new-reserve") }
          assert_equal ["failed"], @journal.derived_attempts("assignment").map(&:state)
        end
      end

      def test_definition_change_requires_all_scopes_terminal
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          pending_bytes = JSON.generate(JSON.parse(registered_bytes).merge("name" => "pending definition"))
          assert_raises(AttemptErrors::Conflict) do
            call("register_assignment", {"definition_bytes" => pending_bytes, "definition_digest" => Digest::SHA256.hexdigest(pending_bytes),
              "expected_generation" => 1}, id: "pending-register")
          end
          abort_child(state)
          changed = JSON.parse(registered_bytes).merge("name" => "changed definition")
          bytes = JSON.generate(changed)
          registration = call("register_assignment", {"definition_bytes" => bytes,
            "definition_digest" => Digest::SHA256.hexdigest(bytes), "expected_generation" => 1}, id: "changed-register").fetch(:data)
          assert_equal 2, registration.fetch("definition_generation")
          old_commit = @journal.ref_value
          assert_raises(AttemptErrors::Conflict) do
            call("reserve_attempt", @reserve_params.merge("scope" => "020", "expected_generation" => 2), id: "other-scope")
          end
          assert_equal old_commit, @journal.ref_value
        end
      end
    end
  end
end
