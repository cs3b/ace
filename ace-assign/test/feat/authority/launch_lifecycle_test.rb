# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/launch_driver"

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
            "groups" => [pid == Process.pid ? 13002 : 13001], "started_at" => "linux:boot:#{pid}", "host" => "fixture",
            "parent_pid" => pid == 91 ? 90 : 1}
        end
        def live!(identity)
          raise Ace::Runtime::RuntimeUnavailableError, "dead" if dead.include?(identity["pid"])
          true
        end
        def pin(identity); live!(identity); handle = Handle.new(identity, false); @handles << handle; handle; end
        def exited?(handle, **); dead.include?(handle.identity.fetch("pid")); end
        def same?(left, right); left == right; end
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
            "worker_groups" => [13001], "bootstrap" => "/usr/libexec/ace-worker-gate", "bootstrap_sha256" => "a" * 64, "worker_cwd" => "/home/worker", "worker_actor" => "worker", "native" => {"server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001]}}
          deployment = Object.new
          mapping = @map
          deployment.define_singleton_method(:mapping) { |_id| mapping }
          deployment.define_singleton_method(:project) { |_id| {"assignment_root" => File.join(cache, "assignments")} }
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "checkout"))
          @authority = Authority::LaunchLifecycle.new(deployment: deployment, kernel: @kernel, journals: {"project" => @journal})
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
            "pane" => "w1:p2", "command" => ["/usr/libexec/ace-worker-gate", "mapping", @ticket], "cwd" => "/home/worker", "server_identity" => @map.dig("native", "server_identity"), "socket_identity" => [1, 2, 13001]}}
      end

      def params(state, child = binding)
        state.slice("attempt_id", "launch_ticket").merge("process_binding" => child, "expected_generation" => state.fetch("generation"))
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

      def test_positive_abort_allows_a_new_reservation_for_the_same_scope
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          assert_equal "failed", abort_child(state).fetch("phase")
          replacement = call("reserve_attempt", @reserve_params, id: "new-reserve").fetch(:data)
          refute_equal state.fetch("attempt_id"), replacement.fetch("attempt_id")
          assert_equal %w[failed reserved], @journal.derived_attempts("assignment").map(&:state).sort
        end
      end

      def test_definition_change_requires_all_scopes_terminal
        with_authority do
          state = call("reserve_attempt", @reserve_params, id: "reserve").fetch(:data)
          state = call("record_launch", params(state), id: "record").fetch(:data)
          abort_child(state)
          changed = JSON.parse(registered_bytes).merge("name" => "changed definition")
          bytes = JSON.generate(changed)
          registration = call("register_assignment", {"definition_bytes" => bytes,
            "definition_digest" => Digest::SHA256.hexdigest(bytes), "expected_generation" => 1}, id: "changed-register").fetch(:data)
          assert_equal 2, registration.fetch("definition_generation")
          call("reserve_attempt", @reserve_params.merge("scope" => "020", "expected_generation" => 2), id: "other-scope")
          newer_bytes = JSON.generate(changed.merge("name" => "must not change while another scope is reserved"))
          old_commit = @journal.ref_value
          assert_raises(AttemptErrors::Conflict) do
            call("register_assignment", {"definition_bytes" => newer_bytes,
              "definition_digest" => Digest::SHA256.hexdigest(newer_bytes), "expected_generation" => 2}, id: "blocked-register")
          end
          assert_equal old_commit, @journal.ref_value
        end
      end
    end
  end
end
