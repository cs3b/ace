# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/protected_service_receiver"
require "tmpdir"
require "etc"
require "open3"

class ProtectedServiceReceiverTest < Minitest::Test
  # These are orchestration classifications, not simulated protected origin
  # acceptance. Actual peer/native checks remain in the installed proof.
  def fixture(client, staging: nil, handler: nil)
    worker = {"uid" => Process.uid + 1, "gid" => 500, "groups" => []}
    map = {"project_id" => "fixture", "worker_uid" => worker["uid"], "worker_gid" => 500,
      "worker_groups" => [], "authority_id" => "authority"}
    project = {"service_receivers" => {"executor" => {"executor_uid" => Process.uid, "staging_root" => staging}},
      "peer_credentials" => {Process.uid.to_s => {"gid" => Process.gid, "groups" => []}}}
    deployment = Object.new
    deployment.define_singleton_method(:verify_composition!) { |authority, composition:| raise "wrong composition" unless authority == "authority" && composition == "services" }
    deployment.define_singleton_method(:mapping) { |_| map }
    deployment.define_singleton_method(:project) { |_| project }
    kernel = Object.new
    kernel.define_singleton_method(:live!) { |_| true }
    kernel.define_singleton_method(:capture) { |_| {"uid" => Process.uid, "gid" => Process.gid, "groups" => []} }
    unless handler
      handler = Object.new
      handler.define_singleton_method(:execute) { |**_| raise "must not invoke" }
    end
    receiver = Ace::Lab::Organisms::ProtectedServiceReceiver.new(mapping_id: "mapping", service_id: "executor",
      deployment: deployment, kernel: kernel, client: client, handler: handler)
    input = {"target" => {"resource" => "fixture"}}
    submission = {"assignment_id" => "assignment", "attempt_id" => "attempt", "expected_generation" => 2,
      "candidate_generation" => 1, "head" => "a" * 40, "request_id" => "request", "operation" => "publish",
      "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input), "target" => Ace::Lab::Atoms::ServiceInput.target(input),
      "authorization" => "decision"}
    [receiver, submission, worker, JSON.generate(input)]
  end

  def run_real_candidate(scenario: :success)
    Dir.mktmpdir("ace-receiver-", Etc.getpwuid(Process.uid).dir) do |root|
      File.chmod(0o700, root)
      repo = File.join(root, "repository")
      Dir.mkdir(repo, 0o700)
      git = lambda do |*args|
        out, error, status = Open3.capture3("git", "-C", repo, *args)
        raise error unless status.success?
        out.strip
      end
      git.call("init", "-b", "main")
      File.write(File.join(repo, "README"), "exact candidate")
      git.call("add", "README")
      git.call("-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "fixture")
      head = git.call("rev-parse", "HEAD")
      tree = git.call("rev-parse", "HEAD^{tree}")
      bundle_path = File.join(root, "candidate.bundle")
      git.call("bundle", "create", bundle_path, "HEAD")
      bundle = File.binread(bundle_path)
      calls = []
      operation = nil
      evidence = nil
      client = Object.new
      client.define_singleton_method(:call) do |name, params, **options|
        calls << name
        if (scenario == :lost_begin && name == "begin_dispatch") ||
            (scenario == :lost_authorization && name == "service_authorization") ||
            (scenario == :lost_completion && name == "complete_service")
          raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "fixture lost reply"
        end
        data = case name
        when "request_service"
          {"claim" => "created", "claim_binding" => "b" * 64, "policy_digest" => "c" * 64, "generation" => 3}
        when "export_candidate"
          return Ace::Assign::Authority::Client::Reply.new(data: {"sha256" => Digest::SHA256.hexdigest(bundle),
            "bytes" => bundle.bytesize, "tree" => tree}, replayed: false, parts: [bundle])
        when "begin_dispatch"
          {"invocation" => "permitted", "generation" => 4}
        when "service_authorization"
          params.slice("request_id", "claim_binding", "head", "candidate_generation").merge("policy_digest" => "c" * 64,
            "operation_digest" => scenario == :changed_operation ? "d" * 64 : Ace::Assign::Atoms::EvidenceDigest.digest(operation))
        when "complete_service"
          receipt, artifact = options.fetch(:upload_parts)
          raise "wrong evidence" unless artifact == evidence && Digest::SHA256.hexdigest(receipt) == params.fetch("receipt_sha256")
          {"request_id" => "request", "state" => "succeeded", "generation" => 5}
        else
          raise "unexpected call"
        end
        Ace::Assign::Authority::Client::Reply.new(data: data, replayed: false)
      end
      receiver, submission, peer, bytes = fixture(client, staging: root, handler: Ace::Lab::Molecules::ProtectedServiceHandler.new)
      submission["head"] = head
      evidence = "ace-service-attestation request:request input:#{submission.fetch('input_digest')} outcome:succeeded\nfixture ran"
      response = JSON.generate("request_id" => "request", "input_digest" => submission.fetch("input_digest"), "outcome" => "succeeded",
        "evidence" => [{"ref" => "proof.txt", "sha256" => Digest::SHA256.hexdigest(evidence)}])
      configured = {"project" => "fixture", "service_id" => "executor", "executor_uid" => Process.uid,
        "lease_expires_at" => (Time.now.utc + 3600).iso8601, "argv" => ["/bin/sh", "-c",
          "test \"$(cat README)\" = 'exact candidate' || exit 9; printf '%s' '#{evidence}' > proof.txt; printf '%s' '#{response}'"]}
      document = {"operations" => {"publish" => configured}}
      operation = Ace::Lab::Molecules::ServicePolicy.new(document).operation!("publish", project: "fixture", service_id: "executor")
      result = Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, document) do
        receiver.execute(submission: submission, peer: peer, input_bytes: bytes, mutation_id: "fixture-mutation")
      end
      return [result, calls, Dir.glob(File.join(root, "**", "proof.txt"))]
    end
  end

  def test_fresh_permission_and_final_read_transfer_real_candidate_handler_evidence
    result, calls, proofs = run_real_candidate
    assert_equal "succeeded", result.fetch("state")
    assert_equal %w[request_service export_candidate begin_dispatch service_authorization complete_service], calls
    assert_equal 1, proofs.length
  end

  def test_lost_begin_or_final_authorization_and_changed_operation_never_invoke_handler
    %i[lost_begin lost_authorization changed_operation].each do |scenario|
      result, calls, proofs = run_real_candidate(scenario: scenario)
      assert_equal "uncertain", result.fetch("state"), scenario
      refute_includes calls, "complete_service", scenario
      assert_empty proofs, scenario
    end
  end

  def test_lost_completion_reply_never_claims_success_after_real_handler_effect
    result, calls, proofs = run_real_candidate(scenario: :lost_completion)
    assert_equal "uncertain", result.fetch("state")
    assert_equal 1, calls.count("complete_service")
    assert_equal 1, proofs.length
  end

  def test_retained_claim_never_invokes_or_begins
    calls = []
    client = Object.new
    client.define_singleton_method(:call) do |operation, params, **_|
      calls << operation
      raise "mutable binding" unless params.frozen? && params.fetch("worker_process_binding").frozen?
      Ace::Assign::Authority::Client::Reply.new(data: {"request_id" => "request", "state" => "uncertain", "claim" => "retained"}, replayed: false)
    end
    receiver, request, peer, bytes = fixture(client)
    result = receiver.execute(submission: request, peer: peer, input_bytes: bytes, mutation_id: "request-mutation")
    assert_equal "retained", result.fetch("claim")
    assert_equal ["request_service"], calls
  end

  def test_lost_claim_reply_retains_uncertainty_without_invocation
    client = Object.new
    client.define_singleton_method(:call) { |*_, **_| raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "fixture reply loss" }
    receiver, request, peer, bytes = fixture(client)
    assert_equal "uncertain", receiver.execute(submission: request, peer: peer, input_bytes: bytes, mutation_id: "request-mutation").fetch("state")
  end

  def test_malformed_peer_or_original_body_refuses_before_authority_contact
    client = Object.new
    client.define_singleton_method(:call) { |*_, **_| raise "must not contact" }
    receiver, request, peer, bytes = fixture(client)
    assert_equal "refused", receiver.execute(submission: request, peer: peer.merge("uid" => peer["uid"] + 1), input_bytes: bytes, mutation_id: "request-mutation").fetch("state")
    assert_equal "refused", receiver.execute(submission: request, peer: peer, input_bytes: "changed", mutation_id: "request-mutation").fetch("state")
    result = receiver.execute(submission: request.merge("request_id" => "secret value\n"), peer: peer, input_bytes: bytes, mutation_id: "request-mutation")
    assert_equal({"request_id" => nil, "state" => "refused", "code" => "invalid_receiver_admission"}, result)
  end
end
