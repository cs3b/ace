# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class TSB36TS001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-b36ts")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    output = stdout + stderr
    assert_match(/ace-b36ts/, output)
    assert_match(/encode/, output)
    assert_match(/decode/, output)
  end

  def test_encode_then_decode_token
    stdout, stderr, status = run_cmd("encode", "now")
    assert status.success?, stderr

    token = stdout.lines.last.to_s.strip
    assert_match(/\A[a-z0-9]+\z/i, token)

    stdout, stderr, status = run_cmd("decode", token)
    assert status.success?, stderr
    refute_empty stdout.strip
  end
end
