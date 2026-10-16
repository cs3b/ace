# frozen_string_literal: true

require "test_helper"
require "socket"
require "openssl"
require "support/tls_fixtures"

TlsClient = Ace::Hitl::Hermes::Transport::TlsClient

# The Hermes TLS lifecycle client of the host/Incus crossing (spec
# 8xa.t.nh0): it authenticates the SERVICE on every connection — DNS
# name, the single expected URI SAN, the serverAuth EKU, the issuing CA
# and the exact configured fingerprint pin — BEFORE any lifecycle
# frame, speaks the unchanged bounded frames, and never falls back to
# cleartext or another transport.
class TlsClientTest < AceHermesTestCase
  SERVER_SAN = "urn:ace:hitl:proj-a:lifecycle-server"
  DNS_NAME = "lifecycle.example.test"

  def setup
    @scratch = Dir.mktmpdir("hermes-tls-client", "/tmp")
    @ca = TlsFixtures.mint_ca
    @server = TlsFixtures.mint_identity(ca: @ca, uri_sans: [SERVER_SAN], dns_names: [DNS_NAME],
      eku: "serverAuth")
    write_material
    @server_thread = nil
    @tcp_server = nil
  end

  def teardown
    @tcp_server&.close
    @server_thread&.join(2)
    @server_thread&.kill
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
  end

  def test_authenticated_exchange_over_tls_1_3
    start_tls_double
    client = build_client
    result = request_over_loopback(client)
    assert_equal true, result["pong"]
  end

  def test_expected_server_fingerprint_pin_is_mandatory_and_exact
    start_tls_double
    credential = base_credential.merge("expected_server_certificate_sha256" => "0" * 64)
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      request_over_loopback(build_client(credential: credential))
    end
    assert_match(/fingerprint/, error.message)
  end

  def test_expected_server_uri_san_must_match_exactly
    start_tls_double
    credential = base_credential.merge("expected_server_uri_san" => "urn:ace:hitl:proj-b:lifecycle-server")
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      request_over_loopback(build_client(credential: credential))
    end
    assert_match(/URI SAN/, error.message)
  end

  def test_dns_identity_is_verified
    # The double serves a certificate with NO DNS SAN at all: the
    # hostname-verified handshake must refuse before any frame.
    no_dns_server = TlsFixtures.mint_identity(ca: @ca, uri_sans: [SERVER_SAN], eku: "serverAuth")
    write_material(server_identity: no_dns_server)
    start_tls_double
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      request_over_loopback(build_client)
    end
    assert_match(/handshake failed|unavailable/, error.message)
  end

  def test_server_without_serverauth_eku_is_refused
    no_eku_server = TlsFixtures.mint_identity(ca: @ca, uri_sans: [SERVER_SAN], dns_names: [DNS_NAME])
    write_material(server_identity: no_eku_server)
    start_tls_double
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      request_over_loopback(build_client)
    end
    assert_match(/serverAuth EKU|fingerprint|URI SAN|handshake/, error.message)
  end

  def test_tls_1_2_only_server_is_refused
    @tcp_server = TCPServer.new("::1", 0)
    @port = @tcp_server.addr[1]
    legacy = Thread.new do
      loop do
        socket = begin
          @tcp_server.accept
        rescue SystemCallError, IOError
          break
        end
        break if socket.nil?

        begin
          context = OpenSSL::SSL::SSLContext.new
          context.set_params
          context.min_version = OpenSSL::SSL::TLS1_2_VERSION
          context.max_version = OpenSSL::SSL::TLS1_2_VERSION
          context.cert = @server.cert
          context.key = @server.key
          ssl = OpenSSL::SSL::SSLSocket.new(socket, context)
          ssl.sync_close = true
          ssl.accept
          sleep 1
        rescue SystemCallError, IOError, OpenSSL::SSL::SSLError
          nil
        end
      end
    end
    @server_thread = legacy
    client = build_client
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      request_over_loopback(client)
    end
    assert_match(/handshake failed|unavailable/, error.message)
  end

  def test_endpoint_forms_are_validated_before_any_connection
    ["tcp://host.tailnet.example:8443", "http://host.tailnet.example:8443",
     "tls+tcp://127.0.0.1:8443", "tls+tcp://0.0.0.0:8443", "unix:///run/x.sock",
     "tls+tcp://localhost:8443", "tls+tcp://host.tailnet.example"].each do |endpoint|
      error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
        TlsClient.new(endpoint: endpoint, credential: base_credential,
          context_builder: ->(_resolved) { client_context })
      end
      assert_match(/tls\+tcp|DNS name/, error.message)
    end
  end

  def test_resolved_route_hash_endpoint_form_is_accepted
    start_tls_double
    client = TlsClient.new(endpoint: {dns: DNS_NAME, port: @port},
      credential: base_credential, context_builder: ->(_resolved) { client_context })
    assert_equal true, request_over_loopback(client)["pong"]
  end

  # ---- fixtures ----

  # Replace DNS resolution only. TCP, TLS, hostname/SAN/EKU/pin verification
  # and lifecycle frames remain real, independent of host resolver aliases.
  def request_over_loopback(client)
    resolve = Addrinfo.method(:tcp)
    Addrinfo.stub(:tcp, ->(dns, port) {
      assert_equal DNS_NAME, dns
      resolve.call("::1", port)
    }) { client.request("ping") }
  end

  def write_material(server_identity: @server)
    @server = server_identity
    @cert_path, @key_path, = TlsFixtures.write_identity(@scratch, prefix: "server",
      identity: @server)
    @ca_file = File.join(@scratch, "ca.pem")
    File.write(@ca_file, @ca.cert.to_pem)
  end

  def base_credential
    {
      "certificate_file" => File.join(@scratch, "client.pem"),
      "private_key_file" => File.join(@scratch, "client-key.pem"),
      "ca_file" => @ca_file,
      "expected_server_uri_san" => SERVER_SAN,
      "expected_server_certificate_sha256" => TlsFixtures.fingerprint(@server.cert)
    }
  end

  def build_client(credential: base_credential)
    TlsClient.new(endpoint: "tls+tcp://#{DNS_NAME}:#{@port}", credential: credential,
      context_builder: ->(_resolved) { client_context })
  end

  def client_context
    context = OpenSSL::SSL::SSLContext.new
    context.set_params
    context.min_version = OpenSSL::SSL::TLS1_3_VERSION
    context.max_version = OpenSSL::SSL::TLS1_3_VERSION
    store = OpenSSL::X509::Store.new
    store.add_file(@ca_file)
    context.cert_store = store
    context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    context.verify_hostname = true
    context
  end

  # A minimal TLS 1.3 lifecycle-frame double: the real bounded protocol,
  # ping-only — the crossing's CLIENT half is under test.
  def start_tls_double
    @tcp_server = TCPServer.new("::1", 0)
    @port = @tcp_server.addr[1]
    context = OpenSSL::SSL::SSLContext.new
    context.set_params
    context.min_version = OpenSSL::SSL::TLS1_3_VERSION
    context.max_version = OpenSSL::SSL::TLS1_3_VERSION
    store = OpenSSL::X509::Store.new
    store.add_file(@ca_file)
    context.cert_store = store
    context.cert = @server.cert
    context.extra_chain_cert = [@ca.cert]
    context.key = @server.key
    context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    context.verify_hostname = false
    @server_thread = Thread.new do
      loop do
        socket = begin
          @tcp_server.accept
        rescue SystemCallError, IOError
          break
        end
        Thread.new(socket) do |tcp|
          ssl = OpenSSL::SSL::SSLSocket.new(tcp, context)
          ssl.sync_close = true
          begin
            ssl.accept
            line = ssl.gets("\n")
            request = Ace::Hitl::Lifecycle::Protocol.decode_request(line) if line
            response = if request && request[:op] == "ping"
              Ace::Hitl::Lifecycle::Protocol.encode_result({"pong" => true})
            else
              Ace::Hitl::Lifecycle::Protocol.encode_error(
                Ace::Hitl::Lifecycle::TransportError.new("the double serves ping only"))
            end
            ssl.write(response)
            ssl.flush
          rescue SystemCallError, IOError, OpenSSL::SSL::SSLError, Ace::Hitl::Lifecycle::Error
            nil
          ensure
            ssl.close rescue nil
          end
        end
      end
    end
  end
end
