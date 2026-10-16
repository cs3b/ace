# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/prepared_registration_fixture"
require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/router"
require "ace/assign/authority/command_execution"

module Ace
  module Assign
    class OrdinaryReviewsTest < AceAssignTestCase
      # Actual Unix/Git/transfer/receipts; only installed native observation is
      # controlled. Two real OS generations are not an installed agent proof.
      class Admission
        attr_reader :service
        attr_accessor :selected, :bindings, :head, :revoked
        def initialize(service)
          @service, @selected, @bindings = service, "supervisor", {}
          @peer = Authority::OrdinaryPeer.new
        end
        def verify_listener! = true
        def peer(socket, deadline:) = @peer.capture(socket, deadline: deadline)
        def authorize!(request:, peer:, deadline:)
          @peer.live!(peer, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity if @revoked || request["project_id"] != "atlas"
          @selected == "supervisor" ? :supervisor : :worker
        end
        def identity!(peer:, pane:, deadline:)
          authorize!(request: {"project_id" => "atlas"}, peer: peer, deadline: deadline)
          binding = @bindings.fetch(@selected)
          raise AttemptErrors::UnauthorizedIdentity unless pane == binding.fetch("pane")
          Molecules::ExecutionIdentityResolver::Identity.new(actor: Etc.getpwuid(peer.fetch("uid")).name,
            role: @selected == "supervisor" ? "coordinator" : "worker", runtime: "herdr", adapter: "ordinary",
            process_pid: binding.dig("process_identity", "pid"), runtime_binding: binding)
        end
        def execution!(peer:, pane:, head:, deadline:)
          identity = identity!(peer: peer, pane: pane, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity unless head == @head
          {identity: identity, checkout: {"cwd" => "/observed/#{@selected}", "head" => head}}
        end
        def recorded_binding!(binding:, deadline:)
          raise AttemptErrors::UnauthorizedIdentity unless !@revoked && @bindings.values.include?(binding)
          binding
        end
        def recorded_execution!(binding:, head:, deadline:)
          raise AttemptErrors::UnauthorizedIdentity unless !@revoked && @bindings.values.include?(binding) && head == @head
          {runtime_binding: binding, checkout: {"cwd" => "/observed/reviewer", "head" => head}}
        end
      end

      # Root launcher/policy observation is controlled here; the command
      # state machine, imported candidate and exact-prefix proof are real.
      class CommandAdmission
        attr_accessor :definition, :enabled
        def initialize = @enabled = true
        def command_request!(**) = @definition
        def command_launcher!(peer:, **) = peer
        def command_claim!(**) = true
        def command_child!(child:, **) = child
        def command_test_evidence!(definition:, **)
          raise AttemptErrors::ReceiptRejected unless @enabled && definition == @definition
          true
        end
      end

      def test_merge_requires_canonical_successful_test_execution_and_rechecks_before_effect
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assigned = assign_review
          @admission.selected = "reviewer"
          accept_review(assigned)
          @admission.selected = "supervisor"
          params = selection.merge("test_execution_ids" => ["tests-1"])
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("merge_evidence", params) }
          execute_test_command
          projection = @client.call("merge_evidence", params).data
          assert_equal "tests-1", projection.fetch("test_evidence").first.fetch("reference")
          record = fixed_record(projection)
          coordinator = Organisms::AttemptCoordinator.new(repo_root: @journal.repo_root,
            journal: @journal, ordinary_merge_evidence: @owner)
          forged = Marshal.load(Marshal.dump(record))
          forged.fetch("request").fetch("review_evidence")["record_sha256"] = "f" * 64
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.admit_fixed_merge_request(forged) }
          assert_nil coordinator.fixed_merge_record("merge-1")
          accepted = coordinator.admit_fixed_merge_request(record)
          assert_equal accepted.fetch("reference"), coordinator.admit_fixed_merge_request(record).fetch("reference")
          @command_admission.enabled = false
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.admit_fixed_merge_request(record) }
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.begin_fixed_merge_effect("merge-1") }
          assert_equal "pending", coordinator.fixed_merge_record("merge-1").fetch("state")
          @command_admission.enabled = true
          coordinator.begin_fixed_merge_effect("merge-1")
          @command_admission.enabled = false
          effects = 0
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.with_fixed_merge_evidence(accepted) { effects += 1 } }
          assert_equal 0, effects
        end
      end

      def test_same_agent_session_or_native_process_cannot_be_relabelled_independent
        fixture do
          producer = @admission.bindings.fetch("producer")
          reviewer = @admission.bindings.fetch("reviewer")
          assert @owner.send(:ordinary_independent_agents!, producer, reviewer)
          assert_raises(AttemptErrors::ReceiptRejected) do
            @owner.send(:ordinary_independent_agents!, producer, reviewer.merge("process_identity" => producer.fetch("process_identity")))
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            session = producer.fetch("agent_session").merge("value" => producer.dig("agent_session", "value").upcase)
            @owner.send(:ordinary_independent_agents!, producer, reviewer.merge("agent_session" => session))
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @owner.send(:ordinary_independent_agents!, producer, reviewer.except("agent_session"))
          end
        end
      end

      def test_two_real_starts_same_account_accept_exact_review_and_restart_revalidates_bytes
        fixture do
          register_and_start
          candidate = submit_candidate
          assert_equal candidate, submit_candidate
          @admission.head = @base_head
          @admission.selected = "supervisor"
          assigned = assign_review
          assert_equal Etc.getpwuid.name, assigned.fetch("reviewer_actor")
          @admission.selected = "reviewer"
          exported = @client.call("export_candidate", selection.merge("pane" => "w1:p2", "review_id" => assigned.fetch("review_id")), download: true, purpose: :candidate)
          assert_equal candidate.fetch("sha256"), Digest::SHA256.hexdigest(exported.parts.fetch(0))
          @admission.head = @head
          accepted = accept_review(assigned)
          assert accepted.data.fetch("receipt_digest")
          assert accept_review(assigned).replayed
          prefix = @journal.ref_value
          events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
          proof = @owner.review_at!(events: events, commit: prefix, head: @head, generation: 1)
          assert_equal assigned.fetch("reviewer_origin"), proof.dig("review_binding", "reviewer_origin")
          assert_equal review_bytes, @journal.blob(proof.fetch("original_receipt_ref"), commit: prefix)
          assert_equal "running", @journal.derived_attempts("producer").first.state
          @admission.selected = "supervisor"
          @client.call("cancel_review", selection.merge("pane" => "w1:pS", "review_id" => assigned.fetch("review_id"), "expected_generation" => 4), mutation_id: "cancel")
          assert_raises(AttemptErrors::ReceiptRejected) do
            prefix = @journal.ref_value
            @owner.review_at!(events: @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }, commit: prefix, head: @head, generation: 1)
          end
          @admission.selected = "reviewer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned) }
        end
      end

      def test_self_review_missing_agent_session_wrong_attempt_and_wrong_caller_refuse
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assert_raises(AttemptErrors::EvidenceUnavailable) { assign_review(reviewer: "producer") }
          assert_raises(AttemptErrors::EvidenceUnavailable) { assign_review(reviewer: "missing") }
          assigned = assign_review
          @admission.selected = "producer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned, pane: "w1:p1") }
          @admission.selected = "reviewer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned, changes: {"head" => "f" * 40}) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned, changes: {"review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => "invented"}}}) }
          before = @journal.ref_value
          original_execution = @admission.method(:execution!)
          @admission.define_singleton_method(:execution!) do |**options|
            @bindings["reviewer"] = @bindings.fetch("reviewer").merge("agent_session" => {"agent" => "pi", "kind" => "id", "value" => SecureRandom.uuid})
            original_execution.call(**options)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned) }
          assert_equal before, @journal.ref_value
          assert_equal 3, @journal.authority_generation(@journal.read_events("producer").select { |event| event["attempt_id"] == "producer-run" })
        end
      end

      def test_missing_or_changed_canonical_report_refuses_and_new_candidate_revokes_old_review
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assigned = assign_review
          @admission.selected = "reviewer"
          accepted = accept_review(assigned).data
          path = accepted.fetch("review_receipt").fetch("artifacts").first.fetch("path")
          original = @journal.method(:blob)
          @journal.define_singleton_method(:blob) { |name, **options| name == path ? "corrupt" : original.call(name, **options) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("review_status", selection) }
          @journal.define_singleton_method(:blob, original)
          assert @client.call("review_status", selection).data.fetch("accepted")
          @admission.selected = "producer"
          submit_candidate(generation: 4, candidate_generation: 1, mutation: "candidate2")
          @admission.selected = "reviewer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned) }
        end
      end

      private

      def execute_test_command
        @command_admission.definition = {"purpose" => "test", "source" => {"head" => @head, "tree" => git(@journal.repo_root, "rev-parse", "HEAD^{tree}").strip},
          "argv" => ["bin/ace-test", "fast"], "executable_sha256" => "a" * 64,
          "executor" => {"uid" => 1002, "cwd" => "/immutable/candidate"}}
        launcher = {"pid" => 22, "uid" => 0, "started_at" => "launcher-birth", "host" => "fixture"}
        kernel = {"pid" => 33, "uid" => 1002, "started_at" => "child-birth", "host" => "fixture"}
        child = {"kernel_identity" => kernel, "root_witness" => kernel.merge("cwd" => "/immutable/candidate"), "witnessed_by" => launcher}
        {"command_admit" => {"selection" => {}}, "command_claim" => {"caller" => {}}, "command_bind" => {"child" => child},
          "command_complete" => {"result" => {"exit_status" => 0, "signal" => nil}}}.each do |operation, extra|
          @commands.dispatch(request: {"project_id" => "atlas", "operation" => operation, "mutation_id" => operation,
            "params" => {"execution_id" => "tests-1"}.merge(extra)}, peer: launcher, role: :worker,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
        end
      end
      def fixed_record(projection)
        document = {"schema" => "ace.lab.service.ordinary-merge-request/v1", "forge" => "forgejo",
          "pr_url" => "https://forge.invalid/atlas/code/pulls/1", "head_repository" => "atlas/code", "head_ref" => "refs/heads/worker",
          "candidate_head" => @head, "base_repository" => "atlas/code", "base_ref" => "refs/heads/main", "expected_base_head" => @head,
          "method" => "merge"}.merge(projection.slice("review_evidence", "test_evidence"))
        digest = Atoms::FixedMergeSchemas.canonical_request_digest(project: "atlas", assignment: "producer", attempt: "producer-run",
          queue_entry: "010.01", authorization: "decision-1", request_id: "merge-1", input: document)
        {"request_id" => "merge-1", "project_id" => "atlas", "assignment_id" => "producer", "attempt_id" => "producer-run",
          "queue_entry" => "010.01", "operation" => "merge", "authorization" => "decision-1", "input_digest" => digest,
          "request" => document, "principal" => "supervisor", "caller_uid" => Process.uid, "receiver_id" => "ordinary",
          "configuration_sha256" => "e" * 64, "execution_identity" => {"checkout_id" => "canonical", "worktree_id" => "main", "branch" => "main"}}
      end

      def selection
        {"assignment_id" => "producer", "attempt_id" => "producer-run", "head" => @head, "candidate_generation" => 1}
      end
      def submit_candidate(generation: 1, candidate_generation: 0, mutation: "candidate")
        @admission.selected = "producer"
        @client.call("submit_candidate", selection.merge("candidate_generation" => candidate_generation,
          "pane" => "w1:p1", "expected_generation" => generation), mutation_id: mutation,
          upload_parts: [@candidate], purpose: :candidate).data
      end
      def assign_review(reviewer: "reviewer")
        @client.call("assign_review", selection.merge("pane" => "w1:pS", "expected_generation" => 2,
          "reviewer_assignment_id" => reviewer, "reviewer_attempt_id" => "#{reviewer}-run"), mutation_id: "assign-#{reviewer}").data
      end
      def review_bytes(changes = {})
        JSON.generate({"assignment_id" => "producer", "attempt_id" => "producer-run", "project_id" => "atlas", "scope" => "010.01",
          "operation" => "review", "producer" => {"actor" => Etc.getpwuid.name, "role" => "worker", "runtime" => "herdr"},
          "head" => @head, "verdict" => "succeeded", "checks" => [{"name" => "review executed", "verdict" => "passed"}],
          "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => Etc.getpwuid.name}},
          "artifacts" => [{"path" => "report.md", "sha256" => Digest::SHA256.hexdigest("Independent review report.")}]}.merge(changes))
      end
      def accept_review(assigned, pane: "w1:p2", changes: {})
        bytes = review_bytes(changes)
        @client.call("accept_review", selection.merge("pane" => pane, "review_id" => assigned.fetch("review_id"),
          "expected_generation" => 3, "receipt_sha256" => Digest::SHA256.hexdigest(bytes)), mutation_id: "accept",
          upload_parts: [bytes, "Independent review report."], purpose: :receipt_artifacts)
      end
      def register_and_start
        %w[producer reviewer].each do |name|
          @admission.selected = "supervisor"
          work = PreparedRegistrationFixture.build(root: @inputs, scope: "010.01", definition: {
            "session_id" => name, "project_id" => "atlas", "task_id" => "8xf.t.ei9.0", "name" => name,
            "created_at" => "2026-10-16T00:00:00Z", "source_config" => "job.yaml"})
          @client.call("register_assignment", work.header(expected_generation: 0).merge("pane" => "w1:pS"),
            mutation_id: "register-#{name}", upload_parts: [work.bundle], purpose: :candidate)
          @admission.selected = name
          @admission.head = name == "reviewer" ? @base_head : @head
          @client.call("start_attempt", {"assignment_id" => name, "attempt_id" => "#{name}-run", "expected_generation" => 0,
            "head" => @admission.head, "pane" => @admission.bindings.fetch(name).fetch("pane"), "scope" => "010.01"}, mutation_id: "start-#{name}")
        end
        @admission.head = @head
      end
      def fixture
        Dir.mktmpdir("ordinary-review-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          repository, @inputs, scratch = %w[journal inputs scratch].map { |part| File.join(root, part) }
          FileUtils.mkdir_p([repository, @inputs, scratch], mode: 0700)
          git(repository, "init", "-b", "main")
          git(repository, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate")
          @base_head = git(repository, "rev-parse", "HEAD").strip
          git(repository, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate change")
          @head = git(repository, "rev-parse", "HEAD").strip
          git(repository, "bundle", "create", File.join(root, "candidate.bundle"), "refs/heads/main")
          @candidate = File.binread(File.join(root, "candidate.bundle"))
          @journal = Molecules::EvidenceJournal.new(repo_root: repository, checkout_root: File.join(root, "checkout"))
          service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(root, "owner.sock"), "state_root" => root}
          @admission = Admission.new(service)
          @admission.head = @head
          child = Process.spawn("/bin/sleep", "60")
          process = Ace::Runtime::Molecules::ProcessIdentity.new
          @admission.bindings = %w[producer reviewer supervisor].each_with_index.to_h do |name, index|
            [name, {"runtime" => "herdr", "session" => "w1", "pane" => ["w1:p1", "w1:p2", "w1:pS"][index],
              "agent" => "pi", "agent_session" => {"agent" => "pi", "kind" => "id", "value" => SecureRandom.uuid},
              "process_identity" => process.capture(index == 1 ? child : Process.pid)}]
          end
          @command_admission = CommandAdmission.new
          @commands = Authority::CommandExecution.new(project: "atlas", journal: @journal, admission: @command_admission)
          @owner = Authority::OrdinaryLifecycle.new(project: "atlas", admission: @admission, journal: @journal,
            exclusion: Molecules::LifecycleExclusion.new(root: File.join(root, "exclusion")), input_root: @inputs, command_evidence: @commands)
          server = Authority::OrdinaryServer.new(admission: @admission, lifecycle: Authority::Router.new(handlers: [@owner]))
          thread = Thread.new { server.serve }
          Timeout.timeout(3) { sleep 0.005 until File.socket?(service.fetch("socket_path")) }
          @client = Authority::OrdinaryClient.new(project_id: "atlas", service: service, scratch_root: scratch, verify_selection: -> {})
          yield
        ensure
          server&.request_stop
          server&.stop
          assert thread.join(3), "ordinary review server must drain" if thread
          Process.kill("TERM", child) if child
          Process.wait(child) if child
        end
      end
      def git(path, *arguments)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", path, *arguments)
        raise error unless status.success?
        output
      end
    end
  end
end
