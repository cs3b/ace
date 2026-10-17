# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../../ace-assign/test/support/ordinary_native_observation"
require_relative "../../../ace-assign/test/support/prepared_registration_fixture"
require "ace/lab/organisms/ordinary_campaign_runner"
require "securerandom"
require "open3"
require "timeout"

module Ace
  module Lab
    # Driver-vs-real-authority integration receipt (review follow-up): the
    # OrdinaryCampaignRunner drives the REAL ordinary owner — real socket
    # server, real journal CAS, real transfer codec — from campaign begin
    # through submit_review_context. Only the model execution is a
    # schema-enforcing engine fake; no request/response shape is faked.
    class OrdinaryCampaignRunnerIntegrationTest < Minitest::Test
      A = Ace::Assign::Authority

      class SchemaEngine
        BINDING_FIELDS = %w[base campaign_id contract_identity head round_id scope scope_identity subject].freeze

        def initialize(result)
          @result = result
        end

        def execute_prepared_campaign(candidate:, subject:, session_dir:, campaign_binding:, execution_boundary:)
          unless campaign_binding.is_a?(Hash) && campaign_binding.keys.sort == BINDING_FIELDS &&
              campaign_binding.fetch("head") == candidate.fetch("head") &&
              campaign_binding.fetch("scope_identity").is_a?(Hash) &&
              campaign_binding.fetch("scope_identity").key?("preset") &&
              !campaign_binding.key?("session_binding")
            raise ArgumentError, "Prepared campaign binding differs"
          end
          execution_boundary.call(binding: campaign_binding, model: "role:review-default") { :dispatched }
          @result
        rescue ArgumentError, KeyError, TypeError => error
          {success: false, error: "Prepared campaign review unavailable: #{error.message}"}
        end
      end

      def setup
        @dir = File.realpath(Dir.mktmpdir("runner-int"))
        @repo, @inputs, @scratch = %w[journal inputs scratch].map { |p| File.join(@dir, p) }
        FileUtils.mkdir_p([@repo, @inputs, @scratch], mode: 0o700)
        git(@repo, "init", "-b", "main")
        git(@repo, "-c", "user.name=t", "-c", "user.email=t@x", "commit", "--allow-empty", "-m", "base")
        @base_head = git(@repo, "rev-parse", "HEAD").strip
        File.write(File.join(@repo, "context.txt"), "candidate context\n")
        git(@repo, "add", "context.txt")
        git(@repo, "-c", "user.name=t", "-c", "user.email=t@x", "commit", "-m", "change")
        @head = git(@repo, "rev-parse", "HEAD").strip
        git(@repo, "bundle", "create", File.join(@dir, "candidate.bundle"), "refs/heads/main")
        @candidate_bytes = File.binread(File.join(@dir, "candidate.bundle"))
        @journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo, checkout_root: File.join(@dir, "checkout"))
        service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(@dir, "owner.sock"), "state_root" => @dir}
        @admission = Ace::Assign::OrdinaryNativeObservation.new(service)
        @admission.head = @head
        child = Process.spawn("/bin/sleep", "90")
        process = Ace::Runtime::Molecules::ProcessIdentity.new
        @admission.bindings = %w[producer reviewer supervisor].each_with_index.to_h do |name, index|
          [name, {"runtime" => "herdr", "session" => "w1", "pane" => ["w1:p1", "w1:p2", "w1:pS"][index],
            "agent" => "pi", "agent_session" => {"agent" => "pi", "kind" => "id", "value" => SecureRandom.uuid},
            "process_identity" => process.capture(index == 1 ? child : Process.pid)}]
        end
        @child = child
        @campaign_root = File.join(@dir, "campaign-repository")
        @campaign_store = File.join(@dir, "campaign-store")
        FileUtils.mkdir_p([@campaign_root, @campaign_store], mode: 0o700)
        @campaign_policy = Struct.new(:enabled) do
          def verify_unchanged! = true
          def with(_reference)
            value = yield({"delivery" => {"revision" => "v1", "minimum_rounds" => 3, "clean_rounds" => 2,
              "required_scopes" => ["full"], "required_checks" => ["tests"]}}, self)
            verify_unchanged!
            value
          end
        end.new(true)
        @owner = A::OrdinaryLifecycle.new(project: "atlas", admission: @admission, journal: @journal,
          exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(root: File.join(@dir, "exclusion")),
          input_root: @inputs, campaign: make_campaign_owner)
        server = A::OrdinaryServer.new(admission: @admission, lifecycle: A::Router.new(handlers: [@owner]))
        @server_thread = Thread.new { server.serve }
        Timeout.timeout(5) { sleep 0.005 until File.socket?(service.fetch("socket_path")) }
        @client = A::OrdinaryClient.new(project_id: "atlas", service: service,
          scratch_root: @scratch, verify_selection: -> {})
        register_and_start
      end

      def teardown
        Process.kill("TERM", @child) if @child && Process.kill(0, @child) rescue nil
        Process.wait(@child) if @child rescue nil
        FileUtils.remove_entry(@dir)
      end

      def adapter
        runner_client = Object.new
        client = @client
        runner_client.define_singleton_method(:request) do |input:|
          request = JSON.parse(File.read(input))
          parts = request.fetch("parts").map { |part| File.binread(File.expand_path(part.fetch("file"), File.dirname(input))) }
          purpose = {"campaign_begin" => nil, "submit_review_context" => :review_context}.fetch(request.fetch("operation"))
          reply = client.call(request.fetch("operation"), request.fetch("params"),
            mutation_id: request.fetch("mutation_id"), upload_parts: parts.empty? ? nil : parts,
            purpose: purpose.nil? && parts.empty? ? nil : (purpose || :review_context))
          {"data" => reply.data, "transport" => {"replayed" => reply.replayed}}
        end
        runner_client
      end

      def runner(engine_result = nil)
        engine = SchemaEngine.new(engine_result || {success: true, verdict: "approved", artifacts: [
          {path: "system-prompt.md", bytes: @prompt = "integration prompt " * 6000, sha256: Digest::SHA256.hexdigest("integration prompt " * 6000)}]})
        Organisms::OrdinaryCampaignRunner.new(project: "atlas", client: adapter, review: engine)
      end

      def test_runner_drives_real_owner_from_begin_to_review_context
        @admission.selected = "supervisor"
        call("campaign_start", {"assignment_id" => "producer", "attempt_id" => "producer-run", "pane" => "w1:pS",
          "expected_generation" => 2, "head" => @head, "candidate_generation" => 1,
          "contract" => "Preserve exact candidate and independently review it.", "profile" => "delivery"}, "campaign-start")
        call("campaign_pin", {"assignment_id" => "producer", "attempt_id" => "producer-run", "pane" => "w1:pS",
          "expected_generation" => 3, "head" => @head, "candidate_generation" => 1, "round_id" => "round-1",
          "scope_identity" => {"full" => {"preset" => "code-valid", "subjects" => ["diff:#{@base_head}..#{@head}"]}}}, "pin-1")
        assigned = call("assign_review", {"assignment_id" => "producer", "attempt_id" => "producer-run", "pane" => "w1:pS",
          "expected_generation" => 4, "head" => @head, "candidate_generation" => 1,
          "reviewer_assignment_id" => "reviewer", "reviewer_attempt_id" => "reviewer-run",
          "campaign" => {"round_id" => "round-1", "scope" => "full"}}, "campaign-review").data
        # Reviewer queue completion keeps its attempt finishable.
        @admission.selected = "reviewer"
        call("queue_finish", {"assignment_id" => "reviewer", "attempt_id" => "reviewer-run", "pane" => "w1:p2",
          "expected_generation" => 1, "step" => "010.01"}, "reviewer-progress", ["Collected."], :artifacts)
        result = runner.run(review_id: assigned.fetch("review_id"),
          producer: {"assignment_id" => "producer", "attempt_id" => "producer-run", "expected_generation" => 5},
          reviewer: {"assignment_id" => "reviewer", "attempt_id" => "reviewer-run", "expected_generation" => 2,
            "pane" => "w1:p2", "actor" => Etc.getpwuid.name, "role" => "worker", "runtime" => "herdr", "scope" => "010.01"},
          candidate: {"head" => @head, "candidate_generation" => 1},
          subject: "diff:#{@base_head}..#{@head}",
          campaign: {"base" => @base_head, "contract_identity" => "c" * 64,
            "scope_identity" => {"preset" => "code-valid", "subjects" => ["diff:#{@base_head}..#{@head}"]}},
          session_dir: tap_dir("session"), output: tap_dir("out"))
        assert result.fetch("dispatched"), result.inspect
        assert result.dig("result", "result_id")
        events = @journal.read_events("reviewer").select { |event| event["attempt_id"] == "reviewer-run" }
        assert events.one? { |event| event["type"] == "review_context_submitted" },
          "the real journal must retain the runner's review-context submission"
      end

      private

      def tap_dir(name)
        path = File.join(@dir, name)
        FileUtils.mkdir_p(path)
        path
      end

      def call(operation, params, mutation, parts = [], purpose = nil)
        @client.call(operation, params, mutation_id: mutation,
          upload_parts: parts.empty? ? nil : parts, purpose: purpose)
      end

      def register_and_start
        %w[producer reviewer].each do |name|
          @admission.selected = "supervisor"
          work = Ace::Assign::PreparedRegistrationFixture.build(root: @inputs, scope: "010.01", definition: {
            "session_id" => name, "project_id" => "atlas", "task_id" => "8xf.t.ei9.8", "name" => name,
            "created_at" => "2026-10-17T00:00:00Z", "source_config" => "job.yaml"})
          call("register_assignment", work.header(expected_generation: 0).merge("pane" => "w1:pS"),
            "register-#{name}", [work.bundle], :candidate)
          @admission.selected = name
          @admission.head = @base_head
          call("start_attempt", {"assignment_id" => name, "attempt_id" => "#{name}-run", "expected_generation" => 0,
            "head" => @admission.head, "pane" => @admission.bindings.fetch(name).fetch("pane"), "scope" => "010.01"}, "start-#{name}")
        end
        @admission.head = @head
        @admission.selected = "supervisor"
        submit_candidate
      end

      def submit_candidate
        @admission.selected = "producer"
        call("submit_candidate", {"assignment_id" => "producer", "attempt_id" => "producer-run",
          "expected_generation" => 1, "head" => @head, "candidate_generation" => 0, "pane" => "w1:p1"},
          "candidate", [@candidate_bytes], :candidate)
        @admission.selected = "supervisor"
      end

      def make_campaign_owner
        A::OrdinaryCampaignOwner.new(repository: @campaign_root, store_root: @campaign_store,
          policy: {"path" => "/etc/lab/campaign-policy.json", "bytes" => 100, "sha256" => "a" * 64},
          verify_selection: -> { true }, consumer: @campaign_policy)
      end

      def git(path, *arguments)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", path, *arguments)
        raise error unless status.success?
        output
      end
    end
  end
end
