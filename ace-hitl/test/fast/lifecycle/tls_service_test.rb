# frozen_string_literal: true

require "test_helper"
require "socket"
require "openssl"
require "support/lifecycle_fixtures"
require "support/tls_fixtures"
require "open3"
require "timeout"

# The TLS lifecycle authority of the host/Incus crossing (spec
# 8xa.t.nh0): the REAL TlsService and raw OpenSSL peers talk over a
# REAL 127.0.0.1 TLS 1.3 listener in-process. The verified project-
# scoped client certificate is the whole identity — single URI SAN,
# exact fingerprint pin, issuing CA and clientAuth EKU, checked BEFORE
# any lifecycle frame — and the bound project is the only reachable
# authority. (The real Incus proxy boundary joins the reviewed
# gad.8/gad.b fixture; these tests never substitute for it.)
class TlsServiceTest < AceHitlTestCase
  include LifecycleFixtures

  PROJECT = "proj-a"
  SERVER_SAN = "urn:ace:hitl:#{PROJECT}:lifecycle-server"
  CLIENT_SAN = "urn:ace:hitl:#{PROJECT}:hermes-client"
  DNS_NAME = "host-a.tailnet.example"

  def setup
    @scratch = Dir.mktmpdir("ace-hitl-tls", "/tmp")
    @ca = TlsFixtures.mint_ca
    @server = TlsFixtures.mint_identity(ca: @ca, uri_sans: [SERVER_SAN], dns_names: [DNS_NAME],
      eku: "serverAuth")
    @client = TlsFixtures.mint_identity(ca: @ca, uri_sans: [CLIENT_SAN], eku: "clientAuth")
    @paths = write_material
    @variants = {}
    @server_variants = {}
    @store_root = File.join(@scratch, "store")
    @binding = LifecycleFixtures::TestBinding.new
    @service = nil
    @thread = nil
  end

  def teardown
    @service&.stop
    @thread&.join(5)
    @thread&.kill
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
  end

  def start_service(server_variant: nil, credential: nil, port: 0, decision_policy: Ace::Hitl::Lifecycle::AccessPolicy.new)
    credential ||= server_credential(server_variant)
    context = Ace::Hitl::Lifecycle::TlsMaterial.build_server_context(credential)
    @service = Ace::Hitl::Lifecycle::TlsService.new(
      root: @store_root, binding: @binding, project: PROJECT, credential: credential,
      ssl_context: context, listen: "127.0.0.1", port: port, group: Etc.getgrgid(Process.gid).name,
      logger: ->(message) { warn message }, decision_policy: decision_policy
    )
    @thread = Thread.new { @service.run }
    wait_for_port
    @service.port
  end

  def test_authenticated_project_client_completes_the_lifecycle_through_tls
    start_service
    client = peer

    assert_equal true, client.request("ping")["pong"]
    created = client.request("create", managed_args)
    assert_equal "hitl001", created["id"]

    facts = client.request("read", {"id" => "hitl001"})
    assert_equal "created", facts["state"]
    refute_includes JSON.generate(facts), "answer"

    delivered = client.request("deliver", {"id" => "hitl001", "answer" => "approved"})
    assert_equal true, delivered["delivered"]
    consumed = client.request("consume", {"id" => "hitl001", "timeout" => 2})
    assert_equal "approved", consumed["answer"]
  end

  def test_service_admits_exactly_the_pinned_client_identity
    start_service

    # A different client certificate from the SAME CA never grants the
    # project: the single allowed SAN/fingerprint pair is the identity.
    other = TlsFixtures.mint_identity(ca: @ca, uri_sans: [CLIENT_SAN], eku: "clientAuth")
    write_variant("other", other)
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      peer(variant: "other").request("ping")
    end
    assert_match(/certificate fingerprint does not match the configured pin/, error.message)
    assert_empty store_requests
  end

  def test_missing_client_certificate_is_refused_before_any_frame
    start_service
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      peer(present_identity: false).request("ping")
    end
    assert_empty store_requests
  end

  def test_forged_ca_and_expired_certificates_are_refused
    start_service

    forged_ca = TlsFixtures.mint_ca(cn: "forged CA")
    forged = TlsFixtures.mint_identity(ca: forged_ca, uri_sans: [CLIENT_SAN], eku: "clientAuth")
    write_variant("forged", forged, ca: forged_ca)
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      peer(variant: "forged").request("ping")
    end

    expired = TlsFixtures.mint_identity(ca: @ca, uri_sans: [CLIENT_SAN], eku: "clientAuth",
      not_after: -10, not_before: -100)
    write_variant("expired", expired)
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      peer(variant: "expired").request("ping")
    end
    assert_empty store_requests
  end

  def test_wrong_san_and_missing_client_eku_are_refused
    start_service

    wrong_san = TlsFixtures.mint_identity(ca: @ca,
      uri_sans: ["urn:ace:hitl:proj-b:hermes-client"], eku: "clientAuth")
    write_variant("wrongsan", wrong_san)
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      peer(variant: "wrongsan").request("ping")
    end

    no_eku = TlsFixtures.mint_identity(ca: @ca, uri_sans: [CLIENT_SAN])
    write_variant("noeku", no_eku)
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      peer(variant: "noeku").request("ping")
    end
    assert_empty store_requests
  end

  def test_server_identity_material_is_validated_before_binding
    wrong_san_server = TlsFixtures.mint_identity(ca: @ca,
      uri_sans: ["urn:ace:hitl:other:lifecycle-server"], dns_names: [DNS_NAME], eku: "serverAuth")
    error = assert_raises(Ace::Hitl::Lifecycle::Error) do
      Ace::Hitl::Lifecycle::TlsMaterial.build_server_context(
        server_credential_material(write_server_material(wrong_san_server, "wrong-san")))
    end
    assert_match(/exact single expected URI SAN/, error.message)

    no_eku_server = TlsFixtures.mint_identity(ca: @ca, uri_sans: [SERVER_SAN], dns_names: [DNS_NAME])
    error = assert_raises(Ace::Hitl::Lifecycle::Error) do
      Ace::Hitl::Lifecycle::TlsMaterial.build_server_context(
        server_credential_material(write_server_material(no_eku_server, "no-eku")))
    end
    assert_match(/serverAuth EKU/, error.message)

    mismatched_key = OpenSSL::PKey::RSA.new(2048)
    key_path = File.join(@scratch, "mismatch-key.pem")
    File.write(key_path, mismatched_key.to_pem)
    material = write_server_material(@server, "mismatch")
    error = assert_raises(Ace::Hitl::Lifecycle::Error) do
      Ace::Hitl::Lifecycle::TlsMaterial.build_server_context(
        server_credential_material(material.merge(key: key_path)))
    end
    assert_match(/does not match its certificate/, error.message)
  end

  def test_cleartext_clients_never_observe_lifecycle_bytes
    port = start_service
    socket = TCPSocket.new("127.0.0.1", port)
    begin
      socket.write("GET / HTTP/1.0\r\n\r\n")
      socket.wait_readable(5)
      echoed = socket.read_nonblock(4096, exception: false)
    rescue SystemCallError, IOError
      echoed = nil
    ensure
      socket.close
    end
    # No cleartext answer and no lifecycle frame is ever served.
    assert (echoed.nil? || echoed.empty?), "the authority echoed cleartext bytes: #{echoed.inspect}"
    assert_empty store_requests
  end

  def test_bound_project_is_the_only_reachable_authority
    start_service
    client = peer
    client.request("create", managed_args)

    # The verified peer is bound to PROJECT: another project's flows are
    # refused BEFORE store access, in both directions.
    error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      client.request("pending", {"project" => "proj-b"})
    end
    assert_match(/never serves project/, error.message)

    error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      client.request("states")
    end
    assert_match(/only project/, error.message)

    page = client.request("pending", {"project" => PROJECT})
    assert_equal ["hitl001"], page["items"].map { |item| item["id"] }
  end

  def test_tls_1_2_peers_are_refused
    start_service
    tcp = TCPSocket.new("127.0.0.1", @service.port)
    context = OpenSSL::SSL::SSLContext.new
    context.set_params
    context.min_version = OpenSSL::SSL::TLS1_2_VERSION
    context.max_version = OpenSSL::SSL::TLS1_2_VERSION
    context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ssl = OpenSSL::SSL::SSLSocket.new(tcp, context)
    error = assert_raises(OpenSSL::SSL::SSLError, SystemCallError, IOError) do
      ssl.connect
    ensure
      ssl.close rescue nil
    end
    refute_nil error
  end

  # ---- helpers ----

  def write_material
    cert_path, key_path, = TlsFixtures.write_identity(@scratch, prefix: "server",
      identity: @server)
    client_cert, client_key, = TlsFixtures.write_identity(@scratch, prefix: "client", identity: @client)
    ca_file = File.join(@scratch, "ca.pem")
    File.write(ca_file, @ca.cert.to_pem)
    {cert: cert_path, key: key_path, ca: ca_file, client_cert: client_cert, client_key: client_key}
  end

  def write_variant(name, identity, ca: @ca)
    cert_path, key_path, = TlsFixtures.write_identity(@scratch, prefix: name, identity: identity)
    ca_file = File.join(@scratch, "#{name}-ca.pem")
    File.write(ca_file, ca.cert.to_pem)
    @variants[name] = {cert: cert_path, key: key_path, ca: ca_file}
  end

  def write_server_material(identity, name)
    cert_path, key_path, = TlsFixtures.write_identity(@scratch, prefix: "srv-#{name}", identity: identity)
    @server_variants[name] = {cert: cert_path, key: key_path}
  end

  def server_credential(variant = nil)
    server_credential_material(variant ? @server_variants.fetch(variant) : @paths)
  end

  def server_credential_material(material)
    {
      "certificate_file" => material[:cert], "private_key_file" => material[:key],
      "ca_file" => @paths[:ca],
      "server_uri_san" => SERVER_SAN, "allowed_client_uri_san" => CLIENT_SAN,
      "allowed_client_certificate_sha256" => TlsFixtures.fingerprint(@client.cert)
    }
  end

  # A raw OpenSSL peer speaking the exact bounded lifecycle frames.
  # Transport-class failures (handshake refusal, identity refusal and
  # abrupt close) surface as the classified transport error, exactly
  # like the production client observes them.
  def peer(variant: nil, present_identity: true)
    context = OpenSSL::SSL::SSLContext.new
    context.set_params
    context.min_version = OpenSSL::SSL::TLS1_3_VERSION
    context.max_version = OpenSSL::SSL::TLS1_3_VERSION
    context.ca_file = @paths[:ca]
    context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    if present_identity
      material = variant ? @variants.fetch(variant) : @paths
      context.cert = OpenSSL::X509::Certificate.new(File.read(material[:client_cert] || material[:cert]))
      context.key = OpenSSL::PKey.read(File.read(material[:client_key] || material[:key]))
    end
    TlsPeer.new(port: -> { @service.port }, context: context, server_name: DNS_NAME)
  end

  def managed_args
    {"id" => "hitl001", "assignment" => "8x3test", "attempt" => "a1b2c3", "kind" => "text",
     "project" => PROJECT, "harness" => "agy", "plan" => "configure CI",
     "question" => "approve the exact change?", "ace_hitl_id" => "ace-hitl-1"}
  end

  def store_requests
    Dir.glob(File.join(@store_root, "requests", "*.json")).map { |path| File.basename(path) }
  end

  def wait_for_port
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    until @thread&.alive? && @service.port.to_i.positive? && @service.instance_variable_get(:@server)
      raise "TLS boundary never started" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      raise "TLS boundary failed: #{@thread&.value.inspect}" if @thread && !@thread.alive?

      sleep 0.02
    end
  end

  # Minimal lifecycle-frame peer used ONLY by these tests.
  class TlsPeer
    def initialize(port:, context:, server_name:)
      @port = port
      @context = context
      @server_name = server_name
    end

    def request(op, params = {})
      tcp = TCPSocket.new("127.0.0.1", @port.call)
      ssl = OpenSSL::SSL::SSLSocket.new(tcp, @context)
      ssl.sync_close = true
      ssl.hostname = @server_name
      ssl.connect
      ssl.write(Ace::Hitl::Lifecycle::Protocol.encode_request(op, params))
      Ace::Hitl::Lifecycle::Protocol.decode_response(ssl.gets("\n"))
    rescue OpenSSL::SSL::SSLError, SystemCallError, IOError, EOFError => e
      raise Ace::Hitl::Lifecycle::TransportError, "refused (#{e.class}: #{e.message})"
    ensure
      ssl&.close
    end
  end
end
