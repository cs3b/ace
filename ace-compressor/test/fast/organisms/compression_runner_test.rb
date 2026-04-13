# frozen_string_literal: true

require "json"
require "tmpdir"
require "fileutils"
require_relative "../../test_helper"

class CompressionRunnerTest < AceCompressorTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_runner")
    @previous_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_reuses_canonical_cache_for_identical_input
    path = File.join(@tmp, "input.md")
    File.write(path, "# Heading\n\nContent")

    first = Ace::Compressor::Organisms::CompressionRunner.new([path], mode: "exact", format: "path").call
    second = Ace::Compressor::Organisms::CompressionRunner.new([path], mode: "exact", format: "stats").call

    assert_equal first[:output_path], second[:output_path]
    assert_includes second[:console_output], "Cache:    hit"
  end

  def test_writes_custom_output_from_cache_without_recompressing
    path = File.join(@tmp, "input.md")
    target = File.join(@tmp, "exports", "copy.pack")
    File.write(path, "# Heading\n\nContent")

    Ace::Compressor::Organisms::CompressionRunner.new([path], mode: "exact").call
    result = Ace::Compressor::Organisms::CompressionRunner.new(
      [path],
      mode: "exact",
      output: target,
      format: "path"
    ).call

    assert_equal target, result[:console_output]
    assert File.file?(target), "Expected custom output file to exist"
  end

  def test_cache_hit_backfills_new_stats_metadata_fields
    path = File.join(@tmp, "input.md")
    File.write(path, "# Why Problems\n\n" + (0...80).map { |index| "- Isolate boundary check #{index}" }.join("\n"))

    initial = Ace::Compressor::Organisms::CompressionRunner.new([path], mode: "exact", format: "path").call
    metadata_path = initial[:output_path].sub(/\.pack\z/, ".json")
    metadata = JSON.parse(File.read(metadata_path))
    metadata.delete("original_bytes")
    metadata.delete("original_lines")
    metadata.delete("packed_bytes")
    metadata.delete("packed_lines")
    File.write(metadata_path, JSON.pretty_generate(metadata))

    result = Ace::Compressor::Organisms::CompressionRunner.new([path], mode: "exact", format: "stats").call
    refreshed = JSON.parse(File.read(metadata_path))

    assert_includes result[:console_output], "Original:"
    assert refreshed["original_bytes"] > 0
    assert refreshed["packed_bytes"] < refreshed["original_bytes"]
    assert refreshed["packed_lines"] < refreshed["original_lines"]
  end

  def test_agent_mode_routes_to_agent_compressor_and_preserves_metadata_contract
    path = File.join(@tmp, "input.md")
    File.write(path, "# Heading\n\nContent")

    fake = Class.new do
      attr_reader :ignored_paths

      def initialize(*)
        @ignored_paths = []
      end

      def resolve_sources
        [File.expand_path("input.md")]
      end

      def compress_sources(_sources)
        "H|ContextPack/3|agent\nFILE|input.md\nSUMMARY|agent output\n"
      end
    end

    Ace::Compressor::Organisms::AgentCompressor.stub(:new, ->(*) { fake.new }) do
      result = Ace::Compressor::Organisms::CompressionRunner.new([path], mode: "agent", format: "stats").call

      assert_includes result[:console_output], "Mode:     agent"
      assert_equal 0, result[:exit_code]
      assert_empty result[:refusal_lines]
      assert_empty result[:fallback_lines]
    end
  end

  def test_agent_mode_simple_output_reports_no_refusals_or_fallbacks
    path = File.join(@tmp, "input.md")
    File.write(path, "# Heading\n\nContent")

    fake = Class.new do
      attr_reader :ignored_paths

      def initialize(*)
        @ignored_paths = []
      end

      def resolve_sources
        [File.expand_path("input.md")]
      end

      def compress_sources(_sources)
        [
          "H|ContextPack/3|agent",
          "FILE|input.md",
          "FACT|Content"
        ].join("\n")
      end
    end

    Ace::Compressor::Organisms::AgentCompressor.stub(:new, ->(*) { fake.new }) do
      result = Ace::Compressor::Organisms::CompressionRunner.new([path], mode: "agent", format: "stdio").call

      assert_equal 0, result[:exit_code]
      assert_empty result[:refusal_lines]
      assert_empty result[:fallback_lines]
      assert_includes result[:console_output], "H|ContextPack/3|agent"
      assert_includes result[:console_output], "FACT|Content"
    end
  end

  def test_shared_workflow_cache_reuses_content_across_project_roots
    shared_root = File.join(@tmp, "shared-cache")
    repo_one = File.join(@tmp, "repo-one")
    repo_two = File.join(@tmp, "repo-two")
    workflow_rel = File.join("ace-task", "handbook", "workflow-instructions", "task", "draft.wf.md")
    workflow_one = File.join(repo_one, workflow_rel)
    workflow_two = File.join(repo_two, workflow_rel)
    FileUtils.mkdir_p(File.dirname(workflow_one))
    FileUtils.mkdir_p(File.dirname(workflow_two))
    File.write(workflow_one, "# Draft\n\nWorkflow content")
    File.write(workflow_two, "# Draft\n\nWorkflow content")

    config = {
      "cache_dir" => ".ace-local/compressor",
      "shared_cache_dir" => shared_root,
      "shared_cache_scope" => "workflow_only",
      "default_format" => "path"
    }

    Ace::Compressor.stub(:config, config) do
      Dir.chdir(repo_one) do
        Ace::Compressor::Organisms::CompressionRunner.new([workflow_one], mode: "exact", format: "path").call
      end

      Dir.chdir(repo_two) do
        result = Ace::Compressor::Organisms::CompressionRunner.new([workflow_two], mode: "exact", format: "stats").call
        assert_includes result[:console_output], "Cache:    hit"
        assert File.file?(result[:output_path]), "Expected hydrated local cache file to exist"
      end
    end
  end

  def test_per_source_scope_returns_individual_outputs_in_resolved_order
    second = File.join(@tmp, "zzz.md")
    first = File.join(@tmp, "aaa.md")
    File.write(second, "# Second\n\nB")
    File.write(first, "# First\n\nA")

    result = Ace::Compressor::Organisms::CompressionRunner.new(
      [second, first],
      mode: "exact",
      source_scope: "per-source",
      format: "path"
    ).call

    paths = result[:console_output].lines.map(&:strip).reject(&:empty?)
    assert_equal 2, paths.size
    assert_equal paths, result[:output_paths]
    assert_includes File.basename(paths[0]), "zzz."
    assert_includes File.basename(paths[1]), "aaa."
  end

  def test_preset_inputs_use_stable_source_identity_for_cache_and_output
    first_bundle_dir = Dir.mktmpdir("ace_compressor_bundle_one")
    second_bundle_dir = Dir.mktmpdir("ace_compressor_bundle_two")
    first_bundle = File.join(first_bundle_dir, "resolved.md")
    second_bundle = File.join(second_bundle_dir, "resolved.md")
    File.write(first_bundle, "# Heading\n\nContent")
    File.write(second_bundle, "# Heading\n\nContent")

    calls = 0
    fake_resolver_class = Class.new do
      define_method(:initialize) { |_sources| nil }
      define_method(:cleanup) {}
      define_method(:call) do
        calls = Thread.current[:ace_compressor_bundle_calls]
        Thread.current[:ace_compressor_bundle_calls] = calls + 1
        bundle = calls.zero? ? first_bundle : second_bundle
        [{content_path: bundle, source_path: "project", source_kind: "preset"}]
      end
    end

    Thread.current[:ace_compressor_bundle_calls] = 0

    Ace::Compressor::Molecules::InputResolver.stub(:new, ->(*) { fake_resolver_class.new(nil) }) do
      first = Ace::Compressor::Organisms::CompressionRunner.new(["project"], mode: "exact", format: "stdio").call
      second = Ace::Compressor::Organisms::CompressionRunner.new(["project"], mode: "exact", format: "stats").call

      assert_includes first[:console_output], "FILE|project"
      assert_includes second[:console_output], "Cache:    hit"
      assert_equal first[:output_path], second[:output_path]
      assert_includes File.basename(first[:output_path]), "project."
    end
  ensure
    Thread.current[:ace_compressor_bundle_calls] = nil
    FileUtils.rm_rf(first_bundle_dir) if first_bundle_dir
    FileUtils.rm_rf(second_bundle_dir) if second_bundle_dir
  end
end
