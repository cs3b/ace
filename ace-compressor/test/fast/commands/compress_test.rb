# frozen_string_literal: true

require "ace/support/cli"
require "tmpdir"
require "fileutils"
require_relative "../../test_helper"

class CompressCommandTest < AceCompressorTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_cmd")
    @previous_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.rm_rf(@tmp)
    super
  end

  def invoke(args)
    stdout, stderr = capture_io do
      @result = Ace::Compressor::CLI.start(args)
    rescue SystemExit => e
      @result = e.status
    rescue Ace::Support::Cli::Error => e
      warn e.message
      @result = e.exit_code
    end

    {stdout: stdout, stderr: stderr, result: @result}
  end

  def test_success_on_single_file_exact_mode
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke([path, "--mode", "exact"])

    assert_equal "", result[:stderr]
    cache_path = result[:stdout].strip
    assert File.file?(cache_path), "Expected cache file to be written"
    output = File.read(cache_path)
    assert_includes output, "H|ContextPack/3|exact"
    assert_includes output, "FILE|vision.md"
    assert_includes output, "SEC|vision"
    assert_includes output, "SUMMARY|Agents can run CLI commands"
  end

  def test_supports_optional_compress_verb_prefix
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke(["compress", path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "H|ContextPack/3|exact"
    assert_includes result[:stdout], "FILE|vision.md"
  end

  def test_preset_input_resolves_and_compresses
    path = File.join(@tmp, "bundle-output.md")
    File.write(path, "# Bundled\n\nFrom preset")
    fake_resolver = Class.new do
      define_method(:initialize) { |_sources| nil }
      define_method(:call) { [{content_path: path, source_path: "project", source_kind: "preset"}] }
    end

    Ace::Compressor::Molecules::InputResolver.stub(:new, ->(*) { fake_resolver.new(nil) }) do
      result = invoke(["project", "--mode", "exact", "--format", "stdio"])

      assert_equal "", result[:stderr]
      assert_includes result[:stdout], "H|ContextPack/3|exact"
      assert_includes result[:stdout], "FILE|project"
    end
  end

  def test_yaml_config_input_resolves_and_compresses
    path = File.join(@tmp, "config-output.md")
    File.write(path, "# Config\n\nFrom yaml")
    fake_resolver = Class.new do
      define_method(:initialize) { |_sources| nil }
      define_method(:call) { [{content_path: path, source_path: File.expand_path("./custom-context.yml"), source_kind: "bundle_config"}] }
    end

    Ace::Compressor::Molecules::InputResolver.stub(:new, ->(*) { fake_resolver.new(nil) }) do
      result = invoke(["./custom-context.yml", "--mode", "exact", "--format", "stdio"])

      assert_equal "", result[:stderr]
      assert_includes result[:stdout], "H|ContextPack/3|exact"
      assert_includes result[:stdout], "FILE|custom-context.yml"
    end
  end

  def test_success_on_single_file_agent_mode_with_stubbed_agent_compressor
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    fake = Class.new do
      attr_reader :ignored_paths

      def initialize(*)
        @ignored_paths = []
      end

      def resolve_sources
        [File.expand_path("vision.md")]
      end

      def compress_sources(_sources)
        [
          "H|ContextPack/3|agent",
          "FILE|vision.md",
          "SUMMARY|Compressed by agent spike",
          "LIST|validated_concepts|[prompt_composed_flow,structured_input_contract,validator_visible_outcome]"
        ].join("\n")
      end
    end

    Ace::Compressor::Organisms::AgentCompressor.stub(:new, ->(*) { fake.new }) do
      result = invoke([path, "--mode", "agent", "--format", "stdio"])
      assert_equal "", result[:stderr]
      assert_includes result[:stdout], "H|ContextPack/3|agent"
      assert_includes result[:stdout], "FILE|vision.md"
    end
  end

  def test_success_on_single_file_compact_mode_emits_aggressive_policy
    path = File.join(@tmp, "vision.md")
    File.write(path, <<~MD)
      # Vision

      ## Overview
      Agents and developers collaborate through shared command-line workflows.

      ## Core Principles
      The process should remain deterministic, transparent, and inspectable.
      Teams must not remove safety constraints.

      ## Why ACE Exists
      Narrative-heavy docs contain repeated framing text that compact mode can trim.
      Narrative-heavy docs contain repeated framing text that compact mode can trim.
    MD

    exact = invoke([path, "--mode", "exact", "--format", "stdio"])
    compact = invoke([path, "--mode", "compact", "--format", "stdio"])

    assert_equal "", compact[:stderr]
    assert_includes compact[:stdout], "H|ContextPack/3|compact"
    assert_includes compact[:stdout], "POLICY|class=narrative-heavy|action=aggressive_compact"
    assert_operator compact[:stdout].bytesize, :<, exact[:stdout].bytesize
  end

  def test_compact_mode_uses_conservative_policy_for_unknown_class
    path = File.join(@tmp, "custom-notes.md")
    File.write(path, "# Scratchpad\n\nalpha beta gamma\n\n- todo one\n- todo two\n")

    result = invoke([path, "--mode", "compact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "POLICY|class=unknown|action=conservative_compact"
  end

  def test_compact_mode_mixed_single_source_emits_fidelity_pass
    path = File.join(@tmp, "blueprint.md")
    File.write(path, <<~MD)
      # Overview

      This document explains repository structure and contributor workflow.

      ## Policy
      Teams must not edit archived retrospectives without explicit approval.
      Only use .ace-local for generated local artifacts.
    MD

    result = invoke([path, "--mode", "compact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "POLICY|class=mixed|action=compact_with_exact_rule_sections"
    assert_includes result[:stdout], "FIDELITY|source=blueprint.md|status=pass|check=exact_rule_sections"
    refute_includes result[:stdout], "REFUSAL|"
  end

  def test_compact_mode_mixed_sources_preserves_safe_output_and_returns_non_zero_on_refusal
    safe = File.join(@tmp, "vision.md")
    unsafe = File.join(@tmp, "decisions.md")

    File.write(safe, <<~MD)
      # Vision

      ## Overview
      Agents and developers collaborate through shared command-line workflows.

      ## Core Principles
      The process should remain deterministic and inspectable.
    MD

    File.write(unsafe, <<~MD)
      # Policy Decisions

      All workflows must be self-contained.

      ## Impact
      Agents should never skip required validation.

      ## Requirements
      Commands must include exact error evidence.

      Only use approved paths for temporary files.
    MD

    result = invoke([safe, unsafe, "--mode", "compact", "--format", "stdio"])

    assert_equal 1, result[:result]
    assert_includes result[:stdout], "POLICY|class=narrative-heavy|action=aggressive_compact"
    assert_includes result[:stdout], "FILE|vision.md"
    assert_includes result[:stdout], "REFUSAL|source=decisions.md|reason=rule-heavy|failed_check=compact_preflight"
    assert_includes result[:stdout], "GUIDANCE|source=decisions.md|retry_with=--mode exact"
    assert_includes result[:stderr], "One or more sources were refused in compact mode"
  end

  def test_error_on_unsupported_mode_lists_agent
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke([path, "--mode", "invalid"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Unsupported mode 'invalid'"
    assert_includes result[:stderr], "--mode agent"
  end

  def test_agent_mode_returns_output_without_refusal_guidance
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    fake = Class.new do
      attr_reader :ignored_paths

      def initialize(*)
        @ignored_paths = []
      end

      def resolve_sources
        [File.expand_path("vision.md")]
      end

      def compress_sources(_sources)
        [
          "H|ContextPack/3|agent",
          "FILE|vision.md",
          "RULE|Agents can run CLI commands"
        ].join("\n")
      end
    end

    Ace::Compressor::Organisms::AgentCompressor.stub(:new, ->(*) { fake.new }) do
      result = invoke([path, "--mode", "agent", "--format", "stdio"])

      assert_equal "", result[:stderr]
      assert_includes result[:stdout], "H|ContextPack/3|agent"
      assert_includes result[:stdout], "FILE|vision.md"
      refute_includes result[:stdout], "REFUSAL|"
      refute_includes result[:stdout], "GUIDANCE|"
    end
  end

  def test_success_on_multiple_files_exact_mode
    second = File.join(@tmp, "zzz.md")
    first = File.join(@tmp, "aaa.md")
    File.write(second, "# Second\n\nB")
    File.write(first, "# First\n\nA")

    result = invoke([second, first, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "H|ContextPack/3|exact"
    first_file_index = result[:stdout].index("FILE|aaa.md")
    second_file_index = result[:stdout].index("FILE|zzz.md")
    first_line_index = result[:stdout].index("SEC|first")
    second_line_index = result[:stdout].index("SEC|second")
    assert first_file_index
    assert second_file_index
    assert first_line_index
    assert second_line_index
    assert_operator first_file_index, :<, first_line_index
    assert_operator first_line_index, :<, second_file_index
    assert_operator second_file_index, :<, second_line_index
    assert_operator first_line_index, :<, second_line_index
  end

  def test_per_source_scope_emits_one_output_path_per_source_in_input_order
    second = File.join(@tmp, "zzz.md")
    first = File.join(@tmp, "aaa.md")
    File.write(second, "# Second\n\nB")
    File.write(first, "# First\n\nA")

    result = invoke([second, first, "--mode", "exact", "--source-scope", "per-source", "--format", "path"])

    assert_equal "", result[:stderr]
    paths = result[:stdout].lines.map(&:strip).reject(&:empty?)
    assert_equal 2, paths.size
    assert File.file?(paths[0]), "Expected first per-source output to exist"
    assert File.file?(paths[1]), "Expected second per-source output to exist"
    assert_includes File.basename(paths[0]), "zzz."
    assert_includes File.basename(paths[1]), "aaa."
  end

  def test_error_on_invalid_source_scope_lists_allowed_values
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke([path, "--mode", "exact", "--source-scope", "invalid"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Unsupported source scope 'invalid'"
    assert_includes result[:stderr], "--source-scope merged or --source-scope per-source"
  end

  def test_per_source_mode_requires_directory_output_for_multiple_inputs
    first = File.join(@tmp, "first.md")
    second = File.join(@tmp, "second.md")
    File.write(first, "# First\n\nA")
    File.write(second, "# Second\n\nB")
    target = File.join(@tmp, "single-output.pack")

    result = invoke([first, second, "--mode", "exact", "--source-scope", "per-source", "--output", target])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Per-source mode with multiple inputs requires --output to be a directory path"
  end

  def test_prose_example_line_emits_example_record
    path = File.join(@tmp, "example.md")
    File.write(path, "# How It Works\n\n**Example: `ace-git-commit`**\n")

    result = invoke([path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "EXAMPLE|tool=ace-git-commit"
    refute_includes result[:stdout], "FACT|Example: ace-git-commit"
  end

  def test_duplicate_explicit_paths_are_collapsed
    path = File.join(@tmp, "dup.md")
    File.write(path, "# Title\n\nOne fact")

    result = invoke([path, path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_equal 1, result[:stdout].scan("FILE|dup.md").size
    assert_equal 1, result[:stdout].scan("SEC|title").size
  end

  def test_directory_input_collects_supported_sources
    docs = File.join(@tmp, "docs")
    FileUtils.mkdir_p(docs)
    File.write(File.join(docs, "a.md"), "# A\n\nfrom a")
    File.write(File.join(docs, "b.txt"), "# B\n\nfrom b")

    result = invoke([docs, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "FILE|docs/a.md"
    assert_includes result[:stdout], "FILE|docs/b.txt"
    assert_includes result[:stdout], "SEC|a"
    assert_includes result[:stdout], "SEC|b"
  end

  def test_error_when_directory_has_no_supported_files
    empty = File.join(@tmp, "empty")
    FileUtils.mkdir_p(empty)
    File.binwrite(File.join(empty, "image.bin"), "\x00\x01")

    result = invoke([empty, "--mode", "exact"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Directory has no supported markdown/text sources"
  end

  def test_error_on_explicit_binary_file
    binary = File.join(@tmp, "sample.bin")
    File.binwrite(binary, "\x00\x01\x02\x03")

    result = invoke([binary, "--mode", "exact"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Binary input is not supported in exact mode"
  end

  def test_error_on_explicit_binary_file_in_compact_mode
    binary = File.join(@tmp, "sample.bin")
    File.binwrite(binary, "\x00\x01\x02\x03")

    result = invoke([binary, "--mode", "compact"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Binary input is not supported in compact mode"
  end

  def test_verbose_reports_ignored_files_from_directory
    docs = File.join(@tmp, "docs")
    FileUtils.mkdir_p(docs)
    File.write(File.join(docs, "a.md"), "# A\n\nfrom a")
    File.binwrite(File.join(docs, "image.dat"), "\x00\x01")

    result = invoke([docs, "--mode", "exact", "--verbose"])

    assert_includes result[:stderr], "Ignoring unsupported file:"
    assert_includes result[:stderr], "image.dat"
  end

  def test_binary_md_file_in_directory_is_skipped_not_processed
    docs = File.join(@tmp, "docs")
    FileUtils.mkdir_p(docs)
    File.write(File.join(docs, "valid.md"), "# Valid\n\nContent here")
    File.binwrite(File.join(docs, "corrupt.md"), "\x00\x01\x02binary content")

    result = invoke([docs, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "SEC|valid"
    assert_equal 1, result[:stdout].scan(/^FILE\|/).size
  end

  def test_error_when_argument_missing
    result = invoke(["--mode", "exact"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Missing input path"
  end

  def test_error_when_file_missing
    result = invoke([File.join(@tmp, "missing.md"), "--mode", "exact"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Input source not found"
  end

  def test_error_when_file_empty
    path = File.join(@tmp, "empty.md")
    File.write(path, "")

    result = invoke([path, "--mode", "exact"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Exact mode requires content"
  end

  def test_headings_only_file_emits_valid_pack
    path = File.join(@tmp, "headings_only.md")
    File.write(path, "# A\n\n## B\n")

    result = invoke([path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "H|ContextPack/3|exact"
    assert_includes result[:stdout], "SEC|a"
    assert_includes result[:stdout], "SEC|b"
  end

  def test_frontmatter_only_plus_heading_works
    path = File.join(@tmp, "frontmatter.md")
    File.write(path, "---\nname: x\n---\n\n# Heading\n")

    result = invoke([path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "SEC|heading"
  end

  def test_modality_and_numeric_facts_are_preserved
    path = File.join(@tmp, "policy.md")
    File.write(path, "# Policy\n\nTeams must not remove controls and only allow 42 retries.")

    result = invoke([path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "RULE|Teams must not remove controls and only allow 42 retries."
  end

  def test_image_only_reference_emits_unresolved_marker_without_failure
    path = File.join(@tmp, "chart.md")
    File.write(path, "# Chart\n\n![Utilization](utilization.png)")

    result = invoke([path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "U|image-only|![Utilization](utilization.png)"
    assert_includes result[:stdout], "utilization.png"
  end

  def test_table_content_is_not_silently_dropped
    path = File.join(@tmp, "table.md")
    File.write(path, "# Capacity\n\n| Service | Limit |\n|---|---|\n| api | 100 |\n")

    result = invoke([path, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "TABLE|cols=Service,Limit|rows=api>100"
    assert_includes result[:stdout], "Service"
    assert_includes result[:stdout], "100"
  end

  def test_compact_mode_emits_table_strategy_and_loss_metadata
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

    result = invoke([path, "--mode", "compact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "TABLE|id=vision_t1|strategy=summarize_with_loss|cols=Tier,QPS|rows=free>10"
    assert_includes result[:stdout], "LOSS|kind=table|target=vision_t1|strategy=summarize_with_loss"
    assert_includes result[:stdout], "original_rows=7"
    assert_includes result[:stdout], "retained_rows=1"
  end

  def test_compact_mode_collapses_duplicate_examples_to_refs
    first = File.join(@tmp, "first.md")
    second = File.join(@tmp, "second.md")
    content = <<~MD
      # How It Works

      ## Example: ace-git-commit
      ```bash
      ace-git-commit -i "fix auth bug"
      ```
    MD
    File.write(first, content)
    File.write(second, content)

    result = invoke([first, second, "--mode", "compact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_equal 1, result[:stdout].scan("EXAMPLE|tool=ace-git-commit").size
    assert_includes result[:stdout], "EXAMPLE_REF|tool=ace-git-commit|source=second.md|original_source=first.md|reason=duplicate_example"
    assert_includes result[:stdout], "LOSS|kind=example|target=ace-git-commit|strategy=reference"
  end

  def test_format_stats_reports_cache_hit_on_second_run
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands\n\nMore context\n\nFinal note")

    first = invoke([path, "--mode", "exact", "--format", "stats"])
    second = invoke([path, "--mode", "exact", "--format", "stats"])

    assert_includes first[:stdout], "Cache:    miss"
    assert_includes first[:stdout], "Original:"
    assert_includes first[:stdout], "Packed:"
    assert_includes first[:stdout], "Change:"
    assert_includes second[:stdout], "Cache:    hit"
  end

  def test_format_stats_reports_real_compression_for_semantic_mode
    path = File.join(@tmp, "vision.md")
    body = [
      "# Vision",
      "",
      "This document provides a high-level summary of how agents and developers can cooperate across long-running initiatives and iterative deliveries.",
      "",
      *(0...80).map { |index| "- Context bloat check #{index}" },
      "",
      "You must run commands with clear boundaries. Never call internal APIs directly."
    ].join("\n")

    File.write(
      path,
      body
    )

    result = invoke([path, "--mode", "exact", "--format", "stats"])

    assert_match(/Change:\s+-\d+\.\d% bytes, -\d+\.\d% lines/, result[:stdout])
  end

  def test_format_stats_aggregates_multiple_source_totals
    first = File.join(@tmp, "a.md")
    second = File.join(@tmp, "b.md")
    File.write(first, "# A\n\nalpha\n")
    File.write(second, "# B\n\nbeta\n")

    result = invoke([first, second, "--mode", "exact", "--format", "stats"])

    assert_includes result[:stdout], "Sources:  2 files"
    assert_includes result[:stdout], "Original:"
    assert_includes result[:stdout], "Packed:"
  end

  def test_output_file_writes_exact_target
    path = File.join(@tmp, "vision.md")
    target = File.join(@tmp, "exports", "vision.pack")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke([path, "--mode", "exact", "--output", target])

    assert_equal "#{target}\n", result[:stdout]
    assert File.file?(target), "Expected custom output file to be written"
  end

  def test_output_directory_derives_hashed_filename
    path = File.join(@tmp, "vision.md")
    output_dir = File.join(@tmp, "exports") + "/"
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke([path, "--mode", "exact", "--output", output_dir])

    output_path = result[:stdout].strip
    assert_includes output_path, File.join(@tmp, "exports")
    assert_match(/vision\.[0-9a-f]{12}\.exact\.pack\z/, output_path)
    assert File.file?(output_path), "Expected derived output path to exist"
  end

  def test_format_stdio_prints_content_even_with_custom_output
    path = File.join(@tmp, "vision.md")
    target = File.join(@tmp, "exports", "vision.pack")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke([path, "--mode", "exact", "--output", target, "--format", "stdio"])

    assert_includes result[:stdout], "H|ContextPack/3|exact"
    assert File.file?(target), "Expected custom output file to be written"
  end

  def test_compact_format_is_smaller_than_previous_verbose_shape_for_single_file
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands\n\nMore context\n\nFinal note")

    result = invoke([path, "--mode", "exact", "--format", "stdio"])
    output = result[:stdout]
    legacy = [
      "H|schema=ContextPack/1|mode=exact|source=#{path}|file_count=1",
      "M|id=sec:1|level=1|title=Vision|src=#{path}",
      "F|id=fact:1|sec=sec:1|text=Agents can run CLI commands|src=#{path}",
      "F|id=fact:2|sec=sec:1|text=More context|src=#{path}",
      "F|id=fact:3|sec=sec:1|text=Final note|src=#{path}"
    ].join("\n")

    assert_operator output.bytesize, :<, legacy.bytesize
  end

  def test_error_when_format_is_invalid
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands")

    result = invoke([path, "--format", "json"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Unsupported format 'json'"
  end

  def test_benchmark_command_prints_comparison_table
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands.\n")

    result = invoke(["benchmark", path, "--modes", "exact,compact", "--format", "table"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "Source"
    assert_includes result[:stdout], "Mode"
    assert_includes result[:stdout], "vision.md"
    assert_includes result[:stdout], "exact"
    assert_includes result[:stdout], "compact"
  end
end
