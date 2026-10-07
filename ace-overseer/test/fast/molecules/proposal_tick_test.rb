# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/proposal_tick"

class ProposalTickTest < AceOverseerTestCase
  def test_tick_invokes_policy_only_and_survives_restart_without_own_timer
    calls = []
    runner = Object.new
    runner.define_singleton_method(:call) do |argv, **limits|
      calls << [argv, limits]
      Ace::Herdr::Molecules::BoundedProcess::Result.new('[{"proposal_id":"p1","status":"approved-by-silence"}]', "", Struct.new(:success?).new(true), false)
    end
    2.times do
      tick = Ace::Overseer::Molecules::ProposalTick.new(runner: runner, socket: "/run/hitl.sock", project: "ace")
      assert_equal "approved-by-silence", tick.call.first["status"]
    end
    assert_equal 2, calls.size
    assert_equal ["/usr/local/bin/ace-hitl", "proposal", "resolve-due", "--project", "ace"], calls.first.first.drop(1)
    assert_equal({"ACE_HITL_SOCKET" => "/run/hitl.sock"}, calls.first.first.first)
    assert_equal({timeout_s: 5, output_limit: 65_536, stderr_limit: 65_536, cleanup_group: true}, calls.first.last)
  end

  def test_unconfigured_tick_has_no_authority_and_failed_tick_is_visible
    assert_equal [], Ace::Overseer::Molecules::ProposalTick.new(socket: nil).call
    runner = Object.new
    runner.define_singleton_method(:call) { |*, **| Ace::Herdr::Molecules::BoundedProcess::Result.new("", "unavailable", Struct.new(:success?).new(false), false) }
    assert_raises(Ace::Overseer::Error) do
      Ace::Overseer::Molecules::ProposalTick.new(runner: runner, socket: "/run/hitl.sock", project: "ace").call
    end
  end

  def test_timeout_oversize_and_malformed_refuse_without_retaining_permission
    [Timeout::Error.new, Ace::Herdr::Molecules::BoundedProcess::PostLaunchError.new("lost cleanup"),
      ["[]", true], ["{}", false], ["bad", false]].each do |outcome|
      runner = Object.new
      runner.define_singleton_method(:call) do |*, **|
        raise outcome if outcome.is_a?(Exception)
        Ace::Herdr::Molecules::BoundedProcess::Result.new(outcome.first, "", Struct.new(:success?).new(true), outcome.last)
      end
      tick = Ace::Overseer::Molecules::ProposalTick.new(runner: runner, socket: "/run/hitl.sock", project: "ace")
      assert_raises(Ace::Overseer::Error) { tick.call }
    end
  end

  def test_concurrent_wakes_coalesce_and_failure_releases_only_original_marker
    entered, finish = Queue.new, Queue.new
    calls = 0
    runner = Object.new
    runner.define_singleton_method(:call) do |*, **|
      calls += 1
      entered << true
      finish.pop
      Ace::Herdr::Molecules::BoundedProcess::Result.new("[]", "", Struct.new(:success?).new(true), false)
    end
    build = -> { Ace::Overseer::Molecules::ProposalTick.new(runner: runner, socket: "/run/hitl.sock", project: "ace") }
    original = Thread.new { build.call.call }
    entered.pop
    3.times { assert_equal [], build.call.call }
    assert_equal 1, calls
    finish << true
    assert_equal [], original.value
    finish << true
    assert_equal [], build.call.call
    assert_equal 2, calls
  ensure
    finish << true if finish
    original&.join(1)
  end
end
