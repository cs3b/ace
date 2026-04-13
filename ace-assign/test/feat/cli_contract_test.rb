# frozen_string_literal: true

require_relative "../test_helper"
require "json"

class CliContractTest < AceAssignTestCase
  def test_cli_help_lists_core_commands
    output = capture_io do
      assert_equal 0, Ace::Assign::CLI.start(["help"])
    end

    registered = Ace::Assign::CLI::REGISTERED_COMMANDS.map(&:first)
    registered.each do |command|
      assert_includes output.first, command
    end

    assert_includes output.first, "ace-assign"
    refute_match(/^\s+advance\s+#/m, output.first)
    refute_match(/^\s+report\s+#/m, output.first)
    refute_match(/^\s+drive\s+#/m, output.first)
    refute_match(/^\s+prepare\s+#/m, output.first)
  end

  def test_cli_lifecycle_contract_with_json_status
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "onboard", "instructions" => "Load context"}
      ]
      config_path = create_test_config(cache_dir, name: "feat-cli-contract", steps: steps)
      report_path = create_report(cache_dir, "done")

      Ace::Assign.config["cache_dir"] = cache_dir

      create_output = capture_io do
        assert_equal 0, Ace::Assign::CLI.start(["create", "--yaml", config_path])
      end
      assert_includes create_output.first, "Assignment: feat-cli-contract"

      status_output = capture_io do
        assert_equal 0, Ace::Assign::CLI.start(["status", "--format", "json"])
      end
      payload = JSON.parse(status_output.first)
      assignment_id = payload.dig("assignment", "id")
      assert_equal "running", payload.dig("assignment", "state")
      assert_equal "010", payload.dig("current_step", "number")

      capture_io do
        assert_equal 0, Ace::Assign::CLI.start([
          "finish",
          "--message",
          report_path,
          "--assignment",
          assignment_id
        ])
      end

      completed_output = capture_io do
        assert_equal 0, Ace::Assign::CLI.start([
          "status",
          "--assignment",
          assignment_id,
          "--format",
          "json"
        ])
      end
      completed = JSON.parse(completed_output.first)
      assert_equal "completed", completed.dig("assignment", "state")
      assert_nil completed["current_step"]
      assert_equal "1/1 done", completed["progress"]

      Ace::Assign.reset_config!
    end
  end
end
