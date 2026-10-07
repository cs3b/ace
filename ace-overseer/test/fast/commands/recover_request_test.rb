# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/cli/commands/work_on"

class RecoverRequestCommandTest < AceOverseerTestCase
  def command
    recovery = Object.new
    @requests = []
    requests = @requests
    recovery.define_singleton_method(:call) { |path:| requests << path; {"request_path" => path, "attribution" => "unattributed"} }
    forbidden = Object.new
    forbidden.define_singleton_method(:call) { |**| raise "launch must not run" }
    Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: forbidden, lab_client: forbidden, recovery: recovery)
  end

  def test_recovery_identity_is_mandatory_even_quiet
    selected = command
    output, = capture_io { selected.call(recover_request: "/private/invocation.json", quiet: true) }
    assert_equal "unattributed", JSON.parse(output).fetch("attribution")
    assert_equal ["/private/invocation.json"], @requests
  end

  def test_recovery_refuses_mode_overrides_before_read
    selected = command
    [{task: ["task"]}, {preset: "preset"}, {work: "old-work"}, {agent: "mapping"}, {runtime: "lab"}].each do |override|
      assert_raises(Ace::Support::Cli::Error) { selected.call(recover_request: "/private/invocation.json", **override) }
    end
    assert_empty @requests
  end
end
