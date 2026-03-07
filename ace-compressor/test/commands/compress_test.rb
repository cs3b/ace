# frozen_string_literal: true

require "dry/cli"
require "tmpdir"
require "fileutils"
require_relative "../test_helper"

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
      begin
        @result = Dry::CLI.new(Ace::Compressor::CLI::Commands::Compress).call(arguments: args)
      rescue SystemExit => e
        @result = e.status
      rescue Ace::Core::CLI::Error => e
        $stderr.puts e.message
        @result = e.exit_code
      end
    end

    { stdout: stdout, stderr: stderr, result: @result }
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

  def test_success_on_multiple_files_exact_mode
    second = File.join(@tmp, "zzz.md")
    first = File.join(@tmp, "aaa.md")
    File.write(second, "# Second\n\nB")
    File.write(first, "# First\n\nA")

    result = invoke([second, first, "--mode", "exact", "--format", "stdio"])

    assert_equal "", result[:stderr]
    assert_includes result[:stdout], "H|ContextPack/3|exact"
    assert_includes result[:stdout], "FILE|aaa.md"
    assert_includes result[:stdout], "FILE|zzz.md"

    first_line_index = result[:stdout].index("SEC|first")
    second_line_index = result[:stdout].index("SEC|second")
    assert first_line_index
    assert second_line_index
    assert_operator first_line_index, :<, second_line_index
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
    assert_includes result[:stdout], "TABLE|"
    assert_includes result[:stdout], "Service"
    assert_includes result[:stdout], "100"
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
      *((0...80).map { |index| "- Context bloat check #{index}" }),
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
end
