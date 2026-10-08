# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../../ace-assign/test/support/endcap_result_owner_fixture"
require_relative "../../../ace-assign/test/support/service_no_effect_owner_fixture"
require "ace/lab/organisms/protected_service_receiver"
require "ace/assign/authority/server"
require "ace/assign/authority/client"

module ProtectedServiceBoundaryFixture
  include Ace::Assign::EndcapResultOwnerFixture
  include Ace::Assign::ServiceNoEffectOwnerFixture

  def configure_result_owner_fixture
    @project["candidate_root"] = @root
    @project["worker_uids"] = [13001]
    @project["service_receivers"] = {"executor" => {"executor_uid" => 13005,
      "socket_path" => "/fixture/service.sock", "staging_root" => @root}}
    @document = {"principals" => {"13001" => {"projects" => ["project"]}, "13005" => {"projects" => ["project"]}},
      "operations" => {"verify-artifact" => {"project" => "project", "service_id" => "executor", "executor_uid" => 13005,
        "argv" => ["/usr/bin/true"], "lease_expires_at" => (Time.now.utc + 3600).iso8601}}, "authorizations" => {}}
    @policy = Ace::Lab::Molecules::ProtectedServicePolicy.new(document_loader: -> { @document },
      proposal_resolver: ->(*) { raise "no proposal authority in this test" })
    owner = nil
    @journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @journal.repo_root, ref: @journal.ref,
      checkout_root: @journal.checkout_root, mode: :protected, evidence_reader: ->(*args) { owner.call(*args) },
      service_authorizer: ->(existing, replacement, pending) {
        @endcap.authorize_service_update!(journal: @journal, existing: existing, replacement: replacement, pending: pending) })
    owner = Ace::Assign::Authority::ServiceEvidence.new(journal: @journal)
  end

  def prepared_submission(accept_review: true)
    path = File.join(@root, "original.bundle")
    git(@journal.repo_root, "bundle", "create", path, "HEAD")
    bundle = File.binread(path)
    transfer = Struct.new(:bytes) { def count; 1; end }.new(bundle)
    descriptor = Ace::Assign::Authority::TransferCodec.new(root: @root).descriptor([bundle], purpose: :candidate)
    candidate = call("submit_candidate", {"head" => @head, "candidate_generation" => 1,
      "expected_generation" => generation, "transfer" => descriptor}, id: "real-candidate", transfer: transfer).fetch(:data)
    number = candidate.fetch("candidate_generation")
    if accept_review
      review = call("assign_review", {"head" => @head, "candidate_generation" => number,
        "expected_generation" => generation, "reviewer_uid" => @reviewer.fetch("uid"),
        "reviewer_process_binding" => @reviewer}, id: "review", peer: @launcher, role: :launcher).fetch(:data)
      _, _, receipt = upload(parts: ["review report"])
      receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
        "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
      params, input, = upload(parts: ["review report"], receipt: receipt)
      call("accept_review", params.merge("candidate_generation" => number, "purpose_id" => review.fetch("review_id")),
        id: "accept-review", peer: @reviewer, role: :reviewer, transfer: input)
    end
    # Generic service lifecycle coverage uses a named artifact-check operation;
    # publication/OTP admission belongs to the dedicated publication tests.
    bytes = JSON.generate("target" => {"resource" => "artifact:ace-hitl:1.2.3", "artifact_digest" => "b" * 64})
    digest = Ace::Lab::Atoms::ServiceInput.digest(JSON.parse(bytes))
    target = Ace::Lab::Atoms::ServiceInput.target(JSON.parse(bytes))
    @document["authorizations"]["decision"] = {"operation" => "verify-artifact", "project_id" => "project",
      "assignment_id" => "assignment", "attempt_id" => @attempt, "input_digest" => digest, "target" => target,
      "candidate_head" => @head, "caller_uid" => 13001, "expires_at" => (Time.now.utc + 3600).iso8601}
    submission = {"assignment_id" => "assignment", "attempt_id" => @attempt, "candidate_generation" => number,
      "head" => @head, "request_id" => "service-request", "expected_generation" => generation,
      "operation" => "verify-artifact", "input_digest" => digest, "target" => target, "authorization" => "decision"}
    [submission, bytes]
  end

  def receiver(client, handler)
    executor = @executor
    kernel = Object.new
    kernel.define_singleton_method(:capture) { |_| executor }
    kernel.define_singleton_method(:live!) { |_| true }
    Ace::Lab::Organisms::ProtectedServiceReceiver.new(mapping_id: "mapping", service_id: "executor",
      deployment: @deployment, kernel: kernel, client: client, handler: handler)
  end

  def controlled_handler(invocations, expire: false)
    document = @document
    handler = Object.new
    handler.define_singleton_method(:execute) do |operation:, envelope:, candidate_root:|
      raise "wrong selected handler" unless operation.fetch("argv") == [File.realpath("/usr/bin/true")]
      invocations << envelope
      if expire
        document.fetch("operations").fetch("verify-artifact")["lease_expires_at"] = "2020-01-01T00:00:00Z"
        document.fetch("authorizations").fetch("decision")["expires_at"] = "2020-01-01T00:00:00Z"
      end
      request = envelope.fetch("request")
      evidence = "ace-service-attestation request:#{request.fetch('request_id')} input:#{request.fetch('input_digest')} outcome:succeeded\ncontrolled original result\n"
      File.binwrite(File.join(candidate_root, "proof"), evidence)
      {"request_id" => request.fetch("request_id"), "input_digest" => request.fetch("input_digest"), "outcome" => "succeeded",
        "evidence" => [{"ref" => "proof", "sha256" => Digest::SHA256.hexdigest(evidence)}]}
    end
    handler
  end

end
