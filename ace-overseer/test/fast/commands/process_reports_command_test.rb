# frozen_string_literal: true

require_relative "../../test_helper"

class ProcessReportsCommandTest < AceOverseerTestCase
  class FakeProcessor
    attr_reader :calls

    def initialize(result: nil)
      @result = result
      @calls = []
    end

    def call(dry_run:, on_progress: nil)
      @calls << {dry_run: dry_run}
      @result
    end
  end

  def result(counts: {})
    {
      dry_run: false,
      outcomes: [
        {event_id: "ab12cd", status: :success, manager_ref: "8xg.t.mgr", step_ref: "8xg.t.mgr.0",
         continuation: {action: "handoff", step_ref: "8xg.t.mgr.1",
           next: {"role" => "reviewer"}},
         message: "step 8xg.t.mgr.0 done (report ab12cd)"}
      ],
      counts: {success: 1, error: 0, needs_answer: 0, duplicate: 0, unmatched: 0}.merge(counts)
    }
  end

  def test_processes_reports_and_prints_outcomes
    processor = FakeProcessor.new(result: result)
    command = Ace::Overseer::CLI::Commands::ProcessReports.new(processor: processor)

    capture_io do
      command.call(dry_run: false)
    end

    assert_equal [{dry_run: false}], processor.calls
  end

  def test_passes_dry_run
    processor = FakeProcessor.new(result: result.merge(dry_run: true))
    command = Ace::Overseer::CLI::Commands::ProcessReports.new(processor: processor)

    capture_io do
      command.call(dry_run: true)
    end

    assert_equal [{dry_run: true}], processor.calls
  end

  def test_wraps_errors_as_cli_errors
    processor = FakeProcessor.new
    def processor.call(**)
      raise Ace::Overseer::Error, "inbox unreadable"
    end
    command = Ace::Overseer::CLI::Commands::ProcessReports.new(processor: processor)

    error = assert_raises(Ace::Support::Cli::Error) do
      capture_io { command.call(dry_run: false) }
    end

    assert_includes error.message, "inbox unreadable"
  end
end
