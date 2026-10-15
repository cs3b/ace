# frozen_string_literal: true

require "test_helper"
require "openssl"
require "support/tls_fixtures"

# The closed configuration schemas of the host/Incus crossing (spec
# 8xa.t.nh0): credential references reject unknown fields and nulls,
# URI SANs are closed-form, fingerprints are exact, and the remote
# endpoint is exactly tls+tcp://HOST_TAILNET_DNS:PORT.
class TlsCredentialsTest < AceHitlTestCase
  VALID_CLIENT = {
    "certificate_file" => "/etc/ace/credentials/proj/client.pem",
    "private_key_file" => "/etc/ace/credentials/proj/client-key.pem",
    "ca_file" => "/etc/ace/credentials/proj/ca.pem",
    "expected_server_uri_san" => "urn:ace:hitl:proj:lifecycle-server",
    "expected_server_certificate_sha256" => "a" * 64
  }.freeze

  VALID_SERVER = {
    "certificate_file" => "/etc/ace/credentials/proj/server.pem",
    "private_key_file" => "/etc/ace/credentials/proj/server-key.pem",
    "ca_file" => "/etc/ace/credentials/proj/ca.pem",
    "server_uri_san" => "urn:ace:hitl:proj:lifecycle-server",
    "allowed_client_uri_san" => "urn:ace:hitl:proj:hermes-client",
    "allowed_client_certificate_sha256" => "b" * 64
  }.freeze

  def test_client_credential_resolves_exactly
    resolved = Ace::Hitl::Lifecycle::TlsCredentials.parse_client(VALID_CLIENT)
    assert_equal VALID_CLIENT, resolved
  end

  def test_server_credential_resolves_exactly
    resolved = Ace::Hitl::Lifecycle::TlsCredentials.parse_server(VALID_SERVER)
    assert_equal VALID_SERVER, resolved
  end

  def test_credential_objects_reject_unknown_fields_and_nulls
    error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
      Ace::Hitl::Lifecycle::TlsCredentials.parse_client(VALID_CLIENT.merge("extra" => "x"))
    end
    assert_match(/unknown fields/, error.message)

    nulls = VALID_CLIENT.merge("ca_file" => nil)
    error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
      Ace::Hitl::Lifecycle::TlsCredentials.parse_client(nulls)
    end
    assert_match(/missing or null/, error.message)

    error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
      Ace::Hitl::Lifecycle::TlsCredentials.parse_server(VALID_SERVER.merge("expected_server_uri_san" => "urn:x"))
    end
    assert_match(/unknown fields/, error.message)
  end

  def test_every_field_must_be_a_non_empty_string
    VALID_CLIENT.each_key do |field|
      error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
        Ace::Hitl::Lifecycle::TlsCredentials.parse_client(VALID_CLIENT.merge(field => ""))
      end
      assert_match(/non-empty string/, error.message)
    end
  end

  def test_paths_must_be_absolute_and_canonical
    ["relative/ca.pem", "/etc/../etc/ace/ca.pem", "/etc/ace//ca.pem", "/etc/ace/./ca.pem"].each do |path|
      error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
        Ace::Hitl::Lifecycle::TlsCredentials.parse_client(VALID_CLIENT.merge("ca_file" => path))
      end
      assert_match(/absolute canonical path/, error.message)
    end
  end

  def test_fingerprints_are_64_lowercase_hex
    ["A" * 64, "g" * 64, "a" * 63, "a" * 65].each do |pin|
      error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
        Ace::Hitl::Lifecycle::TlsCredentials.parse_client(
          VALID_CLIENT.merge("expected_server_certificate_sha256" => pin))
      end
      assert_match(/64 lowercase hex/, error.message)
    end
    error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
      Ace::Hitl::Lifecycle::TlsCredentials.parse_client(
        VALID_CLIENT.merge("expected_server_certificate_sha256" => ""))
    end
    assert_match(/non-empty string/, error.message)
  end

  def test_uri_sans_are_the_closed_urn_form
    ["urn:ace:hitl:proj:wrong-role", "urn:ace:hitl::lifecycle-server", "https://proj", "urn:ace:hitl:proj"].each do |san|
      error = assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
        Ace::Hitl::Lifecycle::TlsCredentials.parse_client(
          VALID_CLIENT.merge("expected_server_uri_san" => san))
      end
      assert_match(/closed-form|role|project id/, error.message)
    end
  end

  def test_project_ids_are_bounded_tokens
    ["ok-Project._1", "x"].each do |project|
      assert_equal project, Ace::Hitl::Lifecycle::TlsCredentials.project_id(project)
    end
    ["-leading", "with:colon", "", "a" * 64, "with space"].each do |project|
      assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
        Ace::Hitl::Lifecycle::TlsCredentials.project_id(project)
      end
    end
  end

  def test_uri_san_project_extracts_the_project_segment
    assert_equal "proj", Ace::Hitl::Lifecycle::TlsCredentials.uri_san_project("urn:ace:hitl:proj:lifecycle-server")
    assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
      Ace::Hitl::Lifecycle::TlsCredentials.uri_san_project("urn:other:proj:lifecycle-server")
    end
  end

  def test_remote_endpoint_is_exactly_tls_tcp_with_a_dns_name
    dns, port = Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint("tls+tcp://host.tailnet.example:8443")
    assert_equal "host.tailnet.example", dns
    assert_equal 8443, port

    ["tcp://host.tailnet.example:8443", "http://host.tailnet.example:8443",
     "tls+tcp://127.0.0.1:8443", "tls+tcp://[::1]:8443", "tls+tcp://0.0.0.0:8443",
     "unix:///run/hitl.sock", "tls+tcp://localhost:8443", "tls+tcp://host:8443",
     "tls+tcp://host.tailnet.example:http", "tls+tcp://host.tailnet.example:0",
     "tls+tcp://host.tailnet.example:8443/extra", "tls+tcp://host.tailnet.example",
     "TLS+TCP://host.tailnet.example:8443"].each do |endpoint|
      assert_raises(Ace::Hitl::Lifecycle::TlsCredentials::Error) do
        Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(endpoint)
      end
    end
  end

  def test_certificate_identity_helpers_read_single_sans_and_eku
    ca = TlsFixtures.mint_ca
    server = TlsFixtures.mint_identity(ca: ca, uri_sans: ["urn:ace:hitl:proj:lifecycle-server"],
      eku: "serverAuth")
    credentials = Ace::Hitl::Lifecycle::TlsCredentials
    assert_equal ["urn:ace:hitl:proj:lifecycle-server"], credentials.uri_sans(server.cert)
    assert credentials.server_auth_eku?(server.cert)
    refute credentials.client_auth_eku?(server.cert)
    assert credentials.valid_time?(server.cert)
    assert_equal TlsFixtures.fingerprint(server.cert), credentials.sha256_fingerprint(server.cert)
  end
end
