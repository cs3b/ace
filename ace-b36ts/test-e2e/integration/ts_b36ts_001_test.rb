# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "json"
require "shellwords"

class TSB36TS001IntegrationTest < Minitest::Test
  FIXED_TIMESTAMP = "2025-01-06T12:30:00Z"
  BATCH_DATES = [
    "2025-01-09T00:00:00Z",
    "2025-01-06T00:00:00Z",
    "2025-01-12T00:00:00Z",
    "2025-01-07T00:00:00Z"
  ].freeze

  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-b36ts")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_tc_001_help_surface
    stdout, stderr, status = run_cmd("--help")
    assert status.success?, stderr

    encode_stdout, encode_stderr, encode_status = run_cmd("encode", "--help")
    assert encode_status.success?, encode_stderr

    decode_stdout, decode_stderr, decode_status = run_cmd("decode", "--help")
    assert decode_status.success?, decode_stderr

    output = stdout + stderr
    assert_match(/ace-b36ts/, output)
    assert_match(/encode/, output)
    assert_match(/decode/, output)
    assert_match(/encode/i, encode_stdout + encode_stderr)
    assert_match(/decode/i, decode_stdout + decode_stderr)
  end

  def test_tc_002_encode_timestamp
    stdout, stderr, status = run_cmd("encode", FIXED_TIMESTAMP)
    assert status.success?, stderr

    assert_token(stdout.lines.last.to_s.strip)
  end

  def test_tc_003_decode_known_token
    stdout, stderr, status = run_cmd("decode", "i50jj3")
    assert status.success?, stderr

    refute_empty stdout.strip
    assert_match(/\d{4}-\d{2}-\d{2}/, stdout)
  end

  def test_tc_004_error_behavior
    invalid_subcommand_stdout, invalid_subcommand_stderr, invalid_subcommand_status = run_cmd("nope")
    refute invalid_subcommand_status.success?
    assert invalid_subcommand_stdout.to_s.strip.empty?
    refute invalid_subcommand_stderr.to_s.strip.empty?

    invalid_decode_stdout, invalid_decode_stderr, invalid_decode_status = run_cmd("decode", "bad!")
    refute invalid_decode_status.success?
    assert invalid_decode_stdout.to_s.strip.empty?
    refute invalid_decode_stderr.to_s.strip.empty?
  end

  def test_tc_005_output_routing
    default_stdout, default_stderr, default_status = run_cmd("encode", FIXED_TIMESTAMP)
    quiet_stdout, quiet_stderr, quiet_status = run_cmd("encode", FIXED_TIMESTAMP, "--quiet")
    verbose_stdout, verbose_stderr, verbose_status = run_cmd("encode", FIXED_TIMESTAMP, "--verbose")

    [default_status, quiet_status, verbose_status].each do |status|
      assert status.success?
    end

    [default_stdout, quiet_stdout, verbose_stdout].each do |stdout|
      assert_token(stdout.lines.last.to_s.strip)
    end

    assert_operator quiet_stderr.bytesize, :<=, verbose_stderr.bytesize
  end

  def test_tc_006_structured_output
    stdout, stderr, status = run_cmd("encode", FIXED_TIMESTAMP, "--count", "3", "--format", "day", "--json")
    assert status.success?, stderr

    payload = JSON.parse(stdout)
    tokens = extract_tokens(payload)

    assert_equal 3, tokens.size
    tokens.each { |token| assert_token(token) }
  end

  def test_tc_007_roundtrip_pipeline
    command = <<~BASH
      token="$("#{Shellwords.escape(@exe)}" encode #{FIXED_TIMESTAMP.shellescape})"
      decoded="$("#{Shellwords.escape(@exe)}" decode "$token" --format iso)"
      printf "ORIGINAL=%s\\nTOKEN=%s\\nDECODED=%s\\n" #{FIXED_TIMESTAMP.shellescape} "$token" "$decoded"
    BASH

    stdout, stderr, status = Open3.capture3("bash", "-lc", command, chdir: @root)
    assert status.success?, stderr

    summary = stdout.lines.map(&:strip).reject(&:empty?).to_h do |line|
      key, value = line.split("=", 2)
      [key, value]
    end

    assert_equal FIXED_TIMESTAMP, summary.fetch("ORIGINAL")
    assert_token(summary.fetch("TOKEN"))
    assert_match(/2025-01-06/, summary.fetch("DECODED"))
  end

  def test_tc_008_batch_sort_order
    rows = BATCH_DATES.map do |date|
      stdout, stderr, status = run_cmd("encode", date, "--format", "day")
      assert status.success?, stderr

      token = stdout.lines.last.to_s.strip
      assert_token(token)
      [token, date]
    end

    sorted_rows = rows.sort_by(&:first)

    assert_equal sorted_rows.map(&:first), sorted_rows.map(&:first).sort
    assert_equal sorted_rows.map(&:last), sorted_rows.map(&:last).sort
  end

  private

  def assert_token(token)
    assert_match(/\A[0-9a-z]{2,8}\z/, token)
  end

  def extract_tokens(value)
    case value
    when Array
      value.flat_map { |item| extract_tokens(item) }
    when Hash
      value.values.flat_map { |item| extract_tokens(item) }
    when String
      value.match?(/\A[0-9a-z]{2,8}\z/) ? [value] : []
    else
      []
    end
  end
end
