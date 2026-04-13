# frozen_string_literal: true

require "open3"
require "rbconfig"
require_relative "../test_helper"

class CliContractTest < AceLlmTestCase
  def test_unknown_provider_reports_actionable_error
    result = run_cli("nope", "Reply with token OK")
    output = "#{result[:stdout]}#{result[:stderr]}"

    refute result[:status].success?
    assert_match(/Unknown provider: nope/i, output)
    assert_match(/ace-llm --list-providers/, output)
  end

  private

  def run_cli(*args)
    exe_path = File.expand_path("../../exe/ace-llm", __dir__)
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, exe_path, *args)
    {stdout: stdout, stderr: stderr, status: status}
  end
end
