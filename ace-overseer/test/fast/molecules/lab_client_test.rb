# frozen_string_literal: true

require_relative "../../test_helper"

class LabClientTest < AceOverseerTestCase
  Status = Struct.new(:success?)

  class FakeRunner
    attr_reader :calls

    def initialize(stdout:, stderr: "", success: true)
      @stdout = stdout
      @stderr = stderr
      @success = success
      @calls = []
    end

    def capture3(*arguments, stdin_data:)
      @calls << {arguments: arguments, stdin_data: stdin_data}
      [@stdout, @stderr, Status.new(@success)]
    end
  end

  class MissingBinaryRunner
    def capture3(*)
      raise Errno::ENOENT
    end
  end

  def test_uses_only_absolute_lab_binary_and_parses_json
    runner = FakeRunner.new(stdout: '{"works":[]}')
    client = Ace::Overseer::Molecules::LabClient.new(runner: runner)

    result = client.call("work", "status", "--json")

    assert_equal({"works" => []}, result)
    assert_equal "/usr/local/bin/lab", runner.calls.first[:arguments].first
  end

  def test_passes_prompt_only_over_stdin
    runner = FakeRunner.new(stdout: "W321\tprompted\n")
    client = Ace::Overseer::Molecules::LabClient.new(runner: runner)

    client.call("work", "prompt", "W321", stdin_data: "review this", json: false)

    assert_equal "review this", runner.calls.first[:stdin_data]
    refute_includes runner.calls.first[:arguments], "review this"
  end

  def test_raises_redacted_command_error
    runner = FakeRunner.new(stdout: "", stderr: "permission denied", success: false)
    client = Ace::Overseer::Molecules::LabClient.new(runner: runner)

    error = assert_raises(Ace::Overseer::Error) { client.call("agents", "--json") }

    assert_equal "permission denied", error.message
  end

  def test_raises_actionable_error_when_lab_binary_is_missing
    client = Ace::Overseer::Molecules::LabClient.new(runner: MissingBinaryRunner.new)

    error = assert_raises(Ace::Overseer::Error) { client.call("agents", "--json") }

    assert_equal "Lab runtime unavailable: /usr/local/bin/lab is not installed", error.message
  end
end
