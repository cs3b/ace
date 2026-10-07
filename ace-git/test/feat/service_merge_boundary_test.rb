# frozen_string_literal: true
require "test_helper"
require_relative "../../../ace-lab/test/support/protected_service_boundary_fixture"
require "ace/git/cli"
require "ace/git/forgejo"
require "stringio"
require "ace/assign/cli/commands/delivery"

# Actual wire/claim/candidate/import owners; only kernel identity, process
# execution and remote provider transport are controlled excluded boundaries.
class ServiceMergeBoundaryTest < AceGitTestCase
  include ProtectedServiceBoundaryFixture
  URL = "https://forge.example.com/owner/repo"

  def configure_result_owner_fixture
    super
    @project.merge!("journal_repository" => @journal.repo_root, "evidence_git_ref" => @journal.ref,
      "evidence_checkout_root" => @journal.checkout_root)
    uid = Process.uid
    @executor.merge!("uid" => uid, "gid" => Process.gid, "groups" => Process.groups.sort)
    @project["service_executor_uids"] = [uid]
    @project["peer_credentials"][uid.to_s] = @executor.slice("gid", "groups").merge("scratch_root" => @root)
    @project["service_receivers"]["executor"]["executor_uid"] = uid
    @document["principals"][uid.to_s] = {"projects" => ["project"]}
    @document["operations"] = {"merge" => {"project" => "project", "service_id" => "executor", "executor_uid" => uid,
      "argv" => [File.expand_path("../../../bin/ace-git", __dir__), "service", "merge"],
      "lease_expires_at" => (Time.now.utc + 3600).iso8601}}
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

  def exercise_completion
    fixture do
      issue_original
      submission, = prepared_submission
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
          result = receiver(traced, Ace::Lab::Molecules::ProtectedServiceHandler.new).execute(
            submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "merge-original")
        end
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
      consumed = consumer.perform(**arguments)
      assert_equal "succeeded", consumed.fetch("state")
      assert_equal "merge", consumed.fetch("delivery_event").fetch("payload").fetch("operation")
      assert_equal "succeeded", consumer.perform(**arguments.merge(operation: "status")).fetch("state")
      assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "delivery" }
      assert_equal 1, calls.count { |args| args[1] == "POST" }, "worker consumption never reruns merge"
      project = @project
      @deployment.define_singleton_method(:data) { {"projects" => {"project" => project}} }
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
      assert_empty err
      assert_equal "succeeded", JSON.parse(out).fetch("state")
      assert_equal before_consume, @journal.ref_value, "public receipt consumption is read-only"
    end
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
