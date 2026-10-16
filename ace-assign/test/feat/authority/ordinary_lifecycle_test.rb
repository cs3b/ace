# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/prepared_registration_fixture"
require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/router"
require "ace/assign/organisms/ordinary_driver"

module Ace
  module Assign
    class OrdinaryLifecycleTest < AceAssignTestCase
      # Wire, transfer, Git and replay are real. Installed/native permission
      # selection is tested in Lab; this is not a distinct-user receipt.
      class Admission
        attr_reader :service
        attr_accessor :role, :authorized, :native, :execution_head, :execution_binding, :supervisor_binding, :unknown_supervisor
        def initialize(service)
          @service, @role, @authorized, @native = service, :supervisor, true, true
          @peer = Authority::OrdinaryPeer.new
        end
        def verify_listener! = true
        def peer(socket, deadline:) = @peer.capture(socket, deadline: deadline)
        def authorize!(request:, peer:, deadline:)
          @peer.live!(peer, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity unless @authorized && request.fetch("project_id") == "atlas"
          @role
        end
        def identity!(peer:, pane:, deadline:)
          @peer.live!(peer, deadline: deadline)
          selected = @role == :supervisor ? @supervisor_binding : @execution_binding
          raise AttemptErrors::UnauthorizedIdentity unless @native && pane == selected.fetch("pane")
          Molecules::ExecutionIdentityResolver::Identity.new(actor: Etc.getpwuid(peer.fetch("uid")).name,
            role: @role == :supervisor ? "coordinator" : "worker", runtime: "herdr", adapter: "ordinary",
            process_pid: selected.dig("process_identity", "pid"), runtime_binding: selected)
        end
        def execution!(peer:, pane:, head:, deadline:)
          identity = identity!(peer: peer, pane: pane, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity unless @execution_head == head
          {identity: identity, checkout: {"head" => @execution_head, "cwd" => "/observed/worker"}}
        end
        def recorded_execution!(binding:, head:, deadline:)
          unless @native && binding == @execution_binding && @execution_head == head
            raise AttemptErrors::UnauthorizedIdentity, "recorded worker changed"
          end
          {runtime_binding: @execution_binding, checkout: {"head" => @execution_head, "cwd" => "/observed/worker"}}
        end
        def supervisor_ended!(binding:, deadline:)
          return {"liveness" => "unknown"} if @unknown_supervisor
          Ace::Runtime::Molecules::ProcessIdentity.new.generation_status(binding.fetch("process_identity"))
        end
      end

      # Same file request interface as Lab; actual canonical wire/server/CAS.
      class DriverTransport
        attr_accessor :lose_reply
        def initialize(client)
          @client = client
        end
        def request(input:, output: nil)
          request = Authority::RetainedInput.json(input)
          operation = request.fetch("operation")
          transfer = Authority::OrdinaryLifecycle::TRANSFER_OPERATIONS[operation]
          upload = request.fetch("parts").map { |entry| File.binread(File.join(File.dirname(input), entry.fetch("file"))) }
          response = @client.call(operation, request.fetch("params"), mutation_id: request.fetch("mutation_id"),
            upload_parts: upload.empty? ? nil : upload, download: !!output, purpose: transfer && transfer.fetch(:purpose))
          if @lose_reply == operation
            @lose_reply = nil
            raise AttemptErrors::EvidenceUnavailable, "injected loss after canonical acceptance"
          end
          result = {"status" => "ok", "data" => response.data, "transport" => {"replayed" => response.replayed}}
          if output
            Authority::RetainedInput.create_output(output)
            result["files"] = response.parts.each_with_index.map do |bytes, index|
              Authority::RetainedInput.write_file(output, "part-#{index}", bytes)
              {"file" => File.join(output, "part-#{index}")}
            end
          end
          result
        end
      end

      def test_public_driver_recovers_original_start_and_adopts_only_canonical_result
        with_fixture do
          with_owner do |client|
            register(client)
            root = File.join(@root, "driver")
            Authority::RetainedInput.create_output(root)
            path = File.join(root, "context.json")
            context = {"version" => 1, "project_id" => "atlas", "assignment_id" => "batch",
              "attempt_id" => "worker-attempt", "scope" => "010.01", "pane" => "w1:p1",
              "supervisor_pane" => "w1:p1", "cwd" => "/observed/worker", "head" => @admission.execution_head,
              "provider" => "pi:zai/glm-5.3-flash"}
            Authority::RetainedInput.write_file(root, "context.json", JSON.generate(context))
            transport = DriverTransport.new(client)
            driver = Organisms::OrdinaryDriver.new(path: path, project: "atlas", transport: transport)
            assert_equal "not_started", driver.status.fetch("state")
            bootstrap = driver.bootstrap(output: File.join(root, "accepted-context"))
            assert_equal @artifact.work.manifest_sha256, bootstrap.fetch("manifest_sha256")
            assert_equal 2, bootstrap.fetch("files").size
            assert_equal "Exact fixture context.\n", File.read(bootstrap.fetch("files").last.fetch("path"))
            assert_raises(ArgumentError) { Organisms::OrdinaryDriver.new(path: path, project: "foreign", transport: transport) }
            assert_raises(ArgumentError) { driver.start(pane: "w2:p3") }
            @admission.role = :worker
            transport.lose_reply = "start_attempt"
            assert_raises(AttemptErrors::EvidenceUnavailable) { driver.start(pane: "w1:p1") }
            started = driver.status
            assert_equal "running", started.fetch("state")
            assert driver.start(pane: "w1:p1").dig("transport", "replayed")
            assert_equal 1, @journal.read_events("batch").count { |entry| entry["type"] == "process_start" }
            queue = driver.queue
            assert_equal "010.01", queue.dig("current", "number")
            report = File.join(root, "report.md")
            File.write(report, result_artifact)
            driver.progress(operation: "queue_finish", pane: "w1:p1", generation: queue.fetch("generation"), report: report)
            assert driver.queue.fetch("complete")
            # A forged callback hint cannot finish an attempt lacking result.
            File.write(File.join(root, "result-hint.json"), '{"state":"succeeded"}')
            @admission.role = :supervisor
            assert_raises(AttemptErrors::EvidenceUnavailable) { driver.adopt(pane: "w1:p1") }
            @admission.role = :worker
            receipt = File.join(root, "receipt.json")
            File.write(receipt, JSON.generate(result_receipt))
            transport.lose_reply = "submit_result"
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              driver.submit(pane: "w1:p1", generation: 2, receipt: receipt, artifacts: [report])
            end
            assert_equal "running", driver.status.fetch("state"), "result submission is not terminal adoption"
            original = File.join(root, "requests", "result", "request.json")
            assert driver.replay(input: original).dig("transport", "replayed")
            assert_equal true, JSON.parse(File.read(File.join(root, "result-hint.json"))).fetch("hint_only")
            @admission.role = :supervisor
            transport.lose_reply = "finish"
            assert_raises(AttemptErrors::EvidenceUnavailable) { driver.adopt(pane: "w1:p1") }
            assert_equal "succeeded", driver.adopt(pane: "w1:p1").dig("data", "state")
            assert_equal 1, @journal.read_events("batch").count { |entry| entry["type"] == "result_submitted" }
          end
        end
      end

      def test_replacement_coordinator_adopts_exact_selection_only_after_old_process_ends
        old_pid = Process.spawn("sleep", "120")
        old_identity = Ace::Runtime::Molecules::ProcessIdentity.new.capture(old_pid)
        assert old_identity
        with_fixture do
          replacement = @admission.supervisor_binding
          original = replacement.merge("process_identity" => old_identity)
          @admission.supervisor_binding = original
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client)
            result = submit_result(client)
            finish_progress(client)
            attempt_before = @journal.read_events("batch").select { |event| event["attempt_id"] == "worker-attempt" }
            @admission.role = :supervisor
            @admission.supervisor_binding = replacement
            owner = client.call("supervisor_status", {"assignment_id" => "batch"}).data
            assert_equal original, owner.fetch("binding")
            params = {"assignment_id" => "batch", "pane" => "w1:p1", "expected_generation" => 1,
              "previous_binding_sha256" => owner.fetch("binding_sha256")}
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("adopt_supervisor", params, mutation_id: "replacement") }
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", completion_params(result, generation: 3), mutation_id: "finish") }
            Process.kill("TERM", old_pid)
            Process.wait(old_pid)
            old_pid = nil
            @admission.unknown_supervisor = true
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("adopt_supervisor", params, mutation_id: "replacement") }
            @admission.unknown_supervisor = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("adopt_supervisor", params.merge("previous_binding_sha256" => "0" * 64), mutation_id: "wrong-owner") }
            @admission.authorized = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("adopt_supervisor", params, mutation_id: "replacement") }
            @admission.authorized = true
            adopted = client.call("adopt_supervisor", params, mutation_id: "replacement")
            assert_equal 2, adopted.data.fetch("generation")
            assert_equal "ended", adopted.data.dig("ended_observation", "liveness")
            assert client.call("adopt_supervisor", params, mutation_id: "replacement").replayed
            assert_equal attempt_before, @journal.read_events("batch").select { |event| event["attempt_id"] == "worker-attempt" }
            assert_equal replacement, client.call("supervisor_status", {"assignment_id" => "batch"}).data.fetch("binding")
            @admission.supervisor_binding = original
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", completion_params(result, generation: 3), mutation_id: "stale-finish") }
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("adopt_supervisor", params, mutation_id: "replacement") }
            @admission.supervisor_binding = replacement
            accepted = client.call("finish", completion_params(result, generation: 3), mutation_id: "finish")
            assert_equal "succeeded", accepted.data.fetch("state")
            assert client.call("finish", completion_params(result, generation: 3), mutation_id: "finish").replayed
            assert_equal 1, @journal.read_events("batch").count { |event| event["type"] == "process_start" }
            assert_equal 1, @journal.read_events("batch").count { |event| event["type"] == "result_submitted" }
          end
        end
      ensure
        if old_pid
          Process.kill("KILL", old_pid) rescue Errno::ESRCH
          Process.wait(old_pid) rescue Errno::ECHILD
        end
      end

      def test_two_public_drivers_start_independently_and_reconcile_lost_result_without_redispatch
        pids = 2.times.map { Process.spawn("sleep", "120") }
        with_fixture do
          with_owner do |client|
            selections = pids.each_with_index.map do |pid, number|
              assignment, attempt, pane = "fresh-#{number}", "attempt-#{number}", "w1:p#{number + 2}"
              artifact = PreparedRegistrationFixture.build(root: @inputs, scope: "010.01", definition: {
                "session_id" => assignment, "project_id" => "atlas", "task_id" => "8xf.t.ei9.#{number}",
                "name" => "independent worker", "created_at" => "2026-10-16T00:00:00Z", "source_config" => "job.yaml"})
              client.call("register_assignment", artifact.header(expected_generation: 0).merge("pane" => "w1:p1"),
                mutation_id: "register-#{number}", upload_parts: [artifact.bundle], purpose: :candidate)
              directory = Authority::RetainedInput.create_output(File.join(@root, assignment))
              context = {"version" => 1, "project_id" => "atlas", "assignment_id" => assignment,
                "attempt_id" => attempt, "scope" => "010.01", "pane" => pane,
                "supervisor_pane" => "w1:p1", "cwd" => "/observed/worker", "head" => @admission.execution_head,
                "provider" => "pi:zai/glm-5.3-flash"}
              path = File.join(directory, "context.json")
              Authority::RetainedInput.write_file(directory, "context.json", JSON.generate(context))
              transport = DriverTransport.new(client)
              binding = @admission.execution_binding.merge("pane" => pane,
                "process_identity" => Ace::Runtime::Molecules::ProcessIdentity.new.capture(pid))
              [Organisms::OrdinaryDriver.new(path: path, project: "atlas", transport: transport), transport, binding]
            end
            @admission.role = :worker
            selections.each do |driver, _transport, binding|
              @admission.execution_binding = binding
              driver.start(pane: binding.fetch("pane"))
              assert_equal "running", driver.status.fetch("state")
            end
            selections.each_with_index do |(driver, transport, binding), number|
              @admission.role, @admission.execution_binding = :worker, binding
              directory = File.dirname(driver.path)
              report, receipt = File.join(directory, "report.md"), File.join(directory, "receipt.json")
              File.write(report, result_artifact)
              driver.progress(operation: "queue_finish", pane: binding.fetch("pane"), generation: 1, report: report)
              File.write(receipt, JSON.generate(result_receipt(changes: driver.context.slice("assignment_id", "attempt_id"))))
              transport.lose_reply = "submit_result" if number.zero?
              if number.zero?
                assert_raises(AttemptErrors::EvidenceUnavailable) { driver.submit(pane: binding.fetch("pane"), generation: 2, receipt: receipt, artifacts: [report]) }
              else
                driver.submit(pane: binding.fetch("pane"), generation: 2, receipt: receipt, artifacts: [report])
              end
              assert_equal "running", driver.status.fetch("state")
              @admission.role = :supervisor
              # Adoption reads the owner's accepted result even with no hint or
              # result acknowledgement at the first worker. No retry launch.
              assert_equal "succeeded", driver.adopt(pane: "w1:p1").dig("data", "state")
              assert_equal "succeeded", driver.adopt(pane: "w1:p1").dig("data", "state")
              events = @journal.read_events(driver.context.fetch("assignment_id"))
              assert_equal 1, events.count { |event| event["type"] == "process_start" }
              assert_equal 1, events.count { |event| event["type"] == "result_submitted" }
              assert_equal "running", selections.last.first.status.fetch("state") if number.zero?
            end
          end
        end
      ensure
        Array(pids).each do |pid|
          Process.kill("TERM", pid)
          Process.wait(pid)
        rescue Errno::ESRCH, Errno::ECHILD
          nil
        end
      end

      def test_registration_replay_survives_owner_restart_and_uses_only_canonical_bytes
        with_fixture do
          first = with_owner { |client| register(client) }
          commit = @journal.ref_value
          assert_equal "registered", first.data.fetch("phase")
          assert_equal @bundle, @journal.blob(first.data.fetch("prepared_bundle_ref"), commit: commit)
          assert_equal @artifact.definition_bytes, @journal.blob(first.data.fetch("definition_ref"), commit: commit)
          queue = Authority::OrdinaryQueue.new(work: @artifact.work, root: @inputs,
            bytes: @journal.blob(first.data.fetch("queue_ref"), commit: commit))
          assert_equal :pending, queue.status.steps.first.status
          # Remove the disposable projection. A new owner reads original
          # registration/reply from Git, not the old coordinator's memory.
          FileUtils.rm_rf(@journal.checkout_root)
          FileUtils.mkdir_p(@journal.checkout_root, mode: 0700)
          with_owner do |client|
            second = register(client)
            assert second.replayed
            assert_equal first.data, second.data
            assert_equal commit, @journal.ref_value
            status = client.call("registration_status", {"assignment_id" => "batch"})
            assert_equal first.data, status.data
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client, mutation: "replacement") }
            assert_equal commit, @journal.ref_value
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              register(client, params: @params.merge("pane" => "w1:p2"))
            end
          end
          assert_equal 1, @journal.read_events("batch").count { |event| event["type"] == "authority_mutation" }
        end
      end

      def test_no_native_start_wrong_role_and_revocation_cannot_admit_or_replay
        with_fixture do
          with_owner do |client|
            @admission.native = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client) }
            assert_empty @journal.read_events("batch")
            @admission.native = true
            @admission.role = :worker
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client) }
            assert_empty @journal.read_events("batch")
            @admission.role = :supervisor
            accepted = register(client)
            @admission.authorized = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client) }
            assert_equal accepted.data.fetch("journal_commit"), @journal.ref_value
          end
        end
      end

      def test_duplicate_waiting_for_journal_lock_rechecks_revocation_before_reply
        with_fixture do
          with_owner do |client|
            register(client)
            commit = @journal.ref_value
            lock = File.open(@journal.send(:lock_path), File::RDWR)
            lock.flock(File::LOCK_EX)
            entered = Queue.new
            original = @journal.method(:with_lock)
            @journal.define_singleton_method(:with_lock) do |**options, &block|
              entered << true
              original.call(**options, &block)
            end
            waiting = Thread.new do
              register(client)
            rescue AttemptErrors::EvidenceUnavailable => error
              error
            end
            Timeout.timeout(5) { entered.pop }
            @admission.authorized = false
            lock.flock(File::LOCK_UN)
            assert waiting.join(3), "revoked replay must finish"
            assert_kind_of AttemptErrors::EvidenceUnavailable, waiting.value
            assert_equal commit, @journal.ref_value
          ensure
            lock&.close
          end
        end
      end

      def test_lifecycle_and_journal_lock_contention_respect_original_deadline
        with_fixture do
          with_owner { |client| register(client) }
          exclusion = Molecules::LifecycleExclusion.new(root: File.join(@root, "exclusion"))
          key = exclusion.task_key("8xf.t.ei9.0")
          exclusion.with_exclusive(key) do
            before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            assert_raises(AttemptErrors::MaintenanceBusy) do
              exclusion.with_shared_multi([key], deadline: before + 0.05) { flunk "contended lock must not admit" }
            end
            assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - before, :<, 1
          end
          File.open(@journal.send(:lock_path), File::RDWR) do |lock|
            lock.flock(File::LOCK_EX)
            before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            assert_raises(AttemptErrors::Conflict) do
              @journal.mutate(assignment_id: "batch", attempt_id: "definition-batch", mutation_id: "blocked",
                operation: "register_assignment", parameters_digest: "a" * 64, expected_generation: 1,
                deadline: before + 0.05) { flunk "contended journal must not mutate" }
            end
            assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - before, :<, 1
          end
        end
      end

      def test_observed_start_and_active_queue_share_one_commit_and_restart_replays_original
        with_fixture do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            first = start(client)
            @accepted_start = first.data
            commit = @journal.ref_value
            assert_equal "running", first.data.fetch("state")
            attempt = @journal.derived_attempts("batch", commit: commit).fetch(0)
            assert_equal ["running", @admission.execution_head, commit], [attempt.state, attempt.binding.base_head, attempt.journal_commit]
            queue = Authority::OrdinaryQueue.new(work: @artifact.work, root: @inputs,
              bytes: @journal.blob(first.data.fetch("queue_ref"), commit: commit))
            assert_equal :active, queue.status.steps.first.status
            event = @journal.read_events("batch", commit: commit).find { |value| value["type"] == "process_start" }
            assert_equal @admission.execution_binding, event.dig("payload", "runtime_binding")
            assert_equal "/observed/worker", event.dig("payload", "checkout", "cwd")
            assert_raises(AttemptErrors::EvidenceUnavailable) { start(client, mutation: "second-request", attempt: "second-attempt") }
            assert_equal commit, @journal.ref_value
          end
          FileUtils.rm_rf(@journal.checkout_root)
          FileUtils.mkdir_p(@journal.checkout_root, mode: 0700)
          with_owner do |client|
            @admission.execution_head = "d" * 40
            repeated = start(client, head: @accepted_start.fetch("base_head"))
            assert repeated.replayed
            assert_equal @accepted_start, repeated.data
            assert_equal @accepted_start.fetch("journal_commit"), @journal.ref_value
            assert_equal 1, @journal.read_events("batch").count { |event| event["type"] == "process_start" }
          end
        end
      end

      def test_absent_start_wrong_head_wrong_role_and_replaced_native_owner_are_not_accepted
        with_fixture do
          with_owner do |client|
            register(client)
            commit = @journal.ref_value
            @admission.role = :worker
            @admission.native = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { start(client) }
            @admission.native = true
            assert_raises(AttemptErrors::EvidenceUnavailable) { start(client, head: "f" * 40) }
            @admission.role = :reviewer
            assert_raises(AttemptErrors::EvidenceUnavailable) { start(client) }
            assert_empty @journal.derived_attempts("batch")
            assert_equal commit, @journal.ref_value
            @admission.role = :worker
            accepted = start(client)
            @admission.execution_binding = @admission.execution_binding.merge("pane" => "replacement")
            assert_raises(AttemptErrors::EvidenceUnavailable) { start(client) }
            assert_equal accepted.data.fetch("journal_commit"), @journal.ref_value
            @admission.authorized = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { start(client) }
          end
        end
      end

      def test_native_owner_is_rechecked_after_journal_wait_for_fresh_start_and_replay
        with_fixture do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            [:fresh, :replay].each do |phase|
              @admission.native = true
              start(client) if phase == :replay
              commit = @journal.ref_value
              lock = File.open(@journal.send(:lock_path), File::RDWR)
              lock.flock(File::LOCK_EX)
              entered = Queue.new
              original = @journal.method(:with_lock)
              @journal.define_singleton_method(:with_lock) do |**options, &block|
                entered << true
                original.call(**options, &block)
              end
              waiting = Thread.new do
                start(client)
              rescue AttemptErrors::EvidenceUnavailable => error
                error
              end
              Timeout.timeout(5) { entered.pop }
              @admission.native = false
              lock.flock(File::LOCK_UN)
              assert waiting.join(3), "lost native owner must refuse after journal wait"
              assert_kind_of AttemptErrors::EvidenceUnavailable, waiting.value
              assert_equal commit, @journal.ref_value
            ensure
              lock&.close
              @journal.define_singleton_method(:with_lock, original) if original
            end
          end
        end
      end

      def test_prepared_and_progress_snapshots_recover_canonical_bytes_without_accepting_success
        with_fixture do
          with_owner do |client|
            register(client)
            before = @journal.ref_value
            prepared = client.call("assignment_snapshot", {"assignment_id" => "batch", "attempt_id" => nil, "kind" => "prepared_work"},
              download: true, purpose: :assignment_snapshot)
            assert_equal [@bundle], prepared.parts
            assert_nil prepared.data.fetch("attempt_id")
            assert_equal before, @journal.ref_value
            @admission.role = :worker
            started = start(client)
            @finish_params = {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
              "step" => nil, "expected_generation" => started.data.fetch("generation")}
            @finish_reply = client.call("queue_finish", @finish_params, mutation_id: "finished-step",
              upload_parts: ["Executed work; independent acceptance remains pending."], purpose: :artifacts)
            assert @finish_reply.data.fetch("queue_complete")
            assert_equal "running", @journal.derived_attempts("batch").fetch(0).state
            snapshot = client.call("assignment_snapshot", {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "kind" => "queue"},
              download: true, purpose: :assignment_snapshot)
            queue = Authority::OrdinaryQueue.new(work: @artifact.work, root: @inputs, bytes: snapshot.parts.fetch(0))
            assert_equal :done, queue.status.steps.first.status
            assert_equal "Executed work; independent acceptance remains pending.", queue.status.steps.first.report
            assert_equal 2, snapshot.data.fetch("generation")
          end
          FileUtils.rm_rf(@journal.checkout_root)
          FileUtils.mkdir_p(@journal.checkout_root, mode: 0700)
          with_owner do |client|
            replay = client.call("queue_finish", @finish_params, mutation_id: "finished-step",
              upload_parts: ["Executed work; independent acceptance remains pending."], purpose: :artifacts)
            assert replay.replayed
            assert_equal @finish_reply.data, replay.data
            assert_equal @finish_reply.data.fetch("journal_commit"), @journal.ref_value
          end
          assert_empty Dir.children(@scratch)
        end
      end

      def test_progress_cannot_cross_native_owner_generation_or_terminal_state
        with_fixture do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            started = start(client)
            params = {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
              "step" => nil, "expected_generation" => started.data.fetch("generation")}
            original_binding = @admission.execution_binding
            @admission.execution_binding = original_binding.merge("pane" => "foreign")
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              client.call("queue_finish", params, mutation_id: "progress", upload_parts: ["report"], purpose: :artifacts)
            end
            assert_equal started.data.fetch("journal_commit"), @journal.ref_value
            @admission.execution_binding = original_binding
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              client.call("queue_finish", params.merge("expected_generation" => 10), mutation_id: "progress",
                upload_parts: ["report"], purpose: :artifacts)
            end
            assert_equal started.data.fetch("journal_commit"), @journal.ref_value
            @journal.record(assignment_id: "batch", attempt_id: "worker-attempt", type: "transition",
              payload: {"from" => "running", "to" => "failed", "reason" => "fixture terminal acceptance"})
            commit = @journal.ref_value
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              client.call("queue_finish", params, mutation_id: "progress", upload_parts: ["report"], purpose: :artifacts)
            end
            assert_equal commit, @journal.ref_value
          end
        end
      end

      def test_result_import_and_restart_replay_preserve_original_bytes_without_accepting_success
        with_fixture do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client)
            @result_reply = submit_result(client)
            assert_equal "succeeded", @result_reply.data.fetch("verdict")
            assert_equal "running", @journal.derived_attempts("batch").fetch(0).state
            events = @journal.read_events("batch")
            assert_empty events.select { |event| event["type"] == "receipt_accepted" }
            submitted = events.find { |event| event["type"] == "result_submitted" }
            reference = submitted.dig("payload", "receipt", "artifacts").fetch(0)
            assert_equal result_artifact, @journal.blob(reference.fetch("path"))
            assert_equal Digest::SHA256.hexdigest(result_artifact), reference.fetch("sha256")
            assert_equal @admission.execution_binding, submitted.dig("payload", "binding", "runtime_binding")
            status = client.call("result_status", {"assignment_id" => "batch", "attempt_id" => "worker-attempt"})
            assert_equal @result_reply.data.except("journal_commit"), status.data.fetch("submitted_result")
            snapshot = client.call("result_snapshot", {"assignment_id" => "batch", "attempt_id" => "worker-attempt",
              "result_id" => @result_reply.data.fetch("result_id")}, download: true, purpose: :receipt_artifacts)
            assert_equal submitted.dig("payload", "receipt"), JSON.parse(snapshot.parts.first)
            assert_equal result_artifact, snapshot.parts.last
            assert_empty Dir.children(@scratch)
          end
          FileUtils.rm_rf(@journal.checkout_root)
          FileUtils.mkdir_p(@journal.checkout_root, mode: 0700)
          with_owner do |client|
            @admission.execution_head = "d" * 40
            replay = submit_result(client, head: @result_reply.data.fetch("head"))
            assert replay.replayed
            assert_equal @result_reply.data, replay.data
            assert_equal @result_reply.data.fetch("journal_commit"), @journal.ref_value
            @admission.native = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { submit_result(client, head: @result_reply.data.fetch("head")) }
          end
          assert_equal 1, @journal.read_events("batch").count { |event| event["type"] == "result_submitted" }
        end
      end

      def test_result_refuses_wrong_producer_head_failed_checks_and_self_approved_effects_without_partial_import
        with_fixture do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client)
            original = @journal.ref_value
            padding = "t" * (16_384 - JSON.generate(result_receipt).bytesize + "tests".bytesize)
            oversized_canonical = {"checks" => [{"name" => padding, "verdict" => "passed"}]}
            assert_equal 16_384, JSON.generate(result_receipt(changes: oversized_canonical)).bytesize
            [{"producer" => {"actor" => "foreign", "role" => "worker", "runtime" => "herdr"}},
              {"head" => "e" * 40}, {"checks" => [{"name" => "tests", "verdict" => "failed"}]},
              {"operation" => "publish"}, {"operation" => "review"}, oversized_canonical].each do |changes|
              assert_raises(AttemptErrors::EvidenceUnavailable) { submit_result(client, changes: changes) }
              assert_equal original, @journal.ref_value
            end
            original_binding = @admission.execution_binding
            @admission.execution_binding = original_binding.merge("pane" => "foreign")
            assert_raises(AttemptErrors::EvidenceUnavailable) { submit_result(client) }
            assert_equal original, @journal.ref_value
            assert_empty @journal.read_events("batch").select { |event| %w[result_submitted evidence_import].include?(event["type"]) }
            @admission.execution_binding = original_binding
            assert_equal "succeeded", submit_result(client).data.fetch("verdict")
          end
        end
      end

      def test_sibling_attempts_share_one_queue_without_cross_scope_completion_or_repeated_work
        scopes = %w[010.01.01 010.01.02 010.01.03]
        with_fixture(children: scopes) do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client, scope: scopes.first)
            start(client, scope: scopes.last, mutation: "integrator-start", attempt: "integrator")
            before = @journal.ref_value
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              start(client, scope: "010.01", mutation: "overlap", attempt: "overlap")
            end
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              start(client, scope: "010.99", mutation: "foreign", attempt: "foreign")
            end
            finish_params = {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
              "step" => scopes.last, "expected_generation" => 1}
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              client.call("queue_finish", finish_params, mutation_id: "cross-scope", upload_parts: ["foreign"], purpose: :artifacts)
            end
            assert_equal before, @journal.ref_value
            done = client.call("queue_finish", finish_params.merge("step" => scopes.first), mutation_id: "child-finish",
              upload_parts: ["Executed check."], purpose: :artifacts)
            assert done.data.fetch("queue_complete")
            snapshot = client.call("assignment_snapshot", {"assignment_id" => "batch", "attempt_id" => "integrator", "kind" => "queue"},
              download: true, purpose: :assignment_snapshot)
            queue = Authority::OrdinaryQueue.new(work: @artifact.work, root: @inputs, bytes: snapshot.parts.fetch(0))
            assert_equal :done, queue.status.find_by_number(scopes.first).status
            assert_equal :active, queue.status.find_by_number(scopes.last).status
            assert_equal :pending, queue.status.find_by_number(scopes[1]).status
            assert_equal 1, snapshot.data.fetch("generation"), "other scopes do not advance the integrator's generation"
            assert_equal scopes.last, snapshot.data.fetch("scope")
            @journal.record(assignment_id: "batch", attempt_id: "worker-attempt", type: "transition",
              payload: {"from" => "running", "to" => "succeeded", "reason" => "fixture independent acceptance"})
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              start(client, scope: scopes.first, mutation: "repeat", attempt: "repeat")
            end
            attempts = @journal.derived_attempts("batch").to_h { |attempt| [attempt.attempt_id, attempt] }
            assert_equal "running", attempts.fetch("integrator").state
            assert_equal "succeeded", attempts.fetch("worker-attempt").state
            assert_equal 2, attempts.size
          end
          with_owner do |client|
            snapshot = client.call("assignment_snapshot", {"assignment_id" => "batch", "attempt_id" => "integrator", "kind" => "queue"},
              download: true, purpose: :assignment_snapshot)
            queue = Authority::OrdinaryQueue.new(work: @artifact.work, root: @inputs, bytes: snapshot.parts.fetch(0))
            assert_equal :done, queue.status.find_by_number(scopes.first).status
            assert_equal :active, queue.status.find_by_number(scopes.last).status
          end
        end
      end

      def test_attempt_id_cannot_alias_another_registered_assignment
        with_fixture do
          other = PreparedRegistrationFixture.build(root: @inputs, scope: "010.01",
            definition: @artifact.work.definition.merge("session_id" => "other"))
          with_owner do |client|
            register(client)
            client.call("register_assignment", other.header(expected_generation: 0).merge("pane" => "w1:p1"),
              mutation_id: "register-other", upload_parts: [other.bundle], purpose: :candidate)
            @admission.role = :worker
            start(client)
            before = @journal.ref_value
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              start(client, attempt: "definition-future", mutation: "reserved-start")
            end
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              client.call("start_attempt", {"assignment_id" => "other", "attempt_id" => "worker-attempt",
                "expected_generation" => 0, "scope" => "010.01", "head" => @admission.execution_head,
                "pane" => "w1:p1"}, mutation_id: "other-start")
            end
            assert_equal before, @journal.ref_value
            assert_empty @journal.derived_attempts("other")
          end
        end
      end

      def test_supervisor_accepts_exact_child_result_and_restart_replay_does_not_close_its_sibling
        scopes = %w[010.01.01 010.01.02]
        with_fixture(children: scopes) do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client, scope: scopes.first)
            start(client, scope: scopes.last, mutation: "integrator-start", attempt: "integrator")
            result = submit_result(client, changes: {"scope" => scopes.first, "operation" => "test"})
            @finish_params = completion_params(result, generation: 3)
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", @finish_params, mutation_id: "finish") }
            finish_progress(client, step: scopes.first)
            @admission.role = :supervisor
            @finished = client.call("finish", @finish_params, mutation_id: "finish")
            assert_equal "succeeded", @finished.data.fetch("state")
            assert_equal scopes.first, @finished.data.fetch("scope")
            attempts = @journal.derived_attempts("batch").to_h { |attempt| [attempt.attempt_id, attempt] }
            assert_equal "succeeded", attempts.fetch("worker-attempt").state
            assert_equal "running", attempts.fetch("integrator").state
            assert_equal result.data.fetch("receipt_digest"), @journal.accepted_receipts("batch").first.fetch("digest")
          end
          with_owner do |client|
            # Re-delivery of the original accepted reply is independent of a
            # worker that has since exited. Current supervisor is still needed.
            @admission.execution_binding = @admission.execution_binding.merge("pane" => "worker-exited")
            replay = client.call("finish", @finish_params, mutation_id: "finish")
            assert replay.replayed
            assert_equal @finished.data, replay.data
            @admission.authorized = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", @finish_params, mutation_id: "finish") }
          end
          events = @journal.read_events("batch")
          assert_equal 1, events.count { |event| event["type"] == "receipt_accepted" }
          assert_equal "ordinary_result_accepted", events.find { |event| event["type"] == "transition" }.dig("payload", "reason")
        end
      end

      def test_completion_refuses_unfinished_scope_moved_head_wrong_result_and_dead_original_worker
        with_fixture do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client)
            result = submit_result(client)
            @admission.role = :supervisor
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              client.call("finish", completion_params(result, generation: 2), mutation_id: "finish")
            end
            @admission.role = :worker
            finish_progress(client)
            @admission.role = :supervisor
            params = completion_params(result, generation: 3)
            before = @journal.ref_value
            [{"result_id" => "foreign"}, {"receipt_digest" => "e" * 64}, {"head" => "e" * 40}].each do |changes|
              assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", params.merge(changes), mutation_id: "finish") }
            end
            original = @admission.execution_head
            @admission.execution_head = "e" * 40
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", params, mutation_id: "finish") }
            @admission.execution_head = original
            @admission.native = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", params, mutation_id: "finish") }
            assert_equal before, @journal.ref_value
            assert_equal "running", @journal.derived_attempts("batch").first.state
          end
        end
      end

      def test_unresolved_delivery_and_wrong_callback_cannot_be_hidden_by_successful_result
        with_fixture do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client)
            result = submit_result(client)
            finish_progress(client)
            payload = {"stage" => "intent", "operation" => "create", "head" => @admission.execution_head}
            @journal.record(assignment_id: "batch", attempt_id: "worker-attempt", type: "delivery", payload: payload)
            intent = @journal.read_events("batch").last
            @admission.role = :supervisor
            params = completion_params(result, generation: 3)
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", params, mutation_id: "finish") }
            callback = payload.merge("stage" => "result", "outcome" => "succeeded", "intent_digest" => intent.fetch("digest"), "intent_attempt_id" => "foreign")
            @journal.record(assignment_id: "batch", attempt_id: "worker-attempt", type: "delivery", payload: callback)
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("finish", params, mutation_id: "finish") }
            @journal.record(assignment_id: "batch", attempt_id: "worker-attempt", type: "delivery", payload: callback.merge("intent_attempt_id" => "worker-attempt"))
            assert_equal "succeeded", client.call("finish", params, mutation_id: "finish").data.fetch("state")
          end
        end
      end

      def test_failed_nested_step_can_finish_its_scope_without_marking_the_parent_successful
        with_fixture(children: ["010.01.01"]) do
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client)
            client.call("queue_start", {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
              "expected_generation" => 1, "step" => "010.01.01"}, mutation_id: "child-start")
            client.call("queue_fail", {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
              "expected_generation" => 2, "message" => "Executed check failed"}, mutation_id: "child-fail")
            result = submit_result(client, generation: 3, changes: {"verdict" => "failed", "checks" => [{"name" => "tests", "verdict" => "failed"}]})
            @admission.role = :supervisor
            accepted = client.call("finish", completion_params(result, generation: 4), mutation_id: "finish")
            assert_equal "failed", accepted.data.fetch("state")
            assert_equal "failed", @journal.derived_attempts("batch").first.state
            snapshot = client.call("assignment_snapshot", {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "kind" => "queue"},
              download: true, purpose: :assignment_snapshot)
            queue = Authority::OrdinaryQueue.new(work: @artifact.work, root: @inputs, bytes: snapshot.parts.first)
            refute queue.status.subtree_complete?("010.01")
            assert queue.status.subtree_failed?("010.01")
          end
        end
      end

      def test_finish_consumes_delivered_inbox_under_retained_owner_locks_through_cas
        with_fixture do
          inbox_root = File.join(@root, "inbox")
          FileUtils.mkdir_p(inbox_root, mode: 0700)
          @inbox = Ace::Herdr::Organisms::Inbox.new(executor: nil, deliveries_dir: inbox_root)
          @admission.execution_binding = @admission.execution_binding.merge("terminal_id" => "terminal", "agent" => "pi",
            "agent_session" => {"agent" => "pi", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"})
          target = @inbox.target_from_owner(@admission.execution_binding)
          reference = {"event_id" => "inbox-event", "attempt_id" => "worker-attempt", "payload_sha256" => Digest::SHA256.hexdigest("prompt")}
          binding = target.merge("payload_sha256" => reference.fetch("payload_sha256"), "agent_status" => "busy")
          metadata = {"attempt_id" => "worker-attempt", "claim_generation" => 1, "origin_target" => target,
            "binding" => binding, "wake" => {"status" => "none"},
            "receipt" => reference.merge("claim_generation" => 1, "binding" => binding)}
          record = Ace::Herdr::Models::DeliveryRecord.new(event_id: "inbox-event", session: "w1", pane: "w1:p1",
            answer: "prompt", answer_digest: reference.fetch("payload_sha256"), state: "delivered", inbox: metadata)
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          store.with_lock(inbox_root, record.event_id) { store.save(record, inbox_root) }
          with_owner do |client|
            register(client)
            @admission.role = :worker
            start(client)
            result = submit_result(client)
            finish_progress(client)
            @journal.record(assignment_id: "batch", attempt_id: "worker-attempt", type: "inbox_binding", payload: reference)
            @admission.role = :supervisor
            original = @journal.method(:mutate)
            locked = false
            @journal.define_singleton_method(:mutate) do |**options, &block|
              original.call(**options) do |*args|
                File.open(store.lock_path(inbox_root, "inbox-event"), File::RDWR) do |competing|
                  locked = !competing.flock(File::LOCK_EX | File::LOCK_NB)
                end
                block.call(*args)
              end
            end
            completed = client.call("finish", completion_params(result, generation: 3), mutation_id: "finish")
            assert_equal "succeeded", completed.data.fetch("state")
            assert_equal [reference.merge("claim_generation" => 1)], completed.data.fetch("inbox_deliveries")
            assert locked, "native Inbox receipt must stay held through canonical acceptance"
          end
        end
      end

      private

      def completion_params(result, generation:)
        result.data.slice("result_id", "receipt_digest", "head").merge("assignment_id" => "batch", "attempt_id" => "worker-attempt",
          "pane" => "w1:p1", "expected_generation" => generation)
      end

      def finish_progress(client, step: "010.01")
        client.call("queue_finish", {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
          "expected_generation" => 2, "step" => step}, mutation_id: "progress-result", upload_parts: [result_artifact], purpose: :artifacts)
      end

      def result_artifact = "Executed tests: all passed."

      def result_receipt(head: @admission.execution_head, changes: {})
        {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "project_id" => "atlas", "scope" => "010.01",
          "operation" => "check", "producer" => {"actor" => Etc.getpwuid.name, "role" => "worker", "runtime" => "herdr"},
          "head" => head, "verdict" => "succeeded", "checks" => [{"name" => "tests", "verdict" => "passed"}],
          "artifacts" => [{"path" => "caller-report.md", "sha256" => Digest::SHA256.hexdigest(result_artifact)}]}.merge(changes)
      end

      def submit_result(client, head: @admission.execution_head, changes: {}, generation: 1)
        bytes = JSON.generate(result_receipt(head: head, changes: changes))
        client.call("submit_result", {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
          "head" => head, "expected_generation" => generation, "receipt_sha256" => Digest::SHA256.hexdigest(bytes)},
          mutation_id: "worker-result", upload_parts: [bytes, result_artifact], purpose: :receipt_artifacts)
      end

      def register(client, mutation: "original-registration", params: @params)
        client.call("register_assignment", params, mutation_id: mutation, upload_parts: [@bundle], purpose: :candidate)
      end

      def start(client, mutation: "original-start", attempt: "worker-attempt", head: @admission.execution_head, scope: @artifact.work.manifest.fetch("scope"))
        client.call("start_attempt", {"assignment_id" => "batch", "attempt_id" => attempt,
          "expected_generation" => 0, "head" => head, "pane" => "w1:p1", "scope" => scope}, mutation_id: mutation)
      end

      def with_owner
        owner = Authority::OrdinaryLifecycle.new(project: "atlas", admission: @admission, journal: @journal,
          exclusion: Molecules::LifecycleExclusion.new(root: File.join(@root, "exclusion")), input_root: @inputs, inbox: @inbox)
        server = Authority::OrdinaryServer.new(admission: @admission, lifecycle: Authority::Router.new(handlers: [owner]))
        thread = Thread.new { server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        yield Authority::OrdinaryClient.new(project_id: "atlas", service: @service, scratch_root: @scratch, verify_selection: -> {})
      ensure
        server&.request_stop
        server&.stop
        assert thread.join(3), "ordinary owner must drain"
      end

      def with_fixture(children: [])
        @inbox = nil
        Dir.mktmpdir("ordinary-lifecycle-", Etc.getpwuid(Process.uid).dir) do |root|
          @root = root
          File.chmod(0o700, root)
          repository = File.join(root, "journal")
          @inputs = File.join(root, "inputs")
          @scratch = File.join(root, "client-scratch")
          FileUtils.mkdir_p([repository, @inputs, @scratch], mode: 0700)
          git(repository, "init", "-b", "main")
          git(repository, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "seed")
          @journal = Molecules::EvidenceJournal.new(repo_root: repository, checkout_root: File.join(root, "checkout"))
          @artifact = PreparedRegistrationFixture.build(root: @inputs, scope: "010.01", children: children, definition: {
            "session_id" => "batch", "project_id" => "atlas", "task_id" => "8xf.t.ei9.0",
            "name" => "verified delivery", "created_at" => "2026-10-16T00:00:00Z", "source_config" => "job.yaml"})
          @bundle = @artifact.bundle
          @params = @artifact.header(expected_generation: 0).merge("pane" => "w1:p1")
          @service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(root, "owner.sock"), "state_root" => root}
          @admission = Admission.new(@service)
          @admission.execution_head = git(repository, "rev-parse", "HEAD").strip
          @admission.execution_binding = {"runtime" => "herdr", "session" => "w1", "pane" => "w1:p1",
            "process_identity" => Ace::Runtime::Molecules::ProcessIdentity.new.capture(Process.pid)}
          @admission.supervisor_binding = @admission.execution_binding.dup
          yield
        end
      end

      def git(directory, *args)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
        raise error unless status.success?
        output
      end

    end
  end
end
