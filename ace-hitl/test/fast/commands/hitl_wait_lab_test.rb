# frozen_string_literal: true

require "test_helper"
require "json"

class HitlWaitLabTest < AceHitlTestCase
  def setup
    super
    @public_dir = Dir.mktmpdir("ace-hitl-public")
  end

  def teardown
    FileUtils.remove_entry(@public_dir) if @public_dir && File.exist?(@public_dir)
    super
  end

  # Real ga9 projection schema: lifecycle `state` plus a SEPARATE
  # `effect_state` field for effect-callback outcomes.
  def write_projection(request_id, state, effect_state: nil)
    projection = {"id" => request_id, "work" => "W685", "state" => state}
    projection["effect_state"] = effect_state unless effect_state.nil?
    File.write(File.join(@public_dir, "#{request_id}.json"), JSON.dump(projection))
  end

  def with_lab_public_dir(&block)
    with_env("ACE_HITL_LAB_PUBLIC_DIR" => @public_dir, &block)
  end

  def event_metadata(root, id)
    Ace::Hitl::Organisms::HitlManager.new(root_dir: root).show(id)[:event].metadata
  end

  def test_wait_surfaces_plain_answer_delivery_for_non_effect_requests
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-callback",
        status: "pending",
        extra_frontmatter: {"lab_request_id" => "labreq42", "lab_request_effect" => "none"}
      )
      write_projection("labreq42", "answer-delivered")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "5"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/Lab request delivered: 8ppq7w \(answer-delivered\)/, result[:stdout])
          assert_match(/Lab request: labreq42/, result[:stdout])
          assert_match(/lab-hitl consume labreq42/, result[:stdout])
          refute_match(/Effect callback/, result[:stdout])

          metadata = event_metadata(root, "8ppq7w")
          assert_equal "answer-delivered", metadata["lab_request_state"]
          assert_equal "lab_delivered", metadata["waiter_state"]
        end
      end
    end
  end

  def test_wait_effect_request_keeps_waiting_through_pending_callback
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-effect-pending",
        status: "pending",
        extra_frontmatter: {"lab_request_id" => "labreq42", "lab_request_effect" => "declared"}
      )
      write_projection("labreq42", "answer-delivered", effect_state: "callback-pending-with-answer")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "1"])

          assert_equal 1, result[:exit_code]
          assert_match(/Timed out waiting/, result[:stderr])

          metadata = event_metadata(root, "8ppq7w")
          assert_equal "callback-pending-with-answer", metadata["lab_request_state"]
          assert_equal "timed_out", metadata["waiter_state"]
        end
      end
    end
  end

  def test_wait_effect_request_surfaces_callback_ok_not_answer_delivery
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-effect-ok",
        status: "pending",
        extra_frontmatter: {"lab_request_id" => "labreq42", "lab_request_effect" => "declared"}
      )
      write_projection("labreq42", "answer-delivered", effect_state: "callback-ok")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "5"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/Lab request delivered: 8ppq7w \(callback-ok\)/, result[:stdout])
          assert_match(/Effect callback: ok/, result[:stdout])

          metadata = event_metadata(root, "8ppq7w")
          assert_equal "callback-ok", metadata["lab_request_state"]
          assert_equal "lab_delivered", metadata["waiter_state"]
        end
      end
    end
  end

  def test_wait_effect_request_surfaces_callback_escalation_with_hint
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-effect-escalated",
        status: "pending",
        extra_frontmatter: {"lab_request_id" => "labreq42", "lab_request_effect" => "declared"}
      )
      write_projection("labreq42", "answer-delivered", effect_state: "callback-escalated")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "5"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/Lab request delivered: 8ppq7w \(callback-escalated\)/, result[:stdout])
          assert_match(/Effect callback: escalated; inspect with: lab-hitl duty/, result[:stdout])
          assert_match(/lab-hitl consume labreq42/, result[:stdout])

          metadata = event_metadata(root, "8ppq7w")
          assert_equal "callback-escalated", metadata["lab_request_state"]
        end
      end
    end
  end

  def test_wait_effect_request_answered_event_still_holds_for_outcome
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-effect-answered",
        status: "answered",
        answer: "Ship it",
        extra_frontmatter: {"lab_request_id" => "labreq42", "lab_request_effect" => "declared"}
      )
      write_projection("labreq42", "answer-delivered", effect_state: "callback-pending-with-answer")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "1"])

          assert_equal 1, result[:exit_code]
          assert_match(/Timed out waiting/, result[:stderr])
        end
      end
    end
  end

  def test_wait_answered_effect_request_reports_effect_outcome
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-effect-answered",
        status: "answered",
        answer: "Ship it",
        extra_frontmatter: {
          "lab_request_id" => "labreq42",
          "lab_request_state" => "answer-delivered",
          "lab_request_effect" => "declared"
        }
      )
      write_projection("labreq42", "answer-delivered", effect_state: "callback-ok")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "5"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/HITL event answered: 8ppq7w/, result[:stdout])
          assert_match(/Ship it/, result[:stdout])
          # The reported state must be the effect outcome, never plain
          # answer-delivered while an effect outcome exists.
          assert_match(/Lab request: labreq42 \(callback-ok\)/, result[:stdout])
        end
      end
    end
  end

  def test_wait_answered_includes_lab_state_when_projected
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-answered",
        status: "answered",
        answer: "Ship it",
        extra_frontmatter: {
          "lab_request_id" => "labreq42",
          "lab_request_state" => "answer-delivered",
          "lab_request_effect" => "none"
        }
      )
      write_projection("labreq42", "answer-delivered")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "5"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/HITL event answered: 8ppq7w/, result[:stdout])
          assert_match(/Ship it/, result[:stdout])
          assert_match(/Lab request: labreq42 \(answer-delivered\)/, result[:stdout])
        end
      end
    end
  end

  def test_wait_without_lab_id_ignores_projection
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "8ppq7w", slug: "plain-pending", status: "pending")
      write_projection("unrelated", "answer-delivered", effect_state: "callback-ok")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "1"])

          assert_equal 1, result[:exit_code]
          assert_match(/Timed out waiting/, result[:stderr])
        end
      end
    end
  end

  def test_wait_times_out_with_non_terminal_lab_state
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-pending",
        status: "pending",
        extra_frontmatter: {"lab_request_id" => "labreq42", "lab_request_effect" => "none"}
      )
      write_projection("labreq42", "created")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "1"])

          assert_equal 1, result[:exit_code]
          assert_match(/Timed out waiting/, result[:stderr])

          metadata = event_metadata(root, "8ppq7w")
          assert_equal "created", metadata["lab_request_state"]
          assert_equal "timed_out", metadata["waiter_state"]
        end
      end
    end
  end

  def test_wait_missing_projection_keeps_waiting_until_timeout
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "no-projection",
        status: "pending",
        extra_frontmatter: {"lab_request_id" => "labreq42"}
      )

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "1"])

          assert_equal 1, result[:exit_code]
          assert_match(/Timed out waiting/, result[:stderr])
        end
      end
    end
  end
end
