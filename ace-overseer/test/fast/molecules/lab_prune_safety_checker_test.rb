# frozen_string_literal: true

require_relative "../../test_helper"

class LabPruneSafetyCheckerTest < AceOverseerTestCase
  class FakeLabClient
    def initialize(entry: nil, error: nil)
      @entry = entry
      @error = error
    end

    def work_entry(_work_id)
      raise @error if @error

      @entry
    end
  end

  def classification(client, proof: nil)
    Ace::Overseer::Molecules::LabPruneSafetyChecker.new.check(
      lab_client: client,
      work_id: "W321",
      preservation_proof: proof
    )
  end

  def preserved_proof
    Ace::Overseer::Models::PreservationProof.preserved(:accepted_ancestor)
  end

  def blocked_proof(reason = "not preserved")
    Ace::Overseer::Models::PreservationProof.blocked(reason)
  end

  def test_terminal_work_with_preservation_evidence_is_safe
    client = FakeLabClient.new(entry: {"id" => "W321", "state" => "completed"})

    classification = classification(client, proof: preserved_proof)

    assert classification.safe?
    assert_nil classification.reason
  end

  def test_active_work_blocks
    client = FakeLabClient.new(entry: {"id" => "W321", "state" => "running"})

    classification = classification(client, proof: preserved_proof)

    refute classification.safe?
    assert_includes classification.reason, "active writer"
  end

  def test_unknown_state_blocks
    client = FakeLabClient.new(entry: {"id" => "W321", "state" => "weird-state"})

    classification = classification(client, proof: preserved_proof)

    refute classification.safe?
    assert_includes classification.reason, "not a documented terminal state"
  end

  def test_missing_work_blocks
    client = FakeLabClient.new(entry: nil)

    classification = classification(client, proof: preserved_proof)

    refute classification.safe?
    assert_includes classification.reason, "missing state"
  end

  def test_unavailable_surface_blocks
    client = FakeLabClient.new(error: Ace::Overseer::Error.new("Lab runtime unavailable"))

    classification = classification(client, proof: preserved_proof)

    refute classification.safe?
    assert_includes classification.reason, "unavailable"
  end

  def test_missing_preservation_evidence_blocks_terminal_work
    client = FakeLabClient.new(entry: {"id" => "W321", "state" => "completed"})

    classification = classification(client, proof: nil)

    refute classification.safe?
    assert_includes classification.reason, "no preservation evidence"
  end

  def test_failed_preservation_proof_blocks
    client = FakeLabClient.new(entry: {"id" => "W321", "state" => "completed"})

    classification = classification(client, proof: blocked_proof("head not contained in base"))

    refute classification.safe?
    assert_includes classification.reason, "head not contained in base"
  end
end
