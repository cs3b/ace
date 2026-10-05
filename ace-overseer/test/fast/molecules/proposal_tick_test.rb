# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/proposal_tick"

class ProposalTickTest < AceOverseerTestCase
  def test_tick_invokes_policy_only_and_survives_restart_without_own_timer
    calls = []
    runner = Object.new
    runner.define_singleton_method(:capture3) do |*argv|
      calls << argv
      ['[{"proposal_id":"p1","status":"approved-by-silence"}]', "", Struct.new(:success?).new(true)]
    end
    2.times do
      tick = Ace::Overseer::Molecules::ProposalTick.new(runner: runner, socket: "/run/hitl.sock", project: "ace")
      assert_equal "approved-by-silence", tick.call.first["status"]
    end
    assert_equal 2, calls.size
    assert_equal ["/usr/local/bin/ace-hitl", "proposal", "resolve-due", "--project", "ace"], calls.first.drop(1)
    assert_equal({"ACE_HITL_SOCKET" => "/run/hitl.sock"}, calls.first.first)
  end

  def test_unconfigured_tick_has_no_authority_and_failed_tick_is_visible
    assert_equal [], Ace::Overseer::Molecules::ProposalTick.new(socket: nil).call
    runner = Object.new
    runner.define_singleton_method(:capture3) { |*| ["", "unavailable", Struct.new(:success?).new(false)] }
    assert_raises(Ace::Overseer::Error) do
      Ace::Overseer::Molecules::ProposalTick.new(runner: runner, socket: "/run/hitl.sock", project: "ace").call
    end
  end
end
