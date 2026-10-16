# frozen_string_literal: true
require "test_helper"
require "ace/hitl/lifecycle"

class RegistryEndpointTest < AceHermesTestCase
  PROJECT = "proj-a"
  def registry(authority, project: PROJECT)
    Ace::Hitl::Hermes::Transport::Registry.new(
      "schema" => "ace.hitl.hermes.channels/v2", "channels" => [
        {"name" => "lab", "chat_id" => "-424242", "captain_user_ids" => ["42"], "machine" => "lab",
         "folder" => "/srv/hermes/inbox", "target" => "lab", "projects" => {project => authority}}])
  end
  def client_credential
    {"certificate_file" => "/etc/ace/credentials/#{PROJECT}/client.pem",
     "private_key_file" => "/etc/ace/credentials/#{PROJECT}/client-key.pem",
     "ca_file" => "/etc/ace/credentials/#{PROJECT}/ca.pem",
     "expected_server_uri_san" => "urn:ace:hitl:#{PROJECT}:lifecycle-server",
     "expected_server_certificate_sha256" => "a" * 64}
  end
  def remote(overrides = {})
    {"hitl_endpoint" => "tls+tcp://host-a.tailnet.example:8443",
     "tls_client_credential" => client_credential}.merge(overrides)
  end
  def test_remote_project_with_exact_credential_is_accepted
    authority = registry(remote).resolve("lab").fetch("projects").fetch(PROJECT)
    assert_equal remote, authority
  end
  def test_endpoint_and_socket_are_mutually_exclusive
    error = assert_raises(Ace::Hitl::Hermes::ContractError) { registry(remote("hitl_socket" => "/run/x.sock")) }
    assert_match(/exactly one authority/, error.message)
  end
  def test_remote_project_requires_a_credential_reference
    authority = remote
    authority.delete("tls_client_credential")
    error = assert_raises(Ace::Hitl::Hermes::ContractError) { registry(authority) }
    assert_match(/requires a tls_client_credential/, error.message)
  end
  def test_remote_endpoint_must_be_the_selected_tls_tcp_form
    ["tcp://host-a.tailnet.example:8443", "tls+tcp://127.0.0.1:8443", "tls+tcp://localhost:8443",
     "unix:///run/hitl.sock", "tls+tcp://host-a.tailnet.example"].each do |endpoint|
      error = assert_raises(Ace::Hitl::Hermes::ContractError) { registry(remote("hitl_endpoint" => endpoint)) }
      assert_match(/tls\+tcp|DNS name/, error.message)
    end
  end
  def test_remote_project_rejects_a_unix_service_uid
    error = assert_raises(Ace::Hitl::Hermes::ContractError) { registry(remote("hitl_service_uid" => 4100)) }
    assert_match(/must not declare a Unix hitl_service_uid/, error.message)
  end
  def test_remote_project_matches_credential_project_and_does_not_strip_tokens
    assert_raises(Ace::Hitl::Hermes::ContractError) { registry(remote, project: "proj-b") }
    assert_raises(Ace::Hitl::Hermes::ContractError) { registry(remote, project: " proj-a ") }
  end
  def test_local_projects_require_explicit_socket_and_service_identity
    [{"hitl_socket" => "/run/hitl.sock"}, {"hitl_service_uid" => 4100},
     {"hitl_socket" => "relative.sock", "hitl_service_uid" => 4100},
     {"hitl_socket" => "/run/hitl.sock", "hitl_service_uid" => 4100, "fallback" => true}].each do |authority|
      assert_raises(Ace::Hitl::Hermes::ContractError) { registry(authority) }
    end
    assert registry({"hitl_socket" => "/run/hitl.sock", "hitl_service_uid" => 4100})
  end
end
