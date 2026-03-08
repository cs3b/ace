# frozen_string_literal: true

require "json"
require "tmpdir"
require "fileutils"
require_relative "../test_helper"

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
end
