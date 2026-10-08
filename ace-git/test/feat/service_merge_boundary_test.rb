# frozen_string_literal: true
require "test_helper"
require_relative "../../../ace-lab/test/support/protected_service_boundary_fixture"
require "ace/git/cli"
require "ace/git/forgejo"
require "stringio"
require "ace/assign/cli/commands/delivery"
require "ace/lab/cli/commands/service"

# Actual wire/claim/candidate/import owners; only kernel identity, process
# execution and remote provider transport are controlled excluded boundaries.
class ServiceMergeBoundaryTest < AceGitTestCase
  include ProtectedServiceBoundaryFixture
  URL = "https://forge.example.com/owner/repo"

  def configure_result_owner_fixture
    super
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

  def test_public_lab_request_and_status_use_original_receiver_and_canonical_result
    @public_lab = true
    exercise_completion
  end

  def test_public_lab_lost_claim_reply_recovers_by_exact_canonical_status_and_replay
    @public_lab = true
    @lose_public_claim = true
    exercise_completion
  end

  def test_public_lab_request_refuses_selector_service_and_foreign_birth_controls
    @public_lab = true
    @public_refusals = %i[selectors missing_service foreign_birth]
    exercise_completion
  end

  def test_public_lab_request_refuses_stale_candidate_and_missing_authorization
    @public_lab = true
    @public_refusals = %i[stale_head stale_generation missing_authorization]
    exercise_completion
  end

  def test_public_lab_request_refuses_candidate_without_accepted_review
    @public_lab = true
    @missing_review = true
    @public_refusals = [:missing_review]
    exercise_completion
  end

  def test_public_lab_pending_status_refuses_changed_input_and_foreign_birth
    @public_lab = true
    @public_status_refusals = true
    exercise_completion
  end

  def test_real_receiver_fixed_cli_neutral_merge_and_canonical_receipt_import
    exercise_completion
  end

  def test_completion_interruption_before_cas_publishes_no_partial_result_or_import
    @interrupt_before_cas = true
    exercise_completion
  end

  def test_measure_original_request_service_admission_only
    @measure_request_admission = true
    exercise_completion
  end

  def test_original_service_artifact_refuses_foreign_principal_and_reused_worker_birth
    @identity_controls = true
    exercise_completion
  end

  def test_original_merge_consumer_refuses_stale_selectors_and_direct_local_artifact
    @selector_controls = true
    exercise_completion
  end

  def test_canonical_status_refuses_a_forged_later_delivery_result
    @forged_control = true
    exercise_completion
  end

  def exercise_completion
    fixture do
      issue_original
      submission, = prepared_submission(accept_review: !@missing_review)
      input = {"target" => {"resource" => "#{URL}/pulls/25", "artifact_digest" => nil}, "method" => "squash",
        "delivery" => {"forge_server" => "selected", "forge_default" => false,
          "pr_provenance" => {"mode" => "canonical", "head_repository_url" => URL, "head_ref" => "feature/x",
            "base_repository_url" => URL, "base_ref" => "main"}}}
      bytes = JSON.generate(input)
      digest = Ace::Lab::Atoms::ServiceInput.digest(input)
      target = Ace::Lab::Atoms::ServiceInput.target(input)
      submission.merge!("operation" => "merge", "input_digest" => digest, "target" => target)
      @document["authorizations"]["decision"].merge!("operation" => "merge", "input_digest" => digest, "target" => target)
      Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => [
        {"name" => "selected", "provider" => "forgejo", "url" => URL}]))
      calls, merged = [], false
      runner = lambda do |args:, **|
        calls << args
        payload = if args[1] == "POST"
          assert_equal @head, args[3].fetch("head_commit_id")
          assert_equal "squash", args[3].fetch("Do")
          merged = true
          nil
        elsif args[2].end_with?("/version")
          {"version" => "8.0.5"}
        else
          assert_equal "GET", args[1]
          assert_equal "https://forge.example.com/api/v1/repos/owner/repo/pulls/25", args[2]
          branch = ->(ref, head) { {"ref" => ref, "sha" => head, "repo" => {"full_name" => "owner/repo"}} }
          {"number" => 25, "title" => "Ship", "body" => "", "state" => merged ? "closed" : "open", "draft" => false,
            "merged" => merged, "merged_at" => merged ? "2026-10-07T12:00:00Z" : nil,
            "merge_commit_sha" => merged ? "d" * 40 : nil, "user" => {"login" => "worker"},
            "head" => branch.call("feature/x", @head), "base" => branch.call("main", "e" * 40)}
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
      client = start_service_server
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
      traced = Object.new
      traced.define_singleton_method(:call) do |name, params, **options|
        phases << name
        raise Timeout::Error, "measurement stops before export or provider" if measure_request && name != "request_service"
        if name == "complete_service" && interrupt_before_cas
          completion_call = [params, options]
          before_completion = journal.ref_value
          fault = ->(*) { cas_fault_reached = true; raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "controlled interruption before publication" }
          return journal.stub(:update_ref_cas, fault) { client.call(name, params, **options) }
        end
        response = client.call(name, params, **options)
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
      if @public_refusals
        assert_equal "refused", result.fetch("state")
        assert_equal 0, effects
        assert_equal 0, calls.count { |args| args[1] == "POST" }
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
      assert_equal 1, calls.count { |args| args[1] == "POST" }
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
        assert_equal 1, calls.count { |args| args[1] == "POST" }
        next
      end
      consumed = consumer.perform(**arguments)
      assert_equal "succeeded", consumed.fetch("state")
      assert_equal "merge", consumed.fetch("delivery_event").fetch("payload").fetch("operation")
      assert_equal "succeeded", consumer.perform(**arguments.merge(operation: "status")).fetch("state")
      assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "delivery" }
      assert_equal 1, calls.count { |args| args[1] == "POST" }, "worker consumption never reruns merge"
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
        "--operation", "merge", "--authorization", "decision", "--request-id", "service-request", "--input", input_path,
        "--mapping", "mapping", "--scope", "010", "--service", "executor", "--candidate-head", @head,
        "--candidate-generation", submission.fetch("candidate_generation").to_s,
        "--expected-generation", submission.fetch("expected_generation").to_s]
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

  # Same controlled gate/release handshake as PreparedWorkFetchTest#issue_original;
  # no native worker is executed. Public original-input fetch requires issued
  # state; the inherited result-only fixture otherwise stops at bound.
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
