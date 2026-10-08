# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/organisms/protected_service_receiver"

class ProtectedPublicationFlowTest < Minitest::Test
  Reply = Struct.new(:data)
  class CanonicalClient
    attr_reader :calls, :completed
    def initialize(peer)
      @calls = []
      @state = {"state" => "uncertain", "dispatch_phase" => "dispatch_started", "generation" => 2,
        "executor_process_binding" => peer}
    end
    def call(operation, params, **options)
      @calls << [operation, params, options]
      case operation
      when "service_status" then Reply.new(@state.dup)
      when "publication_challenge"
        @state = @state.merge("dispatch_phase" => "otp_pending", "generation" => @state.fetch("generation") + 1,
          "publication_challenge_digest" => params.fetch("receipt_sha256"), "publication_challenge_ref" => {"ref" => "original-challenge"})
        Reply.new(@state.dup)
      when "publication_continue"
        raise "duplicate effect admission" unless @state.fetch("dispatch_phase") == "otp_pending"
        @state = @state.merge("dispatch_phase" => "issuing", "generation" => @state.fetch("generation") + 1, "invocation" => "permitted")
        Reply.new(@state.dup)
      when "complete_service"
        @completed = options.fetch(:upload_parts)
        @state = @state.merge("state" => JSON.parse(@completed.first).fetch("outcome"))
        Reply.new(@state.merge("request_id" => params.fetch("request_id")))
      else raise "unexpected canonical operation"
      end
    end
  end
  class HitlClient
    attr_reader :creates, :consumes
    attr_accessor :lose_create_reply
    def initialize(peer)
      @peer, @creates, @consumes = peer, [], 0
    end
    def create(**params)
      @creates << params
      unless @value && @value.fetch("id") == params.fetch(:id)
        @value = JSON.parse(JSON.generate(params.transform_keys(&:to_s).except("deadline"))).merge("state" => "created", "publication_requester_peer" => @peer)
      end
      if @lose_create_reply
        @lose_create_reply = false
        raise IOError, "lost create acknowledgement"
      end
      @value
    end
    def read(id, deadline:)
      raise "wrong ask ID" unless id == @value.fetch("id")
      @value.dup
    end
    def deliver(secret)
      @secret = secret.dup
      @value["state"] = "answer-delivered"
    end
    def expire
      @value.fetch("otp")["expires_at"] = Time.now.to_i - 1
    end
    def consume(id, timeout:, operation:, deadline:)
      raise "unbounded secret transfer" unless timeout == 1 && operation == "publish" && id == @value.fetch("id")
      @consumes += 1
      @value["state"] = "consumed"
      {"answer" => @secret.dup}
    end
    def cancel(id, reason:, deadline:)
      @value["state"] = "cancelled"
    end
  end
  class Publisher
    attr_reader :pushes
    attr_accessor :registry
    def initialize(registry, results)
      @registry, @results, @pushes = registry, results, []
    end
    def verify!(**)
      {"classification" => @registry, "code" => @registry == "succeeded" ? "registry_exact_artifact" : "registry_version_absent"}
    end
    def push!(**params)
      @pushes << params.merge(otp: params[:otp]&.dup)
      classification = @results.shift
      @registry = "succeeded" if classification == "accepted"
      {"classification" => classification == "accepted" ? "uncertain" : classification,
        "code" => classification == "failed" ? "provider_rejected_non_otp" : "provider_rejected_before_acceptance"}
    end
  end

  def setup
    @root = Dir.mktmpdir("publication-flow", "/tmp")
    File.chmod(0o700, @root)
    @artifact = File.join(@root, "exact.gem")
    spec = Gem::Specification.new { |s| s.name = "scoped-fixture"; s.version = "1.0.0"; s.summary = "fixture"; s.authors = ["ACE"]; s.files = [] }
    capture_io { Gem::Package.build(spec, true, false, @artifact) }
    @peer = {"pid" => Process.pid, "uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups,
      "started_at" => "original", "host" => "fixture", "parent_pid" => Process.ppid}
    kernel = Object.new
    peer = @peer
    kernel.define_singleton_method(:capture) { |_| peer }
    kernel.define_singleton_method(:live!) { |_| true }
    map = {"authority_id" => "authority", "project_id" => "ace"}
    project = {"service_receivers" => {"executor" => {"executor_uid" => Process.uid, "staging_root" => @root}}}
    deployment = Object.new
    deployment.define_singleton_method(:mapping) { |_| map }
    deployment.define_singleton_method(:project) { |_| project }
    deployment.define_singleton_method(:verify_composition!) { |*_, **| true }
    @client, @hitl = CanonicalClient.new(@peer), HitlClient.new(@peer)
    @publication = {"gem_name" => "scoped-fixture", "version" => "1.0.0", "head" => "a" * 40,
      "registry" => "https://rubygems.org", "artifact_relative_path" => "exact.gem"}
    target = {"resource" => "rubygems:scoped-fixture:1.0.0", "artifact_digest" => Digest::SHA256.file(@artifact).hexdigest}
    @params = {"request_id" => "publication1", "assignment_id" => "assignment", "attempt_id" => "attempt",
      "candidate_generation" => 1, "head" => "a" * 40, "input_digest" => "c" * 64, "target" => target}
    request = @params.merge("project_id" => "ace", "operation" => "publish", "candidate_head" => "a" * 40,
      "executor_uid" => Process.uid, "transport" => "unix")
    @admitted = {params: @params, claim: {"claim_binding" => "d" * 64}, started: {"executor_process_binding" => @peer},
      dispatch_event_digest: "e" * 64, operation: {"executor_uid" => Process.uid, "argv" => ["fixed-publisher", "--scoped-publication"]},
      envelope: {"input" => {"publication" => @publication, "target" => target}, "request" => request},
      staging_identity: File.lstat(@root), mutation_id: "original"}
    @construction = {mapping_id: "mapping", service_id: "executor", deployment: deployment, kernel: kernel,
      client: @client, publication_hitl: @hitl}
  end

  def teardown
    @receiver&.release_publication_lifetime!
    FileUtils.remove_entry(@root) if File.exist?(@root)
  end

  def begin_flow(registry: "absent", results: ["accepted"])
    @publisher = Publisher.new(registry, results)
    @receiver = Ace::Lab::Organisms::ProtectedServiceReceiver.new(**@construction, publication_publisher: @publisher)
    result = @receiver.begin_publication!(admitted: @admitted, materialized: {"directory" => @root}, deadline: deadline)
    result
  end

  def deadline
    Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
  end

  def tick
    @receiver.tick_publication!(request_id: "publication1", deadline: deadline)
  end

  def test_actual_receiver_publisher_success_and_exact_existing_readback
    assert_equal "succeeded", begin_flow.fetch("state")
    assert_equal 1, @publisher.pushes.size
    refute @receiver.publication_active?
    evidence = JSON.parse(@client.completed.last)
    assert_equal @publication, evidence.fetch("publication")
    assert_equal @params.fetch("target"), evidence.fetch("target")
    assert_equal "registry_exact_artifact", evidence.fetch("code")
  end

  def test_exact_existing_artifact_has_zero_pushes
    assert_equal "succeeded", begin_flow(registry: "succeeded").fetch("state")
    assert_empty @publisher.pushes
  end

  def test_pending_otp_and_duplicate_ticks_have_zero_new_effects_then_one_continuation
    assert_equal "publication-pending", begin_flow(results: ["otp-required", "accepted"]).fetch("state")
    2.times { assert_equal "publication-pending", tick.fetch("state") }
    assert_equal 1, @publisher.pushes.size
    assert_equal 1, @hitl.creates.size
    secret = (1..6).to_a.join
    @hitl.deliver(secret)
    assert_equal "succeeded", tick.fetch("state")
    assert_equal 2, @publisher.pushes.size
    assert_equal 1, @hitl.consumes
    assert_equal 1, @client.calls.count { |operation, _, _| operation == "publication_continue" }
    refute_includes JSON.generate(@client.calls), secret
    refute_includes JSON.generate(@client.completed), secret
  end

  def test_non_otp_failure_does_not_ask_and_uncertainty_never_repushes
    assert_equal "failed", begin_flow(results: ["failed"]).fetch("state")
    assert_empty @hitl.creates
  end

  def test_lost_push_result_is_status_only_until_exact_registry_success
    assert_equal "uncertain", begin_flow(results: ["uncertain"]).fetch("state")
    assert_equal "uncertain", tick.fetch("state")
    assert_equal 1, @publisher.pushes.size
    assert_empty @hitl.creates
    @publisher.registry = "succeeded"
    assert_equal "succeeded", tick.fetch("state")
    assert_equal 1, @publisher.pushes.size
  end

  def test_unknown_initial_registry_is_readonly_until_exact_success
    assert_equal "uncertain", begin_flow(registry: "uncertain").fetch("state")
    assert_equal "uncertain", tick.fetch("state")
    assert_empty @publisher.pushes
    @publisher.registry = "succeeded"
    assert_equal "succeeded", tick.fetch("state")
    assert_empty @publisher.pushes
  end

  def test_lost_create_ack_retries_exact_ask_without_new_effect
    @hitl.lose_create_reply = true
    assert_equal "uncertain", begin_flow(results: ["otp-required", "accepted"]).fetch("state")
    assert_equal "publication-pending", tick.fetch("state")
    assert_equal 1, @hitl.creates.map { |params| params.fetch(:id) }.uniq.size
    assert_equal 1, @publisher.pushes.size
    @hitl.deliver((1..6).to_a.join)
    assert_equal "succeeded", tick.fetch("state")
  end

  def test_expired_ask_is_confirmed_cancelled_before_new_ask
    begin_flow(results: ["otp-required", "accepted"])
    tick
    old = @hitl.creates.last.fetch(:id)
    @hitl.expire
    assert_equal "otp-answer-expired", tick.fetch("code")
    assert_equal 1, @hitl.creates.size
    assert_equal "otp-answer-unavailable", tick.fetch("code")
    tick
    refute_equal old, @hitl.creates.last.fetch(:id)
    assert_equal 1, @publisher.pushes.size
    assert_equal 0, @hitl.consumes
  end

  def test_rejected_and_expired_answers_each_require_a_new_challenge_before_retry
    begin_flow(results: ["otp-required", "otp-rejected", "otp-expired", "accepted"])
    %w[otp-rejected otp-expired succeeded].each_with_index do |classification, index|
      tick
      @hitl.deliver((1..6).to_a.join)
      result = tick
      assert_equal classification == "succeeded" ? "succeeded" : "publication-pending", result.fetch("state")
      assert_equal index + 2, @publisher.pushes.size
    end
    assert_equal 3, @hitl.creates.size
    assert_equal 3, @client.calls.count { |operation, _, _| operation == "publication_continue" }
  end

  def test_artifact_substitution_after_answer_refuses_before_secret_or_continue
    begin_flow(results: ["otp-required", "accepted"])
    @hitl.deliver((1..6).to_a.join)
    File.rename(@artifact, @artifact + ".original")
    File.write(@artifact, "replacement")
    assert_equal "uncertain", tick.fetch("state")
    assert_equal 0, @hitl.consumes
    assert_equal 1, @publisher.pushes.size
    refute @client.calls.any? { |operation, _, _| operation == "publication_continue" }
  end
end
