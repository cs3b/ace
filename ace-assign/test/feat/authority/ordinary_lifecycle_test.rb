# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/prepared_registration_fixture"
require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/router"

module Ace
  module Assign
    class OrdinaryLifecycleTest < AceAssignTestCase
      # Wire, transfer, Git and replay are real. Installed/native permission
      # selection is tested in Lab; this is not a distinct-user receipt.
      class Admission
        attr_reader :service
        attr_accessor :role, :authorized, :native, :execution_head, :execution_binding
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
          raise AttemptErrors::UnauthorizedIdentity unless @native && pane == "w1:p1"
          Molecules::ExecutionIdentityResolver::Identity.new(actor: Etc.getpwuid(peer.fetch("uid")).name,
            role: @role == :supervisor ? "coordinator" : "worker", runtime: "herdr", adapter: "ordinary",
            process_pid: @execution_binding.dig("process_identity", "pid"), runtime_binding: @execution_binding)
        end
        def execution!(peer:, pane:, head:, deadline:)
          identity = identity!(peer: peer, pane: pane, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity unless @execution_head == head
          {identity: identity, checkout: {"head" => @execution_head, "cwd" => "/observed/worker"}}
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
            prepared = client.call("assignment_snapshot", {"assignment_id" => "batch", "kind" => "prepared_work"},
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
            snapshot = client.call("assignment_snapshot", {"assignment_id" => "batch", "kind" => "queue"},
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

      private

      def result_artifact = "Executed tests: all passed."

      def result_receipt(head: @admission.execution_head, changes: {})
        {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "project_id" => "atlas", "scope" => "010.01",
          "operation" => "check", "producer" => {"actor" => Etc.getpwuid.name, "role" => "worker", "runtime" => "herdr"},
          "head" => head, "verdict" => "succeeded", "checks" => [{"name" => "tests", "verdict" => "passed"}],
          "artifacts" => [{"path" => "caller-report.md", "sha256" => Digest::SHA256.hexdigest(result_artifact)}]}.merge(changes)
      end

      def submit_result(client, head: @admission.execution_head, changes: {})
        bytes = JSON.generate(result_receipt(head: head, changes: changes))
        client.call("submit_result", {"assignment_id" => "batch", "attempt_id" => "worker-attempt", "pane" => "w1:p1",
          "head" => head, "expected_generation" => 1, "receipt_sha256" => Digest::SHA256.hexdigest(bytes)},
          mutation_id: "worker-result", upload_parts: [bytes, result_artifact], purpose: :receipt_artifacts)
      end

      def register(client, mutation: "original-registration", params: @params)
        client.call("register_assignment", params, mutation_id: mutation, upload_parts: [@bundle], purpose: :candidate)
      end

      def start(client, mutation: "original-start", attempt: "worker-attempt", head: @admission.execution_head)
        client.call("start_attempt", {"assignment_id" => "batch", "attempt_id" => attempt,
          "expected_generation" => 0, "head" => head, "pane" => "w1:p1"}, mutation_id: mutation)
      end

      def with_owner
        owner = Authority::OrdinaryLifecycle.new(project: "atlas", admission: @admission, journal: @journal,
          exclusion: Molecules::LifecycleExclusion.new(root: File.join(@root, "exclusion")), input_root: @inputs)
        server = Authority::OrdinaryServer.new(admission: @admission, lifecycle: Authority::Router.new(handlers: [owner]))
        thread = Thread.new { server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        yield Authority::OrdinaryClient.new(project_id: "atlas", service: @service, scratch_root: @scratch, verify_selection: -> {})
      ensure
        server&.request_stop
        server&.stop
        assert thread.join(3), "ordinary owner must drain"
      end

      def with_fixture
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
          @artifact = PreparedRegistrationFixture.build(root: @inputs, scope: "010.01", definition: {
            "session_id" => "batch", "project_id" => "atlas", "task_id" => "8xf.t.ei9.0",
            "name" => "verified delivery", "created_at" => "2026-10-16T00:00:00Z", "source_config" => "job.yaml"})
          @bundle = @artifact.bundle
          @params = @artifact.header(expected_generation: 0).merge("pane" => "w1:p1")
          @service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(root, "owner.sock"), "state_root" => root}
          @admission = Admission.new(@service)
          @admission.execution_head = git(repository, "rev-parse", "HEAD").strip
          @admission.execution_binding = {"runtime" => "herdr", "session" => "w1", "pane" => "w1:p1",
            "process_identity" => Ace::Runtime::Molecules::ProcessIdentity.new.capture(Process.pid)}
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
