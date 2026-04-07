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
    assert_equal "instruction-defect", result.status
    assert_equal ["echo hi"], result.commands_found
    assert_equal ["pwd"], result.commands_missing
    assert_equal "instruction_defect", result.classification
    assert_equal true, result.retryable?
  end

  def test_returns_fail_details_when_cast_is_malformed
    cast_path = File.join(@tmp, "malformed.cast")
    File.write(cast_path, "not-json\n")

    result = @verifier.verify(cast_path: cast_path, tape_spec: @spec)

    assert_equal false, result.success?
    assert_equal "verification-error", result.status
    assert_equal [], result.commands_found
    assert_equal ["echo hi", "pwd"], result.commands_missing
    assert_equal "verification_error", result.classification
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

  def test_uses_echoed_output_commands_for_interactive_asciinema_recordings
    cast_path = File.join(@tmp, "interactive.cast")
    File.write(cast_path, <<~CAST)
      {"version":3,"command":"bash --noprofile --norc -i"}
      [0.10,"o","bash-5.3$ "]
      [0.20,"o","echo hi\\r\\n"]
      [0.30,"o","hi\\n"]
      [0.40,"o","bash-5.3$ "]
      [0.50,"o","pwd\\r\\n"]
    CAST

    result = @verifier.verify(cast_path: cast_path, tape_spec: @spec)

    assert_equal true, result.success?
    assert_equal "pass", result.status
    assert_equal ["echo hi", "pwd"], result.commands_found
    assert_equal [], result.commands_missing
    assert_equal 0, result.details[:inputs_recorded]
    assert_equal 5, result.details[:echoed_commands_recorded]
  end

  def test_classifies_missing_required_vars_as_instruction_defect
    cast_path = File.join(@tmp, "missing-vars.cast")
    File.write(cast_path, <<~CAST)
      {"version":3,"command":"bash --noprofile --norc -i"}
      [0.10,"o","echo hi\\r\\n"]
      [0.20,"o","hi\\n"]
    CAST

    result = @verifier.verify(
      cast_path: cast_path,
      tape_spec: @spec.merge("verify" => {"require_vars" => ["DEMO_TASK_REF"]})
    )

    assert_equal false, result.success?
    assert_equal "instruction_defect", result.classification
    assert_equal ["DEMO_TASK_REF"], result.details[:missing_vars]
  end

  def test_classifies_forbidden_output_as_product_bug
    cast_path = File.join(@tmp, "forbidden-output.cast")
    File.write(cast_path, <<~CAST)
      {"version":3,"command":"bash --noprofile --norc -i"}
      [0.10,"o","echo hi\\r\\n"]
      [0.20,"o","GitHub sync warning for task 8r6.t.bad\\n"]
    CAST

    result = @verifier.verify(
      cast_path: cast_path,
      tape_spec: {
        "scenes" => [{"commands" => [{"type" => "echo hi"}]}],
        "verify" => {"forbid_output" => ["GitHub sync warning"]}
      }
    )

    assert_equal false, result.success?
    assert_equal "product-bug", result.status
    assert_equal "product_bug", result.classification
    assert_equal "GitHub sync warning", result.details[:forbidden_hits][0][:pattern]
  end

  def test_runs_assert_commands_with_captured_vars
    command_runner = lambda do |command, _sandbox_path, env|
      if command == 'test "$DEMO_TASK_REF" = "8r6.t.vpn"' && env["DEMO_TASK_REF"] == "8r6.t.vpn"
        ["", "", 0]
      else
        ["", "bad assert", 1]
      end
    end
    verifier = Ace::Demo::Molecules::CastVerifier.new(command_runner: command_runner)
    cast_path = File.join(@tmp, "captured-vars.cast")
    File.write(cast_path, <<~CAST)
      {"version":3,"command":"bash --noprofile --norc -i"}
      [0.10,"o","DEMO_TASK_REF=8r6.t.vpn\\n"]
    CAST

    result = verifier.verify(
      cast_path: cast_path,
      tape_spec: {"scenes" => [], "verify" => {"assert_commands" => ['test "$DEMO_TASK_REF" = "8r6.t.vpn"']}},
      sandbox_path: @tmp,
      env: {}
    )

    assert_equal true, result.success?
    assert_equal "pass", result.status
    assert_equal "8r6.t.vpn", result.details[:captured_vars]["DEMO_TASK_REF"]
  end
end
