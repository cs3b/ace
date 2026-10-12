# frozen_string_literal: true

require "test_helper"
require "socket"
require "openssl"
require "tmpdir"
require "digest"
require "etc"
require "time"
require "ace/hitl/hermes/runtime"
require "support/tls_fixtures"

# The Hermes runtime over the host/Incus crossing (spec 8xa.t.nh0,
# G-A): remote channels build endpoint+credential routes, clients cache
# per endpoint PLUS credential identity, activation is atomic behind
# authenticated health + project-binding checks, and the full
# bidirectional lifecycle crosses a REAL loopback mTLS boundary (the
# real Incus proxy boundary joins the reviewed gad.8/gad.b fixture).
class RuntimeTlsRoutingTest < AceHermesTestCase
  SERVER_SAN = "urn:ace:hitl:proj-a:lifecycle-server"
  CLIENT_SAN = "urn:ace:hitl:proj-a:hermes-client"
  DNS_NAME = "localhost.localdomain"

  def setup
    @tmp = Dir.mktmpdir("hermes-tls-routing", "/tmp")
    @ca = TlsFixtures.mint_ca
    @server = TlsFixtures.mint_identity(ca: @ca, uri_sans: [SERVER_SAN], dns_names: [DNS_NAME],
      eku: "serverAuth")
    @client = TlsFixtures.mint_identity(ca: @ca, uri_sans: [CLIENT_SAN], eku: "clientAuth")
    @cert_path, @key_path, = TlsFixtures.write_identity(@tmp, prefix: "server", identity: @server)
    @client_cert, @client_key, = TlsFixtures.write_identity(@tmp, prefix: "client", identity: @client)
    @ca_file = File.join(@tmp, "ca.pem")
    File.write(@ca_file, @ca.cert.to_pem)
    @services = []
    @threads = []
    @channel_seq = 0
  end

  def teardown
    @services.each(&:stop)
    @threads.each do |thread|
      thread.join(2) rescue nil
      thread.kill rescue nil
    end
    FileUtils.remove_entry(@tmp) if @tmp && File.exist?(@tmp)
    super
  end

  def client_credential(project: "proj-a", pin: nil)
    {
      "certificate_file" => @client_cert, "private_key_file" => @client_key,
      "ca_file" => @ca_file,
      "expected_server_uri_san" => "urn:ace:hitl:#{project}:lifecycle-server",
      "expected_server_certificate_sha256" => pin || TlsFixtures.fingerprint(@server.cert)
    }
  end

  def registry_path(channels)
    path = File.join(@tmp, "channels-#{@services.object_id}.json")
    File.write(path, JSON.generate({"schema" => "ace.hitl.hermes.channels/v1", "channels" => channels}))
    path
  end

  def channel(name:, endpoint:, project:, credential:)
    @channel_seq += 1
    {"name" => name, "chat_id" => "-42424#{@channel_seq}", "captain_user_ids" => ["42"], "machine" => "lab",
     "folder" => File.join(@tmp, name), "target" => "lab-#{name}", "projects" => [project],
     "hitl_endpoint" => endpoint, "tls_client_credential" => credential}
  end

  def runtime_config(registry_path)
    path = File.join(@tmp, "runtime-#{@services.object_id}.json")
    File.write(path, JSON.generate({
      "schema" => "ace.hitl.hermes.runtime/v1", "registry" => registry_path,
      "state" => File.join(@tmp, "state"), "hitl_socket" => File.join(@tmp, "default.sock"),
      "polling_owner" => "ace-hitl-hermes", "hermes_gateway_config" => gateway_path,
      "tls_service_user" => Etc.getpwuid(Process.euid).name,
      "tls_service_group" => Etc.getgrgid(Process.gid).name
    }))
    path
  end

  def gateway_path
    path = File.join(@tmp, "gateway.yml")
    File.write(path, "platforms:\n  telegram:\n    enabled: false\n") unless File.exist?(path)
    path
  end

  def start_authority
    context = Ace::Hitl::Lifecycle::TlsMaterial.build_server_context(server_credential)
    binding_stub = Class.new do
      def validate_request(**_kwargs)
        nil
      end

      def with_active(**_kwargs)
        yield
      end
    end.new
    service = Ace::Hitl::Lifecycle::TlsService.new(
      root: Dir.mktmpdir("authority-store", @tmp), binding: binding_stub, project: "proj-a",
      credential: server_credential, ssl_context: context, listen: "::1", port: 0,
      group: Etc.getgrgid(Process.gid).name)
    thread = Thread.new do
      begin
        service.run
      rescue StandardError
        nil
      end
    end
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    until service.port.to_i.positive? && thread.alive?
      raise "authority never started" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.02
    end
    @services << service
    @threads << thread
    service.port
  end

  def server_credential
    {
      "certificate_file" => @cert_path, "private_key_file" => @key_path, "ca_file" => @ca_file,
      "server_uri_san" => SERVER_SAN, "allowed_client_uri_san" => CLIENT_SAN,
      "allowed_client_certificate_sha256" => TlsFixtures.fingerprint(@client.cert)
    }
  end

  # The recording seam proves the runtime WIRES the provisioning-layout
  # verification; the strict ownership matrix itself joins the
  # root-gated CredentialPathPolicy tests and gad.8/gad.b.
  class PermissiveVerifier
    attr_reader :verified

    def initialize
      @verified = []
    end

    def verify_runtime_file!(path)
      @verified << [:runtime_file, path]
      self
    end

    def verify_credential_tree!(credential)
      @verified << [:credential_tree, credential.fetch("private_key_file")]
      self
    end
  end

  def build_runtime(channels, verifier: PermissiveVerifier.new)
    runtime = Ace::Hitl::Hermes::Runtime.new(runtime_config(registry_path(channels)),
      credential_path_verifier: verifier)
    [runtime, verifier]
  end

  def test_activation_refuses_until_every_authority_passes_the_health_check
    # A channel whose authority is down blocks the WHOLE activation.
    dead = channel(name: "dead", endpoint: "tls+tcp://localhost.localdomain:1",
      project: "proj-a", credential: client_credential)
    runtime, = build_runtime([dead])
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      runtime.send(:verify_authorities!)
    end
    assert_match(/failed the activation health check/, error.message)
  end

  def test_activation_passes_and_routes_cross_the_real_loopback_boundary
    port = start_authority
    channel_entry = channel(name: "gad", endpoint: "tls+tcp://#{DNS_NAME}:#{port}",
      project: "proj-a", credential: client_credential)
    runtime, verifier = build_runtime([channel_entry])
    runtime.send(:verify_authorities!)
    assert verifier.verified.any? { |entry| entry.first == :credential_tree }

    client = runtime.send(:lifecycle_for, "gad")
    assert_kind_of Ace::Hitl::Hermes::Transport::TlsClient, client
    created = client.create("id" => "hitl9001", "assignment" => "8x3test", "attempt" => "a1b2c3",
      "kind" => "text", "project" => "proj-a", "harness" => "agy", "plan" => "test",
      "question" => "Proceed?", "ace_hitl_id" => "ace-hitl-1")
    assert_equal "hitl9001", created["id"]
    delivered = client.deliver("hitl9001", "approved")
    assert_equal true, delivered["delivered"]
    consumed = client.consume("hitl9001", timeout: 5)
    assert_equal "approved", consumed["answer"]
  end

  def test_clients_cache_per_endpoint_plus_credential_identity
    same_endpoint_twice = channel(name: "one", endpoint: "tls+tcp://#{DNS_NAME}:1",
      project: "proj-a", credential: client_credential)
    channel_two = channel(name: "two", endpoint: "tls+tcp://other.tailnet.example:2",
      project: "proj-b", credential: client_credential(project: "proj-b"))
    channel_wrong_pin = channel(name: "three", endpoint: "tls+tcp://other.tailnet.example:2",
      project: "proj-c", credential: client_credential(project: "proj-c", pin: "0" * 64))
    runtime, = build_runtime([same_endpoint_twice, channel_two, channel_wrong_pin])

    one = runtime.send(:lifecycle_for, "one")
    two = runtime.send(:lifecycle_for, "two")
    three = runtime.send(:lifecycle_for, "three")
    refute_same one, two
    refute_same two, three
    assert_same two, runtime.send(:lifecycle_for, "two")
    assert_same three, runtime.send(:lifecycle_for, "three")
  end

  def test_runtime_requires_the_tls_service_identity_for_remote_channels
    port = start_authority
    channel_entry = channel(name: "gad", endpoint: "tls+tcp://#{DNS_NAME}:#{port}",
      project: "proj-a", credential: client_credential)
    config_path = runtime_config(registry_path([channel_entry]))
    config = JSON.parse(File.read(config_path))
    config.delete("tls_service_user")
    config.delete("tls_service_group")
    File.write(config_path, JSON.generate(config))
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      Ace::Hitl::Hermes::Runtime.new(config_path, credential_path_verifier: PermissiveVerifier.new)
    end
    assert_match(/tls_service_user/, error.message)
  end

  def test_runtime_refuses_unprovisioned_credential_trees
    port = start_authority
    channel_entry = channel(name: "gad", endpoint: "tls+tcp://#{DNS_NAME}:#{port}",
      project: "proj-a", credential: client_credential)
    config_path = runtime_config(registry_path([channel_entry]))
    # The referenced tree does not follow the exact provisioning layout
    # (files owned by the test identity, not the exact modes): startup
    # refuses before any connection.
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      Ace::Hitl::Hermes::Runtime.new(config_path)
    end
    assert_match(/TLS deployment is not provisioned/, error.message)
  end

  def test_rollback_preserves_offsets_receipts_and_never_replays
    # Rollback stops the sole poller: durable journal state (offsets,
    # coverage generation, submitted receipts) survives, a lifecycle
    # call across the vanished crossing is never silently replayed, and
    # no send happens after the poller stops.
    registry_entries = [channel(name: "gad", endpoint: "tls+tcp://#{DNS_NAME}:1",
      project: "proj-a", credential: client_credential)]
    registry_object = Ace::Hitl::Hermes::Transport::Registry.new(
      {"schema" => "ace.hitl.hermes.channels/v1", "channels" => registry_entries})
    journal = Ace::Hitl::Hermes::Transport::Journal.new(File.join(@tmp, "rollback-state"))
    state = nil
    journal.synchronize do |journal_state, commit|
      journal_state["cursor"] = {"offset" => 9899, "through" => "2026-09-24T10:00:00Z",
        "generation" => 3, "coverage_from" => "2026-09-24T10:00:00Z"}
      journal_state["requests"]["[\"gad\",\"rt001\"]"] = {
        "request" => "rt001", "revision" => "rev1", "channel" => "gad", "chat_id" => "-424242",
        "binding" => "b1", "sensitive" => false, "status" => "submitted", "message_id" => "100",
        "submitted_at" => "2026-09-24T10:01:00Z", "coverage_generation" => 3}
      commit.call
    end

    # The crossing is gone after rollback: every lifecycle call fails.
    failing = Object.new
    failing.define_singleton_method(:read) do |_id|
      raise Ace::Hitl::Lifecycle::TransportError, "HITL TLS boundary is unavailable"
    end
    failing.define_singleton_method(:deliver) do |_id, _answer|
      raise Ace::Hitl::Lifecycle::TransportError, "HITL TLS boundary is unavailable"
    end
    relay = Ace::Hitl::Hermes::Transport::Relay.new(
      registry: registry_object, journal: journal, lifecycle_for: ->(_channel) { failing },
      sender: ->(_channel, _question) { raise "must never send after rollback" },
      clock: -> { Time.iso8601("2026-09-24T10:05:00Z") })

    error = assert_raises(StandardError) do
      relay.submit(channel: "gad", request: "rt001", revision: "rev1")
    end
    assert_kind_of Ace::Hitl::Lifecycle::TransportError, error
    journal.synchronize do |journal_state|
      state = JSON.parse(JSON.generate(journal_state))
    end
    assert_equal 9899, state.dig("cursor", "offset")
    assert_equal 3, state.dig("cursor", "generation")
    record = state.fetch("requests").fetch("[\"gad\",\"rt001\"]")
    assert_equal "submitted", record["status"]
    # A restarted poller reconciles from the SAME durable state.
    assert_equal "rt001", record["request"]
  end
end
