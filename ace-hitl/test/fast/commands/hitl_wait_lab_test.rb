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

  def write_projection(request_id, state)
    File.write(
      File.join(@public_dir, "#{request_id}.json"),
      JSON.dump({"id" => request_id, "work" => "W685", "state" => state})
    )
  end

  def with_lab_public_dir(&block)
    with_env("ACE_HITL_LAB_PUBLIC_DIR" => @public_dir, &block)
  end

  def test_wait_surfaces_terminal_lab_state_instead_of_hanging_blind
    with_hitl_dir do |root|
      create_hitl_fixture(
        root,
        id: "8ppq7w",
        slug: "lab-callback",
        status: "pending",
        extra_frontmatter: {"lab_request_id" => "labreq42"}
      )
      write_projection("labreq42", "callback-escalated")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "5"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/Lab request delivered: 8ppq7w/, result[:stdout])
          assert_match(/callback-escalated/, result[:stdout])
          assert_match(/Lab request: labreq42/, result[:stdout])
          assert_match(/lab-hitl consume labreq42/, result[:stdout])

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show("8ppq7w")[:event]
          assert_equal "callback-escalated", event.metadata["lab_request_state"]
          assert_equal "lab_delivered", event.metadata["waiter_state"]
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
        extra_frontmatter: {"lab_request_id" => "labreq42", "lab_request_state" => "answer-delivered"}
      )
      write_projection("labreq42", "callback-ok")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "5"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/HITL event answered: 8ppq7w/, result[:stdout])
          assert_match(/Ship it/, result[:stdout])
          assert_match(/Lab request: labreq42 \(callback-ok\)/, result[:stdout])
        end
      end
    end
  end

  def test_wait_without_lab_id_ignores_projection
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "8ppq7w", slug: "plain-pending", status: "pending")
      write_projection("unrelated", "callback-ok")

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
        extra_frontmatter: {"lab_request_id" => "labreq42"}
      )
      write_projection("labreq42", "created")

      with_cli_root(root) do
        with_lab_public_dir do
          result = run_cli(["wait", "8ppq7w", "--poll-every", "1", "--timeout", "1"])

          assert_equal 1, result[:exit_code]
          assert_match(/Timed out waiting/, result[:stderr])

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show("8ppq7w")[:event]
          assert_equal "created", event.metadata["lab_request_state"]
          assert_equal "timed_out", event.metadata["waiter_state"]
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
