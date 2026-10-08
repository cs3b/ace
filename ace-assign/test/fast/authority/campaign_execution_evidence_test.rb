# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/endcap"

class CampaignExecutionEvidenceTest < AceAssignTestCase
  def setup
    super
    @owner = Ace::Assign::Authority::Endcap.allocate
    @params = {"mapping_id" => "child-map", "assignment_id" => "child", "attempt_id" => "attempt"}
    @row = {"canonical_state" => "succeeded", "reservation_release_event_id" => "release",
      "terminal_event_id" => "terminal", "definition_digest" => "definition", "original_binding_digest" => "binding"}
    @execution = {"phase" => "collection", "head" => "head"}
    definition = Struct.new(:campaign_execution).new(@execution)
    row = @row
    launch = Object.new
    launch.define_singleton_method(:completion_terminal!) { |**| row }
    launch.define_singleton_method(:preview_attempt_definition!) { |**| definition }
    @prefixes = []
    prefixes = @prefixes
    result = {"result_id" => "result", "receipt_digest" => "digest", "binding" => {"head" => "head", "candidate_generation" => 1},
      "receipt" => {"verdict" => "succeeded", "artifacts" => [{"path" => "import", "sha256" => "sha"}]}}
    result["artifacts"] = result.fetch("receipt").fetch("artifacts")
    @terminal_receipt = result.fetch("receipt").dup
    terminal_receipt = @terminal_receipt
    launch.define_singleton_method(:preview_attempt_events!) { |commit:, **|
      prefixes << commit
      [{"type" => "result_submitted", "payload" => result},
        {"type" => "receipt_accepted", "digest" => "terminal", "payload" => {"receipt" => terminal_receipt}}]
    }
    @owner.instance_variable_set(:@launch, launch)
    @owner.define_singleton_method(:retained_candidate) { |*| {"head" => "head", "candidate_generation" => 1} }
    @owner.define_singleton_method(:exact_candidate!) { |candidate, _| candidate }
    @owner.define_singleton_method(:retained_origin) { |*| {} }
    @owner.define_singleton_method(:verified_result) { |*arguments, **|
      prefixes << arguments.last
      result
    }
    @owner.define_singleton_method(:approved_review!) { |*arguments, commit:|
      prefixes << commit
      {"review_receipt" => {"artifacts" => result.fetch("artifacts")}}
    }
    @owner.define_singleton_method(:campaign_finished_result!) { |commit:, **| prefixes << commit }
    @owner.define_singleton_method(:result_context) { |_| {} }
    @journal = Object.new
    @journal.define_singleton_method(:canonical_event_inventory!) { |**|
      {"introductions" => {"child" => {"terminal" => "accepted-prefix"}}}
    }
    @expected = @execution.merge(@params.slice("assignment_id", "attempt_id"),
      "definition_digest" => "definition", "binding_digest" => "binding")
  end

  def consume(expected: @expected, &block)
    @owner.with_campaign_execution_evidence!(journal: @journal, commit: "later-prefix", params: @params,
      map: {}, receipt_digest: "digest", execution_binding: expected, &block)
  end

  def test_original_prefix_raw_reader_and_bounded_callback_lifetime
    reads = []
    canonical = Object.new
    canonical.define_singleton_method(:read) { |ref, commit:, **| reads << [ref, commit]; "retained bytes" }
    escaped = nil
    Ace::Assign::Molecules::CanonicalEvidence.stub(:new, canonical) do
      consume do |proof, reader|
        assert proof.frozen?
        assert proof.fetch("execution_binding").frozen?
        assert proof.fetch("artifacts").first.frozen?
        assert_equal "accepted-prefix", proof.fetch("journal_commit")
        assert_equal "retained bytes", reader.call(proof.fetch("artifacts").first)
        assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reader.call({"path" => "foreign", "sha256" => "sha"}) }
        escaped = reader
      end
    end
    assert_equal ["accepted-prefix"], @prefixes.uniq
    assert_equal [[{"ref" => "import", "sha256" => "sha"}, "accepted-prefix"]], reads
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { escaped.call({"path" => "import", "sha256" => "sha"}) }
  end

  def test_unsettled_and_substituted_original_binding_refuse
    @row["reservation_release_event_id"] = nil
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { consume { flunk } }
    @row["reservation_release_event_id"] = "release"
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { consume(expected: @expected.merge("binding_digest" => "other")) { flunk } }
  end

  def test_callback_failure_is_not_mislabeled_as_authority_refusal
    expected = ArgumentError.new("consumer failure")
    error = assert_raises(ArgumentError) { consume { raise expected } }
    assert_same expected, error
  end

  def test_an_earlier_submitted_receipt_is_not_the_accepted_terminal_result
    @terminal_receipt["verdict"] = "failed"
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { consume { flunk } }
  end
end
