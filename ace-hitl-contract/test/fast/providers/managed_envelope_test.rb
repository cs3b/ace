# frozen_string_literal: true

require "test_helper"

class ManagedEnvelopeTest < AceHitlContractTestCase
  Envelope = Ace::Hitl::Contract::ManagedEnvelope
  Invalid = Ace::Hitl::Contract::InvalidEnvelope

  def test_protected_attempt_roundtrip_preserves_exact_expected_binding
    attempt = "launch-#{'a' * 24}"
    value = ordinary.merge("attempt_id" => attempt)
    assert_equal value, Envelope.load(JSON.generate(value), expected: {attempt_id: attempt})
    assert_raises(Invalid) { Envelope.load(value, expected: {attempt_id: "launch-#{'b' * 24}"}) }
    assert_raises(Invalid) { Envelope.load(value.merge("assignment_id" => attempt)) }
    ["launch-#{'a' * 23}", "launch-#{'a' * 25}", "launch-#{'A' * 24}",
      "launch-#{'g' * 24}", "launch-#{'a' * 24}\n", "../launch-#{'a' * 24}"].each do |invalid|
      assert_raises(Invalid) { Envelope.load(value.merge("attempt_id" => invalid)) }
    end
  end

  def test_packaged_shared_examples_are_valid
    directory = File.expand_path("../../../lib/ace/hitl/contract/examples", __dir__)
    paths = Dir[File.join(directory, "managed-*.json")]
    assert_equal 3, paths.length
    paths.each { |path| assert_kind_of Hash, Envelope.load(File.read(path)) }
  end

  def ordinary
    {
      "schema" => Envelope::SCHEMA, "request_id" => "hitl-abcdef1234", "request_incarnation" => "0123456789abcdef", "project" => "ace",
      "assignment_id" => "abc123", "attempt_id" => "def456", "requester" => "lab-admin",
      "correlation_id" => "hitl-abcdef1234", "kind" => "decision", "payload_sha256" => Digest::SHA256.hexdigest("Proceed"),
      "reverse" => {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => "workspace:1", "pane" => "pane:1"}
    }
  end

  def test_exact_binding_and_distinct_nested_contracts
    value = ordinary.merge("payload_sha256" => Digest::SHA256.hexdigest("Proceed"),
      "message" => {"schema" => Envelope::MESSAGE_SCHEMA, "id" => ordinary["correlation_id"],
        "kind" => "answer", "sender" => "captain", "answer" => "Proceed", "received_at" => "2026-10-05T10:00:00Z"},
      "effect" => {"authorization_ref" => "grant:operation", "receipt_ref" => "result:operation"})
    assert_equal value, Envelope.load(JSON.generate(value), expected: {attempt_id: "def456", correlation_id: "hitl-abcdef1234"})
    assert_raises(Invalid) { Envelope.load(value, expected: {attempt_id: "wrong1"}) }
    assert_raises(Invalid) { Envelope.load(value, expected: {correlation_id: "wrong1"}) }
    assert_raises(Invalid) { Envelope.load(value.merge("schema" => "ace.hitl.managed/v2")) }
    assert_raises(Invalid) { Envelope.load(value.merge("payload_sha256" => "0" * 64)) }
    value["message"]["id"] = "wrong1"
    assert_raises(Invalid) { Envelope.load(value) }
  end

  def test_native_reverse_pair_survives_wire_without_target_rewrite_or_authority
    reverse = {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => "$0", "pane" => "%0"}
    value = ordinary.merge("reverse" => reverse)
    assert_equal value, Envelope.load(value)
    assert_raises(Invalid) { Envelope.load(value, expected: {reverse: reverse.merge("pane" => "%1")}) }
  end

  def test_wire_reverse_is_a_canonical_typed_pair
    [["$0", "p1"], ["s1", "%0"], ["%0", "$0"], ["$01", "%0"], ["$0", "%01"],
     [" $0 ", "%0"], ["$0", " %0 "], [" s1 ", "p1"], ["s1", " p1 "], [1, "p1"], ["s1", 2]].each do |session, pane|
      reverse = {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => session, "pane" => pane}
      assert_raises(Invalid, [session, pane].inspect) { Envelope.load(ordinary.merge("reverse" => reverse)) }
    end
  end

  def test_pane_less_is_explicit_and_unknown_fields_do_not_enter_persistence
    assert_nil Envelope.load(ordinary.merge("reverse" => nil))["reverse"]
    %w[answer otp otp_hash work].each do |field|
      assert_raises(Invalid) { Envelope.load(ordinary.merge(field => "private")) }
    end
    assert_raises(Invalid) { Envelope.load(ordinary.merge("reverse" => {"schema" => "another/v1", "pane" => "pane1", "session" => "session1"})) }
    assert_raises(Invalid) { Envelope.load(ordinary.merge("assignment_id" => "W500")) }
    assert_raises(Invalid) { Envelope.load(ordinary.merge("attempt_id" => "A-#{'a' * 24}")) }
  end

  def test_otp_has_no_payload_or_hash_and_no_business_callback
    value = ordinary.reject { |key, _| key == "payload_sha256" }.merge("kind" => "otp")
    assert_equal value, Envelope.load(value)
    %w[payload_sha256 message effect].each do |field|
      assert_raises(Invalid) { Envelope.load(value.merge(field => {})) }
    end
  end

  def test_secret_folder_answer_and_unauthorized_effect_shape_are_rejected
    message = {"schema" => Envelope::MESSAGE_SCHEMA, "id" => ordinary["correlation_id"],
      "kind" => "answer", "sender" => "captain", "answer" => "123456", "received_at" => "2026-10-05T10:00:00Z"}
    assert_raises(Invalid) { Envelope.load(ordinary.merge("message" => message)) }
    assert_raises(Invalid) { Envelope.load(ordinary.merge("effect" => {"receipt_ref" => "receipt1"})) }
    assert_raises(Invalid) { Envelope.load(ordinary.merge("effect" => {"authorization_ref" => "grant1", "argv" => ["execute"]})) }
  end
  def test_digest_requires_json_string
    assert_raises(Invalid) { Envelope.load(ordinary.merge("payload_sha256" => ("1" * 64).to_i)) }
  end

  def test_nested_timestamp_requires_real_canonical_calendar_components
    message = {"schema" => Envelope::MESSAGE_SCHEMA, "id" => ordinary["correlation_id"],
      "kind" => "answer", "sender" => "captain", "answer" => "Proceed"}
    %w[2026-02-30T10:00:00Z 2026-04-31T10:00:00Z 2026-10-05T24:00:00Z 2026-10-05T10:60:00Z].each do |stamp|
      assert_raises(Invalid) { Envelope.load(ordinary.merge("message" => message.merge("received_at" => stamp))) }
    end
    stamp = "2028-02-29T23:59:59Z"
    assert_equal stamp, Envelope.load(ordinary.merge("message" => message.merge("received_at" => stamp))).dig("message", "received_at")
  end

end
