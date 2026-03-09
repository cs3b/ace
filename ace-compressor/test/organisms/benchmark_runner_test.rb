# frozen_string_literal: true

require "json"
require "tmpdir"
require "fileutils"
require_relative "../test_helper"

class BenchmarkRunnerTest < AceCompressorTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_benchmark")
    @previous_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_benchmark_runner_reports_exact_baseline_coverage
    path = File.join(@tmp, "architecture.md")
    File.write(path, <<~MD)
      # Architecture

      ## Overview
      Deterministic tools help agents.

      ## Rules
      Commands must stay parseable.
    MD

    report = Ace::Compressor::Organisms::BenchmarkRunner.new([path], modes: "exact,compact", format: "json").call
    source = report.fetch("sources").first
    exact = source.fetch("modes").find { |row| row.fetch("mode") == "exact" }
    compact = source.fetch("modes").find { |row| row.fetch("mode") == "compact" }

    assert_equal "ok", exact.fetch("status")
    assert_equal 100.0, exact.fetch("coverage").fetch("sections").fetch("percent")
    assert_equal "ok", compact.fetch("status")
    assert compact.fetch("coverage").fetch("sections").fetch("percent") > 0
  end

  def test_benchmark_runner_renders_json
    path = File.join(@tmp, "vision.md")
    File.write(path, "# Vision\n\nAgents can run CLI commands.\n")

    runner = Ace::Compressor::Organisms::BenchmarkRunner.new([path], modes: "exact", format: "json")
    report = runner.call
    rendered = runner.render(report)

    parsed = JSON.parse(rendered)
    assert_equal 1, parsed.fetch("sources").size
    assert_equal "exact", parsed.fetch("sources").first.fetch("modes").first.fetch("mode")
  end
end
