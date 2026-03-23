# frozen_string_literal: true

require_relative "../test_helper"

class CompactPolicyClassifierTest < AceCompressorTestCase
  def setup
    super
    @classifier = Ace::Compressor::Atoms::CompactPolicyClassifier.new
  end

  def test_classifies_readme_with_narrative_headings_as_narrative_heavy
    blocks = [
      {type: :heading, level: 1, text: "Overview"},
      {type: :text, text: "Agents can run commands and work with files."},
      {type: :heading, level: 2, text: "Core Principles"},
      {type: :text, text: "Teams should preserve clear CLI boundaries."}
    ]

    policy = @classifier.call(source: "README.md", blocks: blocks)

    assert_equal "narrative-heavy", policy["class"]
    assert_equal "aggressive_compact", policy["action"]
  end

  def test_classifies_ambiguous_notes_as_unknown
    blocks = [
      {type: :heading, level: 1, text: "Scratchpad"},
      {type: :text, text: "alpha beta gamma"},
      {type: :list, ordered: false, items: ["todo one", "todo two", "todo three"]}
    ]

    policy = @classifier.call(source: "docs/custom-notes.md", blocks: blocks)

    assert_equal "unknown", policy["class"]
    assert_equal "conservative_compact", policy["action"]
  end

  def test_classifies_mixed_doc_for_compact_with_exact_rule_sections
    blocks = [
      {type: :heading, level: 1, text: "Overview"},
      {type: :text, text: "This workflow explains how teams collaborate."},
      {type: :heading, level: 2, text: "Policy"},
      {type: :text, text: "Teams must not remove safety checks."},
      {type: :list, ordered: false, items: ["Only run verified commands"]}
    ]

    policy = @classifier.call(source: "docs/blueprint.md", blocks: blocks)

    assert_equal "mixed", policy["class"]
    assert_equal "compact_with_exact_rule_sections", policy["action"]
  end

  def test_classifies_rule_heavy_doc_for_refusal
    blocks = [
      {type: :heading, level: 1, text: "Policy Decisions"},
      {type: :text, text: "All workflows must be self-contained."},
      {type: :heading, level: 2, text: "Impact"},
      {type: :text, text: "Agents should never load external templates."},
      {type: :text, text: "Commands must include explicit evidence on failure."},
      {type: :list, ordered: false, items: ["Only allow approved file paths"]}
    ]

    policy = @classifier.call(source: "docs/decisions.md", blocks: blocks)

    assert_equal "rule-heavy", policy["class"]
    assert_equal "refuse_compact", policy["action"]
  end
end
