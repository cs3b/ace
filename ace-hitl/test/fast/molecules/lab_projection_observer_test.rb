# frozen_string_literal: true

require "test_helper"
require "ace/hitl/molecules/lab_projection_observer"
require "json"

class LabProjectionObserverTest < AceHitlTestCase
  def write_projection(dir, request_id, state)
    File.write(File.join(dir, "#{request_id}.json"), JSON.dump({"id" => request_id, "state" => state}))
  end

  def test_reads_state_from_projection_file
    Dir.mktmpdir do |dir|
      write_projection(dir, "labreq42", "callback-ok")
      observer = Ace::Hitl::Molecules::LabProjectionObserver.new(public_dir: dir)

      assert_equal "callback-ok", observer.state_for("labreq42")
    end
  end

  def test_missing_projection_file_returns_nil
    Dir.mktmpdir do |dir|
      observer = Ace::Hitl::Molecules::LabProjectionObserver.new(public_dir: dir)

      assert_nil observer.state_for("labreq42")
    end
  end

  def test_malformed_projection_file_returns_nil
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "labreq42.json"), "not json{")
      observer = Ace::Hitl::Molecules::LabProjectionObserver.new(public_dir: dir)

      assert_nil observer.state_for("labreq42")
    end
  end

  def test_terminal_states_recognized
    observer = Ace::Hitl::Molecules::LabProjectionObserver.new

    assert observer.terminal?("answer-delivered")
    assert observer.terminal?("callback-ok")
    assert observer.terminal?("callback-escalated")
    refute observer.terminal?("created")
    refute observer.terminal?(nil)
  end

  def test_env_override_public_dir
    Dir.mktmpdir do |dir|
      write_projection(dir, "labreq42", "answer-delivered")
      observer = Ace::Hitl::Molecules::LabProjectionObserver.new

      with_env("ACE_HITL_LAB_PUBLIC_DIR" => dir) do
        assert_equal "answer-delivered", observer.state_for("labreq42")
      end

      assert_nil observer.state_for("labreq42")
    end
  end

  def test_explicit_public_dir_beats_env
    Dir.mktmpdir do |dir|
      write_projection(dir, "labreq42", "callback-escalated")
      observer = Ace::Hitl::Molecules::LabProjectionObserver.new(public_dir: dir)

      with_env("ACE_HITL_LAB_PUBLIC_DIR" => "/nonexistent") do
        assert_equal "callback-escalated", observer.state_for("labreq42")
      end
    end
  end
end
