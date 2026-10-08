# frozen_string_literal: true
require_relative "../../../ace-lab/test/support/protected_service_boundary_fixture"
require "ace/git/cli"
require "ace/git/forgejo"
require "ace/git/github"
require "stringio"
require "ace/assign/cli/commands/delivery"
require "ace/lab/cli/commands/service"
require "ace/hitl"
require_relative "../../../ace-hitl/test/support/lifecycle_fixtures"


module ProtectedMergeFlowFixture
  include ProtectedServiceBoundaryFixture
  URL = "https://forge.example.com/owner/repo"

  class ProposalBinding < LifecycleFixtures::TestBinding
    attr_accessor :proposal_journal
  end

  class ProposalPolicy < LifecycleFixtures::AllowTransportPolicy
    def proposal?(_peer, project:)
      project == "project"
    end
  end

  def with_original_delivery_worker
    yield
  end

  def delivery_authority_client
    start_service_server
  end

  def observe_pending_delivery!
  end

  def configure_result_owner_fixture
    super
    @policy = Ace::Lab::Molecules::ProtectedServicePolicy.new(document_loader: -> { @document },
      proposal_resolver: ->(project, reference, binding) {
        raise "wrong original proposal project" unless project == "project"
        @journal.proposal_authorize!(reference, binding)
      }) if @authorization_mode
    @project["launcher_uids"] = [@launcher.fetch("uid")]
    @project.merge!("journal_repository" => @journal.repo_root, "evidence_git_ref" => @journal.ref,
      "evidence_checkout_root" => @journal.checkout_root)
    uid = Process.uid
    @executor.merge!("uid" => uid, "gid" => Process.gid, "groups" => Process.groups.sort)
    @executor["groups"] = (@executor.fetch("groups") + [@map.fetch("worker_gid")]).uniq.sort if @public_lab
    @project["service_executor_uids"] = [uid]
    @project["peer_credentials"][uid.to_s] = @executor.slice("gid", "groups").merge("scratch_root" => @root)
    @project["service_receivers"]["executor"]["executor_uid"] = uid
    @document["principals"][uid.to_s] = {"projects" => ["project"]}
    @document["operations"] = {"merge" => {"project" => "project", "service_id" => "executor", "executor_uid" => uid,
      "argv" => [File.expand_path("../../../bin/ace-git", __dir__), "service", "merge"],
      "lease_expires_at" => (Time.now.utc + 3600).iso8601}}
  end

  def configure_merge_authorization(submission, input)
    return unless @authorization_mode

    if %i[missing out_of_scope].include?(@authorization_mode)
      original_authorize = @policy.method(:authorize!)
      expected_message = @authorization_mode == :missing ? "authorization reference is unresolved" : "authorization does not match the exact service request"
      exact = submission.slice("assignment_id", "attempt_id", "operation", "input_digest", "target", "authorization").merge(
        "project_id" => "project", "candidate_head" => @head, "caller_uid" => @worker.fetch("uid"))
      observations = @authorization_observations = []
      @policy.define_singleton_method(:authorize!) do |binding|
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        original_authorize.call(binding)
      rescue SecurityError => error
        observations << {"exact" => exact.all? { |key, value| binding[key] == value },
          "rejected" => error.message == expected_message,
          "seconds" => Process.clock_gettime(Process::CLOCK_MONOTONIC) - started}
        raise
      end
    end
    case @authorization_mode
    when :proposal
      record = create_merge_proposal(input)
      record = @proposal_store.proposal_acknowledge(record.fetch("request_id"), submitted_at: @proposal_now.iso8601)
      @proposal_now += 16 * 3600
      checkpoint = {"schema" => "ace.hitl.hermes.ingress-checkpoint/v1", "request" => record.fetch("request_id"),
        "revision" => record.fetch("revision_id"), "healthy" => true, "drained" => true,
        "checkpoint" => {"through" => record.fetch("deadline"), "sequence" => 0}}
      record = @proposal_store.proposal_reconcile(record.fetch("request_id"), checkpoint: checkpoint)
      assert_equal "approved-by-silence", record.fetch("state")
      submission["authorization"] = record.fetch("revision_id")
      @document.fetch("authorizations").clear
    when :standing
      @document["authorizations"]["standing-decision"] = @document.fetch("authorizations").delete("decision")
      submission["authorization"] = "standing-decision"
    when :missing
      @document.fetch("authorizations").clear
    when :out_of_scope
      @document.fetch("authorizations").fetch("decision")["target"] = input.fetch("target").merge("resource" => "#{URL}/pulls/26")
    end
  end

  def create_merge_proposal(input)
    unless @proposal_store
      identity = LifecycleFixtures::TestIdentity.new(username: "worker")
      worker = @worker
      identity.define_singleton_method(:uid) { worker.fetch("uid") }
      binding = ProposalBinding.new
      binding.proposal_journal = @journal
      @proposal_now = Time.now.utc - 16 * 3600
      @proposal_store = Ace::Hitl::Lifecycle::Store.new(root: File.join(@root, "proposal-store"), binding: binding,
        identity: identity, policy: ProposalPolicy.new, ownership: LifecycleFixtures::RecordingOwnership.new,
        proposal_clock: -> { @proposal_now })
    end
    @proposal_store.proposal_create(id: "proposal-#{'a' * 24}", assignment: "assignment", attempt: @attempt, project: "project",
      document: {"operation" => "merge", "target" => input.fetch("target"), "candidate_head" => @head,
        "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input), "context" => "Exact protected merge",
        "options" => ["yes", "no"], "recommendation" => "yes", "prerequisites" => ["accepted exact-head review"]})
  end

  def matrix_phase(stage)
    return unless name.match?(/test_public_(github_url|forgejo_default|forgejo_named)/)

    @matrix_started ||= Process.clock_gettime(Process::CLOCK_MONOTONIC)
    directory = File.expand_path("../../../.ace-local/task/8wr.t.qkb.1", __dir__)
    FileUtils.mkdir_p(directory)
    File.open(File.join(directory, "#{name}.phases.jsonl"), "a") do |file|
      file.puts(JSON.generate({"stage" => stage,
        "elapsed" => Process.clock_gettime(Process::CLOCK_MONOTONIC) - @matrix_started}))
      file.flush
    end
  end

  def merge_mutation?(provider, args)
    provider == "github" ? args[0, 3] == %w[gh pr merge] : args[1] == "POST"
  end

  def exercise_completion
    fixture do
      matrix_phase("issue-before")
      issue_original
      matrix_phase("issue-after")
      with_original_delivery_worker do
      submission, = prepared_submission(accept_review: !@missing_review)
      matrix_phase("submission-after")
      provider, selection = @merge_provider || "forgejo", @merge_selection || :named
      head_owner = @merge_fork ? "fork-owner" : "owner"
      resource = "#{URL}/#{provider == 'github' ? 'pull' : 'pulls'}/25"
      input = {"target" => {"resource" => resource, "artifact_digest" => nil}, "method" => "squash",
        "delivery" => {"forge_server" => selection == :named ? "selected" : nil, "forge_default" => selection == :default,
          "pr_provenance" => {"mode" => @merge_fork ? "fork" : "canonical", "head_repository_url" => "https://forge.example.com/#{head_owner}/repo", "head_ref" => "feature/x",
            "base_repository_url" => URL, "base_ref" => "main"}}}
      bytes = JSON.generate(input)
      digest = Ace::Lab::Atoms::ServiceInput.digest(input)
      target = Ace::Lab::Atoms::ServiceInput.target(input)
      submission.merge!("operation" => "merge", "input_digest" => digest, "target" => target)
      @document["authorizations"]["decision"].merge!("operation" => "merge", "input_digest" => digest, "target" => target)
      Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => [
        {"name" => "selected", "provider" => provider, "url" => URL, "default" => true}]))
      configure_merge_authorization(submission, input)
      submission["expected_generation"] = generation if @authorization_mode
      calls, merged = [], false
      runner = lambda do |args:, **|
        calls << args
        if provider == "github"
          assert_equal "forge.example.com/owner/repo", args.fetch(args.index("--repo") + 1)
        end
        payload = if merge_mutation?(provider, args)
          if provider == "github"
            assert_includes args, @head
            assert_includes args, "--squash"
          else
            assert_equal "https://forge.example.com/api/v1/repos/owner/repo/pulls/25/merge", args[2]
            assert_equal @head, args[3].fetch("head_commit_id")
            assert_equal "squash", args[3].fetch("Do")
          end
          merged = true
          nil
        elsif provider == "github"
          assert_equal %w[gh pr view 25], args[0, 4]
          {"number" => 25, "title" => "Ship", "body" => "", "state" => merged ? "MERGED" : "OPEN",
            "isDraft" => false, "author" => {"login" => "worker"}, "headRefName" => "feature/x", "baseRefName" => "main",
            "url" => resource, "headRefOid" => @head, "headRepositoryOwner" => {"login" => head_owner},
            "headRepository" => {"name" => "repo"}, "mergeCommit" => merged ? {"oid" => "d" * 40} : nil,
            "mergedAt" => merged ? "2026-10-07T12:00:00Z" : nil}
        elsif args[2].end_with?("/version")
          {"version" => "8.0.5"}
        else
          assert_equal "GET", args[1]
          assert_equal "https://forge.example.com/api/v1/repos/owner/repo/pulls/25", args[2]
          branch = ->(ref, head, owner) { {"ref" => ref, "sha" => head, "repo" => {"full_name" => "#{owner}/repo"}} }
          {"number" => 25, "title" => "Ship", "body" => "", "state" => merged ? "closed" : "open", "draft" => false,
            "merged" => merged, "merged_at" => merged ? "2026-10-07T12:00:00Z" : nil,
            "merge_commit_sha" => merged ? "d" * 40 : nil, "user" => {"login" => "worker"},
            "head" => branch.call("feature/x", @head, head_owner), "base" => branch.call("main", "e" * 40, "owner")}
        end
        {success: true, status: 200, stdout: payload ? JSON.generate(payload) : "", stderr: "", exit_code: 0}
      end
      producer = Ace::Git::Organisms::ServiceMerge.new(lifecycle_factory: ->(**selection) {
        Ace::Git::Organisms::PullRequestLifecycle.new(**selection, runner: runner) })
      effects = 0
      original_process = Ace::Herdr::Molecules::BoundedProcess.method(:call)
      read_metrics = Hash.new { |hash, key| hash[key] = {"calls" => 0, "seconds" => 0.0} }
      @read_metrics = read_metrics
      process = lambda do |argv, **options|
        unless argv == @document.fetch("operations").fetch("merge").fetch("argv")
          started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            next original_process.call(argv, **options)
          ensure
            metric = read_metrics[argv.first == "git" ? "git" : "other"]
            metric["calls"] += 1
            metric["seconds"] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
          end
        end
        assert_equal @document.fetch("operations").fetch("merge").fetch("argv"), argv
        effects += 1
        out, err = capture_io do
          Ace::Git::CLI::Commands::ServiceMerge.new(input: StringIO.new(options.fetch(:stdin_data)),
            producer: producer, root: options.fetch(:chdir)).call
        end
        status = Object.new
        status.define_singleton_method(:success?) { true }
        Struct.new(:stdout, :stderr, :status, :oversized).new(out, err, status, false)
      end
      client = delivery_authority_client
      if @public_lab
        executor_identity = @executor
        client.instance_variable_get(:@kernel).define_singleton_method(:capture) { |_| executor_identity }
      end
      phases = []
      completion_call = nil
      lost_reply_reached = false
      cas_fault_reached = false
      before_completion = nil
      journal = @journal
      interrupt_before_cas = @interrupt_before_cas
      measure_request = @measure_request_admission
      if measure_request
        [[journal, %i[service_request canonical_event_inventory! read_events event_commits!]],
          [@endcap.instance_variable_get(:@launch), %i[with_assignment definition]]].each do |owner, methods|
          methods.each do |method|
            original = owner.method(method)
            owner.define_singleton_method(method) do |*args, **keywords, &block|
              started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              begin
                original.call(*args, **keywords, &block)
              ensure
                metric = read_metrics[method.to_s]
                metric["calls"] += 1
                metric["seconds"] += Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
                selections = metric["commit_selections"] ||= Hash.new(0)
                selected = keywords[:commit]
                selections[selected.is_a?(String) && selected.match?(/\A[0-9a-f]{40}\z/) ? selected : "implicit-current"] += 1
              end
            end
          end
        end
      end
      phase_callback = method(:matrix_phase)
      traced = Object.new
      traced.define_singleton_method(:call) do |name, params, **options|
        phases << name
        phase_callback.call("rpc-#{name}-before")
        raise Timeout::Error, "measurement stops before export or provider" if measure_request && name != "request_service"
        if name == "complete_service" && interrupt_before_cas
          completion_call = [params, options]
          before_completion = journal.ref_value
          fault = ->(*) { cas_fault_reached = true; raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "controlled interruption before publication" }
          return journal.stub(:update_ref_cas, fault) { client.call(name, params, **options) }
        end
        response = client.call(name, params, **options)
        phase_callback.call("rpc-#{name}-after")
        if name == "complete_service"
          completion_call = [params, options]
          lost_reply_reached = true
          raise Timeout::Error, "controlled lost reply after actual canonical completion"
        end
        response
      rescue StandardError, SecurityError => error
        phases << [name, error.class.name, error.message]
        raise
      end
      result = nil
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, @document) do
        Ace::Herdr::Molecules::BoundedProcess.stub(:call, process) do
          if @public_lab
            result = public_lab_request(traced, submission, bytes)
          else
            result = receiver(traced, Ace::Lab::Molecules::ProtectedServiceHandler.new).execute(
              submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "merge-original")
          end
        end
      end
      if %i[missing out_of_scope].include?(@authorization_mode)
        assert_equal "blocked", result.fetch("state")
        assert_equal 0, effects
        assert_empty calls
        assert_empty @journal.proposals
        proposal = create_merge_proposal(input)
        assert_equal "awaiting-delivery", proposal.fetch("state")
        assert_equal 1, @journal.proposals.length
        binding = submission.slice("assignment_id", "attempt_id", "operation", "input_digest", "target").merge(
          "project_id" => "project", "candidate_head" => @head, "caller_uid" => @worker.fetch("uid"))
        assert_equal binding, proposal.slice(*Ace::Assign::Molecules::ProposalJournal::PROPOSAL_BINDING)
        assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
          @journal.proposal_authorize!(proposal.fetch("revision_id"), binding)
        end
        next
      end
      if @public_refusals
        assert_equal "refused", result.fetch("state")
        assert_equal 0, effects
        assert_equal 0, calls.count { |args| merge_mutation?(provider, args) }
        assert_equal 0, @journal.read_events("assignment").count { |event| event["type"] == "service_claim" || event["type"] == "delivery" }
        next
      end
      if measure_request
        directory = File.expand_path("../../../.ace-local/task/8wr.t.qkb.1", __dir__)
        FileUtils.mkdir_p(directory)
        path = File.join(directory, "request-admission-measurement.json")
        File.write(path, JSON.pretty_generate({"method" => "test_measure_original_request_service_admission_only",
          "phases" => phases, "processes" => read_metrics, "provider_effects" => effects}))
        assert_equal 0, effects
        assert_equal "request_service", phases.first
        assert_operator read_metrics.fetch("git").fetch("calls"), :>, 0
        next
      end
      if interrupt_before_cas
        assert cas_fault_reached, "CAS fault must be reached: #{[result, phases].inspect}"
        assert_equal before_completion, @journal.ref_value
        assert_equal "uncertain", @journal.service_request("service-request").fetch("state")
        events = @journal.read_events("assignment")
        assert_equal 0, events.count { |event| event["type"] == "delivery" }
        assert_equal 0, events.count { |event| event["type"] == "service_transition" && event.dig("payload", "state") == "succeeded" }
        assert_equal 0, events.count { |event| event["type"] == "evidence_import" && event.dig("payload", "kind") == "service" }
        completion = client.call("complete_service", completion_call.fetch(0), **completion_call.fetch(1))
        refute completion.replayed
        assert_equal "succeeded", completion.data.fetch("state")
      else
        assert lost_reply_reached, "fault must follow the actual complete_service reply: #{[result, phases].inspect}"
      end
      assert_equal "uncertain", result.fetch("state"), [result, phases].inspect
      assert_equal 1, effects
      assert_equal 1, calls.count { |args| merge_mutation?(provider, args) }
      record = @journal.service_request(submission.fetch("request_id"))
      assert_equal "succeeded", record.fetch("state")
      assert_equal @head, record.fetch("candidate_head")
      assert_equal digest, record.fetch("input_digest")
      assert_equal target, record.fetch("target")
      assert_equal "merge", record.fetch("operation")
      assert @journal.read_events("assignment").any? { |event| event["type"] == "service_transition" && event.dig("payload", "state") == "succeeded" }
      before_replay = @journal.ref_value
      replay = client.call("complete_service", completion_call.fetch(0), **completion_call.fetch(1))
      assert replay.replayed
      assert_equal "succeeded", replay.data.fetch("state")
      assert_equal before_replay, @journal.ref_value, "identical completion replay cannot append another import or result"
      assert_equal 1, effects
      assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "delivery" }
      next if interrupt_before_cas # Lost-reply case owns the full public worker composition.
      @kernel.peer_identity = @worker
      worker_kernel = Ace::Assign::EndcapResultOwnerFixture::Kernel.new
      original_worker = @worker
      worker_kernel.define_singleton_method(:capture) { |_| original_worker }
      worker_kernel.peer_identity = @service.slice("uid", "gid", "groups")
      worker_client = Ace::Assign::Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: worker_kernel)
      arguments = {assignment_id: "assignment", attempt_id: @attempt, operation: "merge", service_request_id: "service-request",
        candidate_head: @head, candidate_generation: submission.fetch("candidate_generation"), input_digest: digest, target: target}
      consumer = Ace::Assign::Organisms::ProtectedDeliveryCoordinator.new(client: worker_client, project_id: "project")
      if @identity_controls || @selector_controls || @forged_control
        reference = record.fetch("receipt").fetch("evidence").first.fetch("ref").delete_prefix("evidence/imports/")
        fetch = {"assignment_id" => "assignment", "attempt_id" => @attempt, "kind" => "service",
          "purpose_id" => "service-request", "artifact_id" => reference}
        before_controls = @journal.ref_value
        if @identity_controls
          [@reviewer, @worker.merge("started_at" => "linux:#{Ace::Assign::ExecutionScopeObservationFixtures::BOOT}:999")].each do |foreign|
            @kernel.peer_identity = foreign
            error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
              worker_client.call("evidence_fetch", fetch, download: true, purpose: :artifacts)
            end
            assert_includes error.message, "unauthorized", "identity refusal must be reached, not a timeout"
          end
          @kernel.peer_identity = @worker
        elsif @selector_controls
          [arguments.merge(candidate_head: "f" * 40), arguments.merge(candidate_generation: arguments.fetch(:candidate_generation) + 1)].each do |stale|
            error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { consumer.perform(**stale.merge(operation: "status")) }
            assert_includes error.message, "unauthorized"
          end
          assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { consumer.perform(**arguments.merge(operation: "status", input_digest: "f" * 64)) }
          assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) { consumer.perform(**arguments.merge(operation: "status", target: target.merge("resource" => "#{URL}/pulls/26"))) }
          File.binwrite(File.join(@root, "local-proof"), "not canonical evidence")
          error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
            worker_client.call("evidence_fetch", fetch.merge("artifact_id" => "local-proof"), download: true, purpose: :artifacts)
          end
          refute_includes error.message, "deadline", "local artifact must be refused by the canonical owner"
        else
          original = @journal.read_events("assignment").find { |event| event["type"] == "delivery" }
          @journal.record(assignment_id: "assignment", attempt_id: @attempt, type: "delivery",
            payload: original.fetch("payload").merge("outcome" => "failed"))
          before_controls = @journal.ref_value
          error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { consumer.perform(**arguments.merge(operation: "status")) }
          refute_includes error.message, "deadline", "later forged result must fail canonical verification"
        end
        assert_equal before_controls, @journal.ref_value, "negative observations do not write or repair evidence"
        assert_equal 1, effects
        assert_equal 1, calls.count { |args| merge_mutation?(provider, args) }
        next
      end
      consumed = consumer.perform(**arguments)
      assert_equal "succeeded", consumed.fetch("state")
      assert_equal "merge", consumed.fetch("delivery_event").fetch("payload").fetch("operation")
      assert_equal "succeeded", consumer.perform(**arguments.merge(operation: "status")).fetch("state")
      assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "delivery" }
      assert_equal 1, calls.count { |args| merge_mutation?(provider, args) }, "worker consumption never reruns merge"
      project = @project
      mapping, authority = @map, @service
      @deployment.define_singleton_method(:data) { {"projects" => {"project" => project}, "launch_mappings" => {"mapping" => mapping}, "authorities" => {"authority" => {"uid" => authority.fetch("uid")}}} }
      history = Object.new
      history.define_singleton_method(:descriptors) { [] }
      context = Ace::Assign::Authority::ProtectedAssignmentContext.new(deployment: @deployment, history: history,
        uid: @worker.fetch("uid"), kernel: worker_kernel, env: {})
      cli = Ace::Assign::CLI::Commands::Delivery.new(protected_context: context)
      before_consume = @journal.ref_value
      out, err = capture_io do
        cli.call(assignment: "assignment", attempt: @attempt, operation: "merge", mapping: "mapping", scope: "010",
          candidate_head: @head, candidate_generation: submission.fetch("candidate_generation"),
          input_digest: digest, target: target.fetch("resource"), service_request: "service-request")
      end
      if @public_lab
        command = Ace::Lab::CLI::Commands::Service::Status.new
        command.instance_variable_set(:@protected_service, Ace::Lab::Organisms::ProtectedServiceRequest.new(context: context))
        out, err = capture_io do
          registered_lab_call("service status", command, ["--request", "service-request", "--project", "project", "--assignment", "assignment",
            "--attempt", @attempt, "--mapping", "mapping", "--scope", "010", "--candidate-head", @head,
            "--candidate-generation", submission.fetch("candidate_generation").to_s, "--input-digest", digest, "--target", target.fetch("resource")])
        end
        assert_equal "ok", JSON.parse(out).fetch("status")
        assert_equal "succeeded", JSON.parse(out).dig("data", "state")
        out = JSON.generate(JSON.parse(out).fetch("data"))
      end
      assert_empty err
      assert_equal "succeeded", JSON.parse(out).fetch("state")
      assert_equal before_consume, @journal.ref_value, "public receipt consumption is read-only"
      if @authorization_mode
        proposals = @journal.proposals
        assert_equal @authorization_mode == :proposal ? 1 : 0, proposals.length
        if @authorization_mode == :proposal
          assert_equal submission.fetch("authorization"), proposals.first.fetch("revision_id")
          assert_equal "approved-by-silence", proposals.first.fetch("state")
        end
      end
      end
    end
  end

  def registered_lab_call(name, command, arguments)
    original, = Ace::Lab::CLI.resolve(name.split)
    Ace::Lab::CLI.register(name, command)
    assert_equal 0, Ace::Lab::CLI.start(name.split + arguments)
  ensure
    Ace::Lab::CLI.register(name, original) if original
  end

  def exercise_registered_request_refusals(command, original, worker, controls)
    replacement = lambda do |flag, value|
      arguments = original.dup
      arguments[arguments.index(flag) + 1] = value
      arguments
    end
    if controls.include?(:selectors)
      [["--scope", "011"], ["--project", "foreign"]].each do |flag, value|
        @kernel.peer_identity = worker
        capture_io do
          assert_raises(Ace::Support::Cli::Error) do
            registered_lab_call("service request", command, replacement.call(flag, value))
          end
        end
      end
      capture_io do
        assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service request", command, replacement.call("--candidate-head", "a" * 64)) }
      end
    end
    if controls.include?(:missing_service)
      @kernel.peer_identity = worker
      capture_io do
        assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service request", command, replacement.call("--service", "missing")) }
      end
    end
    if controls.include?(:foreign_birth)
      @kernel.peer_identity = worker.merge("started_at" => "linux:#{Ace::Assign::ExecutionScopeObservationFixtures::BOOT}:999")
      capture_io do
        error = assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service request", command, original) }
        assert_includes error.message, "unauthorized"
      end
    end
    [["--candidate-head", "f" * 40, :stale_head], ["--candidate-generation", (original[original.index("--candidate-generation") + 1].to_i + 1).to_s, :stale_generation],
      ["--authorization", "missing-decision", :missing_authorization], ["--authorization", "decision", :missing_review]].each do |flag, value, selected|
      next unless controls.include?(selected)
      @kernel.peer_identity = worker
      output = capture_io do
        assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service request", command, replacement.call(flag, value)) }
      end.first
      refusal = JSON.parse(output)
      assert_equal "error", refusal.fetch("status")
      assert_includes %w[service_claim_refused service_claim_unconfirmed], refusal.dig("error", "code")
    end
  ensure
    @kernel.peer_identity = worker
  end

  def public_lab_request(client, submission, bytes)
    diagnostic = []
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    record = ->(phase, error = nil) { diagnostic << {"phase" => phase, "elapsed" => Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, "error_class" => error&.class&.name, "error" => error&.message&.byteslice(0, 256)} }
    receiver_owner = receiver(client, Ace::Lab::Molecules::ProtectedServiceHandler.new)
    reached, release, completed, ready = Queue.new, Queue.new, Queue.new, Queue.new
    original_handler = receiver_owner.instance_variable_get(:@handler)
    blocked = Object.new
    blocked.define_singleton_method(:execute) do |**arguments|
      reached << true
      release.pop
      original_handler.execute(**arguments)
    end
    receiver_owner.instance_variable_set(:@handler, blocked)
    receiver_call = receiver_owner.method(:execute)
    receiver_owner.define_singleton_method(:execute) do |**arguments|
      record.call("receiver.execute.before")
      result = receiver_call.call(**arguments)
      record.call("receiver.execute.after")
      completed << result
      result
    end
    worker, executor = @worker, @executor
    listener_kernel = Object.new
    listener_kernel.define_singleton_method(:peer) { |_| worker }
    listener_kernel.define_singleton_method(:capture) { |_| executor }
    listener_kernel.define_singleton_method(:live!) { |_| true }
    wire, real = Module.new, Ace::Runtime::Molecules::ProtectedSocket
    lose_reply, lost_reply = @lose_public_claim, false
    wire.define_singleton_method(:deadline) { |*args| real.deadline(*args) }
    %i[read write connect].each do |method|
      wire.define_singleton_method(method) do |*args, **kwargs, &block|
        record.call("wire.#{method}.before")
        if method == :write && lose_reply && !lost_reply && args[1].is_a?(Hash) && args[1]["type"] == "service_claim_accepted"
          lost_reply = true
          record.call("wire.claim_reply.suppressed")
          raise Ace::Runtime::RuntimeUnavailableError, "controlled loss of authenticated canonical claim reply"
        end
        result = real.public_send(method, *args, **kwargs, &block)
        record.call("wire.#{method}.after")
        result
      rescue Exception => error
        record.call("wire.#{method}.error", error)
        raise
      end
    end
    path = File.join(@root, "public-receiver.sock")
    @project.fetch("service_receivers").fetch("executor")["socket_path"] = path
    wire.define_singleton_method(:socket_identity) do |selected|
      stat = File.lstat(selected)
      raise "wrong controlled socket" unless selected == path && stat.socket?
      ready << true
      [stat.dev, stat.ino, executor.fetch("uid")]
    end
    wire.define_singleton_method(:root_path!) do |selected, directory:, owner:|
      raise "wrong controlled socket parent" unless selected == File.dirname(path) && directory && owner == executor.fetch("uid")
    end
    new_listener = -> { Ace::Lab::Organisms::ProtectedServiceListener.new(mapping_id: "mapping", service_id: "executor",
      deployment: @deployment, kernel: listener_kernel, receiver: receiver_owner, wire: wire) }
    listener = new_listener.call
    worker_kernel = Ace::Assign::EndcapResultOwnerFixture::Kernel.new
    worker_kernel.define_singleton_method(:capture) { |_| worker }
    worker_kernel.peer_identity = @service.slice("uid", "gid", "groups")
    caller = Object.new
    caller.define_singleton_method(:capture) { |_| worker }
    caller.define_singleton_method(:peer) { |_| executor }
    project = @project
    mapping, authority = @map, @service
    @deployment.define_singleton_method(:data) { {"projects" => {"project" => project}, "launch_mappings" => {"mapping" => mapping}, "authorities" => {"authority" => {"uid" => authority.fetch("uid")}}} }
    history = Object.new
    history.define_singleton_method(:descriptors) { [] }
    context = Ace::Assign::Authority::ProtectedAssignmentContext.new(deployment: @deployment, history: history,
      uid: worker.fetch("uid"), kernel: worker_kernel, env: {})
    @kernel.peer_identity = worker
    # The worker reads the actual public current generation before its first
    # claim. No arithmetic or fixture generation substitutes for this owner.
    before_generation = @journal.ref_value
    status_client = context.client(options: {mapping: "mapping"})
    generation_out, generation_err = capture_io do
      Ace::Assign::Authority::Client.stub(:new, ->(**_) { status_client }) do
        Ace::Assign::CLI::Commands::Authority::Status.new.call(mapping: "mapping", assignment: "assignment", attempt: @attempt)
      end
    end
    assert_empty generation_err
    public_generation = JSON.parse(generation_out)
    assert_equal submission.fetch("expected_generation"), public_generation.fetch("generation")
    assert_equal submission.fetch("candidate_generation"), public_generation.fetch("result_candidate_generation")
    assert_equal before_generation, @journal.ref_value, "generation discovery is read-only"
    adapter = Ace::Lab::Organisms::ProtectedServiceRequest.new(context: context, ingress_factory: ->(**selection) {
      @kernel.peer_identity = executor
      Ace::Lab::Organisms::ProtectedServiceClient.new(**selection.merge(kernel: caller, wire: wire)) })
    command = Ace::Lab::CLI::Commands::Service::Request.new
    command.instance_variable_set(:@protected_service, adapter)
    input_path = File.join(@root, "public-input.json")
    File.write(input_path, bytes)
    original_chown = File.method(:chown)
    controlled_chown = lambda do |uid, gid, *paths|
      raise "unexpected ownership mutation" unless paths == [path] && uid.nil? && gid == @map.fetch("worker_gid")
      original_chown.call(nil, Process.gid, path)
    end
    owner = nil
    File.stub(:chown, controlled_chown) do
      owner = Thread.new { listener.serve }
      Timeout.timeout(5) { ready.pop }
      arguments = ["--project", "project", "--assignment", "assignment", "--attempt", @attempt,
        "--operation", "merge", "--authorization", submission.fetch("authorization"), "--request-id", "service-request", "--input", input_path,
        "--mapping", "mapping", "--scope", "010", "--service", "executor", "--candidate-head", @head,
        "--candidate-generation", submission.fetch("candidate_generation").to_s,
        "--expected-generation", public_generation.fetch("generation").to_s]
      if @public_refusals
        before_refusals = @journal.ref_value
        exercise_registered_request_refusals(command, arguments, worker, @public_refusals)
        assert_equal before_refusals, @journal.ref_value, "public refusal cannot claim/write/repair"
        assert_empty reached, "no fixed handler admitted"
        listener.stop
        assert owner.join(10)
        owner.value
        next({"state" => "refused"})
      end
      if %i[missing out_of_scope].include?(@authorization_mode)
        before_refusal = @journal.ref_value
        output, error_output = capture_io do
          assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service request", command, arguments) }
        end
        assert_empty error_output
        response = JSON.parse(output)
        assert_equal "error", response.fetch("status")
        @authorization_blocker = response.dig("error", "code")
        assert_includes %w[service_claim_refused service_claim_unconfirmed], @authorization_blocker
        listener.stop
        assert owner.join(10)
        owner.value # listener ensure joins its admitted worker before releasing exclusion
        assert_equal before_refusal, @journal.ref_value, "terminal canonical owner proves no claim was published"
        assert_empty reached, "terminal fixed provider handler was not admitted"
        assert @authorization_observations.any? { |entry| entry.fetch("exact") && entry.fetch("rejected") },
          "maintained policy must reject the exact authorization, not merely time out"
        directory = File.expand_path("../../../.ace-local/task/8wr.t.qkb.1", __dir__)
        FileUtils.mkdir_p(directory)
        File.write(File.join(directory, "#{name}.authorization.json"), JSON.pretty_generate({
          "blocker" => @authorization_blocker, "policy" => @authorization_observations}))
        # A contacted authority rejection remains uncertain at transport.
        # Actual policy denial plus terminal canonical/effect checks above
        # prove this scenario; an unconfirmed reply alone never does.
        next({"state" => "blocked", "blocker" => @authorization_blocker})
      end
      record.call("cli.request.before")
      out, err = capture_io do
        if lose_reply
          error = assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service request", command, arguments) }
          assert_includes error.message, "service_claim_unconfirmed"
        else
          registered_lab_call("service request", command, arguments)
        end
      end
      assert_empty err
      record.call("cli.request.after")
      claim = JSON.parse(out)
      if lose_reply
        assert lost_reply, "fault must follow validated original canonical claim"
        assert_equal "error", claim.fetch("status")
        assert_equal "service_claim_unconfirmed", claim.dig("error", "code")
        assert_equal "service-request", claim.dig("error", "selection", "request_id")
      else
        assert_equal "ok", claim.fetch("status")
        assert_equal "service_claim_accepted", claim.dig("data", "claim", "type")
        assert_equal "service-request", claim.dig("data", "selection", "request_id")
      end
      refute release.size.positive?, "public acknowledgement precedes provider execution release"
      Timeout.timeout(30) { reached.pop }
      # Provider is parked, so no executor authority call overlaps this worker read.
      @kernel.peer_identity = worker
      status_command = Ace::Lab::CLI::Commands::Service::Status.new
      status_command.instance_variable_set(:@protected_service, Ace::Lab::Organisms::ProtectedServiceRequest.new(context: context))
      before_status = @journal.ref_value
      status_out, status_err = capture_io do
        registered_lab_call("service status", status_command, ["--request", "service-request", "--project", "project",
          "--assignment", "assignment", "--attempt", @attempt, "--mapping", "mapping", "--scope", "010", "--candidate-head", @head,
          "--candidate-generation", submission.fetch("candidate_generation").to_s,
          "--input-digest", submission.fetch("input_digest"), "--target", submission.fetch("target").fetch("resource")])
      end
      if @public_status_refusals
        status_arguments = ["--request", "service-request", "--project", "project", "--assignment", "assignment",
          "--attempt", @attempt, "--mapping", "mapping", "--scope", "010", "--candidate-head", @head,
          "--candidate-generation", submission.fetch("candidate_generation").to_s,
          "--input-digest", submission.fetch("input_digest"), "--target", submission.fetch("target").fetch("resource")]
        [["--input-digest", "f" * 64], ["--candidate-head", "f" * 40], ["--target", "foreign"]].each do |flag, value|
          changed = status_arguments.dup
          changed[changed.index(flag) + 1] = value
          refused_out, refused_err = capture_io do
            assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service status", status_command, changed) }
          end
          assert_empty refused_err
          assert_equal "error", JSON.parse(refused_out).fetch("status")
          assert_equal before_status, @journal.ref_value, "wrong status selection cannot write or repair"
        end
        @kernel.peer_identity = worker.merge("started_at" => "linux:#{Ace::Assign::ExecutionScopeObservationFixtures::BOOT}:999")
        refused_out, refused_err = capture_io do
          assert_raises(Ace::Support::Cli::Error) { registered_lab_call("service status", status_command, status_arguments) }
        end
        assert_empty refused_err
        assert_equal "error", JSON.parse(refused_out).fetch("status")
        assert_equal before_status, @journal.ref_value
        @kernel.peer_identity = worker
      end
      assert_empty status_err
      assert_equal "uncertain", JSON.parse(status_out).dig("data", "state")
      observe_pending_delivery!
      assert_equal before_status, @journal.ref_value, "pending/lost-reply observation cannot write or restart"
      @kernel.peer_identity = executor
      listener.stop
      release << true
      assert owner.join(30), "owned receiver must finish after admitted provider"
      owner.value
      result = Timeout.timeout(1) { completed.pop }
      before_replay = @journal.ref_value
      @kernel.peer_identity = worker
      listener = new_listener.call
      ready.clear
      owner = Thread.new { listener.serve }
      Timeout.timeout(5) { ready.pop }
      replay_out, replay_err = capture_io { registered_lab_call("service request", command, arguments) }
      assert_empty replay_err
      replay_claim = JSON.parse(replay_out).fetch("data").fetch("claim")
      assert_equal "service_claim_accepted", replay_claim.fetch("type")
      assert replay_claim.fetch("data").fetch("replayed")
      assert_equal "succeeded", replay_claim.fetch("data").fetch("state")
      listener.stop
      assert owner.join(30)
      owner.value
      assert_equal before_replay, @journal.ref_value, "identical public invocation preserves canonical completion"
      result
    end
  ensure
    release << true if release
    listener&.stop
    owner&.join(30)
    directory = File.expand_path("../../../.ace-local/task/8wr.t.qkb.1", __dir__)
    FileUtils.mkdir_p(directory)
    File.write(File.join(directory, "public-service-wire-phases.json"), JSON.pretty_generate({
      "method" => name, "phases" => diagnostic}))
  end

  def issue_original
    state = call("inspect_launch", {}, peer: @launcher, role: :launcher).fetch(:data)
    server, worker = UNIXSocket.pair
    request = {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}}
    wire = Ace::Assign::EndcapResultOwnerFixture::WIRE
    gate = Thread.new { @launch.gate_ready(request: request, peer: @worker, socket: server, deadline: wire.deadline(5)) }
    assert_equal "ready", wire.read(worker, deadline: wire.deadline(5)).dig("data", "phase")
    call("release_launch", {"launch_ticket" => state.fetch("launch_ticket"), "process_binding" => @binding,
      "expected_generation" => state.fetch("generation")}, id: "release", peer: @launcher, role: :launcher)
    assert_equal "release", wire.read(worker, deadline: wire.deadline(5)).fetch("operation")
    gate.join(2)
    refute gate.alive?
  ensure
    server&.close
    worker&.close
    gate&.kill if gate&.alive?
  end
end
