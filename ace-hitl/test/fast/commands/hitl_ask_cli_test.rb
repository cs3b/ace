# frozen_string_literal: true

require "test_helper"
require "json"

class HitlAskCliTest < AceHitlTestCase
  LAB_REQUEST_ID = "labreq777"
  HITL_EVENT_LINE = /HITL event: (\S+)/
  LAB_REQUEST_LINE = /Lab request: #{LAB_REQUEST_ID}/

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

  def with_stub_lab_bin(exit_code: 0, request_id: LAB_REQUEST_ID, herdr: {session: "w692-test", pane: "agent-1"})
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

    env = {
      "ACE_HITL_LAB_BIN" => @stub_bin,
      "ACE_HITL_LAB_CAPTURE" => @capture_path
    }
    env["HERDR_SESSION"] = herdr && herdr[:session]
    env["HERDR_PANE"] = herdr && herdr[:pane]
    with_env(env) do
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
          assert_match(HITL_EVENT_LINE, result[:stdout])
          assert_match(LAB_REQUEST_LINE, result[:stdout])

          event_id = result[:stdout][HITL_EVENT_LINE, 1]
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
          assert_equal "declared", event.metadata["lab_request_effect"]
          assert_equal "lab", event.metadata["provider"]
          assert_equal "ace.hitl.ref/v1", event.metadata["ref_schema"]
          assert_equal "w692-test", event.metadata["ref_session"]
          assert_equal "agent-1", event.metadata["ref_pane"]
        end
      end
    end
  end

  def test_ask_prints_provider_and_reverse_address
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli(["ask", "Continue?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/Provider: lab \(ref w692-test\/agent-1, ace\.hitl\.ref\/v1\)/, result[:stdout])
        end
      end
    end
  end

  def test_explicit_provider_lab_dispatches
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli([
            "ask", "Explicit?", "--provider", "lab",
            "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"
          ])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(HITL_EVENT_LINE, result[:stdout])
          assert_match(LAB_REQUEST_LINE, result[:stdout])
        end
      end
    end
  end

  def test_unknown_provider_fails_closed_without_event_or_transport
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli([
            "ask", "No such provider?", "--provider", "nope",
            "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"
          ])

          assert_equal 1, result[:exit_code]
          assert_match(/unknown HITL provider 'nope'/, result[:stderr])
          assert_match(/available: lab/, result[:stderr])
          refute File.exist?(@capture_path), "transport must not be invoked for an unknown provider"

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
        end
      end
    end
  end

  def test_missing_herdr_session_fails_closed_without_event_or_transport
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin(herdr: nil) do
          result = run_cli(["ask", "No ref?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/HERDR_SESSION is required/, result[:stderr])
          refute File.exist?(@capture_path), "transport must not be invoked without a reverse address"

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
        end
      end
    end
  end

  def test_missing_herdr_pane_fails_closed_without_event_or_transport
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin(herdr: {session: "w692-test", pane: nil}) do
          result = run_cli(["ask", "No pane?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/HERDR_PANE is required/, result[:stderr])
          refute File.exist?(@capture_path), "transport must not be invoked without a reverse address"

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
        end
      end
    end
  end

  def test_invalid_herdr_pane_fails_closed
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin(herdr: {session: "w692-test", pane: "bad pane; rm"}) do
          result = run_cli(["ask", "Bad pane?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/HERDR_PANE contains invalid characters/, result[:stderr])
          refute File.exist?(@capture_path)

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
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

  def test_ask_without_effect_flags_records_none
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli(["ask", "Continue?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 0, result[:exit_code], result[:stderr]
          event_id = result[:stdout][HITL_EVENT_LINE, 1]

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show(event_id)[:event]
          assert_equal "none", event.metadata["lab_request_effect"]
        end
      end
    end
  end

  def test_ask_effect_arg_values_pass_through_verbatim
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli([
            "ask", "Padded argv?",
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--effect-arg", "  /bin/false  "
          ])

          assert_equal 0, result[:exit_code], result[:stderr]
          argv = captured_argv
          index = argv.index("--effect-arg")

          assert_equal "  /bin/false  ", argv[index + 1]
        end
      end
    end
  end

  def test_ask_whitespace_only_effect_arg_fails_before_external_call
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin do
          result = run_cli([
            "ask", "Blank argv?",
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--effect-arg", "   "
          ])

          assert_equal 1, result[:exit_code]
          assert_match(/--effect-arg #1 is empty/, result[:stderr])
          refute File.exist?(@capture_path), "lab-hitl must not be invoked on invalid declarations"
        end
      end
    end
  end

  def test_ask_lab_failure_reports_orphan_event_id
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_stub_lab_bin(exit_code: 1) do
          result = run_cli(["ask", "Orphaned?", "--work", "BAD", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/lab-hitl request failed/, result[:stderr])
          orphan_id = result[:stderr][/HITL event (\S+) was created/, 1]
          refute_nil orphan_id, "error must surface the orphan local event id"
          assert_match(/never bound to a Lab request \(orphan\)/, result[:stderr])

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show(orphan_id)[:event]
          refute_nil event, "orphan event stays inspectable"
          assert_nil event.metadata["lab_request_id"]
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
