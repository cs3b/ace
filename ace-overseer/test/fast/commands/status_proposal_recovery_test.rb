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

  def test_protected_status_is_read_only_and_does_not_run_proposal_tick
    tick = Object.new
    tick.define_singleton_method(:call) { raise Ace::Overseer::Error, 'temporarily unavailable' }
    tick.define_singleton_method(:call) { raise 'protected status must never resolve proposals' }
    status = Object.new
    status.define_singleton_method(:collect) { |**_| {'project_id' => 'project', 'provisioned_capacity' => 1,
      'visible_capacity' => 1, 'visibility' => 'complete', 'agents' => []} }
    command = Ace::Overseer::CLI::Commands::Status.new(protected_status: status, proposal_tick: tick)
    out, err = capture_io { command.call(format: 'json', project: 'project') }
    assert_equal 'project', JSON.parse(out).fetch('project_id')
    assert_empty err
    refute JSON.parse(out).key?('proposal_resolution')
  end

  def test_invalid_protected_options_have_no_proposal_or_discovery_effect
    tick = Object.new
    tick.define_singleton_method(:call) { raise Ace::Overseer::Error, 'temporarily unavailable' }
    calls = []
    tick.define_singleton_method(:call) { calls << :tick }
    status = Object.new
    status.define_singleton_method(:collect) { |**_| calls << :discovery }
    command = Ace::Overseer::CLI::Commands::Status.new(protected_status: status, proposal_tick: tick)
    assert_raises(Ace::Support::Cli::Error) { command.call(format: 'json', project: 'project', runtime: 'lab') }
    assert_raises(Ace::Support::Cli::Error) { command.call(format: 'json', project: 'project', watch: true) }
    assert_empty calls
  end

end
