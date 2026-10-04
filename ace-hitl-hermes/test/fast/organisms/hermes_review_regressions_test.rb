# frozen_string_literal: true

require "test_helper"
require "json"

# Regression tests for the PR#336 review findings (codex astra high,
# session review-8wq2uw): each test asserts the CORRECTED behavior of a
# probe that reproduced the reported defect, plus schema <-> Ruby parity
# for the shipped JSON Schema asset.
class HermesReviewRegressionsTest < AceHermesTestCase
  def test_publish_rejects_envelopes_exceeding_the_byte_gate
    Dir.mktmpdir("hermes-publish-regression") do |folder|
      box = build_box(folder)
      error = assert_raises(Ace::Hitl::Hermes::InvalidMessageError) do
        box.publish(kind: :answer, id: "probe1", body: "a" * 65_536, sender: "captain",
          timestamp: "2026-09-24T10:00:00Z")
      end
      assert_match(/size bound/, error.message)
      # Fail-closed at the producer: nothing reached the folder, so the
      # message can never be terminally quarantined by its own poll.
      assert_empty pollable_files(folder)
    end
  end

  def test_poll_quarantines_a_symlink_instead_of_following_it
    Dir.mktmpdir("hermes-symlink-regression") do |folder|
      box = build_box(folder)
      box.publish(kind: :answer, id: "probe1", body: "answer", sender: "captain",
        timestamp: "2026-09-24T10:00:00Z")
      quarantined = Ace::Hitl::Hermes::Molecules::HermesQuarantine.move(
        folder, File.join(folder, "probe1.json"), reason: "retry_exhausted"
      )
      File.symlink(quarantined, File.join(folder, "probe1.json"))

      result = box.poll
      assert_empty result.messages
      assert_equal 1, result.quarantined.length
      assert_match(/symlink/, result.quarantined.first.reason)
    end
  end

  # The shipped schema asset and the Ruby exact-field/strip checks must
  # accept and reject the same envelopes (review 8wq2ztu1 on PR#336).
  def test_schema_and_ruby_validation_agree_on_shared_fixtures
    fixtures = [
      ["valid answer", valid_answer, true],
      ["valid question", valid_question, true],
      ["answer carrying question fields", valid_answer.merge("question" => "go?", "created_at" => STAMP), false],
      ["question carrying answer fields", valid_question.merge("answer" => "yes", "received_at" => STAMP), false],
      ["whitespace-only answer body", valid_answer.merge("answer" => "   "), false],
      ["whitespace-only question body", valid_question.merge("question" => "\t"), false]
    ]
    schema = JSON.parse(File.read(Ace::Hitl::Hermes::Molecules::HermesContract.schema_asset_path))

    fixtures.each do |name, envelope, expected|
      schema_result = draft07_subset_valid?(envelope, schema)
      ruby_result = begin
        Ace::Hitl::Hermes::Molecules::HermesMessage.from_hash(envelope, filename_id: envelope["id"])
        true
      rescue Ace::Hitl::Hermes::Error
        false
      end
      assert_equal expected, schema_result, "schema verdict for #{name}"
      assert_equal expected, ruby_result, "ruby verdict for #{name}"
      assert_equal schema_result, ruby_result, "parity for #{name}"
    end
  end

  private

  STAMP = "2026-09-24T10:00:00Z"

  def build_box(folder)
    channel = Ace::Hitl::Hermes::Molecules::HermesChannels::Channel.new(name: "inbox", machine: "lab", folder: folder)
    Ace::Hitl::Hermes::Organisms::HermesBox.new(channel: channel,
      answer_authorizer: ->(id) { {"id" => id, "kind" => "text", "sensitive" => false} })
  end

  def pollable_files(folder)
    Dir.children(folder).sort
  end

  def valid_answer
    {"schema" => "ace.hitl.hermes.message/v1", "id" => "q1", "kind" => "answer", "sender" => "captain",
      "answer" => "yes", "received_at" => STAMP}
  end

  def valid_question
    {"schema" => "ace.hitl.hermes.message/v1", "id" => "q1", "kind" => "question", "sender" => "captain",
      "question" => "go?", "created_at" => STAMP}
  end

  # Minimal draft-07 subset covering exactly the keywords the shipped
  # schema uses: type, required, const, enum, properties,
  # additionalProperties: false, pattern, minLength, oneOf, and
  # not/anyOf/required exclusions.
  def draft07_subset_valid?(doc, schema, root = schema)
    return false if schema["const"] && doc != schema["const"]
    return false if schema["enum"] && !schema["enum"].include?(doc)
    return false if schema["type"] == "object" && !doc.is_a?(Hash)
    return false if schema["type"] == "string" && !doc.is_a?(String)
    return false if schema["type"] == "string" && schema["pattern"] && doc !~ /#{schema["pattern"]}/
    return false if schema["type"] == "string" && schema["minLength"] && doc.length < schema["minLength"]

    if doc.is_a?(Hash)
      (schema["required"] || []).each do |key|
        return false unless doc.key?(key)
      end
      (schema["properties"] || {}).each do |key, sub|
        return false if doc.key?(key) && !draft07_subset_valid?(doc[key], sub, root)
      end
      if schema["additionalProperties"] == false
        undeclared = doc.keys - (schema["properties"] || {}).keys
        return false unless undeclared.empty?
      end
    end
    # JSON Schema keywords apply independently: oneOf adds an
    # exactly-one constraint on top of everything above, not/anyOf
    # compose the same way.
    return false if schema.key?("oneOf") && !one_of_valid?(doc, schema["oneOf"], root)
    return false if schema.key?("anyOf") && !any_of_valid?(doc, schema, root)
    return false if schema.key?("not") && draft07_subset_valid?(doc, schema["not"], root)

    true
  end

  def one_of_valid?(doc, branches, root)
    branches.count { |branch| draft07_subset_valid?(doc, branch, root) } == 1
  end

  def any_of_valid?(doc, schema, root)
    schema["anyOf"].any? { |sub| draft07_subset_valid?(doc, sub, root) }
  end
end
