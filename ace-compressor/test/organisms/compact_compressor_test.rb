# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../test_helper"

class CompactCompressorTest < AceCompressorTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_compact")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_narrative_heavy_file_emits_aggressive_policy_and_smaller_output
    path = File.join(@tmp, "vision.md")
    File.write(path, <<~MD)
      # Vision

      ## Overview
      Agents and developers collaborate across long-running tasks with shared CLI tooling.

      ## Core Principles
      The workflow should remain transparent, deterministic, and easy to inspect.
      Teams must not remove safety boundaries when automating execution.

      ## Why ACE Exists
      Narrative-heavy docs carry repeated framing that compact mode should trim.
      Narrative-heavy docs carry repeated framing that compact mode should trim.
      Narrative-heavy docs carry repeated framing that compact mode should trim.
    MD

    exact = Ace::Compressor::Organisms::ExactCompressor.new([path]).call
    compact = Ace::Compressor::Organisms::CompactCompressor.new([path]).call

    assert_includes compact, "H|ContextPack/3|compact"
    assert_includes compact, "POLICY|class=narrative-heavy|action=aggressive_compact"
    assert_match(/must not remove safety boundaries/i, compact)
    assert_operator compact.bytesize, :<, exact.bytesize
  end

  def test_unknown_file_emits_conservative_policy
    path = File.join(@tmp, "custom-notes.md")
    File.write(path, <<~MD)
      # Scratchpad

      alpha beta gamma

      - todo one
      - todo two
      - todo three
    MD

    compact = Ace::Compressor::Organisms::CompactCompressor.new([path]).call

    assert_includes compact, "POLICY|class=unknown|action=conservative_compact"
  end

  def test_mixed_doc_emits_fidelity_pass_and_preserves_rule_records
    path = File.join(@tmp, "blueprint.md")
    File.write(path, <<~MD)
      # Overview

      This guide explains repository structure for contributors.

      ## Policy
      Teams must not modify read-only ADR files unless explicitly asked.

      Only use task-scoped commits for focused delivery.
    MD

    compact = Ace::Compressor::Organisms::CompactCompressor.new([path]).call

    assert_includes compact, "POLICY|class=mixed|action=compact_with_exact_rule_sections"
    assert_match(/FIDELITY\|source=.*blueprint\.md\|status=pass\|check=exact_rule_sections/, compact)
    assert_includes compact, "RULE|Teams must not modify read-only ADR files unless explicitly asked."
    assert_includes compact, "RULE|Only use task-scoped commits for focused delivery."
  end

  def test_rule_heavy_doc_emits_refusal_and_guidance
    path = File.join(@tmp, "decisions.md")
    File.write(path, <<~MD)
      # Policy Decisions

      All workflows must be self-contained.

      ## Impact
      Agents should never skip required validation.

      ## Requirements
      Commands must include exact error evidence.

      Only use approved paths for temporary files.
    MD

    compressor = Ace::Compressor::Organisms::CompactCompressor.new([path])
    compact = compressor.call

    assert_includes compact, "POLICY|class=rule-heavy|action=refuse_compact"
    assert_match(/FIDELITY\|source=.*decisions\.md\|status=fail\|check=compact_preflight/, compact)
    assert_match(/REFUSAL\|source=.*decisions\.md\|reason=rule-heavy\|failed_check=compact_preflight/, compact)
    assert_match(/GUIDANCE\|source=.*decisions\.md\|retry_with=--mode exact/, compact)
    assert_equal 1, compressor.refused_sources.size
  end

  def test_table_records_emit_explicit_strategy_and_loss_metadata
    path = File.join(@tmp, "vision.md")
    File.write(path, <<~MD)
      # Vision

      ## Capacity
      | Tier | QPS |
      |---|---|
      | free | 10 |
      | team | 50 |
      | pro | 100 |
      | scale | 250 |
      | enterprise | 500 |
      | burst | 800 |
      | max | 1000 |
    MD

    compact = Ace::Compressor::Organisms::CompactCompressor.new([path]).call

    assert_includes compact, "TABLE|id=vision_t1|strategy=summarize_with_loss|cols=Tier,QPS|rows=free>10"
    assert_includes compact, "LOSS|kind=table|target=vision_t1|strategy=summarize_with_loss"
    assert_includes compact, "original_rows=7"
    assert_includes compact, "retained_rows=1"
    assert_includes compact, "dropped_rows=6"
    assert_includes compact, "details=data_rows_only"
  end

  def test_duplicate_examples_collapse_to_example_ref_with_loss_metadata
    first = File.join(@tmp, "first.md")
    second = File.join(@tmp, "second.md")

    example_body = <<~MD
      # How It Works

      ## Example: ace-git-commit
      ```bash
      ace-git-commit -i "fix auth bug"
      ```
    MD

    File.write(first, example_body)
    File.write(second, example_body)

    compact = Ace::Compressor::Organisms::CompactCompressor.new([first, second]).call

    assert_equal 1, compact.scan("EXAMPLE|tool=ace-git-commit").size
    assert_match(
      /EXAMPLE_REF\|tool=ace-git-commit\|source=.*second\.md\|original_source=.*first\.md\|reason=duplicate_example/,
      compact
    )
    assert_includes compact, "LOSS|kind=example|target=ace-git-commit|strategy=reference"
    assert_equal 1, compact.scan('CMD|ace-git-commit -i "fix auth bug"').size
  end

  def test_mimicry_required_examples_stay_explicit
    first = File.join(@tmp, "first.md")
    second = File.join(@tmp, "second.md")

    first_body = <<~MD
      # Output Contract
      Example output must match exactly for this command.

      ## Example: ace-git-commit
      ```bash
      ace-git-commit -i "fix auth bug"
      ```
    MD

    second_body = <<~MD
      # Output Contract
      Required format: follow exactly.

      ## Example: ace-git-commit
      ```bash
      ace-git-commit -i "fix auth bug"
      ```
    MD

    File.write(first, first_body)
    File.write(second, second_body)

    compact = Ace::Compressor::Organisms::CompactCompressor.new([first, second]).call

    assert_equal 2, compact.scan("EXAMPLE|tool=ace-git-commit").size
    refute_includes compact, "EXAMPLE_REF|tool=ace-git-commit"
  end
end
