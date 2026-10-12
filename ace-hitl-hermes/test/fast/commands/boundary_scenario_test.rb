# frozen_string_literal: true

require "test_helper"
require "openssl"
require "time"
require "support/tls_fixtures"

# The nh0-A source scenario harness (spec 8xa.t.nh0): the closed
# manifest, the closed receipt, the three fixture-driven phases, and
# the refusal semantics of every case — exercised against a LOCAL test
# double as the spec permits. The REAL boundary acceptance is the
# invocation-bound `nh0_real_incus_acceptance` receipt from the
# reviewed `bin/lab-hitl-boundary-fixture` (gad.8/gad.b); these tests
# NEVER substitute for it and are marked fixture-gated.
class BoundaryScenarioTest < AceHermesTestCase
  PROJECT_A = "proj-a"
  PROJECT_B = "proj-b"

  def setup
    @clock = -> { Time.iso8601("2026-10-12T10:00:00Z") }
    @ids = (1..99).map { |n| format("receipt-%04d", n) }.each
    # Real test-minted material: the manifest references actual files so
    # the double authority's identity simulation reads what the real
    # crossing would read.
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
      "request" => {"assignment" => "8x3test", "attempt_prefix" => "nh0a", "harness" => "agy",
                    "question" => "Proceed?", "answer" => "approved"}
    }.merge(overrides)
  end

  def credential_entry(project, material: @material[project], pin: "a" * 64)
    {"tls_client_credential" => material.merge(
      "expected_server_uri_san" => "urn:ace:hitl:#{project}:lifecycle-server",
      "expected_server_certificate_sha256" => pin
    ), "service_user" => "hitl-#{project}", "service_group" => "hitl-#{project}"}
  end

  # The scripted double authority: full lifecycle behavior for the
  # bound project, transport refusals for everything the crossing
  # refuses. Its acceptance rules mirror the real crossing's contract.
  # Simulates the authority's client-identity admission from the SAME
  # material the real crossing reads: configured pin, expected server
  # SAN project, the trusted issuing CA, the validity window and the
  # exact single client URI SAN.
  class DoubleAuthority
    attr_reader :requests, :project

    def initialize(project:, trusted_ca_file:, strict_identity: true)
      @project = project
      @trusted_ca_file = trusted_ca_file
      @strict_identity = strict_identity
      @requests = {}
    end

    def call(endpoint:, credential:)
      pinned = credential["expected_server_uri_san"]
      wrong_pin = credential["expected_server_certificate_sha256"] == ("0" * 64)
      wrong_project = pinned != "urn:ace:hitl:#{@project}:lifecycle-server"
      if @strict_identity && (wrong_pin || wrong_project || identity_material_refused?(credential))
        raise Ace::Hitl::Lifecycle::TransportError, "refused (identity mismatch)"
      end

      Session.new(self)
    end

    private

    def identity_material_refused?(credential)
      certificate = OpenSSL::X509::Certificate.new(File.read(credential["certificate_file"]))
      ca = OpenSSL::X509::Certificate.new(File.read(@trusted_ca_file))
      return true unless certificate.verify(ca.public_key)
      return true unless Time.now.between?(certificate.not_before, certificate.not_after)

      sans = uri_sans(certificate)
      sans != ["urn:ace:hitl:#{@project}:hermes-client"]
    rescue SystemCallError, IOError, OpenSSL::OpenSSLError
      true
    end

    def uri_sans(certificate)
      san = certificate.extensions.find { |extension| extension.oid == "subjectAltName" }
      return [] unless san

      san.value.split(/\s*,\s*/).select { |entry| entry.start_with?("URI:") }
        .map { |entry| entry.delete_prefix("URI:") }
    end

    class Session
      def initialize(authority)
        @authority = authority
      end

      def create(params)
        id = params.fetch("id")
        raise Ace::Hitl::Lifecycle::StateError, "duplicate id" if @authority.requests.key?(id)

        @authority.requests[id] = params.merge("state" => "created", "project" => @authority.project)
        {"id" => id, "requested" => true}
      end

      def read(id)
        request = @authority.requests[id]
        raise Ace::Hitl::Lifecycle::PermissionError, "cross-authority read is refused" unless request

        request.merge("state" => @authority.requests[id]["state"])
      end

      def deliver(id, answer)
        request = @authority.requests[id]
        raise Ace::Hitl::Lifecycle::PermissionError, "cross-authority deliver is refused" unless request

        request["state"] = "answer-delivered"
        request["answer"] = answer
        {"id" => id, "delivered" => true}
      end

      def consume(id, timeout: 0, operation: nil, deadline: nil)
        request = @authority.requests[id]
        raise Ace::Hitl::Lifecycle::PermissionError, "cross-authority consume is refused" unless request

        request["state"] = "consumed"
        {"id" => id, "answer" => request["answer"]}
      end

      def pending(project: nil)
        raise Ace::Hitl::Lifecycle::PermissionError, "foreign project" unless project == @authority.project

        @authority.requests.select { |_id, r| r["state"] == "created" }
          .map { |id, r| {"id" => id, "project" => r["project"]} }
      end

      def proposal_history(project:, query: "", after: nil)
        raise Ace::Hitl::Lifecycle::PermissionError, "foreign project" unless project == @authority.project

        {"items" => [], "next" => nil}
      end

      def proposal_due(project:, after: nil)
        raise Ace::Hitl::Lifecycle::PermissionError, "foreign project" unless project == @authority.project

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

  def build_scenario(manifest_value = manifest, strict_identity: true)
    endpoint_projects = {
      manifest_value.dig("authorities", "A", "endpoint") => manifest_value.dig("authorities", "A", "project"),
      manifest_value.dig("authorities", "B", "endpoint") => manifest_value.dig("authorities", "B", "project")
    }
    trusted_cas = {
      manifest_value.dig("authorities", "A", "endpoint") =>
        manifest_value.dig("credentials", "client_a", "tls_client_credential", "ca_file"),
      manifest_value.dig("authorities", "B", "endpoint") =>
        manifest_value.dig("credentials", "client_b", "tls_client_credential", "ca_file")
    }
    authorities = {}
    scenario = Ace::Hitl::Hermes::Boundary::Scenario.new(
      manifest: Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(manifest_value),
      client_factory: lambda do |endpoint:, credential:|
        authority = authorities[endpoint] ||= DoubleAuthority.new(
          project: endpoint_projects.fetch(endpoint), trusted_ca_file: trusted_cas.fetch(endpoint),
          strict_identity: strict_identity)
        authority.call(endpoint: endpoint, credential: credential)
      end,
      probe_factory: ->(endpoint:) { @probe ||= RefusingProbe.new },
      clock: @clock, id_generator: -> { @ids.next })
    [scenario, authorities]
  end

  # ---- manifest contract ----

  def test_manifest_rejects_unknown_fields_nulls_and_wrong_scenario
    ["schema", "invocation_id", "scenario", "authorities", "credentials", "request"].each do |field|
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
        manifest("authorities" => {"A" => {"endpoint" => "x", "project" => "p"}}))
    end
    assert_match(/exactly authorities A and B/, error.message)

    error = assert_raises(Ace::Hitl::Hermes::Boundary::Scenario::Error) do
      Ace::Hitl::Hermes::Boundary::Scenario::Manifest.new(manifest("request" => manifest["request"].merge("question" => "")))
    end
    assert_match(/request template/, error.message)
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
      scenario.run("invented")
    end
    assert_match(/unknown scenario phase/, error.message)
  end

  # ---- baseline phase (double-driven; real-boundary runs are fixture-gated) ----

  def test_baseline_passes_against_a_correct_crossing
    scenario, = build_scenario
    receipt = scenario.run("baseline")
    assert_equal true, receipt["passed"]
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

  def test_baseline_credential_negatives_fail_against_an_accepting_crossing
    # A crossing that accepts everything (a mock proxy or a diluted
    # identity check) MUST fail the scenario: the refusal cases are the
    # acceptance.
    scenario, = build_scenario(strict_identity: false)
    @probe = AcceptingProbe.new
    receipt = scenario.run("baseline")
    assert_equal false, receipt["passed"]
    failed = receipt["cases"].select { |entry| entry["passed"] == false }.map { |entry| entry["id"] }
    assert_includes failed, "N01"
    assert_includes failed, "N05"
    assert_includes failed, "N08"
  end

  def test_baseline_covers_the_declared_case_matrix
    scenario, = build_scenario
    receipt = scenario.run("baseline")
    ids = receipt["cases"].map { |entry| entry["id"] }
    ["N01", "N02", "N03", "N04", "N05", "N06", "N07", "N08", "N09", "N10", "N11",
     "P0", "P1", "P2", "P3"].each do |required|
      assert_includes ids, required, "the baseline phase must cover #{required}"
    end
  end

  # ---- uncertainty and recovery phases ----

  def test_uncertainty_and_recovery_phases_reconcile_without_replay
    scenario, = build_scenario
    uncertainty = scenario.run("uncertainty")
    assert_equal true, uncertainty["passed"], uncertainty["cases"].inspect

    # The fixture restarts services and proxies between phases; the
    # recovery phase re-observes the canonical receipts and must
    # reconcile without replay.
    recovery = scenario.run("recovery")
    assert_equal true, recovery["passed"], recovery["cases"].inspect
  end

  # ---- report ----

  def test_report_lines_are_sanitized_and_bounded
    scenario, = build_scenario
    report_path = File.join(Dir.mktmpdir("scenario-report", "/tmp"), "report.jsonl")
    receipt = scenario.run("uncertainty", report: report_path)
    lines = File.readlines(report_path).map { |line| JSON.parse(line) }
    assert_equal receipt["positive_cases"], lines.size
    lines.each do |entry|
      assert_equal receipt["receipt_id"], entry["receipt_id"]
      assert entry["case"].is_a?(Hash)
      refute_includes JSON.generate(entry), "secret"
    end
  end
end
