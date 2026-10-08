# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../../ace-assign/test/support/endcap_result_owner_fixture"
require_relative "../../../ace-assign/test/support/service_no_effect_owner_fixture"
require "ace/lab/organisms/protected_service_receiver"
require "ace/assign/authority/server"
require "ace/assign/authority/client"

class ProtectedServiceRecoveryTest < Minitest::Test
  include Ace::Assign::EndcapResultOwnerFixture
  include Ace::Assign::ServiceNoEffectOwnerFixture
  Parts = Struct.new(:parts) do
    def count; parts.length; end
    def bytes(index: 0); parts.fetch(index); end
  end

  def configure_result_owner_fixture
    @project["worker_uids"] = [13001]
    @project["service_receivers"] = {"executor" => {"executor_uid" => 13005,
      "socket_path" => "/fixture/service.sock", "staging_root" => @root}}
    owner = nil
    @journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @journal.repo_root, ref: @journal.ref,
      checkout_root: @journal.checkout_root, mode: :protected,
      evidence_reader: ->(*args) { owner.call(*args) },
      service_authorizer: ->(existing, replacement, pending) {
        @endcap.authorize_service_update!(journal: @journal, existing: existing, replacement: replacement, pending: pending) })
    owner = Ace::Assign::Authority::ServiceEvidence.new(journal: @journal)
  end

  def request_uncertain_service
    review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
      "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer},
      id: "review", peer: @launcher, role: :launcher).fetch(:data)
    _, _, receipt = upload(parts: ["review report"])
    receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
    params, input, = upload(parts: ["review report"], receipt: receipt)
    call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "accept-review", peer: @reviewer, role: :reviewer, transfer: input)
    @body = JSON.generate("target" => {"resource" => "fixture"})
    digest = Ace::Lab::Atoms::ServiceInput.digest(JSON.parse(@body))
    target = Ace::Lab::Atoms::ServiceInput.target(JSON.parse(@body))
    @policy.define_singleton_method(:input_binding) do |bytes, expected_digest:, expected_target:, operation:|
      raise "changed original input" unless bytes == @original_body && expected_digest == @original_digest && expected_target == @original_target && operation == "verify-artifact"
    end
    @policy.instance_variable_set(:@original_body, @body)
    @policy.instance_variable_set(:@original_digest, digest)
    @policy.instance_variable_set(:@original_target, target)
    @policy.define_singleton_method(:prepare!) do |binding, input_bytes:|
      raise "changed original input" unless input_bytes == @original_body && binding.fetch("input_digest") == @original_digest
      {binding: binding.merge("executor_uid" => 13005, "transport" => "unix"), policy_digest: "f" * 64}
    end
    transfer = Ace::Assign::Authority::TransferCodec.new(root: @root).descriptor([@body], purpose: :service_input)
    params = {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation, "request_id" => "service-request",
      "operation" => "verify-artifact", "input_digest" => digest, "target" => target, "authorization" => "review",
      "service_id" => "executor", "worker_process_binding" => @worker, "transfer" => transfer}
    claim = call("request_service", params, id: "claim", peer: @executor, role: :executor, transfer: Parts.new([@body])).fetch(:data)
    call("begin_dispatch", params.slice("head", "candidate_generation", "request_id", "transfer")
      .merge("expected_generation" => generation, "claim_binding" => claim.fetch("claim_binding")),
      id: "begin", peer: @executor, role: :executor, transfer: Parts.new([@body]))
    @launch.close_execution_scope!(params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt,
      "mutation_id" => "seal", "expected_generation" => generation}, peer: @launcher, role: :launcher)
  end

  def test_actual_receiver_recovers_lost_challenge_and_completion_ack_without_effect_reissue
    fixture do
      request_uncertain_service
      real_client = start_service_server
      calls = []
      caller_bytes = @body.dup
      caller_mutation = +"recover"
      mutate_inputs = true
      lost = %w[claim_service_settlement complete_no_effect]
      client = Object.new
      client.define_singleton_method(:call) do |name, params, **options|
        calls << [name, params.dup, options.dup]
        if name == "service_status" && mutate_inputs
          mutate_inputs = false
          caller_bytes.replace("changed caller input")
          caller_mutation.replace("changed-mutation")
        end
        reply = real_client.call(name, params, **options.merge(timeout: 60))
        if lost.delete(name)
          raise Ace::Runtime::RuntimeUnavailableError, "controlled accepted ACK loss"
        end
        reply
      end
      inspections = []
      inspector = Object.new
      inspector.define_singleton_method(:execute) do |operation:, envelope:, candidate_root:|
        raise "normal effect must never be invoked" unless operation.fetch("argv") == [File.realpath("/usr/bin/true")] &&
          envelope.fetch("kind") == "service_no_effect_inspection"
        inspections << envelope
        request = envelope.fetch("request")
        observation = envelope.fetch("challenge").merge("version" => 1, "target" => request.fetch("target"),
          "dispatch_phase" => envelope.dig("execution", "dispatch_phase"),
          "effect_absent" => true, "handler_terminated" => true, "writers_absent" => true)
        bytes = "ace-service-attestation request:#{request.fetch('request_id')} input:#{request.fetch('input_digest')} outcome:failed no-effect:true\n" +
          "ace-service-no-effect #{JSON.generate(observation)}\n"
        File.binwrite(File.join(candidate_root, "inspection"), bytes)
        {"request_id" => request.fetch("request_id"), "input_digest" => request.fetch("input_digest"), "outcome" => "failed",
          "evidence" => [{"ref" => "inspection", "sha256" => Digest::SHA256.hexdigest(bytes)}]}
      end
      kernel = Object.new
      executor = @executor
      kernel.define_singleton_method(:capture) { |_| executor }
      kernel.define_singleton_method(:live!) { |_| true }
      receiver = Ace::Lab::Organisms::ProtectedServiceReceiver.new(mapping_id: "mapping", service_id: "executor",
        deployment: @deployment, kernel: kernel, client: client, handler: inspector)
      # The selected executable/inspection is a controlled domain prerequisite,
      # not proof that the actual gad.b inspector has been implemented.
      document = {"operations" => {"verify-artifact" => {"project" => "project", "service_id" => "executor",
        "executor_uid" => 13005, "argv" => ["/must/not/execute"], "no_effect_argv" => ["/usr/bin/true"],
        "lease_expires_at" => "2020-01-01T00:00:00Z"}}}
      binding = {"assignment_id" => "assignment", "attempt_id" => @attempt, "candidate_generation" => 1,
        "head" => @head, "request_id" => "service-request"}
      original_generation = generation
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, document) do
        first = receiver.recover_no_effect(binding: binding, input_bytes: caller_bytes, mutation_id: caller_mutation, expected_generation: original_generation)
        assert_equal "uncertain", first.fetch("state"), "lost completion ACK must remain uncertain"
        assert_equal "failed-settled", @journal.service_request("service-request").fetch("state")
        assert_equal "changed caller input", caller_bytes
        assert_equal "changed-mutation", caller_mutation
        assert_equal "recover", calls.find { |name, _| name == "claim_service_settlement" }.last.fetch(:mutation_id)
        assert_equal Digest::SHA256.hexdigest("no-effect:recover"), calls.find { |name, _| name == "complete_no_effect" }.last.fetch(:mutation_id)
        before = @journal.ref_value
        @server.stop
        @owner.join(3)
        refute @owner.alive?, "original authority listener must end before restart"
        restart
        real_client = start_service_server
        receiver = Ace::Lab::Organisms::ProtectedServiceReceiver.new(mapping_id: "mapping", service_id: "executor",
          deployment: @deployment, kernel: kernel, client: client, handler: inspector)
        second = receiver.recover_no_effect(binding: binding, input_bytes: @body, mutation_id: "recover", expected_generation: original_generation)
        assert_equal "failed-settled", second.fetch("state")
        assert_equal before, @journal.ref_value
        assert_equal 1, inspections.size
        assert_equal 1, calls.count { |name, _| name == "claim_service_settlement" }
        assert_equal original_generation, calls.find { |name, _| name == "claim_service_settlement" }.fetch(1).fetch("expected_generation")
        assert_equal 1, calls.count { |name, _| name == "complete_no_effect" }
        changed = receiver.recover_no_effect(binding: binding, input_bytes: JSON.generate("target" => {"resource" => "other"}),
          mutation_id: "recover", expected_generation: original_generation)
        assert_equal "uncertain", changed.fetch("state"), "settled early return must authenticate original input"
        assert_equal 1, inspections.size
        assert_equal before, @journal.ref_value
        @project.fetch("service_receivers")["other"] = @project.fetch("service_receivers").fetch("executor").dup
        foreign = Ace::Lab::Organisms::ProtectedServiceReceiver.new(mapping_id: "mapping", service_id: "other",
          deployment: @deployment, kernel: kernel, client: client, handler: inspector)
        assert_equal "uncertain", foreign.recover_no_effect(binding: binding, input_bytes: @body,
          mutation_id: "foreign-service", expected_generation: original_generation).fetch("state")
        assert_equal 1, inspections.size, "same executor cannot adopt a different receiver's settled service"
        error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
          @endcap.send(:service_status, {}, binding.merge("mapping_id" => "other"), @map, @executor, :executor)
        end
        assert_equal "Original control reservation is unavailable", error.message
        assert_equal before, @journal.ref_value
        record = @journal.service_request("service-request")
        context = Ace::Assign::Authority::ServiceEvidence.new(journal: @journal).settlement_context(record)
        assert_raises(FrozenError) { context.fetch("request").fetch("target")["resource"].replace("changed") }
        reference = record.fetch("receipt").fetch("evidence").first.fetch("ref")
        checkout = @journal.send(:checkout_dir)
        File.binwrite(File.join(checkout, reference), "changed accepted artifact")
        git(checkout, "add", "--", reference)
        git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "corrupt accepted artifact")
        git(@journal.repo_root, "update-ref", @journal.ref, git(checkout, "rev-parse", "HEAD"), before)
        corrupted = receiver.recover_no_effect(binding: binding, input_bytes: @body,
          mutation_id: "recover", expected_generation: original_generation)
        assert_equal "uncertain", corrupted.fetch("state"), "settled shortcut must authenticate original imported bytes"
        assert_equal 1, inspections.size

      end
    end
  end
end
