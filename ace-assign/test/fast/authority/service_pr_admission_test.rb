# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/endcap"

# Admission logic with injected deployment/process/journal observations. The
# real review and candidate checks execute; installed kernel behavior is gad.2.
class ServicePrAdmissionTest < AceAssignTestCase
  def setup
    super
    @worker, @executor = {"uid" => 13001}, {"uid" => 13005}
    @map = {"project_id" => "project", "worker_uid" => 13001, "launcher_uid" => 13002}
    @origin = {"phase" => "issued", "process_binding" => {"process_identity" => @worker},
      "launch_ticket" => "ticket", "reservation_generation" => 1}
    @params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
      "candidate_generation" => 1, "head" => "a" * 40, "request_id" => "request", "operation" => "create",
      "input_digest" => "d" * 64, "target" => {"resource" => "https://forge.example/owner/repo", "artifact_digest" => nil},
      "authorization" => "decision", "service_id" => "executor", "worker_process_binding" => @worker}
    @events = [Ace::Assign::Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: "attempt",
      payload: {"operation" => "submit_candidate", "data" => {"head" => "a" * 40, "candidate_generation" => 1}})]
    @record, @revoked = nil, false
    fixture = self
    @journal = Object.new
    @journal.define_singleton_method(:evidence_mode) { :protected }
    @journal.define_singleton_method(:ref_value) { "b" * 40 }
    @journal.define_singleton_method(:read_events) { |*, **| fixture.instance_variable_get(:@events) }
    @journal.define_singleton_method(:service_request) { |*, **| fixture.instance_variable_get(:@record) }
    journal, origin = @journal, @origin
    launch = Object.new
    launch.define_singleton_method(:with_assignment) { |**_, &block| block.call(journal, {}) }
    launch.define_singleton_method(:origin) { |*, **| origin }
    launch.define_singleton_method(:scope_open_for_effect!) { |**| true }
    kernel = Object.new
    kernel.define_singleton_method(:live!) { |_| true }
    kernel.define_singleton_method(:descendant?) { |*, **| true }
    project = {"service_receivers" => {"executor" => {"executor_uid" => 13005}},
      "service_executor_uids" => [13005], "worker_uids" => [13001]}
    map = @map
    deployment = Object.new
    deployment.define_singleton_method(:mapping) { |_| map }
    deployment.define_singleton_method(:project) { |_| project }
    policy = Object.new
    policy.define_singleton_method(:visible!) { |**| true }
    policy.define_singleton_method(:prepare!) do |binding, **|
      raise SecurityError, "scope revoked" if fixture.instance_variable_get(:@revoked)
      {binding: binding.merge("executor_uid" => 13005, "transport" => "unix"),
        policy_digest: "e" * 64, operation_digest: "f" * 64}
    end
    @owner = Ace::Assign::Authority::Endcap.new(deployment: deployment, launch: launch, kernel: kernel, service_policy: policy)
  end

  def test_draft_claim_authorization_dispatch_and_cas_work_without_review
    %w[create update].each do |operation|
      @record = nil
      @params["operation"] = operation
      claim = @owner.send(:service_claim_plan, @journal, @events, @params, @map, @executor, :executor, "{}")
      @record = claim.fetch(:service_updates).first.fetch(:replacement)
      binding = @params.slice("mapping_id", "assignment_id", "attempt_id", "candidate_generation", "head", "request_id", "input_digest")
        .merge("claim_binding" => @record.fetch("claim_binding"))
      transfer = Struct.new(:bytes) { def count; 1; end }.new("{}")
      result = @owner.send(:service_authorization, {"operation" => "service_authorization"}, binding, @map, @executor, :executor, transfer)
      assert_equal "e" * 64, result.fetch(:data).fetch("policy_digest")
      plan = @owner.send(:service_begin_plan, @journal, @events, binding, @map, @executor, :executor, "{}")
      assert_equal "permitted", plan.fetch(:data).fetch("invocation")
      replacement = plan.fetch(:service_updates).first.fetch(:replacement)
      assert @owner.authorize_service_update!(journal: @journal, existing: @record, replacement: replacement,
        pending: {current_events: @events, service_inputs: {"request" => "{}"}})
      assert_equal "dispatch_started", replacement.fetch("dispatch_phase")
    end
  end

  def test_ready_and_merge_cannot_claim_without_current_independent_review
    %w[ready merge].each do |operation|
      @params["operation"] = operation
      error = assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) do
        @owner.send(:service_claim_plan, @journal, @events, @params, @map, @executor, :executor, "{}")
      end
      assert_includes error.message, "independent review"
      assert_nil @record
    end
  end

  def test_ready_and_merge_revalidate_campaign_gate_at_claim_authorization_dispatch_and_cas
    calls = []
    @owner.define_singleton_method(:approved_review!) do |*_, service_operation:, **|
      calls << service_operation
    end
    %w[ready merge].each do |operation|
      @record = nil
      @params["operation"] = operation
      claim = @owner.send(:service_claim_plan, @journal, @events, @params, @map, @executor, :executor, "{}")
      @record = claim.fetch(:service_updates).first.fetch(:replacement)
      binding = @params.slice("mapping_id", "assignment_id", "attempt_id", "candidate_generation", "head", "request_id", "input_digest")
        .merge("claim_binding" => @record.fetch("claim_binding"))
      transfer = Struct.new(:bytes) { def count; 1; end }.new("{}")
      @owner.send(:service_authorization, {"operation" => "service_authorization"}, binding, @map, @executor, :executor, transfer)
      plan = @owner.send(:service_begin_plan, @journal, @events, binding, @map, @executor, :executor, "{}")
      replacement = plan.fetch(:service_updates).first.fetch(:replacement)
      @owner.authorize_service_update!(journal: @journal, existing: @record, replacement: replacement,
        pending: {current_events: @events, service_inputs: {"request" => "{}"}})
      assert_equal [operation] * 4, calls
      calls.clear
    end
  end

  def test_draft_still_refuses_stale_candidate_wrong_executor_and_revoked_scope
    assert_raises(Ace::Assign::AttemptErrors::Conflict) do
      @owner.send(:service_claim_plan, @journal, @events, @params.merge("head" => "c" * 40), @map, @executor, :executor, "{}")
    end
    assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
      @owner.send(:service_claim_plan, @journal, @events, @params, @map, @worker, :executor, "{}")
    end
    @revoked = true
    assert_raises(SecurityError) do
      @owner.send(:service_claim_plan, @journal, @events, @params, @map, @executor, :executor, "{}")
    end
    assert_nil @record
  end
end
