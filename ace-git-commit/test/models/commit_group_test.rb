# frozen_string_literal: true

require_relative "../test_helper"

class CommitGroupTest < TestCase
  def test_add_file_mutates_group
    group = Ace::GitCommit::Models::CommitGroup.new(
      scope_name: "docs",
      source: ".ace/git/commit.yml",
      config: {"model" => "glite"},
      files: ["a.md"]
    )

    group.add_file("b.md")

    assert_equal ["a.md", "b.md"], group.files
  end

  def test_signature_is_stable
    config_a = {"model" => "glite", "conventions" => {"format" => "simple"}}
    config_b = {"conventions" => {"format" => "simple"}, "model" => "glite"}

    sig_a = Ace::GitCommit::Models::CommitGroup.signature_for(config_a)
    sig_b = Ace::GitCommit::Models::CommitGroup.signature_for(config_b)

    assert_equal sig_a, sig_b
  end

  def test_signature_is_stable_with_nested_structures
    # Test that deeply nested configs produce stable signatures regardless of key order
    config_a = {
      "paths" => [{"glob" => "docs/**", "type_hint" => "docs"}, {"glob" => "lib/**", "type_hint" => "feat"}],
      "model" => "glite"
    }
    config_b = {
      "model" => "glite",
      "paths" => [{"type_hint" => "docs", "glob" => "docs/**"}, {"type_hint" => "feat", "glob" => "lib/**"}]
    }

    sig_a = Ace::GitCommit::Models::CommitGroup.signature_for(config_a)
    sig_b = Ace::GitCommit::Models::CommitGroup.signature_for(config_b)

    assert_equal sig_a, sig_b, "Signature should be stable regardless of hash key order"
  end

  def test_signature_differs_for_different_array_content
    # Arrays with different content should produce different signatures
    config_a = {"paths" => [{"glob" => "docs/**"}]}
    config_b = {"paths" => [{"glob" => "lib/**"}]}

    sig_a = Ace::GitCommit::Models::CommitGroup.signature_for(config_a)
    sig_b = Ace::GitCommit::Models::CommitGroup.signature_for(config_b)

    refute_equal sig_a, sig_b, "Different array content should produce different signatures"
  end

  def test_signature_differs_for_different_array_order
    # NOTE: Array order DOES matter for signatures - same elements in different order = different signature
    # This is intentional: [A, B] and [B, A] represent different path rule priorities
    config_a = {"paths" => [{"glob" => "docs/**"}, {"glob" => "lib/**"}]}
    config_b = {"paths" => [{"glob" => "lib/**"}, {"glob" => "docs/**"}]}

    sig_a = Ace::GitCommit::Models::CommitGroup.signature_for(config_a)
    sig_b = Ace::GitCommit::Models::CommitGroup.signature_for(config_b)

    refute_equal sig_a, sig_b, "Different array order should produce different signatures (order matters for path rules)"
  end
end
