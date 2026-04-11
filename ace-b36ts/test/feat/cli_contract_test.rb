# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "shellwords"
require_relative "../test_helper"

class TsB36ts001Test < AceB36tsTestCase
  def test_tc_001_help_survey
    root_help = run_cli("--help")
    encode_help = run_cli("encode", "--help")
    decode_help = run_cli("decode", "--help")

    assert root_help[:status].success?
    assert encode_help[:status].success?
    assert decode_help[:status].success?

    assert_includes root_help[:stdout], "encode"
    assert_includes root_help[:stdout], "decode"
    assert_includes encode_help[:stdout], "--format"
    assert_includes decode_help[:stdout], "decode"
  end

  def test_tc_002_encode_today
    result = run_cli("encode", "2026-03-23 12:00:00 UTC")
    token = result[:stdout].strip

    assert result[:status].success?
    assert_match(/\A[0-9a-z]{6}\z/, token)
  end

  def test_tc_003_decode_token
    result = run_cli("decode", "i50jj3")
    expected_date = Ace::B36ts.decode_auto("i50jj3").strftime("%Y-%m-%d")

    assert result[:status].success?
    assert_includes result[:stdout], expected_date
  end

  def test_tc_004_error_behavior
    result = run_cli("encode", "not-a-time")

    refute result[:status].success?
    assert_match(/Error/i, result[:stderr])
  end

  def test_tc_005_output_routing
    normal = run_cli("config")
    verbose = run_cli("config", "--verbose")
    invalid = run_cli("encode", "not-a-time")

    assert normal[:status].success?
    assert verbose[:status].success?
    refute invalid[:status].success?

    assert_includes normal[:stdout], "Current ace-b36ts configuration"
    assert_includes verbose[:stdout], "Configuration sources"
    assert_operator invalid[:stderr].strip.length, :>, 0
    assert_equal "", invalid[:stdout].strip
  end

  def test_tc_006_structured_output
    result = run_cli("encode", "2025-01-06 12:30:00 UTC", "--split", "month,day", "--json")
    parsed = JSON.parse(result[:stdout])

    assert result[:status].success?
    assert_kind_of Hash, parsed
    assert parsed.key?("month")
    assert parsed.key?("day")
    assert parsed.key?("path")
    assert parsed.key?("full")
  end

  def test_tc_007_roundtrip_pipeline
    original = "2025-06-15 14:30:45 UTC"
    escaped_exe = Shellwords.escape(File.expand_path("../../exe/ace-b36ts", __dir__))
    command = "token=$(#{Shellwords.escape(RbConfig.ruby)} #{escaped_exe} encode #{Shellwords.escape(original)}) && " \
              "#{Shellwords.escape(RbConfig.ruby)} #{escaped_exe} decode \"$token\""
    decoded = run_shell(command)

    assert decoded[:status].success?
    assert_includes decoded[:stdout], "2025-06-15"
  end

  def test_tc_008_batch_sort
    dated_ids = [
      ["2025-01-03 00:00:00 UTC", run_cli("encode", "2025-01-03 00:00:00 UTC")[:stdout].strip],
      ["2025-01-01 00:00:00 UTC", run_cli("encode", "2025-01-01 00:00:00 UTC")[:stdout].strip],
      ["2025-01-02 00:00:00 UTC", run_cli("encode", "2025-01-02 00:00:00 UTC")[:stdout].strip]
    ]
    ordered_dates = dated_ids.sort_by { |_date, token| token }.map(&:first)

    assert_equal [
      "2025-01-01 00:00:00 UTC",
      "2025-01-02 00:00:00 UTC",
      "2025-01-03 00:00:00 UTC"
    ], ordered_dates
  end

  private

  def run_cli(*args)
    exe_path = File.expand_path("../../exe/ace-b36ts", __dir__)
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, exe_path, *args)
    {stdout: stdout, stderr: stderr, status: status}
  end

  def run_shell(command)
    stdout, stderr, status = Open3.capture3("bash", "-lc", command)
    {stdout: stdout, stderr: stderr, status: status}
  end
end
