# frozen_string_literal: true

require "test_helper"
require "ace/hitl/lifecycle"

# Remote channel authorities of the transport registry (spec 8xa.t.nh0,
# G-A): each channel resolves to EXACTLY ONE authority — a local Unix
# socket with its service uid, or the selected tls+tcp:// endpoint with
# the project's exact client credential and no Unix uid.
class RegistryEndpointTest < AceHermesTestCase
  PROJECT = "proj-a"

  def registry(channels)
    Ace::Hitl::Hermes::Transport::Registry.new(
      {"schema" => "ace.hitl.hermes.channels/v1", "channels" => channels})
  end

  def local_channel(overrides = {})
    {"name" => "lab", "chat_id" => "-424242", "captain_user_ids" => ["42"], "machine" => "lab",
     "folder" => "/srv/hermes/inbox", "target" => "lab", "projects" => ["proj-lab"],
     "hitl_service_uid" => 4100}.merge(overrides)
  end

  def client_credential(project: PROJECT)
    {
      "certificate_file" => "/etc/ace/credentials/#{project}/client.pem",
      "private_key_file" => "/etc/ace/credentials/#{project}/client-key.pem",
      "ca_file" => "/etc/ace/credentials/#{project}/ca.pem",
      "expected_server_uri_san" => "urn:ace:hitl:#{project}:lifecycle-server",
      "expected_server_certificate_sha256" => "a" * 64
    }
  end

  def remote_channel(overrides = {})
    channel = local_channel("name" => "gad", "projects" => [PROJECT],
      "hitl_endpoint" => "tls+tcp://host-a.tailnet.example:8443",
      "tls_client_credential" => client_credential)
    channel.delete("hitl_service_uid")
    channel.merge(overrides)
  end

  def test_remote_channel_with_exact_credential_is_accepted
    registry_object = registry([remote_channel])
    channel = registry_object.resolve("gad")
    assert_equal "tls+tcp://host-a.tailnet.example:8443", channel["hitl_endpoint"]
    assert_equal client_credential, channel["tls_client_credential"]
  end

  def test_endpoint_and_socket_are_mutually_exclusive
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      registry([remote_channel("hitl_socket" => "/run/lab/hitl.sock")])
    end
    assert_match(/exactly one authority/, error.message)
  end

  def test_remote_channel_requires_a_credential_reference
    channel = remote_channel
    channel.delete("tls_client_credential")
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      registry([channel])
    end
    assert_match(/requires a tls_client_credential/, error.message)
  end

  def test_remote_endpoint_must_be_the_selected_tls_tcp_form
    ["tcp://host-a.tailnet.example:8443", "tls+tcp://127.0.0.1:8443", "tls+tcp://localhost:8443",
     "unix:///run/hitl.sock", "tls+tcp://host-a.tailnet.example"].each do |endpoint|
      error = assert_raises(Ace::Hitl::Hermes::ContractError) do
        registry([remote_channel("hitl_endpoint" => endpoint)])
      end
      assert_match(/tls\+tcp|DNS name/, error.message)
    end
  end

  def test_remote_channel_rejects_a_unix_service_uid
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      registry([remote_channel("hitl_service_uid" => 4100)])
    end
    assert_match(/must not declare a Unix hitl_service_uid/, error.message)
  end

  def test_remote_channel_routes_exactly_its_credential_project
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      registry([remote_channel("projects" => ["proj-b"])])
    end
    assert_match(/credential project/, error.message)

    channel = remote_channel("projects" => [PROJECT, "proj-b"])
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      registry([channel])
    end
    assert_match(/credential project/, error.message)
  end

  def test_local_channels_still_require_the_service_uid
    channel = local_channel
    channel.delete("hitl_service_uid")
    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      registry([channel])
    end
    assert_match(/hitl_service_uid/, error.message)
  end
end
