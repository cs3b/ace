# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

# The boundary authorization facts (spec 8wq.t.34i): transport authority
# and the service identity come only from the trusted deployment
# document, matched against the kernel-verified peer uid; an
# unverifiable document authorizes NOTHING.
class ScopedPolicyTest < AceHitlTestCase
  def test_second_commander_is_an_explicit_project_scoped_principal
    document = grants_document
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: document)
    refute policy.proposal?(stub_peer(4211), project: "ace"), "transport alone must not admit proposals"
    document["hitl"]["proposal_uids"] = [4211]
    assert policy.proposal?(stub_peer(4211), project: "ace")
    refute policy.proposal?(stub_peer(4211), project: "other")
    refute policy.proposal?(stub_peer(4212), project: "other")
    document["authorization"]["principals"].delete("4211")
    refute policy.proposal?(stub_peer(4211), project: "ace")
    refute Ace::Hitl::Lifecycle::AccessPolicy.new.proposal?(stub_peer(4211), project: "ace")
  end
  def grants_document
    {
      "hitl" => {"service_uid" => 4210, "transport_uids" => [4211, 4212]},
      "authorization" => {
        "principals" => {
          "4211" => {"projects" => ["ace"]},
          "4212" => {"projects" => ["other"]}
        }
      }
    }
  end

  def policy(document: grants_document)
    Ace::Hitl::Lifecycle::GrantsPolicy.new(document: document)
  end

  def test_transport_uid_with_project_visibility_may_deliver_that_project
    peer = Ace::Hitl::Lifecycle::Peer.for_uid(4211) rescue nil
    peer ||= stub_peer(4211)
    assert policy.transport?(peer, project: "ace")
    refute policy.transport?(peer, project: "other")
  end

  def test_transport_uid_for_another_project_is_scoped_out
    peer = stub_peer(4212)
    assert policy.transport?(peer, project: "other")
    refute policy.transport?(peer, project: "ace")
  end

  def test_unknown_uid_is_transport_for_nothing
    peer = stub_peer(9999)
    refute policy.transport?(peer, project: "ace")
    refute policy.transport?(peer)
  end

  def test_transport_uid_without_a_principal_entry_is_nobody
    # Aligned with ace-lab's HitlAuthorizer (review 8x327buh): a uid on
    # the transport list without a principals entry authorizes nothing.
    orphaned = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {
      "hitl" => {"service_uid" => 4210, "transport_uids" => [4299]},
      "authorization" => {"principals" => {"4211" => {"projects" => ["ace"]}}}
    })
    peer = stub_peer(4299)
    refute orphaned.transport?(peer, project: "ace")
    refute orphaned.transport?(peer)
  end

  def test_service_uid_comes_from_the_trusted_document_only
    assert_equal 4210, policy.service_uid
    assert_nil Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {}).service_uid
    assert_nil Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {}).service_uid
  end

  def test_default_policy_grants_nothing
    deny_all = Ace::Hitl::Lifecycle::AccessPolicy.new
    peer = stub_peer(4211)
    refute deny_all.transport?(peer, project: "ace")
    assert_nil deny_all.service_uid
  end

  def test_trusted_file_refuses_a_user_owned_document
    # A document the calling user owns is never trusted: an attacker-
    # controlled file cannot inject transport authority (spec 8wq.t.34i).
    Dir.mktmpdir("ace-hitl-grants") do |dir|
      path = File.join(dir, "authorization.yml")
      File.write(path, YAML.dump(grants_document))
      error = assert_raises(Ace::Hitl::Lifecycle::Error) do
        Ace::Hitl::Lifecycle::TrustedFile.read_yaml(path)
      end
      assert_match(/root-owned/, error.message)
    end
  end

  def test_trusted_file_refuses_a_world_writable_directory_component
    Dir.mktmpdir("ace-hitl-grants") do |dir|
      FileUtils.chmod(0o777, dir)
      path = File.join(dir, "authorization.yml")
      File.write(path, YAML.dump(grants_document))
      error = assert_raises(Ace::Hitl::Lifecycle::Error) do
        Ace::Hitl::Lifecycle::TrustedFile.read_yaml(path)
      end
      assert_match(/root-owned/, error.message)
    end
  end

  def test_unverifiable_and_unconfigured_sources_authorize_nothing
    Dir.mktmpdir("ace-hitl-grants") do |dir|
      path = File.join(dir, "absent.yml")
      # A user-owned path never verifies, so the document is unreadable
      # and the policy fails closed.
      result = (Ace::Hitl::Lifecycle::TrustedFile.read_yaml(path) rescue :error)
      assert_equal :error, result
    end
    # An unconfigured policy (no path, no document) grants nothing.
    unconfigured = Ace::Hitl::Lifecycle::GrantsPolicy.new
    assert_nil unconfigured.service_uid
    refute unconfigured.transport?(stub_peer(4211), project: "ace")
  end

  def test_peer_resolves_the_passwd_identity_and_rejects_unknown_uids
    peer = Ace::Hitl::Lifecycle::Peer.for_uid(Process.uid)
    assert_equal Process.uid, peer.uid
    assert_equal Process.uid, peer.euid
    refute_empty peer.username

    error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      Ace::Hitl::Lifecycle::Peer.for_uid(4_000_000_001)
    end
    assert_match(/unknown peer identity/, error.message)
  end

  private

  # A peer built without touching the passwd db (fixture uids).
  def stub_peer(uid)
    peer = Ace::Hitl::Lifecycle::Peer.allocate
    peer.send(:initialize, uid: uid, gid: uid, username: "fixture-#{uid}")
    peer
  end
end
