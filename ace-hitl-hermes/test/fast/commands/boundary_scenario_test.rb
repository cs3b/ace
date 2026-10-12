# frozen_string_literal: true

require "test_helper"
require "etc"
require "openssl"
require "time"
require "support/tls_fixtures"

# The nh0-A source scenario harness (spec 8xa.t.nh0): the closed
# manifest, the closed receipts, the local-worker ask step through the
# SUPPORTED binding mechanism (with_verified_attempt semantics), the
# host TLS phases that consume only binding-verified asks, and the
# in-slice nh0_real_incus_acceptance schema/verifier. Exercised against
# a LOCAL test double as the spec permits; the REAL boundary acceptance
# is the invocation-bound receipt from the host gad.8/gad.b fixture
# contract — these tests NEVER substitute for it, and no case claims a
# pass it did not verify.
class BoundaryScenarioTest < AceHermesTestCase
  PROJECT_A = "proj-a"
  PROJECT_B = "proj-b"

  def setup
    @clock = -> { Time.iso8601("2026-10-12T10:00:00Z") }
    @ids = (1..99).map { |n| format("receipt-%04d", n) }.each
    @material_dir = Dir.mktmpdir("boundary-material", "/tmp")
    @material = {}
    @ca_structs = {}
    %w[proj-a proj-b].each do |project|
      ca = TlsFixtures.mint_ca
      @ca_structs[project] = ca
      client = TlsFixtures.mint_identity(ca: ca,
        uri_sans: ["urn:ace:hitl:#{project}:hermes-client"], eku: "clientAuth")
      cert_path, key_path, = TlsFixtures.write_identity(@material_dir, prefix: "#{project}-client",
        identity: client)
      ca_path = File.join(@material_dir, "#{project}-ca.pem")
      File.write(ca_path, ca.cert.to_pem)
      @material[project] = {"certificate_file" => cert_path, "private_key_file" => key_path,
                            "ca_file" => ca_path}
    end
    forged_ca = TlsFixtures.mint_ca
    forged = TlsFixtures.mint_identity(ca: forged_ca,
      uri_sans: ["urn:ace:hitl:proj-a:hermes-client"], eku: "clientAuth")
    forged_paths = TlsFixtures.write_identity(@material_dir, prefix: "forged-client", identity: forged)
    forged_ca_path = File.join(@material_dir, "forged-ca.pem")
    File.write(forged_ca_path, forged_ca.cert.to_pem)
    @material["forged"] = {"certificate_file" => forged_paths[0],
                           "private_key_file" => forged_paths[1], "ca_file" => forged_ca_path}

    expired = TlsFixtures.mint_identity(ca: @ca_structs.fetch("proj-a"),
      uri_sans: ["urn:ace:hitl:proj-a:hermes-client"], eku: "clientAuth",
      not_after: -10, not_before: -100)
    expired_paths = TlsFixtures.write_identity(@material_dir, prefix: "expired-client", identity: expired)
    @material["expired"] = {"certificate_file" => expired_paths[0],
                            "private_key_file" => expired_paths[1], "ca_file" => @material["proj-a"]["ca_file"]}

    wrong_san = TlsFixtures.mint_identity(ca: @ca_structs.fetch("proj-a"),
      uri_sans: ["urn:ace:hitl:proj-a:lifecycle-server"], eku: "clientAuth")
    wrong_paths = TlsFixtures.write_identity(@material_dir, prefix: "wrongsan-client", identity: wrong_san)
    @material["wrongsan"] = {"certificate_file" => wrong_paths[0],
                             "private_key_file" => wrong_paths[1], "ca_file" => @material["proj-a"]["ca_file"]}
  end

  def teardown
    FileUtils.remove_entry(@material_dir) if @material_dir && File.exist?(@material_dir)
    super
  end

  def manifest(overrides = {})
    {
      "schema" => "ace.hitl.boundary.scenario/v1",
      "invocation_id" => "inv-0001",
      "scenario" => "nh0-a-v1",
      "authorities" => {
        "A" => {"endpoint" => "tls+tcp://host-a.tailnet.example:8443", "project" => PROJECT_A},
        "B" => {"endpoint" => "tls+tcp://host-b.tailnet.example:8443", "project" => PROJECT_B}
      },
      "credentials" => {
        "client_a" => credential_entry(PROJECT_A), "client_b" => credential_entry(PROJECT_B),
        "client_a_forged" => credential_entry(PROJECT_A, material: @material["forged"]),
        "client_a_expired" => credential_entry(PROJECT_A, material: @material["expired"]),
        "client_a_wrong_san" => credential_entry(PROJECT_A, material: @material["wrongsan"])
      },
      "asks" => {
        "A" => genuine_ask_entry, "B" => genuine_ask_entry
      },
      "payload" => {"question" => "Proceed?", "harness" => "agy", "answer" => "approved"}
    }.merge(overrides)
  end

  def credential_entry(project, material: @material[project], pin: "a" * 64)
    {"tls_client_credential" => material.merge(
      "expected_server_uri_san" => "urn:ace:hitl:#{project}:lifecycle-server",
      "expected_server_certificate_sha256" => pin
    ), "service_user" => "hitl-#{project}", "service_group" => "hitl-#{project}"}
  end

  # The fixture-declared GENUINE binding from real Assign state; the
  # scripted local authority below refuses anything else, exactly like
  # the real serve-path binding (with_verified_attempt).
  def genuine_ask_entry
    {"socket" => "/run/ace-hitl/proj-a/hitl.sock", "service_uid" => 4100,
     "worker_user" => worker_user, "assignment" => "assign900", "attempt" => "attempt900"}
  end

  def worker_user
    Etc.getpwuid(Process.euid).name
  end

  # One shared fixture store behind BOTH boundaries, exactly like the
  # real deployment: the local worker creates through the Unix boundary
  # (binding verified), the TLS crossing observes the same records. The
  # TLS side applies the client-identity admission from the SAME
  # material the real crossing reads (configured pin, expected server
  # SAN project, trusted issuing CA, validity window, exact single
  # client URI SAN); the local side applies the REAL create admission —
  # only the fixture-declared genuine assignment/attempt binds,
  # anything else raises the classified ended-attempt error like the
  # serve-path with_verified_attempt verification.
  class FixtureStoreDouble
    attr_reader :requests, :genuine

    def initialize(genuine_assignments:, trusted_ca_files:, strict_identity: true)
      @genuine = genuine_assignments
      @trusted_ca_files = trusted_ca_files
      @strict_identity = strict_identity
      @requests = {}
    end

    def local_client(project)
      LocalClient.new(self, project)
    end

    def tls_session(project)
      TlsSession.new(self, project)
    end

    def record(params)
      @requests[params.fetch("id")] = params.merge("state" => "created")
    end

    def request(id)
      @requests[id]
    end

    def identity_refused?(project, credential)
      pinned = credential["expected_server_uri_san"]
      return true if pinned != "urn:ace:hitl:#{project}:lifecycle-server"
      return true if credential["expected_server_certificate_sha256"] == ("0" * 64)
      return false unless @strict_identity


      certificate = OpenSSL::X509::Certificate.new(File.read(credential["certificate_file"]))
      ca = OpenSSL::X509::Certificate.new(File.read(@trusted_ca_files.fetch(project)))
      return true unless certificate.verify(ca.public_key)
      return true unless Time.now.between?(certificate.not_before, certificate.not_after)

      san = certificate.extensions.find { |extension| extension.oid == "subjectAltName" }
      sans = san ? san.value.split(/\s*,\s*/).select { |entry| entry.start_with?("URI:") }
        .map { |entry| entry.delete_prefix("URI:") } : []
      sans != ["urn:ace:hitl:#{project}:hermes-client"]
    rescue SystemCallError, IOError, OpenSSL::OpenSSLError
      true
    end

    class LocalClient
      def initialize(store, project)
        @store = store
        @project = project
      end

      def create(params)
        genuine = @store.genuine.fetch(@project, []).include?(
          [params.fetch("assignment"), params.fetch("attempt")])
        unless genuine
          raise Ace::Hitl::Lifecycle::EndedAttemptError,
            "HITL attempt is unknown: #{params.fetch('assignment')}/#{params.fetch('attempt')}"
        end

        @store.record(params)
        {"id" => params.fetch("id"), "requested" => true}
      end

      def consume(id, timeout: 0, operation: nil, deadline: nil)
        request = @store.request(id)
        raise Ace::Hitl::Lifecycle::PermissionError, "requester-only consume" unless request

        request["state"] = "consumed"
        {"id" => id, "answer" => request["answer"]}
      end
    end

    class TlsSession
      def initialize(store, project)
        @store = store
        @project = project
      end

      def read(id)
        request = @store.request(id)
        raise Ace::Hitl::Lifecycle::PermissionError, "cross-authority read is refused" unless request && request["project"] == @project

        request
      end

      def deliver(id, answer)
        request = @store.request(id)
        unless request && request["project"] == @project
          raise Ace::Hitl::Lifecycle::PermissionError, "cross-authority deliver is refused"
        end

        request["state"] = "answer-delivered"
        request["answer"] = answer
        {"id" => id, "delivered" => true}
      end

      def pending(project: nil)
        unless project == @project
          raise Ace::Hitl::Lifecycle::PermissionError, "foreign project pending is refused"
        end

        @store.requests.values.select { |r| r["state"] == "created" && r["project"] == project }
          .map { |r| {"id" => r["id"], "project" => r["project"]} }
      end

      def proposal_history(project:, query: "", after: nil)
        unless project == @project
          raise Ace::Hitl::Lifecycle::PermissionError, "foreign project is refused"
        end

        {"items" => [], "next" => nil}
      end

      def proposal_due(project:, after: nil)
        unless project == @project
          raise Ace::Hitl::Lifecycle::PermissionError, "foreign project is refused"
        end

        {"items" => [], "next" => nil}
      end

      def ping
        {"pong" => true}
      end
    end
  end

  class AcceptingProbe
    def handshake_without_certificate(_ca_file)
      :accepted
    end

    def cleartext_roundtrip
      :echoed
    end
  end

  class RefusingProbe
    def handshake_without_certificate(_ca_file)
      :refused
    end

    def cleartext_roundtrip
      :refused
    end
  end

  def state_path
    @state_path ||= File.join(@material_dir, "state.json")
  end

  def shared_store(manifest_value = manifest, strict_identity: true)
    FixtureStoreDouble.new(
      genuine_assignments: {
        manifest_value.dig("authorities", "A", "project") => [
          [manifest_value.dig("asks", "A", "assignment"), manifest_value.dig("asks", "A", "attempt")]],
        manifest_value.dig("authorities", "B", "project") => [
          [manifest_value.dig("asks", "B", "assignment"), manifest_value.dig("asks", "B", "attempt")]]
      },
      trusted_ca_files: {
        manifest_value.dig("authorities", "A", "project") =>
          manifest_value.dig("credentials", "client_a", "tls_client_credential", "ca_file"),
        manifest_value.dig("authorities", "B", "project") =>
          manifest_value.dig("credentials", "client_b", "tls_client_credential", "ca_file")
      },
      strict_identity: strict_identity)
  end

  def build_scenario(manifest_value = manifest, strict_identity: true, store: nil)
    store ||= shared_store(manifest_value, strict_identity: strict_identity)
    endpoint_projects = {
      manifest_value.dig("authorities", "A", "endpoint") => manifest_value.dig("authorities", "A", "project"),
      manifest_value.dig("authorities", "B", "endpoint") => manifest_value.dig("authorities", "B", "project")
    }
    scenario = Ace::Hitl::Hermes::Boundary::Scenario.new(
      manifest: Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(manifest_value),
      client_factory: lambda do |endpoint:, credential:|
        project = endpoint_projects.fetch(endpoint)
        raise Ace::Hitl::Lifecycle::TransportError, "refused (identity mismatch)" if store.identity_refused?(project, credential)

        store.tls_session(project)
      end,
      probe_factory: ->(endpoint:) { @probe ||= RefusingProbe.new },
      clock: @clock, id_generator: -> { @ids.next })
    [scenario, store]
  end

  def local_worker(authority:, stage:, manifest_value: manifest, store: nil, state: state_path)
    store ||= shared_store(manifest_value)
    project = manifest_value.dig("authorities", authority, "project")
    Ace::Hitl::Hermes::Boundary::LocalWorker.new(
      manifest: Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(manifest_value),
      state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state),
      authority: authority, stage: stage,
      local_client_factory: ->(socket:, service_uid:) { store.local_client(project) },
      clock: @clock, id_generator: -> { @ids.next })
  end

  # ---- manifest contract ----

  def test_manifest_rejects_unknown_fields_nulls_and_wrong_scenario
    ["schema", "invocation_id", "scenario", "authorities", "credentials", "asks",
     "payload"].each do |field|
      broken = manifest
      broken.delete(field)
      assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
        Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(broken)
      end
    end

    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(manifest("schema" => "other/v1"))
    end
    assert_match(/nh0-a-v1/, error.message)

    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(
        manifest("asks" => {"A" => genuine_ask_entry}))
    end
    assert_match(/asks exactly for authorities A and B/, error.message)
  end

  def test_manifest_credentials_must_pin_their_authority_project
    broken = manifest
    broken["credentials"]["client_a"]["tls_client_credential"]["expected_server_uri_san"] =
      "urn:ace:hitl:proj-b:lifecycle-server"
    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(broken)
    end
    assert_match(/pins project/, error.message)
  end

  def test_unknown_phases_are_refused
    scenario, = build_scenario
    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      scenario.run("invented", state: Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path))
    end
    assert_match(/unknown scenario phase/, error.message)
  end

  # ---- local worker ask step: supported binding, real identity mapping ----

  def test_ask_step_creates_only_through_the_genuine_binding
    store = shared_store
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    worker = local_worker(authority: "A", stage: "create", store: store)
    receipt = worker.run
    assert_equal true, receipt["passed"]
    assert_equal true, receipt["binding_verified"]
    assert_equal true, receipt["worker_identity_verified"]
    assert_equal worker_user, receipt["worker_user"]

    # A fabricated attempt is refused truthfully by the binding: the
    # ask step reports failure and never fabricates a pass.
    broken = manifest
    broken["asks"]["A"] = genuine_ask_entry.merge("attempt" => "attempt-invented")
    worker = local_worker(authority: "A", stage: "create", manifest_value: broken,
      store: store)
    receipt = worker.run
    assert_equal false, receipt["passed"]
    assert_equal false, receipt["binding_verified"]
  end

  def test_ask_step_refuses_worker_identity_mapping_mismatch
    broken = manifest
    broken["asks"]["A"] = genuine_ask_entry.merge("worker_user" => "someone-else")
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    worker = local_worker(authority: "A", stage: "create", manifest_value: broken,
      store: shared_store(broken))
    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      worker.run
    end
    assert_match(/worker identity mapping mismatch/, error.message)
  end

  # ---- baseline phase (double-driven; real-boundary runs are fixture-gated) ----

  def test_baseline_passes_against_a_correct_crossing_with_genuine_asks
    store = shared_store
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    %w[A B].each do |authority|
      receipt = local_worker(authority: authority, stage: "create", store: store).run
      assert_equal true, receipt["passed"]
    end

    scenario, = build_scenario(store: store)
    receipt = scenario.run("baseline", state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path))
    assert_equal true, receipt["passed"], receipt["cases"].reject { |c| c["passed"] }.inspect
    assert_equal "nh0_a_source_scenario", receipt["type"]
    assert_equal 1, receipt["version"]
    assert_equal "inv-0001", receipt["invocation_id"]
    assert_equal "nh0-a-v1", receipt["scenario"]
    assert_equal "baseline", receipt["phase"]
    assert_match(/\Areceipt-\d{4}\z/, receipt["receipt_id"])
    assert_equal Time.iso8601("2026-10-12T10:00:00Z"), Time.iso8601(receipt["completed_at"])
    assert_operator receipt["positive_cases"], :>=, 1
    assert_operator receipt["negative_cases"], :>=, 9
    assert_equal receipt["positive_cases"] + receipt["negative_cases"], receipt["cases"].size
    assert receipt["cases"].all? { |entry| entry["passed"] == true }
    kinds = receipt["cases"].map { |entry| entry["kind"] }.uniq.sort
    assert_equal %w[negative positive], kinds
  end

  def test_baseline_reports_missing_asks_truthfully
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    scenario, = build_scenario
    receipt = scenario.run("baseline", state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path))
    assert_equal false, receipt["passed"]
    p0 = receipt["cases"].find { |entry| entry["id"] == "P0" }
    assert_equal false, p0["passed"]
  end

  def test_baseline_credential_negatives_fail_against_an_accepting_crossing
    # A crossing that accepts everything (a mock proxy or a diluted
    # identity check) MUST fail the scenario: the refusal cases are the
    # acceptance.
    store = shared_store(strict_identity: false)
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    %w[A B].each do |authority|
      local_worker(authority: authority, stage: "create", store: store).run
    end

    scenario, = build_scenario(strict_identity: false, store: store)
    @probe = AcceptingProbe.new
    receipt = scenario.run("baseline", state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path))
    assert_equal false, receipt["passed"]
    failed = receipt["cases"].select { |entry| entry["passed"] == false }.map { |entry| entry["id"] }
    assert_includes failed, "N01"
    assert_includes failed, "N02"
    assert_includes failed, "N03"
    assert_includes failed, "N04"
    assert_includes failed, "N08"
    # The configured fingerprint pin is the client's own contract and is
    # never diluted by a diluted server: N05 still refuses.
    refute_includes failed, "N05"
  end

  def test_baseline_covers_the_declared_case_matrix
    store = shared_store
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    %w[A B].each do |authority|
      local_worker(authority: authority, stage: "create", store: store).run
    end

    scenario, = build_scenario(store: store)
    receipt = scenario.run("baseline", state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path))
    ids = receipt["cases"].map { |entry| entry["id"] }
    ["N01", "N02", "N03", "N04", "N05", "N06", "N07", "N08", "N09", "N10", "N11",
     "P0", "P1", "P2", "P3", "P4"].each do |required|
      assert_includes ids, required, "the baseline phase must cover #{required}"
    end
  end

  # ---- uncertainty and recovery phases ----

  def test_uncertainty_and_recovery_phases_reconcile_without_replay
    store = shared_store
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    %w[A B].each do |authority|
      receipt = local_worker(authority: authority, stage: "create", store: store).run
      assert_equal true, receipt["passed"]
    end

    scenario, = build_scenario(store: store)
    # Real phase order: ask create -> baseline (main asks answered) ->
    # uncertainty (mid-flight deliver) -> fixture restarts -> recovery.
    baseline = scenario.run("baseline", state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path))
    assert_equal true, baseline["passed"], baseline["cases"].reject { |c| c["passed"] }.inspect

    uncertainty = scenario.run("uncertainty",
      state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path))
    assert_equal true, uncertainty["passed"], uncertainty["cases"].reject { |c| c["passed"] }.inspect

    # The fixture restarts services and proxies between phases; the
    # recovery phase re-observes the canonical receipts and must
    # reconcile without replay. The local worker settles the answers.
    recovery = scenario.run("recovery",
      state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path))
    assert_equal true, recovery["passed"], recovery["cases"].reject { |c| c["passed"] }.inspect

    settle = local_worker(authority: "A", stage: "settle", store: store).run
    assert_equal true, settle["passed"], settle.inspect
  end

  # ---- report ----

  def test_report_lines_are_sanitized_and_bounded
    store = shared_store
    Ace::Hitl::Hermes::Boundary::Scenario::State.empty(state_path)
    local_worker(authority: "A", stage: "create", store: store).run

    scenario, = build_scenario(store: store)
    report_path = File.join(@material_dir, "report.jsonl")
    receipt = scenario.run("uncertainty", state: Ace::Hitl::Hermes::Boundary::Scenario::State.load(state_path),
      report: report_path)
    lines = File.readlines(report_path).map { |line| JSON.parse(line) }
    assert_equal receipt["positive_cases"], lines.size
    lines.each do |entry|
      assert_equal receipt["receipt_id"], entry["receipt_id"]
      assert entry["case"].is_a?(Hash)
    end
  end

  # ---- the host fixture's invocation-bound acceptance receipt ----

  def acceptance_receipt(overrides = {})
    {
      "type" => "nh0_real_incus_acceptance",
      "version" => 1,
      "invocation_id" => "inv-777",
      "scenario" => "nh0-a-v1",
      "ace_head" => "a" * 40,
      "lab_config_head" => "b" * 40,
      "provision" => {
        "instance_id" => "incus-nh0a-777",
        "project_ids" => ["A", "B"],
        "proxy_configuration_sha256" => "c" * 64,
        "credential_layout_sha256" => "d" * 64,
        "server_certificate_sha256s" => ["e" * 64, "f" * 64],
        "client_certificate_sha256s" => ["0" * 64, "1" * 64],
        "completed_at" => "2026-10-12T10:00:00Z"
      },
      "test" => {
        "command" => "ace-hitl-boundary-scenario run --manifest /run/manifest.json --phase baseline --state /run/state.json",
        "receipt_ids" => ["receipt-0001", "receipt-0002"],
        "passed" => true,
        "positive_cases" => 6,
        "negative_cases" => 11,
        "completed_at" => "2026-10-12T10:05:00Z"
      },
      "teardown" => {
        "services_stopped" => true,
        "proxy_devices_removed" => true,
        "firewall_removed" => true,
        "instance_destroyed" => true,
        "credential_files_removed" => true,
        "completed_at" => "2026-10-12T10:06:00Z"
      },
      "evidence_sha256" => "9" * 64
    }.merge(overrides)
  end

  def test_acceptance_receipt_parses_and_verifies_against_the_exact_head
    receipt = Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(acceptance_receipt)
    assert_same receipt, receipt.verify!(ace_head: "a" * 40)
  end

  def test_acceptance_receipt_rejects_foreign_head_failed_test_and_incomplete_teardown
    receipt = Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(acceptance_receipt)
    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      receipt.verify!(ace_head: "f" * 40)
    end
    assert_match(/names head/, error.message)

    failed = Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
      acceptance_receipt("test" => acceptance_receipt["test"].merge("passed" => false)))
    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      failed.verify!(ace_head: "a" * 40)
    end
    assert_match(/did not pass/, error.message)

    partial = Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
      acceptance_receipt("teardown" => acceptance_receipt["teardown"].merge("instance_destroyed" => false)))
    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      partial.verify!(ace_head: "a" * 40)
    end
    assert_match(/teardown is incomplete/, error.message)
  end

  def test_acceptance_receipt_schema_is_closed_and_counts_are_exact
    assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
        acceptance_receipt("phantom_field" => "x"))
    end
    assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
        acceptance_receipt("provision" => acceptance_receipt["provision"].merge("instance_id" => nil)))
    end
    [["positive_cases", 0], ["negative_cases", 8]].each do |field, count|
      assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
        Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
          acceptance_receipt("test" => acceptance_receipt["test"].merge(field => count)))
      end
    end
    assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
        acceptance_receipt("test" => acceptance_receipt["test"].merge(
          "receipt_ids" => ["receipt-0001", "receipt-0001"])))
    end
    assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
        acceptance_receipt("provision" => acceptance_receipt["provision"].merge(
          "project_ids" => ["A", "A"])))
    end
    assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::AcceptanceReceipt.parse(
        acceptance_receipt("teardown" => acceptance_receipt["teardown"].merge(
          "completed_at" => "yesterday")))
    end
  end
end
