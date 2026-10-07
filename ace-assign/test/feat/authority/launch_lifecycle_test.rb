# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/launch_driver"
require "ace/assign/authority/server"
require "ace/assign/cli/commands/authority/launch"
require_relative "../../support/execution_scope_observation_fixtures"
require_relative "../../support/execution_scope_native_owner_fixture"

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

      # Actual private readiness callback producer with controlled kernel,
      # manager and filesystem observations; no installed/native probes.
      def self.class_temp_dir
        @class_temp_dir ||= Dir.mktmpdir("ace-launch-owner-", Etc.getpwuid(Process.uid).dir)
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
            "launcher_uid" => 13002, "launcher_gid" => 13002, "launcher_groups" => [13002],
            "worker_groups" => [13001], "bootstrap" => "/usr/libexec/ace-worker-gate", "bootstrap_sha256" => "a" * 64, "worker_cwd" => "/home/worker", "worker_actor" => "worker", "native" => {"workspace_id" => "w1"}}
          deployment = Object.new
          deployment.define_singleton_method(:artifact_reference) { {"sha256" => "d" * 64} }
          mapping = @map
          deployment.define_singleton_method(:mapping) { |_id| mapping }
          deployment.define_singleton_method(:authority) { |_id| {"state_root" => File.join(cache, "authority-state")} }
          deployment.define_singleton_method(:project) { |_id| {"assignment_root" => File.join(cache, "assignments")} }
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "checkout"))
          @authority = Authority::LaunchLifecycle.new(deployment: deployment, kernel: @kernel, journals: {"project" => @journal}, scope_observer_factory: ->(_id) { ExecutionScopeNativeOwnerFixture.new(@map, @journal, @kernel, owner: @authority) })
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
        {"runtime" => "herdr", "session" => "w1", "pane" => "w1:p2", "terminal_id" => "term_ab",
          "process_identity" => child, "shell_identity" => child, "native_origin" => {"workspace" => "w1", "tab" => "w1:t2",
            "pane" => "w1:p2", "command" => ["/usr/libexec/ace-worker-gate", "mapping", @ticket], "cwd" => "/home/worker", "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001]}}
      end

      def params(state, child = binding)
        generation = if state["phase"] == "reserved"
          call("inspect_launch", state.slice("attempt_id"), id: nil).dig(:data, "generation")
        else
          state.fetch("generation")
        end
        result = state.slice("attempt_id", "launch_ticket").merge("process_binding" => child, "expected_generation" => generation)
        if state["phase"] == "reserved"
          result["guarded_origin"] = {"terminal_id" => child.fetch("terminal_id"), "runtime_incarnation" => ExecutionScopeObservationFixtures::BOOT,
            "child" => child.fetch("process_identity")}
        end
        result
      end

      def test_record_launch_guard_requires_exact_original_actor_before_canonical_acceptance
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          request = params(state)
          old = @journal.ref_value
          guard = request.fetch("guarded_origin")
          [nil, guard.merge("terminal_id" => "term_cd"), guard.merge("child" => guard.fetch("child").merge("pid" => 92))].each_with_index do |changed, index|
            assert_raises(Ace::Runtime::RuntimeUnavailableError) do
              call("record_launch", request.merge("guarded_origin" => changed), id: "bad-guard-#{index}")
            end
            assert_equal old, @journal.ref_value
            assert_nil @journal.mutation_result("bad-guard-#{index}")
          end
        end
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

      class StreamKernel
        def initialize(kernel, me:, peer:)
          @kernel, @me, @peer = kernel, me, peer
        end
        def supported!; true; end
        def capture(pid); pid == Process.pid ? @me : @kernel.capture(pid); end
        def peer(_socket); @peer; end
        def method_missing(name, *args, **options, &block); @kernel.public_send(name, *args, **options, &block); end
        def respond_to_missing?(name, include_private = false); @kernel.respond_to?(name, include_private) || super; end
      end

      class OriginalGuardedNative < Ace::Herdr::Molecules::ProtectedNativeControl
        attr_reader :prompt_calls
        attr_accessor :before_prompt_ack
        def exchange(method, params = {}, **limits)
          raise "Unexpected native effect" unless method == "agent.prompt"
          (@prompt_calls ||= []) << params
          before_prompt_ack&.call
          {"id" => "native-fixture", "result" => {"type" => "agent_prompted", "agent" => {"status" => "ready"},
            "origin" => params.fetch("expected_origin"), "submission" => "submitted"}}
        end
        private :exchange

        def request(method, params = {})
          case method
          when "ping" then {"version" => "0.9.3", "protocol" => 22, "capabilities" => {"endpoint_protocol_generation" => 1}}
          when "workspace.get" then {"workspace" => {"workspace_id" => "w1"}}
          when "layout.apply" then {"layout" => {"workspace_id" => "w1", "tab_id" => "w1:t2", "root" => {
            "type" => "pane", "pane_id" => "w1:p2", "command" => params.fetch("root").fetch("command"), "cwd" => @mapping.fetch("worker_cwd")}}}
          when "pane.get" then {"pane" => {"workspace_id" => "w1", "tab_id" => "w1:t2", "pane_id" => "w1:p2", "terminal_id" => "term_ab"}}
          when "pane.process_info" then {"process_info" => {"pane_id" => "w1:p2", "shell_pid" => 91,
            "guarded_prompt" => true, "guarded_input_drain" => true, "guarded_prompt_origin" => {
              "terminal_id" => "term_ab", "runtime_incarnation" => ExecutionScopeObservationFixtures::BOOT, "child" => @kernel.capture(91)}}}
          else raise "Unexpected source native request"
          end
        end
      end

      def test_actual_launch_driver_remains_valid_and_explicit_native_guard_capture_preserves_scope_binding
        with_authority do
          fixed = @map.merge("native" => @map.fetch("native").merge("server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001]))
          native = OriginalGuardedNative.new(mapping: fixed, kernel: @kernel)
          client = ClientAdapter.new(@authority, @peer)
          original_call = client.method(:call)
          ready = Queue.new
          errors = []
          client.define_singleton_method(:call) do |operation, params, **options|
            response = original_call.call(operation, params, **options)
            ready << response.data if operation == "record_launch"
            response
          rescue StandardError => error
            errors << [operation, error.class.name, error.message]
            raise
          end
          server, worker = UNIXSocket.pair
          gate = Thread.new do
            state = ready.pop
            @authority.gate_ready(request: {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}},
              peer: @kernel.capture(91), socket: server, deadline: WIRE.deadline(30))
          end
          deployment = Object.new
          map = @map
          deployment.define_singleton_method(:mapping) { |_id| map }
          deployment.define_singleton_method(:verify!) { |*_args, **_kwargs| map }
          launch = Authority::LaunchDriver.new(mapping_id: "mapping", deployment: deployment, kernel: @kernel, client: client, native: native)
          issued_for_cli = Queue.new
          continue_cli = Queue.new
          cli_ready = Queue.new
          retained_driver = launch.method(:serve_control!)
          launch.define_singleton_method(:serve_control!) do |state:, &announce|
            issued_for_cli << state
            continue_cli.pop
            retained_driver.call(state: state, &announce)
          end
          command = CLI::Commands::Authority::Launch.new
          command.define_singleton_method(:build_driver) { |_| launch }
          definition_root = Dir.mktmpdir("original-cli-definition-")
          definition_path = File.join(definition_root, "definition.json")
          File.write(definition_path, registered_bytes)
          cli_output = StringIO.new
          cli_output.define_singleton_method(:write) do |line|
            count = super(line)
            cli_ready << JSON.parse(line)
            count
          end
          original_stdout = $stdout
          $stdout = cli_output
          cli_thread = Thread.new do
            command.call(mapping: "mapping", assignment: "assignment", definition: definition_path,
              step: "010", base_head: "a" * 40, mutation: "actual-guard-owner")
          end
          state = issued_for_cli.pop
          assert_equal "issued", state.fetch("phase"), errors.inspect + " " + state.inspect
          recorded = @journal.mutation_result("actual-guard-owner-record").fetch("data")
          assert_equal native.guarded_binding!(recorded.fetch("process_binding")).fetch("guarded_origin"), recorded.fetch("guarded_origin")
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") }
          original_record = events.find { |event| event.dig("payload", "operation") == "record_launch" }
          authenticated = @authority.send(:original_prompt_record!, events, state,
            params: state.slice("mapping_id", "assignment_id", "attempt_id"))
          assert_equal original_record.fetch("digest"), authenticated.fetch("binding_digest")
          assert_equal recorded.fetch("guarded_origin"), authenticated.fetch("origin")
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @authority.send(:original_prompt_record!, events, state.merge("guarded_origin" => nil),
              params: state.slice("mapping_id", "assignment_id", "attempt_id"))
          end

          original = state.fetch("process_binding")
          refute original.key?("guarded_origin")
          guarded = native.guarded_binding!(original)
          guard = guarded.fetch("guarded_origin")
          assert_equal @kernel.capture(91), guard.fetch("child")
          assert_equal "term_ab", guard.fetch("terminal_id")
          assert_equal original, @journal.mutation_result("actual-guard-owner-record").dig("data", "process_binding")
          assert_equal original, @journal.read_events("assignment").find { |event| event["type"] == "scope_child_bound" }.dig("payload", "original_process_binding")
          assert_equal original, guarded.reject { |key, _| key == "guarded_origin" }
          assert_equal "ready", WIRE.read(worker, deadline: WIRE.deadline(5)).dig("data", "phase")
          assert_equal "release", WIRE.read(worker, deadline: WIRE.deadline(5)).fetch("operation")
          gate.join(2)
          refute gate.alive?
          exercise_actual_prompt_stream(launch, native, state, authenticated, cli_thread: cli_thread, continue_cli: continue_cli, cli_ready: cli_ready)
          assert_equal 1, cli_output.string.lines.length
          assert_equal "launch_ready", JSON.parse(cli_output.string).fetch("type")
        ensure
          $stdout = original_stdout if original_stdout
          FileUtils.rm_rf(definition_root) if definition_root
          continue_cli << true if continue_cli
          launch&.request_control_cancel
          cli_thread&.join(3)
          server&.close
          worker&.close
          gate&.kill if gate&.alive?
        end
      end

      def exercise_actual_prompt_stream(launch, native, state, authenticated, cli_thread:, continue_cli:, cli_ready:)
        deployment = @authority.instance_variable_get(:@deployment)
        service_root = deployment.authority("authority").fetch("state_root")
        FileUtils.mkdir_p(service_root, mode: 0700)
        File.chmod(0700, service_root)
        service = @kernel.capture(Process.pid).merge("uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort,
          "socket_path" => File.join(service_root, "authority.sock"), "state_root" => service_root)
        project = deployment.project("project").merge("supervisor_uids" => [], "peer_credentials" => {
          @peer.fetch("uid").to_s => @peer.slice("gid", "groups").merge("scratch_root" => service_root)})
        deployment.define_singleton_method(:authority) { |_| service }
        deployment.define_singleton_method(:project) { |_| project }
        deployment.define_singleton_method(:verify!) { |*_, **_| @fixture_map }
        deployment.instance_variable_set(:@fixture_map, @map)
        deployment.define_singleton_method(:verify_composition!) { |*_, **_| true }
        deployment.define_singleton_method(:verify_receiver_paths!) { |_| true }
        server_kernel = StreamKernel.new(@kernel, me: service, peer: @peer)
        client_kernel = StreamKernel.new(@kernel, me: @peer, peer: service)
        server = Authority::Server.new(authority_id: "authority", lifecycle: @authority, deployment: deployment, kernel: server_kernel)
        listener = Thread.new { server.serve }
        deadline = WIRE.deadline(3)
        until File.socket?(service.fetch("socket_path"))
          raise "Source listener failed to start" unless listener.alive? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
          sleep(0.01)
        end
        client = Authority::Client.new(mapping_id: "mapping", deployment: deployment, kernel: client_kernel)
        report_trace = []
        original_stream_call = client.method(:call)
        client.define_singleton_method(:call) do |operation, params, **options|
          tracing = operation == "launch_prompt_completion"
          report_trace << ["start", params.fetch("mutation_id"), Process.clock_gettime(Process::CLOCK_MONOTONIC)] if tracing
          result = original_stream_call.call(operation, params, **options)
          report_trace << ["done", params.fetch("mutation_id"), Process.clock_gettime(Process::CLOCK_MONOTONIC)] if tracing
          result
        rescue StandardError => error
          report_trace << ["error", params.fetch("mutation_id"), error.class.name, error.message] if tracing
          raise
        end
        launch.instance_variable_set(:@client, client)
        disconnected_generation = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        disconnected_ref = @journal.ref_value
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          client.call("prompt_attempt", state.slice("assignment_id", "attempt_id").merge("expected_generation" => disconnected_generation),
            mutation_id: "no-original-channel", upload_parts: ["valid prompt before channel"], purpose: :prompt_text)
        end
        assert_equal disconnected_ref, @journal.ref_value
        assert_nil native.prompt_calls
        driver = cli_thread
        continue_cli << true
        ready_frame = cli_ready.pop
        assert_equal "launch_ready", ready_frame.fetch("type")
        assert_equal authenticated.fetch("binding_digest"), ready_frame.fetch("original_binding_digest")
        original_generation = ready_frame.fetch("generation")
        selectors = state.slice("assignment_id", "attempt_id").merge("expected_generation" => original_generation)
        old = @journal.ref_value
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          client.call("prompt_attempt", selectors, mutation_id: "unicode-blank", upload_parts: ["\u2003"], purpose: :prompt_text)
        end
        assert_equal old, @journal.ref_value
        assert_nil native.prompt_calls
        first = client.call("prompt_attempt", selectors, mutation_id: "stream-first", upload_parts: ["first private prompt"], purpose: :prompt_text, timeout: 30)
        assert_equal "submitted", first.data.fetch("outcome")
        assert_equal 1, native.prompt_calls.length
        intent = @journal.prompt_intent("stream-first")
        query = {"version" => 1, "operation" => "launch_prompt_intent", "mutation_id" => nil, "project_id" => "project",
          "params" => state.slice("assignment_id", "attempt_id").merge("mapping_id" => "mapping", "mutation_id" => "stream-first",
            "intent_event_id" => intent.fetch("digest"), "journal_commit" => first.data.fetch("journal_commit"))}
        before_invalid_query = @journal.ref_value
        WIRE.connect(service.fetch("socket_path"), deadline: WIRE.deadline(3)) do |socket|
          WIRE.write(socket, query, deadline: WIRE.deadline(3))
          socket.write("unexpected body")
          socket.shutdown(Socket::SHUT_WR)
          rejected = WIRE.read(socket, deadline: WIRE.deadline(3))
          refute_equal "ok", rejected.fetch("status")
        end
        assert_equal before_invalid_query, @journal.ref_value
        assert_equal 1, native.prompt_calls.length
        replay = client.call("prompt_attempt", selectors, mutation_id: "stream-first", upload_parts: ["first private prompt"], purpose: :prompt_text, timeout: 30)
        assert replay.replayed
        assert_equal first.data, replay.data
        assert_equal 1, native.prompt_calls.length
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          client.call("prompt_attempt", selectors, mutation_id: "stream-first", upload_parts: ["changed private prompt"], purpose: :prompt_text, timeout: 30)
        end
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        second = client.call("prompt_attempt", selectors.merge("expected_generation" => current), mutation_id: "stream-second",
          upload_parts: ["second private prompt"], purpose: :prompt_text, timeout: 30)
        assert_equal "submitted", second.data.fetch("outcome")
        assert_equal 2, native.prompt_calls.length
        assert_equal 2, @journal.read_events("assignment").count { |event| event["type"] == "prompt_issued" }
        refute JSON.generate(@journal.read_events("assignment")).include?("private prompt")
        unused_commit = @journal.ref_value
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          client.call("prompt_attempt", selectors, mutation_id: "stale-capacity", upload_parts: ["valid stale-generation prompt"], purpose: :prompt_text, timeout: 30)
        end
        assert_equal unused_commit, @journal.ref_value
        assert_nil @journal.prompt_intent("stale-capacity")
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        original_cas = @journal.method(:update_ref_cas)
        abandoned_commits = []
        @journal.define_singleton_method(:update_ref_cas) { |candidate, _old| abandoned_commits << candidate; false }
        begin
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            client.call("prompt_attempt", selectors.merge("expected_generation" => current), mutation_id: "failed-cas-capacity",
              upload_parts: ["valid lost-CAS prompt"], purpose: :prompt_text, timeout: 30)
          end
        ensure
          @journal.define_singleton_method(:update_ref_cas, original_cas)
        end
        assert_equal unused_commit, @journal.ref_value
        assert_nil @journal.prompt_intent("failed-cas-capacity")
        assert_equal Molecules::EvidenceJournal::CAS_ATTEMPTS, abandoned_commits.length
        assert_raises(AttemptErrors::EvidenceUnavailable) { @journal.verify_prompt_prefix!(commit: abandoned_commits.last) }
        assert_equal 2, native.prompt_calls.length
        pending_entered = Queue.new
        allow_native_completion = Queue.new
        native.before_prompt_ack = -> { pending_entered << true; allow_native_completion.pop }
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        pending_caller = Thread.new do
          client.call("prompt_attempt", selectors.merge("expected_generation" => current), mutation_id: "stream-capacity-first",
            upload_parts: ["queued third prompt"], purpose: :prompt_text, timeout: 30)
        rescue Ace::Runtime::RuntimeUnavailableError => error
          error
        end
        pending_entered.pop
        busy_commit = @journal.ref_value
        busy_generation = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          client.call("prompt_attempt", selectors.merge("expected_generation" => busy_generation), mutation_id: "stream-busy",
            upload_parts: ["distinct concurrent prompt"], purpose: :prompt_text, timeout: 30)
        end
        assert_equal busy_commit, @journal.ref_value
        assert_nil @journal.prompt_intent("stream-busy")
        assert_equal 3, native.prompt_calls.length
        # Controlled public deadline boundary while the private stream remains
        # intact. Its canonical ACK must select the later observed native fact.
        capacity_intent = @journal.prompt_intent("stream-capacity-first")
        ack_selectors = state.slice("assignment_id", "attempt_id").merge("mapping_id" => "mapping")
        capacity_uncertain = @authority.send(:finish_prompt_outcome!, ack_selectors, @map, capacity_intent,
          {"outcome" => "uncertain", "origin" => authenticated.fetch("origin")})
        allow_native_completion << true
        assert_equal "uncertain", pending_caller.value.data.fetch("outcome")
        ack_deadline = WIRE.deadline(5)
        until (ack_commit = launch.instance_variable_get(:@reported_prompt_completions)[capacity_intent.fetch("digest")])
          raise "Original driver did not receive canonical live-stream ACK" unless Process.clock_gettime(Process::CLOCK_MONOTONIC) < ack_deadline
          sleep(0.01)
        end
        refute_equal capacity_uncertain.dig(:data, "journal_commit"), ack_commit
        assert @journal.read_events("assignment", commit: ack_commit).any? { |event| event["type"] == "prompt_completion_observed" &&
          event.dig("payload", "external_mutation_id") == "stream-capacity-first" && event.dig("payload", "evidence", "outcome") == "submitted" }
        native.before_prompt_ack = nil
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        available = client.call("prompt_attempt", selectors.merge("expected_generation" => current), mutation_id: "stream-busy",
          upload_parts: ["distinct concurrent prompt"], purpose: :prompt_text, timeout: 30)
        assert_equal "submitted", available.data.fetch("outcome")
        assert_equal 4, native.prompt_calls.length
        native.before_prompt_ack = -> { pending_entered << true; allow_native_completion.pop }
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        pending_caller = Thread.new do
          client.call("prompt_attempt", selectors.merge("expected_generation" => current), mutation_id: "stream-pending",
            upload_parts: ["fifth prompt pending close"], purpose: :prompt_text, timeout: 30)
        rescue Ace::Runtime::RuntimeUnavailableError => error
          error
        end
        pending_entered.pop
        close_selectors = state.slice("assignment_id", "attempt_id").merge("mapping_id" => "mapping")
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        @authority.close_execution_scope!(params: close_selectors.merge("mutation_id" => "seal-with-pending", "expected_generation" => current), peer: @peer, role: :launcher)
        observed = @authority.observe_execution_scope!(params: close_selectors, peer: @peer, role: :launcher)
        assert_equal "unverifiable", observed.fetch("state")
        assert_equal "drain_original_prompt_issuer", observed.fetch("required_action")
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        closed = @authority.close_execution_scope!(params: close_selectors.merge("mutation_id" => "close-with-pending", "expected_generation" => current), peer: @peer, role: :launcher)
        assert_equal "running", closed.dig(:data, "state")
        refute @journal.read_events("assignment").any? { |event| event["type"] == "scope_closed_no_writers" }
        # Controlled deadline boundary: use the actual canonical completion
        # owner to finalize uncertainty before the held native ACK is released.
        pending_intent = @journal.prompt_intent("stream-pending")
        original_guard = authenticated.fetch("origin")
        first_uncertain = @authority.send(:finish_prompt_outcome!, close_selectors, @map, pending_intent,
          {"outcome" => "uncertain", "origin" => original_guard})
        assert_equal "uncertain", first_uncertain.dig(:data, "outcome")
        old_channel = @authority.instance_variable_get(:@control_channels).values.first
        private_socket = old_channel.instance_variable_get(:@socket)
        private_socket.close unless private_socket.closed?
        allow_native_completion << true
        public_result = pending_caller.value
        if public_result.is_a?(Authority::Client::Reply)
          assert_equal "uncertain", public_result.data.fetch("outcome")
        else
          assert_instance_of Ace::Runtime::RuntimeUnavailableError, public_result
        end
        assert_equal 5, native.prompt_calls.length
        assert_equal "uncertain", @journal.mutation_result("stream-pending").dig("data", "outcome")
        late = nil
        recovery_deadline = WIRE.deadline(30)
        until late
          late = @journal.read_events("assignment").find { |event| event["type"] == "prompt_completion_observed" && event.dig("payload", "external_mutation_id") == "stream-pending" }
          unless Process.clock_gettime(Process::CLOCK_MONOTONIC) < recovery_deadline
            reported = launch.instance_variable_get(:@reported_prompt_completions).size
            known = launch.instance_variable_get(:@seen_prompt_intents).size
            raise "Original process did not recover known ACK: reported=#{reported}/#{known}, trace=#{report_trace.last(12).inspect}"
          end
          sleep(0.05) unless late
        end
        assert_equal "submitted", late.dig("payload", "evidence", "outcome")
        assert cli_ready.empty?, "Original process reconnect must not print a second ready frame"
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        proven = @authority.close_execution_scope!(params: close_selectors.merge("mutation_id" => "close-after-actual-ack", "expected_generation" => current), peer: @peer, role: :launcher)
        assert_equal "closed_no_writers", proven.dig(:data, "state")
        assert proven.dig(:data, "proof_id")
      ensure
        allow_native_completion << true if allow_native_completion
        pending_caller&.join(3)
        launch.request_control_cancel
        server&.stop
        driver&.join(3)
        listener&.join(3)
        refute driver&.alive?
        refute listener&.alive?
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
