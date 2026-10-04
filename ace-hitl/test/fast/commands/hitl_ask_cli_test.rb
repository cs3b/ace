# frozen_string_literal: true

require "test_helper"
require "etc"
require "socket"
require "json"

# Test successor of HitlAskCliTest (spec 8wm.t.y21 §10): `ace-hitl ask`
# creates the local event and the NATIVE relay request through the
# provider=lab store, with the binding policy served over a REAL
# AF_UNIX socket. The relay files land in ACE_HITL_STORE_ROOT.
class HitlAskCliTest < AceHitlTestCase
  HITL_EVENT_LINE = /HITL event: (\S+)/
  LAB_REQUEST_LINE = /Lab request: (\S+)/

  # The requester identity is the KERNEL peer identity the boundary
  # service resolves (spec 8wq.t.34i): the daemon binding reply must
  # name exactly that account for validation to pass.
  REQUESTER = Etc.getpwuid(Process.uid).name

  def setup
    super
    @raw_reply = nil
    @scratch = Dir.mktmpdir("ace-hitl-ask")
    @store_root = File.join(@scratch, "store")
    @labd_socket = File.join(@scratch, "labd.sock")
    @hitl_socket = File.join(@scratch, "hitl.sock")
    @queries = []
    @listener = UNIXServer.new(@labd_socket)
    @server = Thread.new { serve_binding }

    # The REAL boundary service runs in-process; the CLI reaches it
    # through the real client (only the root-owned grants file is
    # injected, as a document — the sanctioned seam).
    require "ace/hitl"
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(
      document: {"hitl" => {"service_uid" => Process.uid, "transport_uids" => [Process.uid]}}
    )
    @service = Ace::Hitl::Lifecycle::Service.new(
      root: @store_root,
      binding: Ace::Hitl::Providers::Lab::DaemonBinding.new(socket_path: @labd_socket),
      policy: policy,
      socket_path: @hitl_socket,
      group: "staff"
    )
    @service_thread = Thread.new { @service.run }
    @client = Ace::Hitl::Lifecycle::Client.new(socket_path: @hitl_socket, service_uid: Process.uid)
    @original_boundary_client = Ace::Hitl::Providers::Lab.method(:boundary_client)
    injected_client = @client
    Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client) { |**_options| injected_client }
    wait_for_hitl_socket
  end

  def teardown
    Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client, @original_boundary_client)
    @service&.stop
    @service_thread&.join(5)
    @service_thread&.exit
    @server.exit
    @listener.close
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
    super
  end

  def wait_for_hitl_socket
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    until File.exist?(@hitl_socket)
      raise "the boundary socket never appeared" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.02
    end
  end

  def serve_binding
    loop do
      conn = @listener.accept
      line = conn.gets("\n")
      query = line ? JSON.parse(line) : {}
      @queries << query
      conn.write(@raw_reply || JSON.generate(ok_binding_reply(query)) + "\n")
      conn.close
    end
  rescue
    nil
  end

  def ok_binding_reply(query)
    attempt = query["attempt"]
    {
      "ok" => true,
      "result" => {
        "work" => {
          "id" => query["work"],
          "project" => "ace",
          "active_attempt" => attempt,
          "assignment" => {
            "dispatch_id" => attempt.to_s.delete_prefix("A-"),
            "agent" => "admin-agy",
            "pane_id" => "s1:pA",
            "herdr_session" => "lab",
            "started_at" => 1234
          }
        },
        "attempt" => {
          "id" => attempt,
          "work" => query["work"],
          "project" => "ace",
          "state" => "working",
          "unix_user" => REQUESTER,
          "owner" => "",
          "execution" => "container",
          "herdr" => {"session" => "lab", "pane_id" => "s1:pA", "terminal_id" => "t-1"},
          "process" => {"kind" => "", "boot_id" => ""}
        }
      }
    }
  end

  def with_ask_env(herdr: {session: "w692-test", pane: "agent-1"})
    env = {
      "ACE_HITL_STORE_ROOT" => @store_root,
      "ACE_HITL_LABD_SOCKET" => @labd_socket
    }
    env["HERDR_SESSION"] = herdr && herdr[:session]
    env["HERDR_PANE"] = herdr && herdr[:pane]
    with_env(env) { yield }
  end

  def persisted_request(request_id)
    JSON.parse(File.read(File.join(@store_root, "requests", "#{request_id}.json")))
  end

  def test_ask_creates_event_and_native_relay_request_with_binding
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env do
          result = run_cli([
            "ask", "Proceed with deploy?",
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--effect-arg", "/bin/false",
            "--effect-cwd", "/tmp"
          ])

          assert_equal 0, result[:exit_code], result[:stderr]
          event_id = result[:stdout][HITL_EVENT_LINE, 1]
          request_id = result[:stdout][LAB_REQUEST_LINE, 1]
          assert_match(/\Ahitl-[0-9a-f]{16}\z/, request_id)

          # One exact narrow binding query reached the daemon.
          assert_equal(
            [{"op" => "hitl_binding", "work" => "W685", "attempt" => "A-a73ebdaeb811210d51e0251e"}],
            @queries
          )

          record = persisted_request(request_id)
          assert_equal "W685", record["work"]
          assert_equal "A-a73ebdaeb811210d51e0251e", record["attempt"]
          assert_equal event_id, record["ace_hitl_id"]
          assert_equal "Proceed with deploy?", record["question"]
          # The effect declaration persists in the deployed shape.
          assert_equal(
            {"argv" => ["/bin/false"], "cwd" => "/tmp", "match" => nil, "timeout_s" => 120},
            record["effect"]
          )
          assert_path_exists File.join(@store_root, "public", "#{request_id}.json")

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show(event_id)[:event]
          assert_equal request_id, event.metadata["lab_request_id"]
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
        with_ask_env do
          result = run_cli(["ask", "Continue?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 0, result[:exit_code], result[:stderr]
          assert_match(/Provider: lab \(ref w692-test\/agent-1, ace\.hitl\.ref\/v1\)/, result[:stdout])
          assert_equal "none", manager_effect(result[:stdout], root)
        end
      end
    end
  end

  def test_unknown_provider_fails_closed_without_event_or_request
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env do
          result = run_cli([
            "ask", "No such provider?", "--provider", "nope",
            "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"
          ])

          assert_equal 1, result[:exit_code]
          assert_match(/unknown HITL provider 'nope'/, result[:stderr])
          assert_match(/available: lab/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))
          assert_empty @queries

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
        end
      end
    end
  end

  def test_missing_herdr_session_fails_closed_without_event_or_request
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env(herdr: nil) do
          result = run_cli(["ask", "No ref?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/HERDR_SESSION is required/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))
          assert_empty @queries

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
        end
      end
    end
  end

  def test_missing_herdr_pane_fails_closed_without_event_or_request
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env(herdr: {session: "w692-test", pane: nil}) do
          result = run_cli(["ask", "No pane?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/HERDR_PANE is required/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))
          assert_empty @queries
        end
      end
    end
  end

  def test_non_json_binding_reply_fails_closed_and_surfaces_orphan_event
    with_hitl_dir do |root|
      with_cli_root(root) do
        @raw_reply = "this is not json"
        with_ask_env do
          result = run_cli(["ask", "Garbled daemon?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/HITL Attempt records are unavailable/, result[:stderr])
          orphan_id = result[:stderr][/HITL event (\S+) was created/, 1]
          refute_nil orphan_id, "error must surface the orphan local event id"
          assert_match(/never bound to a Lab request \(orphan\)/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))
        end
      end
    end
  end

  def test_binding_unavailability_fails_closed_and_reports_orphan_event
    with_hitl_dir do |root|
      with_cli_root(root) do
        # A boundary service whose binding authority (the lab daemon) is
        # absent: the store create must fail closed with the orphan
        # event surfaced.
        absent_socket = File.join(@scratch, "absent.sock")
        orphan_policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(
          document: {"hitl" => {"service_uid" => Process.uid}}
        )
        orphan_service = Ace::Hitl::Lifecycle::Service.new(
          root: @store_root,
          binding: Ace::Hitl::Providers::Lab::DaemonBinding.new(socket_path: absent_socket),
          policy: orphan_policy,
          socket_path: File.join(@scratch, "hitl-orphan.sock"),
          group: "staff"
        )
        orphan_thread = Thread.new { orphan_service.run }
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
        until File.exist?(File.join(@scratch, "hitl-orphan.sock"))
          raise "orphan socket never appeared" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

          sleep 0.02
        end
        orphan_client = Ace::Hitl::Lifecycle::Client.new(
          socket_path: File.join(@scratch, "hitl-orphan.sock"), service_uid: Process.uid
        )
        Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client) { |**_options| orphan_client }

        with_env(
          "HERDR_SESSION" => "w692-test",
          "HERDR_PANE" => "agent-1"
        ) do
          result = run_cli(["ask", "Orphaned?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 1, result[:exit_code]
          assert_match(/HITL Attempt records are unavailable/, result[:stderr])
          orphan_id = result[:stderr][/HITL event (\S+) was created/, 1]
          refute_nil orphan_id, "error must surface the orphan local event id"
          assert_match(/never bound to a Lab request \(orphan\)/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show(orphan_id)[:event]
          refute_nil event, "orphan event stays inspectable"
          assert_nil event.metadata["lab_request_id"]
        end
      ensure
        # Restore the primary boundary stub for later assertions.
        injected_client = @client
        Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client) { |**_options| injected_client }
        orphan_service.stop
        orphan_thread.join(5)
        orphan_thread.exit
      end
    end
  end

  def test_ask_rejects_environment_derived_attempt_identity
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env do
          # An environment variable is never attempt authority
          # (spec 8wq.t.34i): the visible, typed failure must happen
          # before any state is created.
          with_env("LAB_ATTEMPT_ID" => "A-000000000000000000000000") do
            result = run_cli(["ask", "Env attempt?", "--work", "W685"])

            assert_equal 1, result[:exit_code]
            assert_match(/--attempt required/, result[:stderr])
            assert_empty Dir.children(File.join(@store_root, "requests"))
          end
        end
      end
    end
  end

  def test_ask_invalid_effect_declaration_fails_before_any_store_use
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env do
          result = run_cli([
            "ask", "Bad declaration?",
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--effect-arg", "/bin/false",
            "--effect-cwd", "relative/path"
          ])

          assert_equal 1, result[:exit_code]
          assert_match(/must be an absolute path/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))
          assert_empty @queries

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_empty manager.list(in_folder: "all")
        end
      end
    end
  end

  def test_ask_cwd_less_effect_declaration_fails_typed_with_orphan_event
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env do
          result = run_cli([
            "ask", "No cwd?",
            "--work", "W685",
            "--attempt", "A-a73ebdaeb811210d51e0251e",
            "--effect-arg", "/bin/false"
          ])

          # The declaration error is a Lifecycle::Error (review F-R1 on
          # W696): the typed provider surface — clean failure with the
          # orphan local event reported — never a raw backtrace.
          assert_equal 1, result[:exit_code]
          assert_match(/--effect-cwd is required/, result[:stderr])
          orphan_id = result[:stderr][/HITL event (\S+) was created/, 1]
          refute_nil orphan_id, "error must surface the orphan local event id"
          assert_match(/never bound to a Lab request \(orphan\)/, result[:stderr])
          refute_match(/\.rb:\d+/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))

          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          event = manager.show(orphan_id)[:event]
          refute_nil event, "orphan event stays inspectable"
          assert_nil event.metadata["lab_request_id"]
        end
      end
    end
  end

  def test_ask_requires_binding_and_attempt
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env do
          result = run_cli(["ask", "No binding?", "--attempt", "A-a73ebdaeb811210d51e0251e"])
          assert_equal 1, result[:exit_code]
          assert_match(/--assignment required/, result[:stderr])

          result = run_cli(["ask", "No attempt?", "--work", "W685"])
          assert_equal 1, result[:exit_code]
          assert_match(/--attempt required/, result[:stderr])

          result = run_cli([
            "ask", "Both bindings?", "--work", "W685",
            "--assignment", "abc123", "--attempt", "A-a73ebdaeb811210d51e0251e"
          ])
          assert_equal 1, result[:exit_code]
          assert_match(/mutually exclusive/, result[:stderr])
          assert_empty Dir.children(File.join(@store_root, "requests"))
        end
      end
    end
  end

  def test_ask_without_effect_flags_records_none
    with_hitl_dir do |root|
      with_cli_root(root) do
        with_ask_env do
          result = run_cli(["ask", "Continue?", "--work", "W685", "--attempt", "A-a73ebdaeb811210d51e0251e"])

          assert_equal 0, result[:exit_code], result[:stderr]
          event_id = result[:stdout][HITL_EVENT_LINE, 1]
          manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
          assert_equal "none", manager.show(event_id)[:event].metadata["lab_request_effect"]
        end
      end
    end
  end

  private

  def manager_effect(stdout, root)
    event_id = stdout[HITL_EVENT_LINE, 1]
    manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
    manager.show(event_id)[:event].metadata["lab_request_effect"]
  end
end
