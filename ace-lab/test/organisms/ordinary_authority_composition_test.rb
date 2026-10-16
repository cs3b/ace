# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/ordinary_owner_fixture"
require "ace/lab/organisms/ordinary_authority_composition"

class OrdinaryAuthorityCompositionTest < Minitest::Test
  include OrdinaryOwnerFixture
  L = Ace::Lab
  A = Ace::Assign

  # Constructor join only. Linux installation owns the root path, UID and
  # native peer acceptance; these tests do not claim that installed proof.
  class InstalledSelection < L::Molecules::OrdinaryOwnerConfig
    def initialize(...)
      @revocation = {revoked: false}
      super
    end
    def revoked=(value)
      @revocation[:revoked] = value
    end
    def verify_listener! = true
    def verify_selection!
      raise L::InvalidConfigurationError, "installed owner changed" if @revocation[:revoked]
      true
    end
  end

  def setup
    @root = File.realpath(Dir.mktmpdir("ordinary-composition"))
    @document = ordinary_owner_document(peer: {"uid" => 41001, "gid" => 41001, "pid" => 123,
      "host" => "lab", "started_at" => "birth"})
    entry = @document.fetch("projects").fetch("atlas")
    entry["service"]["state_root"] = File.join(@root, "state")
    entry["service"]["socket_path"] = File.join(@root, "assign.sock")
    entry["assignment_root"] = File.join(@root, "state", "assignments")
    entry["lifecycle_root"] = File.join(@root, "state", "lifecycle")
    entry["journal"] = {"repository" => File.join(@root, "journal"), "ref" => "refs/ace/execution",
      "checkout_root" => File.join(@root, "state", "checkout")}
    entry["hitl"]["root"] = File.join(@root, "state", "hitl")
    entry["hitl"]["socket_path"] = File.join(@root, "hitl.sock")
    [entry.fetch("assignment_root"), entry.fetch("lifecycle_root"), entry.dig("journal", "checkout_root"), entry.dig("hitl", "root")].each do |path|
      FileUtils.mkdir_p(path, mode: 0o700)
    end
    candidate = File.join(@root, "candidate")
    FileUtils.mkdir_p(candidate)
    @receiver = {"project" => "atlas", "receiver_id" => "ordinary-receiver",
      "socket_path" => File.join(@root, "merge.sock"), "receiver_uid" => 41000,
      "principal" => "atlas-worker", "principal_uid" => 41001, "repo_path" => candidate,
      "policy_path" => "/etc/lab/ace-lab/authorization.yml",
      "execution_identity" => {"checkout_id" => "candidate", "worktree_id" => "candidate", "branch" => "main"}}
    @policy = {"operations" => {}, "authorizations" => {}, "ordinary" => {"projects" => {"atlas" => {
      "receiver_id" => "ordinary-receiver", "socket_path" => @receiver.fetch("socket_path"), "receiver_uid" => 41000,
      "principal" => "atlas-worker", "admission" => "enabled", "journal_repository" => entry.dig("journal", "repository"),
      "journal_ref" => "refs/ace/execution"}}}}
    @hitl_policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {"hitl" => {"service_uid" => 41000}})
    @forge = L::Molecules::ForgeMergeConfig.new({"base_url" => "https://forge.example.com", "owner" => "acme", "repo" => "widget",
      "token" => "test-scoped-token", "merge_timeout_seconds" => 30, "escalation_owner" => "host-integrator",
      "review_attachment" => {"enabled" => true}})
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def construct
    @owner = InstalledSelection.new(@document, project: "atlas", source: L::Molecules::OrdinaryOwnerConfig::PATH)
    receiver = L::Molecules::OrdinaryReceiverConfig.new(@receiver)
    L::Molecules::GrantResolver.stub(:trusted_document, @policy) do
      L::Molecules::ForgeMergeConfig.stub(:load, @forge) do
        Ace::Hitl::Providers::Lab.stub(:grants_policy, @hitl_policy) do
          L::Organisms::OrdinaryAuthorityComposition.new(receiver_config: receiver, owner_config: @owner).build
        end
      end
    end
  end

  def test_real_component_graph_shares_one_selected_journal_and_exclusion
    server = construct
    assert_instance_of A::Authority::OrdinaryServer, server
    lifecycle = server.instance_variable_get(:@lifecycle).instance_variable_get(:@routes).fetch("finish")
    hitl, merge = server.instance_variable_get(:@services)
    assert_instance_of Ace::Hitl::Lifecycle::Service, hitl
    assert_instance_of L::Molecules::OrdinaryListener, merge
    receiver = merge.instance_variable_get(:@handler)
    coordinator = receiver.instance_variable_get(:@coordinator)
    journal = hitl.instance_variable_get(:@binding).proposal_journal(project: "atlas")
    assert_same journal, lifecycle.instance_variable_get(:@journal)
    assert_same journal, coordinator.send(:journal_for)
    assert_same lifecycle.instance_variable_get(:@exclusion), coordinator.send(:lifecycle_exclusion)
    assert_equal File.join(@root, "journal"), journal.repo_root
    refute_equal @receiver.fetch("repo_path"), journal.repo_root
    assert_equal :local, journal.evidence_mode
    assert_equal "refs/ace/execution", journal.ref
    observer = coordinator.instance_variable_get(:@recorded_binding_observer)
    admission = server.instance_variable_get(:@admission)
    assert_instance_of L::Molecules::CommandOwnerAdmission, admission
    assert_same admission.instance_variable_get(:@base), observer.receiver
    assert_same lifecycle.instance_variable_get(:@admission), observer.receiver
    command = server.instance_variable_get(:@lifecycle).instance_variable_get(:@routes).fetch("command_admit")
    assert_instance_of A::Authority::CommandExecution, command
    assert_same journal, command.instance_variable_get(:@journal)
    assert_same admission, command.instance_variable_get(:@admission)
    assert_equal :recorded_binding!, observer.name
    assert_equal File.join(@root, "hitl.sock"), hitl.socket_path
    assert_equal File.join(@root, "state", "hitl"), hitl.instance_variable_get(:@root)
    refute File.exist?(File.join(@root, "journal")), "constructing owners must not seed or replace accepted history"
  end

  def test_mismatched_canonical_locations_receiver_identity_or_participant_refuse
    ["journal_repository", "journal_ref", "receiver_uid", "principal", "socket_path"].each do |field|
      original = @policy["ordinary"]["projects"]["atlas"][field]
      @policy["ordinary"]["projects"]["atlas"][field] = case field
      when "receiver_uid" then 42000
      when "journal_repository", "socket_path" then "/foreign/location"
      when "journal_ref" then "refs/foreign/execution"
      else "foreign"
      end
      assert_raises(L::InvalidConfigurationError) { construct }
      @policy["ordinary"]["projects"]["atlas"][field] = original
    end
    @receiver["principal_uid"] = 42000
    assert_raises(L::InvalidConfigurationError) { construct }
    refute File.exist?(File.join(@root, "journal"))
  end

  def test_hitl_requires_same_installed_service_principal
    @hitl_policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {"hitl" => {"service_uid" => 42000}})
    assert_raises(L::InvalidConfigurationError) { construct }
    refute File.exist?(File.join(@root, "journal"))
  end

  def test_hitl_is_fixed_to_selected_project_and_rechecks_owner_and_service_uid
    server = construct
    hitl = server.instance_variable_get(:@services).first
    binding = hitl.instance_variable_get(:@binding)
    assert_equal ["atlas"], binding.proposal_projects
    assert_raises(Ace::Hitl::Lifecycle::BindingError) { binding.proposal_journal(project: "foreign") }
    @owner.revoked = true
    assert_raises(Ace::Hitl::Lifecycle::BindingError) { binding.proposal_journal(project: "atlas") }
    assert_raises(Ace::Hitl::Lifecycle::BindingError) { binding.proposal_projects }
    @owner.revoked = false
    @hitl_policy.instance_variable_get(:@document)["hitl"]["service_uid"] = 42000
    assert_raises(Ace::Hitl::Lifecycle::BindingError) { binding.proposal_journal(project: "atlas") }
    assert_raises(Ace::Hitl::Lifecycle::BindingError) { binding.proposal_projects }
  end

  def test_hitl_store_cannot_overlap_input_or_reuse_an_endpoint
    entry = @document.fetch("projects").fetch("atlas")
    entry["hitl"]["root"] = entry.fetch("assignment_root")
    assert_raises(L::InvalidConfigurationError) { construct }
    entry["hitl"]["root"] = File.join(@root, "state", "hitl")
    entry["hitl"]["socket_path"] = entry.dig("service", "socket_path")
    assert_raises(L::InvalidConfigurationError) { construct }
  end

  def test_hitl_store_layout_remains_valid_after_its_owner_prepares_it
    construct
    root = @document.dig("projects", "atlas", "hitl", "root")
    store = Ace::Hitl::Lifecycle::Store.new(root: root, binding: Ace::Hitl::Lifecycle::Binding.new)
    Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, true) do
      store.ensure_layout!
      assert @owner.send(:verify_hitl_root!)
      store.ensure_layout!
      assert @owner.send(:verify_hitl_root!)
      File.chmod(0o777, root)
      assert_raises(L::InvalidConfigurationError) { @owner.send(:verify_hitl_root!) }
    end
  end

  def test_retained_protected_classification_revokes_existing_hitl_and_merge_owners
    server = construct
    hitl, listener = server.instance_variable_get(:@services)
    binding = hitl.instance_variable_get(:@binding)
    receiver = listener.instance_variable_get(:@handler)
    protected_uid = nil
    classification = ->(uid:) { Struct.new(:protected_participant?).new(uid == protected_uid) }
    A::Authority::ProtectedAssignmentContext.stub(:load, classification) do
      Etc.stub(:getpwuid, Struct.new(:name).new("atlas-worker")) do
        guard = receiver.instance_variable_get(:@owner_guard)
        assert guard.call
        assert binding.proposal_journal(project: "atlas")
        protected_uid = 41000
        assert_raises(Ace::Hitl::Lifecycle::BindingError) { binding.proposal_journal(project: "atlas") }
        assert_raises(A::AttemptErrors::UnauthorizedIdentity) { guard.call }
        refusal = receiver.send(:current_authorization_refusal, {})
        assert_match(/protected principal/, refusal)
        protected_uid = 41001
        assert_raises(A::AttemptErrors::UnauthorizedIdentity) { guard.call }
        refusal = receiver.send(:current_authorization_refusal, {})
        assert_match(/protected principal/, refusal)
      end
    end
  end

  def test_remote_hermes_uses_same_binding_decision_policy_and_one_time_vault
    server = with_tls { construct }
    unix, tls, merge = server.instance_variable_get(:@services)
    assert_instance_of Ace::Hitl::Lifecycle::TlsService, tls
    assert_same unix.instance_variable_get(:@binding), tls.instance_variable_get(:@binding)
    assert_same unix.instance_variable_get(:@vault), tls.instance_variable_get(:@vault)
    assert_same @hitl_policy, tls.instance_variable_get(:@policy).instance_variable_get(:@decision_policy)
    assert_equal unix.instance_variable_get(:@root), tls.instance_variable_get(:@root)
    assert_equal unix.instance_variable_get(:@group), tls.instance_variable_get(:@group)
    assert_same merge.instance_variable_get(:@handler).instance_variable_get(:@coordinator),
      tls.instance_variable_get(:@binding).instance_variable_get(:@coordinator)
    peer = Ace::Hitl::Lifecycle::RemotePeer.new(project: "atlas", identity: "urn:ace:hitl:atlas:hermes-client")
    assert_nil peer.uid
    policy = tls.instance_variable_get(:@policy)
    assert policy.transport?(peer, project: "atlas")
    refute policy.transport?(peer, project: "foreign")
    refute @hitl_policy.transport?(peer, project: "atlas"), "mTLS must not manufacture a Unix transport grant"
    value = {"id" => "synthetic-challenge", "incarnation" => "one"}
    tls.instance_variable_get(:@vault).write(nil, value, "123456")
    assert_equal "123456", unix.instance_variable_get(:@vault).read(nil, value)
    assert_raises(Ace::Hitl::Lifecycle::OtpVault::MissError) { tls.instance_variable_get(:@vault).read(nil, value) }
    @owner.revoked = true
    assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      tls.instance_variable_get(:@binding).proposal_journal(project: "atlas")
    end
    refute File.exist?(File.join(@root, "journal"))
  end

  def test_tls_requires_selected_project_account_group_and_verified_material_before_build
    [{project: "foreign"}, {uid: 42000}, {gid: 42000}].each do |selection|
      assert_raises(L::InvalidConfigurationError) { with_tls(**selection) { construct } }
    end
    assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      with_tls(material: ->(*) { raise Ace::Hitl::Lifecycle::TransportError, "unavailable material" }) { construct }
    end
    refute File.exist?(File.join(@root, "journal"))
    refute File.exist?(File.join(@root, "assign.sock"))
    refute File.exist?(File.join(@root, "hitl.sock"))
  end

  def test_tls_selection_is_an_explicit_absolute_reference_without_caller_options
    [nil, "relative.json", "/etc/../tmp/authority.json", {"port" => 443}].each do |value|
      @document["projects"]["atlas"]["hitl"]["tls_authority"] = value
      assert_raises(L::InvalidConfigurationError) { construct }
    end
  end

  private

  # Validate the real schema and component graph. Root-owned filesystem and
  # certificate handshakes are covered by HITL and the installed Linux fixture.
  def with_tls(project: "atlas", uid: 41000, gid: 41000, material: OpenSSL::SSL::SSLContext.new)
    path = "/etc/lab/ace-hitl/atlas-tls.json"
    @document["projects"]["atlas"]["hitl"]["tls_authority"] = path
    authority = Ace::Hitl::Lifecycle::TlsAuthority.new({
      "schema" => "ace.hitl.tls.authority/v1", "project_id" => project,
      "listen" => "127.0.0.1", "port" => 8431, "service_user" => "atlas-owner", "service_group" => "atlas-owner",
      "tls_server_credential" => {
        "certificate_file" => "/etc/lab/ace-hitl/tls/server.pem", "private_key_file" => "/etc/lab/ace-hitl/tls/key.pem",
        "ca_file" => "/etc/lab/ace-hitl/tls/ca.pem", "server_uri_san" => "urn:ace:hitl:#{project}:lifecycle-server",
        "allowed_client_uri_san" => "urn:ace:hitl:#{project}:hermes-client", "allowed_client_certificate_sha256" => "a" * 64}})
    loader = ->(actual) { assert_equal path, actual; authority }
    Ace::Hitl::Lifecycle::TlsAuthority.stub(:load, loader) do
      Etc.stub(:getpwnam, Struct.new(:uid).new(uid)) do
        Etc.stub(:getgrnam, Struct.new(:gid).new(gid)) do
          Ace::Hitl::Lifecycle::CredentialPathPolicy.stub(:verify_credential_tree!, true) do
            Ace::Hitl::Lifecycle::TlsMaterial.stub(:build_server_context, material) { yield }
          end
        end
      end
    end
  end
end
