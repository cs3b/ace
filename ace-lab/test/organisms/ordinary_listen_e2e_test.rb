# frozen_string_literal: true

require_relative "../test_helper"
require "digest"
require "open3"
require "tmpdir"
require "ace/assign/atoms/fixed_merge_schemas"

module Ace
  module Lab
    # The executable acceptance loop (spec 8x3.t.xz9.4 execution clauses):
    # consumer-side request over the REAL OrdinarySocket client → the
    # receiver listener authenticates, admits through the canonical Assign
    # coordinator, executes a REAL fast-forward merge on a sandbox
    # repository, settles the exact terminal receipt into the fixture Assign
    # journal, read-only status resolves it, and the next request advances —
    # entirely without host chat. Real distinct-account installation stays
    # fixture-gated/host-owned (gad.b/gad.2).
    class OrdinaryListenEndToEndTest < Minitest::Test
      def setup
        @dir = Dir.mktmpdir("ordinary-e2e")
        @repo = File.join(@dir, "repo")
        FileUtils.mkdir_p(@repo)
        git("init", "-b", "main")
        git("config", "user.name", "test")
        git("config", "user.email", "test@example.com")
        File.write(File.join(@repo, "base.txt"), "base\n")
        git("add", "base.txt")
        git("commit", "-m", "base")
        @base = git("rev-parse", "HEAD")
        @head_a = branch_commit("feat/a", "a.txt")
        git("checkout", "feat/a")
        @head_b = branch_commit("feat/b", "b.txt")   # descendant of A
        git("checkout", "-b", "feat/c", "main")
        @head_c = branch_commit("feat/c", "c.txt")   # sibling: non-ff after A
        git("checkout", "main")

        cache = File.join(@dir, "cache")
        @coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: cache,
          repo_root: @repo, journal: Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo,
            checkout_root: File.join(@dir, "journal")),
          lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(
            root: File.join(@dir, "exclusion")
          ))
        assignment = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache).create(
          name: "ordinary-e2e", source_config: "job.yaml", task_id: "8x3.t.xz9",
          project_id: "atlas"
        )
        @attempt = @coordinator.start(assignment_id: assignment.id, step: "010", project_id: "atlas")
        @assignment_id = assignment.id
        @attempt_id = @attempt.attempt_id

        @policy_document = {
          "operations" => {},
          "authorizations" => {
            "decision-a" => decision(@head_a, "refs/heads/feat/a", @base, "request-a"),
            "decision-b" => decision(@head_b, "refs/heads/feat/b", @head_a, "request-b"),
            "decision-c" => decision(@head_c, "refs/heads/feat/c", @head_b, "request-c")
          },
          "ordinary" => {
            "projects" => {
              "atlas" => {"receiver_id" => "ordinary-receiver",
                          "socket_path" => File.join(@dir, "ordinary.sock"),
                          "receiver_uid" => Process.uid, "principal" => principal,
                          "admission" => "enabled"}
            }
          }
        }
        @config = {
          "project" => "atlas", "receiver_id" => "ordinary-receiver",
          "socket_path" => File.join(@dir, "ordinary.sock"),
          "receiver_uid" => Process.uid, "principal" => principal,
          "principal_uid" => Process.uid, "repo_path" => @repo,
          "policy_path" => policy_path,
          "execution_identity" => {"checkout_id" => "checkout-atlas",
                                   "worktree_id" => "wt-canonical", "branch" => "main"}
        }
        File.write(policy_path, YAML.safe_dump(@policy_document))
        File.write(config_path, YAML.safe_dump(@config))
      end

      def teardown
        @listener&.stop
        FileUtils.rm_rf(@dir)
      end

      def test_request_executes_real_ff_merge_settles_receipt_and_next_request_advances
        start_listener!
        producer = new_producer

        # 1. Request candidate A: consumer-side request over the real client,
        #    receiver executes the real merge, receipt lands in the journal.
        git("checkout", "feat/a")
        ack = producer.request(**request_args("request-a", "decision-a", "feat/a",
          @head_a, @base))
        assert_equal "ok", ack.fetch("status"), ack
        reference = ack.fetch("data").fetch("reference")
        digest = ack.fetch("data").fetch("input_digest")
        status = wait_for_terminal(producer, "request-a", reference, digest)
        assert_equal "succeeded", status.fetch("state")
        receipt = status.fetch("receipt")
        assert_equal "merged", receipt.dig("effect", "outcome")
        assert_equal @head_a, receipt.dig("remote_observation", "resulting_target_head")
        assert_equal @head_a, receipt.dig("remote_observation", "merge_commit")
        assert_equal @head_a, git("rev-parse", "refs/heads/main")

        # 2. The next request advances: candidate B (descendant of the new
        #    main) fast-forwards main from A to B.
        git("checkout", "feat/b")
        ack = producer.request(**request_args("request-b", "decision-b", "feat/b",
          @head_b, @head_a))
        assert_equal "ok", ack.fetch("status"), ack
        status = wait_for_terminal(producer, "request-b", ack.fetch("data").fetch("reference"),
          ack.fetch("data").fetch("input_digest"))
        assert_equal "succeeded", status.fetch("state")
        assert_equal @head_b, git("rev-parse", "refs/heads/main")

        # 3. Non-fast-forwardable candidate C (forked from base, main now at
        #    B): the moved-target/needs-rebase refusal family — never a
        #    silent merge-commit fallback. The request binds the CURRENT
        #    main as expected base, so the failure is specifically the
        #    fast-forward precondition.
        git("checkout", "feat/c")
        refusal = producer.request(**request_args("request-c", "decision-c", "feat/c",
          @head_c, @head_b))
        assert_equal "error", refusal.fetch("status")
        assert_equal "ordinary_merge_target_changed", refusal.dig("error", "code")
        assert_nil @coordinator.fixed_merge_record("request-c")
        assert_equal @head_b, git("rev-parse", "refs/heads/main")
      end

      def test_mutual_peer_identity_is_enforced_fail_closed
        listener = Molecules::OrdinaryListener.new(socket_path: @config.fetch("socket_path"),
          peer_uid: Process.uid + 424_242, handler: ->(_submission) { flunk "must not dispatch" })
        peer, local = UNIXSocket.pair
        nil
        begin
          listener.serve_connection(local)
        rescue Molecules::OrdinaryListener::OrdinaryListenerError
          nil
        end
        envelope = read_frame(peer)
        assert_equal "error", envelope.fetch("status")
        assert_equal "ordinary_merge_unauthenticated", envelope.dig("error", "code")
      ensure
        peer&.close unless peer&.closed?
        local&.close unless local&.closed?
      end

      def test_framing_violations_fail_closed
        start_listener!
        path = @config.fetch("socket_path")
        # Malformed JSON in a well-framed document → closed refusal envelope.
        socket = UNIXSocket.new(path)
        socket.write("#{Molecules::OrdinarySocket::HANDSHAKE} 8\n{not json")
        envelope = read_frame(socket)
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
        socket.close
        # Invalid handshake header → connection closed without dispatch.
        socket = UNIXSocket.new(path)
        socket.write("http/1.1 GET /\n")
        assert_nil read_frame(socket)
        socket.close
        # Oversize length header → connection closed.
        socket = UNIXSocket.new(path)
        socket.write("#{Molecules::OrdinarySocket::HANDSHAKE} 999999\n")
        assert_nil read_frame(socket)
        socket.close
        records = @coordinator.fixed_merge_records
        assert_empty records
      end

      private

      def start_listener!
        policy_loader = ->(path) { YAML.safe_load_file(path, permitted_classes: [Date, Time], aliases: true) }
        @forge = SandboxForge.new(repo_path: @repo, prs: {
          1 => {"head_ref" => "refs/heads/feat/a", "base_ref" => "refs/heads/main"},
          2 => {"head_ref" => "refs/heads/feat/b", "base_ref" => "refs/heads/main"},
          3 => {"head_ref" => "refs/heads/feat/c", "base_ref" => "refs/heads/main"}
        })
        @receiver = Organisms::OrdinaryMergeReceiver.new(
          config: Molecules::OrdinaryReceiverConfig.new(@config),
          coordinator: @coordinator,
          policy_document: YAML.safe_load_file(policy_path, permitted_classes: [Date, Time]),
          resolver: Molecules::OrdinaryAdmissionResolver.new(
            YAML.safe_load_file(policy_path, permitted_classes: [Date, Time], aliases: true),
            path: policy_path, loader: policy_loader
          ),
          forge_config: forge_config,
          forge_factory: ->(_document) { @forge }
        )
        @listener = Molecules::OrdinaryListener.new(socket_path: @config.fetch("socket_path"),
          peer_uid: Process.uid, handler: @receiver)
        @thread = Thread.new { @listener.serve }
        deadline = Time.now.utc + 5
        sleep 0.01 until File.exist?(@config.fetch("socket_path")) || Time.now.utc > deadline
        raise "listener did not bind" unless File.exist?(@config.fetch("socket_path"))
      end

      # The host-installed forge merge configuration this test deployment
      # provisions (matching the request fixtures' pr_url identities).
      def forge_config
        @forge_config ||= Molecules::ForgeMergeConfig.new({
          "base_url" => "https://forge.example.com", "owner" => "acme", "repo" => "widget",
          "token" => "test-scoped-token", "merge_timeout_seconds" => 30,
          "escalation_owner" => "host-integrator",
          "review_attachment" => {"enabled" => true}
        })
      end

      def wait_for_terminal(producer, request, reference, digest)
        deadline = Time.now.utc + 10
        loop do
          status = producer.status(format: "json", mode: "ordinary-merge",
            reference: reference, request: request, project: "atlas",
            assignment: @assignment_id, attempt: @attempt_id, queue_entry: "010",
            input_digest: digest)
          raise "status failed: #{status}" unless status.fetch("status") == "ok"
          return status.fetch("data") if %w[succeeded failed].include?(status.dig("data", "state"))
          raise "status did not settle in time: #{status.dig("data", "state")}" if Time.now.utc > deadline
          sleep 0.02
        end
      end

      def new_producer
        Organisms::OrdinaryMergeRequest.new(
          topology: Organisms::TopologyService.from_config(
            authorized_for_local(topology_config, ["atlas"])
          ),
          policy: Molecules::ServicePolicy.new(@policy_document),
          coordinator: @coordinator, repo_root: @repo
        )
      end

      def request_args(request_id, authorization, branch, candidate, expected_base)
        path = File.join(@dir, "#{request_id}.json")
        File.write(path, JSON.generate(
          request_document(candidate, "refs/heads/#{branch}", expected_base, request_id)
        ))
        {project: "atlas", assignment: @assignment_id, attempt: @attempt_id,
         queue_entry: "010", operation: "merge", input: path, authorization: authorization,
         request_id: request_id}
      end

      AUTHORIZATIONS = {"request-a" => "decision-a", "request-b" => "decision-b",
                        "request-c" => "decision-c"}.freeze
      PR_INDEXES = {"request-a" => 1, "request-b" => 2, "request-c" => 3}.freeze

      def pr_url(request_id)
        "https://forge.example.com/acme/widget/pulls/#{PR_INDEXES.fetch(request_id)}"
      end

      def decision(candidate, head_ref, expected_base, request_id)
        {
          "operation" => "merge", "project_id" => "atlas",
          "assignment_id" => @assignment_id, "attempt_id" => @attempt_id,
          "queue_entry" => "010",
          "input_digest" => Ace::Assign::Atoms::FixedMergeSchemas.canonical_request_digest(
            project: "atlas", assignment: @assignment_id, attempt: @attempt_id,
            queue_entry: "010", authorization: AUTHORIZATIONS.fetch(request_id),
            request_id: request_id,
            input: request_document(candidate, head_ref, expected_base, request_id)
          ),
          "forge" => "forgejo",
          "pr_url" => pr_url(request_id),
          "head_repository" => "acme/widget", "head_ref" => head_ref,
          "candidate_head" => candidate, "base_repository" => "acme/widget",
          "base_ref" => "refs/heads/main", "expected_base_head" => expected_base,
          "expires_at" => (Time.now.utc + 3600).iso8601
        }
      end

      def request_document(candidate, head_ref, expected_base, request_id)
        {
          "schema" => "ace.lab.service.ordinary-merge-request/v1",
          "forge" => "forgejo",
          "pr_url" => pr_url(request_id),
          "head_repository" => "acme/widget",
          "head_ref" => head_ref,
          "candidate_head" => candidate,
          "base_repository" => "acme/widget",
          "base_ref" => "refs/heads/main",
          "expected_base_head" => expected_base,
          "method" => "merge",
          "review_evidence" => {
            "schema" => "ace.review.acceptance-reference/v1",
            "reference" => "review-#{request_id}", "reviewer" => "independent-reviewer",
            "verdict" => "approved", "reviewed_head" => candidate,
            "recorded_at" => "2026-10-12T10:00:00Z", "record_sha256" => "c" * 64
          },
          "test_evidence" => [{
            "schema" => "ace.test.execution-reference/v1",
            "reference" => "test-#{request_id}", "candidate_head" => candidate,
            "command" => "bin/ace-test ace-lab fast", "result" => "passed",
            "recorded_at" => "2026-10-12T10:30:00Z", "receipt_sha256" => "d" * 64
          }]
        }
      end

      def read_frame(socket)
        header = +""
        while !header.end_with?("\n") && header.bytesize <= 128
          byte = socket.readpartial(1)
          header << byte
        end
        match = /\A#{Regexp.escape(Molecules::OrdinarySocket::HANDSHAKE)} (\d{1,5})\n\z/o.match(header)
        return nil unless match
        JSON.parse(socket.readpartial(Integer(match[1]) + 1).strip)
      rescue EOFError, Errno::ECONNRESET
        nil
      end

      def branch_commit(branch, file)
        git("checkout", "-b", branch) unless branch_exists?(branch)
        File.write(File.join(@repo, file), "#{file}\n")
        git("add", file)
        git("commit", "-m", file)
        git("rev-parse", "HEAD")
      end

      def branch_exists?(branch)
        git("rev-parse", "--verify", branch)
        true
      rescue
        false
      end

      def principal
        @principal ||= Ace::Lab::Molecules::CallerAuthorizer.local_identity.first
      end

      # In-process double standing in for the Forgejo merge adapter at the
      # receiver boundary — the forge HTTP layer itself is NEVER mocked: the
      # adapter tests run against the real lab forge. This double simulates
      # the forge side inside the sandbox repository (including the
      # fast-forward-only semantics and the real readback documents), so the
      # executable acceptance loop stays hermetic.
      class SandboxForge
        Result = Molecules::ForgejoMergeAdapter::Result

        def initialize(repo_path:, prs:)
          @repo_path = repo_path
          @prs = prs
        end

        def pull_request(owner:, repo:, index:)
          spec = @prs[index]
          return nil unless spec
          base = git("rev-parse", spec.fetch("base_ref"))
          merged = spec[:merged] == true
          {"merged" => merged,
           "merge_commit_sha" => merged ? base : nil,
           "head" => {"sha" => git("rev-parse", spec.fetch("head_ref"))},
           "base" => {"sha" => base}}
        end

        # Fast-forward-only semantics, forge side: the base ref moves to the
        # head commit only when the head is a descendant of the base.
        def merge_pull_request!(owner:, repo:, index:)
          spec = @prs[index]
          unless spec
            return Result.new(outcome: :refused, status: 409,
              reason: "HTTP 409: pull request is absent")
          end
          if spec[:merged]
            return Result.new(outcome: :refused, status: 405,
              reason: "HTTP 405: pull request is already merged")
          end
          current = git("rev-parse", spec.fetch("base_ref"))
          head = git("rev-parse", spec.fetch("head_ref"))
          unless system("git", "merge-base", "--is-ancestor", current, head,
            chdir: @repo_path)
            return Result.new(outcome: :refused, status: 406,
              reason: "HTTP 406: fast-forward-only merge is not possible")
          end
          git("update-ref", spec.fetch("base_ref"), head, current)
          spec[:merged] = true
          Result.new(outcome: :invoked, status: 200, reason: nil)
        end

        def create_comment(owner:, repo:, index:, body:)
          Result.new(outcome: :invoked, status: 201, reason: nil)
        end

        private

        def git(*argv)
          out, stderr, status = Open3.capture3("git", *argv, chdir: @repo_path)
          raise "git #{argv.first} failed: #{stderr}" unless status.success?
          out.strip
        end
      end

      def policy_path
        File.join(@dir, "authorization.yml")
      end

      def config_path
        File.join(@dir, "receiver.yml")
      end

      def git(*argv)
        out, stderr, status = Open3.capture3("git", *argv, chdir: @repo)
        raise "git #{argv.first} failed: #{stderr}" unless status.success?
        out.strip
      end
    end
  end
end
