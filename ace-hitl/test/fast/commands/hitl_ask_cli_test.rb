# frozen_string_literal: true

require "test_helper"
require "json"

class HitlAskCliTest < AceHitlTestCase
  LAB_REQUEST_ID = "labreq777"

  def setup
    super
    @scratch = Dir.mktmpdir("ace-hitl-ask")
    @capture_path = File.join(@scratch, "argv-capture.txt")
    @stub_bin = File.join(@scratch, "stub-lab-hitl")
  end

  def teardown
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
    super
  end

  def with_stub_lab_bin(exit_code: 0, request_id: LAB_REQUEST_ID)
    File.write(@stub_bin, <<~SH)
      #!/bin/sh
      {
        for arg in "$@"; do
          printf '%s\\n' "$arg"
        done
      } > "$ACE_HITL_LAB_CAPTURE"
      if [ "#{exit_code}" -ne 0 ]; then
        printf 'lab-hitl: invalid work id\\n' >&2
        exit #{exit_code}
      fi
      printf '%s\\n' '{"id": "#{request_id}", "requested": true}'
    SH
    FileUtils.chmod(0o755, @stub_bin)

    with_env("ACE_HITL_LAB_BIN" => @stub_bin, "ACE_HITL_LAB_CAPTURE" => @capture_path) do
      yield
    end
  end

  def captured_argv
    File.read(@capture_path).split("\n")
  end

  def test_ask_creates_event_binds_lab_request_and_prints_both_ids
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli([
            "ask", "Proceed with deploy?",
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--effect-arg", "/bin/false",
            "--effect-cwd", "/tmp"
          ])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/HITL event: (\S+)/, result[:stdout])
          assert_match(/Lab request: #{LAB_REQUEST_ID}/, result[:stdout])

          event_id = result[:stdout][/HITL event: (\S+)/, 1]
          argv = captured_argv
          bound_lab_id = argv[argv.index("--id") + 1]
          assert_match(/\A[A-Za-z0-9_-]{6,64}\Z/, bound_lab_id)
          # Shell "$@" excludes argv[0], so the captured argv starts at "request".
          assert_equal [
            "request",
            "--id", bound_lab_id,
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--project", "ace",
            "--harness", "lab-admin",
            "--plan", "ace-hitl ask",
            "--question", "Proceed with deploy?",
            "--ace-hitl-id", event_id,
            "--effect-arg", "/bin/false",
            "--effect-cwd", "/tmp"
          ], argv

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show(event_id)[:event]
          assert_equal LAB_REQUEST_ID, event.metadata["lab_request_id"]
          assert_equal "created", event.metadata["lab_request_state"]
        end
      end
    end
  end

  def test_ask_binds_generated_request_id_and_prints_lab_id
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli(["ask", "Continue?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 0, result[:exit_code], result[:stderr]
          argv = captured_argv
          local_id = argv[argv.index("--id") + 1]
          assert_match(/\Ahitl-[0-9a-f]{16}\Z/, local_id)
          # The lab tool echoes the request id; ask prints the lab-side id.
          assert_equal LAB_REQUEST_ID, result[:stdout][/Lab request: (\S+)/, 1]
        end
      end
    end
  end

  def test_ask_defaults_attempt_from_lab_attempt_id_env
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          with_env("LAB_ATTEMPT_ID" => "A-000000000000000000000000") do
            result = run_cli(["ask", "Env attempt?", "--work", "W685"])

            assert_equal 0, result[:exit_code], result[:stderr]
            argv = captured_argv
            assert_equal "A-000000000000000000000000", argv[argv.index("--attempt") + 1]
          end
        end
      end
    end
  end

  def test_ask_invalid_effect_declaration_fails_before_any_external_call
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli([
            "ask", "Bad declaration?",
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--effect-arg", "/bin/false",
            "--effect-cwd", "relative/path"
          ])

          assert_equal 1, result[:exit_code]
          assert_match(/must be an absolute path/, result[:stderr])
          refute File.exist?(@capture_path), "lab-hitl must not be invoked on invalid declarations"

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
        end
      end
    end
  end

  def test_ask_requires_work
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli(["ask", "No work?", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/--work required/, result[:stderr])
          refute File.exist?(@capture_path)
        end
      end
    end
  end

  def test_ask_requires_attempt
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          with_env("LAB_ATTEMPT_ID" => nil) do
            result = run_cli(["ask", "No attempt?", "--work", "W685"])

            assert_equal 1, result[:exit_code]
            assert_match(/--attempt required/, result[:stderr])
            refute File.exist?(@capture_path)
          end
        end
      end
    end
  end

  def test_ask_surfaces_lab_failure
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin(exit_code: 1) do
          result = run_cli(["ask", "Failing lab?", "--work", "BAD", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/lab-hitl request failed/, result[:stderr])
          assert_match(/invalid work id/, result[:stderr])
        end
      end
    end
  end

  def test_ask_is_registered_in_help
    result = run_cli(["help"])

    assert_equal 0, result[:exit_code]
    assert_match(/ask/, result[:stdout])
  end
end
