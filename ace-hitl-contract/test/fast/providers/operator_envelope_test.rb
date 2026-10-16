# frozen_string_literal: true
require "test_helper"
require "ace/hitl/contract/request_envelope"
class OperatorEnvelopeTest < AceHitlContractTestCase
  C = Ace::Hitl::Contract
  def value
    {"schema" => C::OperatorEnvelope::SCHEMA, "context" => "operator-question", "request_id" => "question001",
      "request_incarnation" => "a" * 16, "project" => "ace", "requester" => "operator", "requester_uid" => 1000,
      "correlation_id" => "question001", "kind" => "question", "payload_sha256" => "b" * 64,
      "input_sha256" => "c" * 64}
  end
  def test_closed_operator_variant_has_no_execution_or_secret_authority
    assert_equal value, C::RequestEnvelope.load(value)
    %w[assignment_id attempt_id reverse effect otp publication_binding sensitive].each do |field|
      assert_raises(C::InvalidEnvelope) { C::RequestEnvelope.load(value.merge(field => nil)) }
    end
    %w[otp proposal secret].each do |kind|
      assert_raises(C::InvalidEnvelope) { C::RequestEnvelope.load(value.merge("kind" => kind)) }
    end
  end
  def test_shipped_operator_example_and_schema_name_the_same_closed_fields
    root = File.expand_path("../../../lib/ace/hitl/contract", __dir__)
    example = JSON.parse(File.read(File.join(root, "examples/operator-question.json")))
    schema = JSON.parse(File.read(File.join(root, "operator-question.v1.schema.json")))
    assert_equal example, C::RequestEnvelope.load(example)
    assert_equal C::OperatorEnvelope::FIELDS.sort, schema.fetch("required").sort
    assert_equal false, schema.fetch("additionalProperties")
  end
  def test_expected_binding_and_schema_are_exact
    [{"schema" => "unknown"}, {"context" => "managed"}, {"correlation_id" => "other"},
     {"requester_uid" => nil}, {"requester_uid" => "1000"}, {"requester_uid" => -1},
     {"input_sha256" => "wrong"}, {"request_incarnation" => "a" * 15}].each do |change|
      assert_raises(C::InvalidEnvelope) { C::RequestEnvelope.load(value.merge(change)) }
    end
    assert_raises(C::InvalidEnvelope) { C::RequestEnvelope.load(value, expected: {project: "other"}) }
    assert_raises(C::InvalidEnvelope) { C::RequestEnvelope.load(value, expected: {requester_uid: 1001}) }
  end
end
