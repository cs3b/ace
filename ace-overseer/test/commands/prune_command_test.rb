# frozen_string_literal: true

require "stringio"
require_relative "../test_helper"

class PruneCommandTest < AceOverseerTestCase
  class FakePruneOrchestrator
    attr_reader :calls

    def initialize(result:)
      @result = result
      @calls = []
    end

    def call(**kwargs)
      @calls << kwargs
      @result
    end
  end

  def test_progress_output_passed_when_not_quiet
    orchestrator = FakePruneOrchestrator.new(
      result: { dry_run: false, safe: [], unsafe: [], pruned: [], failed: [], aborted: false }
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    capture_io do
      command.call(quiet: false, dry_run: false, yes: true, debug: false)
    end

    assert_equal 1, orchestrator.calls.length
    refute_nil orchestrator.calls.first[:on_progress]
  end

  def test_no_progress_output_in_quiet_mode
    orchestrator = FakePruneOrchestrator.new(
      result: { dry_run: false, safe: [], unsafe: [], pruned: [], failed: [], aborted: false }
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    capture_io do
      command.call(quiet: true, dry_run: false, yes: true, debug: false)
    end

    assert_nil orchestrator.calls.first[:on_progress]
  end

  def test_quiet_mode_still_executes_orchestrator
    orchestrator = FakePruneOrchestrator.new(
      result: { dry_run: true, safe: [], unsafe: [], pruned: [], failed: [] }
    )
    command = Ace::Overseer::CLI::Commands::Prune.new(
      orchestrator: orchestrator,
      input: StringIO.new,
      output: StringIO.new
    )

    output = capture_io do
      command.call(quiet: true, dry_run: true, yes: false, debug: false)
    end

    assert_equal 1, orchestrator.calls.length
    assert_equal "", output.first
  end
end
