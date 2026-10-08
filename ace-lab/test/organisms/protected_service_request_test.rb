# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/organisms/protected_service_request"

class ProtectedServiceRequestTest < Minitest::Test
  def setup
    @descriptor = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment",
      "attempt_id" => "attempt", "scope" => "1.2"}
    @input = Struct.new(:descriptor).new(@descriptor)
    @calls = []
    input, calls = @input, @calls
    @context = Object.new
    @context.define_singleton_method(:protected_worker?) { false }
    @context.define_singleton_method(:protected_participant?) { false }
    @context.define_singleton_method(:mapping_hint?) { false }
    @context.define_singleton_method(:resolve) { |**arguments| calls << [:resolve, arguments]; input }
    @context.define_singleton_method(:with_installed_selection) { |**arguments, &block| calls << [:selection, arguments]; block.call(:deployment, :kernel, "mapping") }
    @reply = {"version" => 1, "type" => "service_claim_accepted", "data" => {"request_id" => "request", "generation" => 2}}
    ingress = Object.new
    reply = @reply
    ingress.define_singleton_method(:submit) { |**arguments| calls << [:submit, arguments]; reply }
    @adapter = Ace::Lab::Organisms::ProtectedServiceRequest.new(context: @context,
      ingress_factory: ->(**arguments) { calls << [:ingress, arguments]; ingress })
    @options = {mapping: "mapping", scope: "1.2", service: "executor", candidate_head: "a" * 40,
      candidate_generation: 1, expected_generation: 3}
    @bytes = {"target" => {"resource" => "https://forge.example/team/repo/pulls/1", "artifact_digest" => nil},
      "delivery" => {"forge_server" => "forge", "forge_default" => false, "pr_provenance" => {
        "mode" => "canonical", "head_repository_url" => "https://forge.example/team/repo", "head_ref" => "work",
        "base_repository_url" => "https://forge.example/team/repo", "base_ref" => "main"}}, "method" => "squash"}
  end

  def request(options = @options)
    Dir.mktmpdir do |root|
      path = File.join(root, "input.json")
      File.write(path, JSON.generate(@bytes))
      @adapter.request(project: "project", assignment: "assignment", attempt: "attempt", operation: "merge",
        authorization: "approval", request_id: "request", input_path: path, **options)
    end
  end

  def test_standalone_attempt_alone_does_not_select_protected_route
    refute @adapter.selected?({attempt: "attempt"})
    assert @adapter.selected?({scope: "1.2"})
  end

  def test_original_resolution_precedes_ingress_and_exact_replay_keeps_mutation
    result = request
    assert_equal "ok", result.fetch("status")
    assert_equal @reply, result.dig("data", "claim")
    assert_equal %i[resolve selection ingress submit], @calls.map(&:first)
    first = @calls.last.last
    assert_equal Digest::SHA256.hexdigest("qkb.merge.claim:v1:assignment:attempt:request"), first.fetch(:mutation_id)
    assert_equal 3, first.fetch(:submission).fetch("expected_generation")
    assert_equal @bytes, JSON.parse(first.fetch(:input_bytes))
    @calls.clear
    request(@options.merge(expected_generation: 4))
    assert_equal first.fetch(:mutation_id), @calls.last.last.fetch(:mutation_id)
  end

  def test_invalid_scope_head_generation_and_dry_run_refuse_before_owner_contact
    [{scope: 1}, {scope: "1.x"}, {candidate_head: "a" * 64}, {candidate_generation: 1.0}, {dry_run: true}, {input_digest: "f" * 64}, {unknown: true}].each do |change|
      assert_raises(ArgumentError) { request(@options.merge(change)) }
      assert_empty @calls
    end
  end

  def test_original_project_mismatch_never_constructs_ingress
    @descriptor["project_id"] = "foreign"
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { request }
    assert_equal [:resolve], @calls.map(&:first)
  end

  def test_other_installed_participant_refuses_without_input_or_local_effect
    @context.define_singleton_method(:protected_participant?) { true }
    assert @adapter.selected?({})
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { request }
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { @adapter.status(request_id: "request") }
    assert_empty @calls
  end

  def test_unconfirmed_claim_is_error_not_success_or_retry
    @reply.replace({"version" => 1, "type" => "service_claim_unconfirmed", "required_action" => "inspect_canonical_service_status"})
    result = request
    assert_equal "error", result.fetch("status")
    assert_equal "service_claim_unconfirmed", result.dig("error", "code")
    assert_equal 1, @calls.count { |item| item.first == :submit }
  end
end
