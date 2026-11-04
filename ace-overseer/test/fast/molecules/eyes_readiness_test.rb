# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/eyes_readiness"

class EyesReadinessTest < Minitest::Test
  def setup
    @env = {"ACE_LAB_SESSION" => "1", "ACE_TOOLCHAIN" => "installed"}
    @response = {"ready" => true, "root" => "/lab/ace", "role" => "project-overseer"}
    @calls = []
    owner = self
    client = Object.new
    client.define_singleton_method(:readiness) { |target:| owner.query(target) }
    local = Object.new
    local.define_singleton_method(:ready?) { |**| raise "must not read private files locally" }
    @reader = Ace::Overseer::Molecules::EyesReadiness.new(env: @env, client: client, local: local)
    @args = {pane: "w1:p2", root: "/lab/ace",
      prompt: Ace::Overseer::Atoms::StartContract::FIRST_TURN_PROMPT,
      required_sources: Ace::Overseer::Atoms::ObservationSources::REQUIRED}
  end

  def query(target)
    @calls << target
    raise Ace::Lab::Auth::Error if @failed
    @response
  end

  def test_isolated_start_uses_authenticated_evaluator
    assert @reader.ready?(**@args)
    assert_equal ["w1:p2"], @calls
  end

  def test_scope_or_source_mismatch_is_not_ready
    @response["root"] = "/lab/other"
    refute @reader.ready?(**@args)
    @response["root"] = "/lab/ace"
    @response["role"] = "lab-overseer"
    refute @reader.ready?(**@args)
    assert @reader.ready?(**@args.merge(required_sources: @args[:required_sources] + ["project_sessions"]))
  end

  def test_transport_failure_and_wrong_runtime_never_fall_back_to_local_read
    @failed = true
    assert_raises(Ace::Overseer::Error) { @reader.ready?(**@args) }
    @env["ACE_TOOLCHAIN"] = "auto"
    assert_raises(Ace::Overseer::Error) { @reader.ready?(**@args) }
    assert_equal 1, @calls.size
  end
end
