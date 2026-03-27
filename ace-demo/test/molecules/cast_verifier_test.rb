# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class CastVerifierTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_cast_verifier")
    @verifier = Ace::Demo::Molecules::CastVerifier.new
    @spec = {
      "scenes" => [
        {
          "name" => "main",
          "commands" => [
            {"type" => "echo hi", "sleep" => "1s"},
            {"type" => "pwd", "sleep" => "1s"}
          ]
        }
      ]
    }
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_passes_when_all_commands_are_found
    cast_path = File.join(@tmp, "all-found.cast")
    File.write(cast_path, <<~CAST)
      {"version":2,"width":80,"height":24}
      [0.10,"i","echo hi\\r"]
      [0.20,"o","hi\\n"]
      [0.30,"i","pwd\\r"]
    CAST

    result = @verifier.verify(cast_path: cast_path, tape_spec: @spec)

    assert_equal true, result.success?
    assert_equal "pass", result.status
    assert_equal ["echo hi", "pwd"], result.commands_found
    assert_equal [], result.commands_missing
  end

  def test_warns_when_expected_command_is_missing
    cast_path = File.join(@tmp, "missing-command.cast")
    File.write(cast_path, <<~CAST)
      {"version":2,"width":80,"height":24}
      [0.10,"i","echo hi\\r"]
    CAST

    result = @verifier.verify(cast_path: cast_path, tape_spec: @spec)

    assert_equal false, result.success?
    assert_equal "warn", result.status
    assert_equal ["echo hi"], result.commands_found
    assert_equal ["pwd"], result.commands_missing
  end

  def test_returns_fail_details_when_cast_is_malformed
    cast_path = File.join(@tmp, "malformed.cast")
    File.write(cast_path, "not-json\n")

    result = @verifier.verify(cast_path: cast_path, tape_spec: @spec)

    assert_equal false, result.success?
    assert_equal "fail-details", result.status
    assert_equal [], result.commands_found
    assert_equal ["echo hi", "pwd"], result.commands_missing
    assert_includes result.details.fetch(:error), "Invalid JSON"
  end

  def test_uses_script_commands_for_asciinema_command_recordings
    script_path = File.join(@tmp, "compiled.sh")
    File.write(script_path, <<~SCRIPT)
      #!/usr/bin/env bash
      set -euo pipefail
      echo hi
      sleep 1s
      pwd
    SCRIPT

    cast_path = File.join(@tmp, "command-mode.cast")
    File.write(cast_path, <<~CAST)
      {"version":3,"command":"bash #{script_path}"}
      [0.10,"o","hi\\n"]
      [0.20,"x","0"]
    CAST

    result = @verifier.verify(cast_path: cast_path, tape_spec: @spec)

    assert_equal true, result.success?
    assert_equal "pass", result.status
    assert_equal ["echo hi", "pwd"], result.commands_found
    assert_equal [], result.commands_missing
    assert_equal 0, result.details[:inputs_recorded]
    assert_equal 2, result.details[:script_commands_recorded]
  end
end
