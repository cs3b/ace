# frozen_string_literal: true

require "test_helper"
require "ace/hitl/molecules/lab_projection_observer"
require "json"

class LabProjectionObserverTest < AceHitlTestCase
  # Real ga9 projection schema: lifecycle `state` plus a SEPARATE
  # `effect_state` for effect-callback outcomes.
  def write_projection(dir, request_id, state, effect_state: nil)
    projection = {"id" => request_id, "state" => state}
    projection["effect_state"] = effect_state unless effect_state.nil?
    File.write(File.join(dir, "#{request_id}.json"), JSON.dump(projection))
  end

  def read_snapshot(dir, request_id = "labreq42")
    Ace::Hitl::Molecules::LabProjectionObserver.new(public_dir: dir).snapshot_for(request_id)
  end

  def test_reads_lifecycle_state_and_effect_state_fields
    Dir.mktmpdir do |dir|
      write_projection(dir, "labreq42", "answer-delivered", effect_state: "callback-ok")
      snapshot = read_snapshot(dir)

      assert_equal "answer-delivered", snapshot.state
      assert_equal "callback-ok", snapshot.effect_state
    end
  end

  def test_effect_state_may_be_absent_while_lifecycle_state_present
    Dir.mktmpdir do |dir|
      write_projection(dir, "labreq42", "created")
      snapshot = read_snapshot(dir)

      assert_equal "created", snapshot.state
      assert_nil snapshot.effect_state
    end
  end

  def test_missing_projection_file_returns_nil
    Dir.mktmpdir do |dir|
      assert_nil read_snapshot(dir)
    end
  end

  def test_malformed_projection_file_returns_nil
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "labreq42.json"), "not json{")
      assert_nil read_snapshot(dir)
    end
  end

  def observer
    Ace::Hitl::Molecules::LabProjectionObserver.new
  end

  def snapshot_class
    Ace::Hitl::Molecules::LabProjectionObserver::Snapshot
  end

  def test_effective_state_prefers_effect_outcome_over_lifecycle_state
    delivered_with_outcome = snapshot_class.new(state: "answer-delivered", effect_state: "callback-ok")

    assert_equal "callback-ok", observer.effective_state(delivered_with_outcome)
    assert_equal "answer-delivered", observer.effective_state(
      snapshot_class.new(state: "answer-delivered", effect_state: nil)
    )
    assert_nil observer.effective_state(nil)
  end

  def test_terminal_for_effect_requests_requires_effect_verdict
    snapshot_class = self.snapshot_class

    assert observer.terminal?(
      snapshot_class.new(state: "answer-delivered", effect_state: "callback-ok"),
      effect_declared: true
    )
    assert observer.terminal?(
      snapshot_class.new(state: "answer-delivered", effect_state: "callback-escalated"),
      effect_declared: true
    )
    refute observer.terminal?(
      snapshot_class.new(state: "answer-delivered", effect_state: "callback-pending-with-answer"),
      effect_declared: true
    )
    # Plain answer delivery must NOT end an effect-declaring wait.
    refute observer.terminal?(
      snapshot_class.new(state: "answer-delivered", effect_state: nil),
      effect_declared: true
    )
  end

  def test_terminal_for_plain_requests_uses_lifecycle_states
    snapshot_class = self.snapshot_class

    %w[answer-delivered consumed cancelled].each do |state|
      assert observer.terminal?(snapshot_class.new(state: state, effect_state: nil))
    end
    refute observer.terminal?(snapshot_class.new(state: "created", effect_state: nil))
    refute observer.terminal?(
      snapshot_class.new(state: "created", effect_state: "callback-ok"),
      effect_declared: false
    )
    refute observer.terminal?(nil)
  end

  def test_env_override_public_dir
    Dir.mktmpdir do |dir|
      write_projection(dir, "labreq42", "answer-delivered")
      observer = Ace::Hitl::Molecules::LabProjectionObserver.new

      with_env("ACE_HITL_LAB_PUBLIC_DIR" => dir) do
        assert_equal "answer-delivered", observer.snapshot_for("labreq42").state
      end

      assert_nil observer.snapshot_for("labreq42")
    end
  end

  def test_explicit_public_dir_beats_env
    Dir.mktmpdir do |dir|
      write_projection(dir, "labreq42", "answer-delivered", effect_state: "callback-escalated")
      observer = Ace::Hitl::Molecules::LabProjectionObserver.new(public_dir: dir)

      with_env("ACE_HITL_LAB_PUBLIC_DIR" => "/nonexistent") do
        assert_equal "callback-escalated", observer.snapshot_for("labreq42").effect_state
      end
    end
  end
end
