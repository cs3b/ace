# frozen_string_literal: true

require "test_helper"

# Deployment-fact adapter for the lifecycle/relay transport: trusted grants
# policy and authenticated boundary client. The managed ask/native-delivery
# path and its attempt-bound assignment binding are removed with the old
# authority model.
class LabProviderTest < AceHitlTestCase
  def test_grants_policy_comes_from_the_trusted_document
    policy = Ace::Hitl::Providers::Lab.grants_policy(document: {
      "hitl" => {"service_uid" => 4210}
    })
    assert_equal 4210, policy.service_uid
  end

  def test_boundary_client_uses_the_configured_transport_identity
    with_env("ACE_HITL_SOCKET" => "/tmp/boundary.sock") do
      policy = Ace::Hitl::Providers::Lab.grants_policy(document: {"hitl" => {"service_uid" => 4210}})
      client = Ace::Hitl::Providers::Lab.boundary_client(policy: policy)
      assert_instance_of Ace::Hitl::Lifecycle::Client, client
      assert_equal "/tmp/boundary.sock", client.socket_path
      assert_equal 4210, client.service_uid
    end
  end

  def test_boundary_client_fails_closed_without_a_configured_service_identity
    error = assert_raises(Ace::Hitl::Providers::ProviderUnavailableError) do
      Ace::Hitl::Providers::Lab.boundary_client(
        policy: Ace::Hitl::Providers::Lab.grants_policy(document: {})
      )
    end
    assert_match(/service is not configured/, error.message)
  end

  def test_managed_ask_and_assignment_binding_are_removed
    refute_respond_to Ace::Hitl::Providers::Lab, :assignment_binding
    refute_respond_to Ace::Hitl::Providers::Lab, :ask
    refute_respond_to Ace::Hitl::Providers::Lab, :deliver
    refute_respond_to Ace::Hitl::Providers::Lab, :watch
  end
end
