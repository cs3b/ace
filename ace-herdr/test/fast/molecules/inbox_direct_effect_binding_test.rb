# frozen_string_literal: true
require "test_helper"
require "ace/herdr/molecules/inbox_direct_effect_binding"

class InboxDirectEffectBindingTest < Minitest::Test
  Binding = Ace::Herdr::Molecules::InboxDirectEffectBinding
  Error = Ace::Herdr::ValidationError
  def original
    {"project_id" => "project", "assignment_id" => "assignment", "mapping_id" => "mapping", "inbox_context_id" => "context"}
  end
  def build(selection: {"expected_claim_generation" => 0}, purpose: "deliver", original: self.original)
    Binding.build(purpose: purpose, event_id: "event", attempt_id: "attempt", key_generation: 1,
      original: original, selection: selection)
  end

  def test_original_tuple_is_part_of_exact_input_digest
    first = build
    assert_equal "ace.herdr.inbox-direct-effect/v2", first.fetch("schema")
    original.each_key do |key|
      changed = build(original: original.merge(key => "other"))
      refute_equal first.fetch("input_sha256"), changed.fetch("input_sha256")
      assert_raises(Error) { Binding.verify!(first.merge(key => "other"), key_generation: 1) }
    end
  end

  def test_no_missing_extra_or_malformed_original_selector_is_admitted
    [{}, original.merge("extra" => "permit"), original.merge("assignment_id" => ""),
      original.merge("mapping_id" => "mapping:other")].each do |value|
      assert_raises(Error) { build(original: value) }
    end
    assert_raises(Error) { Binding.verify!(build.merge("schema" => "ace.herdr.inbox-direct-effect/v1"), key_generation: 1) }
  end

  def test_reverse_native_ref_retains_its_existing_colon_rules
    selection = {"reverse" => {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => "ws:one", "pane" => "pane:one"},
      "payload_bytes" => 5, "payload_sha256" => "a" * 64}
    result = build(selection: selection, purpose: "enqueue")
    assert_equal selection, result.fetch("selection")
    assert_raises(Error) { Binding.verify!(result, key_generation: 2) }
  end
end
