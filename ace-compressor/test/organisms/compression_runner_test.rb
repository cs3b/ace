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
    File.write(path, "# Heading\n\nContent\n\nMore text\n\nFinal note")

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
    assert_equal 7, refreshed["original_lines"]
    assert refreshed["packed_bytes"] > refreshed["original_bytes"]
    assert refreshed["packed_lines"] < refreshed["original_lines"]
  end
end
