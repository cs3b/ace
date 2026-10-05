# frozen_string_literal: true
require_relative '../../test_helper'
require 'ace/overseer/cli'

class ProposalWatchRegressionTest < AceOverseerTestCase
  def test_review_watch_keeps_running_after_transient_tick_failure
    calls = 0
    tick = Object.new
    tick.define_singleton_method(:call) do
      calls += 1
      raise Ace::Overseer::Error, 'Proposal resolution unavailable; deadlines deferred' if calls == 2
      raise Interrupt if calls == 4
      []
    end
    collector = Object.new
    collector.define_singleton_method(:collect) { {} }
    collector.define_singleton_method(:collect_quick) { |snapshot| snapshot }
    collector.define_singleton_method(:to_table) { |_| 'status' }
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector,
      config: {'watch' => {'refresh_interval' => 1, 'git_refresh_interval' => 300}}, proposal_tick: tick)
    command.define_singleton_method(:sleep_interruptible) { |_| }
    capture_io { command.call(format: 'table', watch: true) }
    assert_equal 4, calls, 'a failed tick must defer resolution and retry on the next watch tick'
  end
  def test_startup_tick_failure_still_displays_status_with_deferred_projection
    tick = Object.new
    tick.define_singleton_method(:call) { raise Ace::Overseer::Error, 'temporarily unavailable' }
    collector = Object.new
    collector.define_singleton_method(:collect) { {} }
    collector.define_singleton_method(:to_h) { |_| {worktrees: []} }
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector, proposal_tick: tick)
    out, = capture_io { command.call(format: 'json') }
    value = JSON.parse(out)
    assert_equal [], value['worktrees']
    assert_equal 'deferred', value.dig('proposal_resolution', 'status')
  end

end
