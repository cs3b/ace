# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/launch_driver"
require "ace/assign/authority/server"
require "ace/assign/cli/commands/authority/launch"
require_relative "../../support/execution_scope_observation_fixtures"
require_relative "../../support/execution_scope_native_owner_fixture"
require_relative "../../support/original_launch_driver_owner_fixture"

module Ace
  module Assign
    class ProtectedLaunchLifecycleTest < AceAssignTestCase
      include OriginalLaunchDriverOwnerFixture
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

      def test_input_inhibition_selection_and_evidence_fail_closed_without_original_authentication
        with_authority do
          map = @map
          @authority.instance_variable_get(:@deployment).define_singleton_method(:verify!) { |*_args, **_kwargs| map }
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          close = call("close_execution_scope", state.slice("attempt_id").merge("expected_generation" => state.fetch("generation")), id: "seal").fetch(:data)
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") }
          record = events.find { |event| event.dig("payload", "operation") == "record_launch" }
          seal = events.find { |event| event["type"] == "scope_sealed" }
          selected = state.slice("attempt_id").merge("mapping_id" => "mapping", "assignment_id" => "assignment",
            "original_binding_digest" => record.fetch("digest"), "seal_event_id" => seal.fetch("digest"), "journal_commit" => close.fetch("journal_commit"))
          request = {"version" => 1, "project_id" => "project", "operation" => "launch_input_inhibit_selection", "mutation_id" => nil, "params" => selected}
          old = @journal.ref_value
          assert_equal selected.slice("attempt_id", "original_binding_digest", "seal_event_id", "journal_commit"), @authority.dispatch(request: request, peer: @peer, role: :launcher).fetch(:data)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { @authority.dispatch(request: request, peer: @peer.merge("pid" => 500, "started_at" => "different birth"), role: :launcher) }
          %w[original_binding_digest seal_event_id].each do |key|
            assert_raises(AttemptErrors::EvidenceUnavailable) { @authority.dispatch(request: request.merge("params" => selected.merge(key => "f" * 64)), peer: @peer, role: :launcher) }
          end
          original = record.dig("payload", "data", "guarded_origin")
          evidence = {"outcome" => "inhibited", "origin" => original, "input_state" => "inhibited", "pending_input" => 0}
          invalid = [evidence.merge("pending_input" => 0.0), evidence.merge("outcome" => "unconfirmed"),
            evidence.merge("origin" => original.merge("terminal_id" => "term_other")), evidence.merge("extra" => true)]
          invalid.each { |value| assert_raises(AttemptErrors::EvidenceUnavailable) { @journal.verify_input_drained_evidence!(value, original) } }
          [nil, "scalar", []].each do |payload|
            assert_raises(AttemptErrors::EvidenceUnavailable) { @authority.send(:accepted_input_inhibition?, [{"type" => "input_inhibited", "payload" => payload}], @journal, old) }
          end
          assert_raises(ArgumentError) do
            @journal.mutate(assignment_id: "assignment", attempt_id: state.fetch("attempt_id"), mutation_id: "input-inhibit.#{seal.fetch('digest')}",
              operation: "ordinary", parameters_digest: "a" * 64, expected_generation: close.fetch("generation")) { flunk "reserved inhibition namespace admitted" }
          end
          assert_equal old, @journal.ref_value
        end
      end

      def test_prompt_status_authenticates_original_snapshot_and_late_outcome_without_replay_upgrade
        with_authority do
          map = @map
          @authority.instance_variable_get(:@deployment).define_singleton_method(:verify!) { |*_args, **_kwargs| map }
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          selected = state.slice("assignment_id", "attempt_id").merge("mapping_id" => "mapping")
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") }
          original = @authority.send(:original_prompt_record!, events, state, params: selected)
          binding = selected.merge("project_id" => "project", "action" => "prompt_attempt", "mutation_id" => "status-prompt",
            "expected_generation" => @journal.authority_generation(events), "caller" => @peer.slice("uid", "gid", "groups").merge("role" => "launcher"),
            "original_binding_digest" => original.fetch("binding_digest"), "text_sha256" => Digest::SHA256.hexdigest("private"), "text_bytes" => 7)
          @journal.issue_prompt(binding: binding, issued_by: @peer) { |current, *| @authority.send(:original_prompt_record!, current, state, params: selected) }
          intent = @journal.prompt_intent("status-prompt")
          status_request = {"version" => 1, "operation" => "prompt_status", "project_id" => "project", "mutation_id" => nil,
            "params" => selected.merge("mutation_id" => "status-prompt")}
          query = ->(peer = @peer, request = status_request) { @authority.dispatch(request: request, peer: peer, role: :launcher).fetch(:data) }
          old = @journal.ref_value
          pending = query.call
          assert_equal "uncertain", pending.fetch("outcome")
          assert_nil pending.fetch("outcome_event_id")
          assert_equal old, @journal.ref_value
          assert_equal pending, query.call(@peer.merge("pid" => 500, "started_at" => "new authorized process"))
          assert_raises(AttemptErrors::NotFound) { query.call(@peer, status_request.merge("params" => selected.merge("mutation_id" => "missing"))) }
          assert_raises(AttemptErrors::Conflict) { query.call(@peer, status_request.merge("params" => selected.merge("attempt_id" => "other", "mutation_id" => "status-prompt"))) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { query.call(@peer.merge("uid" => 14000)) }
          authentication = ->(current, *) { @authority.send(:original_prompt_record!, current, state, params: selected) }
          uncertain = @journal.finalize_prompt(mutation_id: "status-prompt", intent_event_id: intent.fetch("digest"),
            binding_digest: intent.dig("payload", "binding_digest"), evidence: {"outcome" => "uncertain", "origin" => original.fetch("origin")}, &authentication)
          evidence = {"outcome" => "submitted", "origin" => original.fetch("origin"), "submission" => "submitted"}
          @journal.observe_prompt_completion(mutation_id: "status-prompt", intent_event_id: intent.fetch("digest"),
            binding_digest: intent.dig("payload", "binding_digest"), evidence: evidence, &authentication)
          known = query.call
          observation = @journal.read_events("assignment").find { |event| event["type"] == "prompt_completion_observed" }
          assert_equal "submitted", known.fetch("outcome")
          assert_equal observation.fetch("digest"), known.fetch("outcome_event_id")
          assert_equal @journal.ref_value, known.fetch("journal_commit")
          assert_equal @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") }), known.fetch("generation")
          replay = @journal.finalize_prompt(mutation_id: "status-prompt", intent_event_id: intent.fetch("digest"),
            binding_digest: intent.dig("payload", "binding_digest"), evidence: evidence, &authentication)
          assert_equal uncertain.fetch(:data), replay.fetch(:data)
          deployment = @authority.instance_variable_get(:@deployment)
          root = deployment.authority("authority").fetch("state_root")
          FileUtils.mkdir_p(root, mode: 0700)
          File.chmod(0700, root)
          service = @kernel.capture(Process.pid).merge("uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort,
            "socket_path" => File.join(root, "status.sock"), "state_root" => root)
          project = deployment.project("project").merge("supervisor_uids" => [], "peer_credentials" => {})
          deployment.define_singleton_method(:authority) { |_| service }
          deployment.define_singleton_method(:project) { |_| project }
          deployment.define_singleton_method(:verify_composition!) { |*_, **_| true }
          deployment.define_singleton_method(:verify_receiver_paths!) { |_| true }
          server = Authority::Server.new(authority_id: "authority", lifecycle: @authority, deployment: deployment,
            kernel: StreamKernel.new(@kernel, me: service, peer: @peer))
          listener = Thread.new { server.serve }
          deadline = WIRE.deadline(3)
          until File.socket?(service.fetch("socket_path"))
            raise "Source status listener failed to start" unless listener.alive? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
            sleep(0.01)
          end
          client = Authority::Client.new(mapping_id: "mapping", deployment: deployment,
            kernel: StreamKernel.new(@kernel, me: @peer, peer: service))
          old = @journal.ref_value
          assert_equal known, client.call("prompt_status", selected.reject { |key, _| key == "mapping_id" }.merge("mutation_id" => "status-prompt")).data
          WIRE.connect(service.fetch("socket_path"), deadline: WIRE.deadline(3)) do |socket|
            WIRE.write(socket, status_request, deadline: WIRE.deadline(3))
            socket.write("trailing body")
            socket.shutdown(Socket::SHUT_WR)
            refute_equal "ok", WIRE.read(socket, deadline: WIRE.deadline(3)).fetch("status")
          end
          assert_equal old, @journal.ref_value
        ensure
          server&.stop
          listener&.join
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

      def test_actual_launch_driver_remains_valid_and_explicit_native_guard_capture_preserves_scope_binding
        exercise_actual_launch_owner
      end

      def test_actual_original_driver_recovers_unconfirmed_drain_and_unknown_prompt_without_resend
        exercise_actual_launch_owner(input_drain: true)
      end

      def test_issued_actor_without_prompt_rows_requires_positive_lifetime_input_inhibition
        exercise_actual_launch_owner(input_drain: :no_prompt)
      end

      def test_public_stop_owns_containment_without_changing_running_state_or_replaying_native_input
        exercise_actual_launch_owner(input_drain: :stop_no_prompt)
      end

      def test_original_driver_reports_lost_drain_ack_after_child_exit_without_second_native_effect
        exercise_actual_launch_owner(input_drain: :lost_ack)
      end

      def exercise_actual_launch_owner(input_drain: false)
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
          deployment.define_singleton_method(:authority) { |_| {"composition" => "launch"} }
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
          exercise_actual_prompt_stream(launch, native, state, authenticated, cli_thread: cli_thread, continue_cli: continue_cli, cli_ready: cli_ready, input_drain: input_drain)
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

      def exercise_actual_prompt_stream(launch, native, state, authenticated, cli_thread:, continue_cli:, cli_ready:, input_drain: false)
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
        if input_drain
          if %i[no_prompt stop_no_prompt].include?(input_drain)
            exercise_no_prompt_input_drain(client, native, state, original_generation, operation: input_drain == :stop_no_prompt ? "stop_attempt" : "close_execution_scope")
          elsif input_drain == :lost_ack
            exercise_lost_input_drain_ack(client, native, state, original_generation)
          else
            exercise_actual_input_drain(client, native, state, original_generation)
          end
          return
        end
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
        assert_raises(AttemptErrors::EvidenceUnavailable) { @journal.verify_canonical_prefix!(commit: abandoned_commits.last) }
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
        inhibit_started = Queue.new
        original_inhibit = @authority.method(:request_original_input_inhibition!)
        @authority.define_singleton_method(:request_original_input_inhibition!) do |params, map, journal|
          inhibit_started << params.fetch("mutation_id")
          original_inhibit.call(params, map, journal)
        end
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        first_closer = Thread.new { @authority.close_execution_scope!(params: close_selectors.merge("mutation_id" => "seal-with-pending", "expected_generation" => current), peer: @peer, role: :launcher) }
        assert_equal "seal-with-pending", inhibit_started.pop
        observed = @authority.observe_execution_scope!(params: close_selectors, peer: @peer, role: :launcher)
        assert_equal "unverifiable", observed.fetch("state")
        assert_equal "drain_original_prompt_issuer", observed.fetch("required_action")
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        second_closer = Thread.new { @authority.close_execution_scope!(params: close_selectors.merge("mutation_id" => "close-with-pending", "expected_generation" => current), peer: @peer, role: :launcher) }
        assert_equal "close-with-pending", inhibit_started.pop
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
        assert_equal "running", first_closer.value.dig(:data, "state")
        assert_equal "running", second_closer.value.dig(:data, "state")
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
        first_closer&.join(3)
        second_closer&.join(3)
        launch.request_control_cancel
        server&.stop
        driver&.join(3)
        listener&.join(3)
        refute driver&.alive?
        refute listener&.alive?
      end

      def exercise_actual_input_drain(client, native, state, generation)
        selected = state.slice("assignment_id", "attempt_id")
        old = @journal.ref_value
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          client.call("prompt_attempt", selected.merge("expected_generation" => generation), mutation_id: "input-inhibit.#{'a' * 64}",
            upload_parts: ["reserved namespace prompt"], purpose: :prompt_text, timeout: 30)
        end
        assert_equal old, @journal.ref_value
        assert_nil native.prompt_calls
        native.drop_prompt_ack = true
        native.unconfirmed_drains = 1
        prompt = client.call("prompt_attempt", selected.merge("expected_generation" => generation), mutation_id: "unknown-input",
          upload_parts: ["controlled unknown prompt"], purpose: :prompt_text, timeout: 30)
        assert_equal "uncertain", prompt.data.fetch("outcome")
        assert_equal 1, native.prompt_calls.length
        generation = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        first = client.call("close_execution_scope", selected.merge("expected_generation" => generation), mutation_id: "first-unconfirmed-drain", timeout: 30)
        assert_equal "running", first.data.fetch("state")
        assert_equal 1, native.drain_calls.length
        refute @journal.read_events("assignment").any? { |event| event["type"] == "input_inhibited" }
        assert_equal "drain_original_prompt_issuer", client.call("observe_execution_scope", selected).data.fetch("required_action")
        limit = WIRE.deadline(10)
        until @authority.instance_variable_get(:@control_channels).values.any? { |channel| !channel.closed? }
          raise "Original driver did not reconnect after unconfirmed drain" unless Process.clock_gettime(Process::CLOCK_MONOTONIC) < limit
          sleep(0.01)
        end
        generation = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        second = client.call("close_execution_scope", selected.merge("expected_generation" => generation), mutation_id: "fresh-drain-after-worker-stop", timeout: 30)
        assert_equal "running", second.data.fetch("state")
        proof = @journal.read_events("assignment").find { |event| event["type"] == "input_inhibited" }
        refute_nil proof
        assert_equal 2, native.drain_calls.length
        assert_equal 1, native.prompt_calls.length
        later = client.call("prompt_status", selected.merge("mutation_id" => "unknown-input")).data
        assert_equal "uncertain", later.fetch("outcome")
        assert_nil later.fetch("outcome_event_id")
        # Replay uses its original generation, even after drain observations.
        original_generation = @journal.prompt_intent("unknown-input").dig("payload", "binding", "expected_generation")
        assert_equal prompt.data, client.call("prompt_attempt", selected.merge("expected_generation" => original_generation), mutation_id: "unknown-input",
          upload_parts: ["controlled unknown prompt"], purpose: :prompt_text, timeout: 30).data
        assert_equal first.data, client.call("close_execution_scope", selected.merge("expected_generation" => first.data.fetch("generation") - 1),
          mutation_id: "first-unconfirmed-drain", timeout: 30).data
        assert_equal 2, native.drain_calls.length
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        closed = client.call("close_execution_scope", selected.merge("expected_generation" => current), mutation_id: "proof-after-authentic-drain", timeout: 30)
        assert_equal "closed_no_writers", closed.data.fetch("state")
        assert_equal closed.data.fetch("proof_id"), client.call("observe_execution_scope", selected).data.fetch("proof_id")
        assert_equal 2, native.drain_calls.length
      end

      def exercise_no_prompt_input_drain(client, native, state, generation, operation: "close_execution_scope")
        selected = state.slice("assignment_id", "attempt_id")
        native.unconfirmed_drains = 1
        first = client.call(operation, selected.merge("expected_generation" => generation), mutation_id: "no-prompt-unconfirmed-drain", timeout: 30)
        assert_equal operation == "stop_attempt" ? "uncertain" : "running", first.data.fetch("state")
        assert_equal 1, native.drain_calls.length
        assert_nil native.prompt_calls
        events = @journal.read_events("assignment")
        refute events.any? { |event| %w[prompt_issued input_inhibited scope_closed_no_writers].include?(event["type"]) }
        assert_equal "drain_original_prompt_issuer", client.call("observe_execution_scope", selected).data.fetch("required_action")
        limit = WIRE.deadline(10)
        until @authority.instance_variable_get(:@control_channels).values.any? { |channel| !channel.closed? }
          raise "Original driver did not reconnect after unconfirmed no-prompt drain" unless Process.clock_gettime(Process::CLOCK_MONOTONIC) < limit
          sleep(0.01)
        end
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        second = client.call(operation, selected.merge("expected_generation" => current), mutation_id: "no-prompt-positive-drain", timeout: 30)
        assert_equal operation == "stop_attempt" ? "uncertain" : "running", second.data.fetch("state")
        events = @journal.read_events("assignment")
        assert_equal 1, events.count { |event| event["type"] == "input_inhibited" }
        refute events.any? { |event| event["type"] == "scope_closed_no_writers" }
        assert_equal 2, native.drain_calls.length
        assert_nil native.prompt_calls
        current = @journal.authority_generation(events.select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        proof = client.call(operation, selected.merge("expected_generation" => current), mutation_id: "no-prompt-proof-after-drain", timeout: 30)
        assert_equal operation == "stop_attempt" ? "uncertain" : "closed_no_writers", proof.data.fetch("state")
        assert proof.data.fetch("proof_id")
        assert_equal "running", @journal.canonical_attempt_state(@journal.read_events(state.fetch("assignment_id")).select { |event| event["attempt_id"] == state.fetch("attempt_id") }) if operation == "stop_attempt"
        replay = client.call(operation, selected.merge("expected_generation" => generation), mutation_id: "no-prompt-unconfirmed-drain", timeout: 30)
        assert_equal first.data, replay.data
        assert_equal 2, native.drain_calls.length
        assert_nil native.prompt_calls
        refute @journal.read_events("assignment").any? { |event| event["type"] == "prompt_issued" }
      end

      def exercise_lost_input_drain_ack(client, native, state, generation)
        selected = state.slice("assignment_id", "attempt_id")
        native.drop_prompt_ack = true
        prompt = client.call("prompt_attempt", selected.merge("expected_generation" => generation), mutation_id: "unknown-before-drain-loss",
          upload_parts: ["controlled unknown original input"], purpose: :prompt_text, timeout: 30)
        assert_equal "uncertain", prompt.data.fetch("outcome")
        entered, release = Queue.new, Queue.new
        native.before_drain_ack = -> { entered << true; release.pop }
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        first = Thread.new do
          client.call("close_execution_scope", selected.merge("expected_generation" => current), mutation_id: "seal-with-lost-drain-ack", timeout: 30)
        end
        entered.pop
        observed = client.call("observe_execution_scope", selected).data
        assert_equal "drain_original_prompt_issuer", observed.fetch("required_action")
        channel = @authority.instance_variable_get(:@control_channels).values.find { |candidate| !candidate.closed? }
        socket = channel.instance_variable_get(:@socket)
        socket.close unless socket.closed?
        first_reply = first.value
        assert_equal "running", first_reply.data.fetch("state")
        refute @journal.read_events("assignment").any? { |event| event["type"] == "input_inhibited" }
        @kernel.dead << 91
        release << true
        limit = WIRE.deadline(30)
        until @journal.read_events("assignment").any? { |event| event["type"] == "input_inhibited" }
          raise "Known original drain ACK was not recovered" unless Process.clock_gettime(Process::CLOCK_MONOTONIC) < limit
          sleep(0.01)
        end
        assert_equal 1, native.drain_calls.length
        assert_equal 1, native.prompt_calls.length
        assert_equal "uncertain", client.call("prompt_status", selected.merge("mutation_id" => "unknown-before-drain-loss")).data.fetch("outcome")
        original_generation = @journal.prompt_intent("unknown-before-drain-loss").dig("payload", "binding", "expected_generation")
        assert_equal prompt.data, client.call("prompt_attempt", selected.merge("expected_generation" => original_generation), mutation_id: "unknown-before-drain-loss",
          upload_parts: ["controlled unknown original input"], purpose: :prompt_text, timeout: 30).data
        current = @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") })
        proof = client.call("close_execution_scope", selected.merge("expected_generation" => current), mutation_id: "fresh-proof-after-drain-recovery", timeout: 30)
        assert_equal "closed_no_writers", proof.data.fetch("state")
        assert_equal 1, native.drain_calls.length
      ensure
        release << true if release
        first&.join(3)
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

      def test_definition_reader_selects_original_accepted_commit_after_replacement
        with_authority do
          selected = @journal.ref_value
          original = @authority.send(:definition, @journal, "assignment", commit: selected)
          changed = JSON.parse(registered_bytes).merge("task_id" => "different-task", "name" => "replacement definition")
          bytes = JSON.generate(changed)
          registration = call("register_assignment", {"definition_bytes" => bytes,
            "definition_digest" => Digest::SHA256.hexdigest(bytes), "expected_generation" => 1}, id: "replace-definition").fetch(:data)
          assert_equal "different-task", registration.fetch("task_id")
          assert_equal registration.fetch("definition_digest"), @authority.send(:definition, @journal, "assignment").fetch("definition_digest")
          assert_equal original, @authority.send(:definition, @journal, "assignment", commit: selected)
          assert_equal "09j", @authority.send(:definition, @journal, "assignment", commit: selected).fetch("task_id")
          assert_equal selected, @journal.verify_canonical_prefix!(commit: selected) && selected
        end
      end

      def test_inventory_reads_registration_and_reserved_attempt_at_selected_canonical_snapshot
        with_authority do
          selected_map = @map
          deployment = @authority.instance_variable_get(:@deployment)
          deployment.define_singleton_method(:verify!) { |_id, **| selected_map }
          query = lambda do |commit = nil, after = nil, limit = 25, role = :launcher|
            @authority.dispatch(request: {"version" => 1, "operation" => "assignment_inventory", "mutation_id" => nil,
              "project_id" => "project", "params" => {"mapping_id" => "mapping", "journal_commit" => commit,
                "after" => after, "limit" => limit}}, peer: @peer, role: role).fetch(:data)
          end
          old = @journal.ref_value
          registration = query.call
          assert_equal old, registration.fetch("journal_commit")
          assert_equal 1, registration.fetch("items").size
          row = registration.fetch("items").first
          assert_equal "09j", row.fetch("task_id")
          %w[attempt_id generation scope canonical_state original_binding_digest terminal_event_id reservation_release_event_id].each { |key| assert_nil row.fetch(key) }
          reserved = call("reserve_attempt", @reserve_params, id: "inventory-reserve").fetch(:data)
          current = @journal.ref_value
          attempt = query.call.fetch("items").first
          assert_equal reserved.fetch("attempt_id"), attempt.fetch("attempt_id")
          assert_equal "reserved", attempt.fetch("canonical_state")
          selected_chain = @journal.read_events("assignment", commit: current).select { |event| event["attempt_id"] == reserved.fetch("attempt_id") }
          assert_equal @journal.authority_generation(selected_chain), attempt.fetch("generation")
          assert_equal "010", attempt.fetch("scope")
          assert_equal registration, query.call(old)
          assert_equal current, @journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) { query.call(nil, nil, 25, :worker) }
          assert_raises(ArgumentError) { query.call(nil, nil, 1.0) }
          assert_raises(ArgumentError) { query.call(nil, {"assignment_id" => "assignment", "attempt_id" => reserved.fetch("attempt_id")}) }
          assert_raises(AttemptErrors::NotFound) { query.call(current, {"assignment_id" => "missing", "attempt_id" => nil}) }
          assert_empty query.call(current, {"assignment_id" => "assignment", "attempt_id" => reserved.fetch("attempt_id")}).fetch("items")
          assert_equal current, @journal.ref_value
        end
      end

      def test_inventory_refuses_raw_git_registration_corruption_and_wrong_accepted_tuple
        ["digest", "project_id", "assignment_id", "mapping_id"].each do |changed|
          with_authority do
            selected_map = @map
            @authority.instance_variable_get(:@deployment).define_singleton_method(:verify!) { |_id, **| selected_map }
            old = @journal.ref_value
            original = @journal.read_events("assignment", commit: old).find { |event| event.dig("payload", "operation") == "register_assignment" }
            event = JSON.parse(JSON.generate(original))
            if changed == "digest"
              event["digest"] = "f" * 64
            else
              event.fetch("payload").fetch("data")[changed] = "foreign"
              event["digest"] = Atoms::EvidenceDigest.digest(event.except("digest"))
              assert Models::EvidenceEvent.valid?(event), "wrong tuple must remain cryptographically valid to target association checks"
            end
            checkout = @journal.send(:checkout_dir)
            directory = File.join(checkout, "execution", "assignment", "events")
            File.unlink(File.join(directory, @journal.send(:event_filename, original)))
            File.write(File.join(directory, @journal.send(:event_filename, event)), JSON.pretty_generate(event))
            [ ["add", "-A", "execution/assignment"],
              ["-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "-m", "controlled invalid registration"] ].each do |arguments|
              _out, error, result = Open3.capture3("git", "-C", checkout, *arguments)
              assert result.success?, error
            end
            commit, error, result = Open3.capture3("git", "-C", checkout, "rev-parse", "HEAD")
            assert result.success?, error
            _out, error, result = Open3.capture3("git", "-C", @journal.repo_root, "update-ref", @journal.ref, commit.delete_suffix("\n"), old)
            assert result.success?, error
            request = {"version" => 1, "operation" => "assignment_inventory", "mutation_id" => nil, "project_id" => "project",
              "params" => {"mapping_id" => "mapping", "journal_commit" => nil, "after" => nil, "limit" => 25}}
            assert_raises(AttemptErrors::EvidenceUnavailable) { @authority.dispatch(request: request, peer: @peer, role: :launcher) }
            assert_equal commit.delete_suffix("\n"), @journal.ref_value
            _out, error, result = Open3.capture3("git", "-C", @journal.repo_root, "update-ref", @journal.ref, old, commit.delete_suffix("\n"))
            assert result.success?, error
          end
        end
      end

      def test_inventory_shortens_genuine_bounded_rows_and_keeps_continuation_at_original_commit
        with_authority do
          selected_map = @map
          @authority.instance_variable_get(:@deployment).define_singleton_method(:verify!) { |_id, **| selected_map }
          register = lambda do |id, index|
            bytes = JSON.generate(JSON.parse(registered_bytes).merge("session_id" => id, "task_id" => "t" * 128))
            @authority.dispatch(request: {"operation" => "register_assignment", "mutation_id" => "page-register-#{index}",
              "params" => {"mapping_id" => "mapping", "assignment_id" => id, "definition_bytes" => bytes,
                "definition_digest" => Digest::SHA256.hexdigest(bytes), "expected_generation" => 0}}, peer: @peer, role: :launcher)
          end
          ids = 35.times.map { |index| "large-#{'a' * 100}#{format('%03d', index)}" }
          ids.each_with_index { |id, index| register.call(id, index) }
          query = lambda do |commit = nil, after = nil|
            @authority.dispatch(request: {"operation" => "assignment_inventory", "mutation_id" => nil,
              "params" => {"mapping_id" => "mapping", "journal_commit" => commit, "after" => after, "limit" => 50}},
              peer: @peer, role: :launcher).fetch(:data)
          end
          selected = @journal.ref_value
          first = query.call
          expected = ["assignment"] + ids
          actual = first.fetch("items").map { |row| row.fetch("assignment_id") }
          assert_operator actual.size, :<, expected.size
          assert_equal expected.take(actual.size), actual
          assert_equal first.fetch("items").last.slice("assignment_id", "attempt_id"), first.fetch("next_after")
          frame = JSON.generate("status" => "ok", "data" => first, "transport" => {"replayed" => false}) + "\n"
          assert_operator frame.bytesize, :<=, 16_384
          last = query.call(first.fetch("journal_commit"), first.fetch("next_after"))
          assert_equal expected.drop(actual.size), last.fetch("items").map { |row| row.fetch("assignment_id") }
          assert_nil last.fetch("next_after")
          assert_equal selected, @journal.ref_value
          register.call("later-registration", 35)
          assert_equal last, query.call(first.fetch("journal_commit"), first.fetch("next_after"))
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
