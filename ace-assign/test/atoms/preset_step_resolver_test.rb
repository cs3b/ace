# frozen_string_literal: true

require_relative "../test_helper"

class PresetStepResolverTest < AceAssignTestCase
  def sample_preset
    {
      "name" => "sample",
      "steps" => [
        {"name" => "review-valid-1", "instructions" => "Valid"},
        {"name" => "review-fit-1", "instructions" => "Fit"},
        {"name" => "release", "instructions" => "Release"}
      ]
    }
  end

  def test_find_step_matches_exact_name_first
    step = Ace::Assign::Atoms::PresetStepResolver.find_step(sample_preset, "review-fit-1")

    assert_equal "review-fit-1", step["name"]
  end

  def test_find_step_matches_base_name
    step = Ace::Assign::Atoms::PresetStepResolver.find_step(sample_preset, "review-fit")

    assert_equal "review-fit-1", step["name"]
  end

  def test_find_step_raises_for_unknown_name
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::Atoms::PresetStepResolver.find_step(sample_preset, "unknown")
    end

    assert_includes error.message, "Step 'unknown' not found"
  end

  def test_find_step_raises_clear_error_when_preset_has_no_steps
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::Atoms::PresetStepResolver.find_step({"name" => "empty"}, "review-fit")
    end

    assert_includes error.message, "has no steps defined"
  end

  def test_next_iteration_name_increments_from_existing_names
    next_name = Ace::Assign::Atoms::PresetStepResolver.next_iteration_name(
      "review-fit",
      ["review-fit-1", "review-fit-2", "release"]
    )

    assert_equal "review-fit-3", next_name
  end

  def test_next_iteration_name_starts_at_one
    next_name = Ace::Assign::Atoms::PresetStepResolver.next_iteration_name("review-fit", ["release"])

    assert_equal "review-fit-1", next_name
  end
end
