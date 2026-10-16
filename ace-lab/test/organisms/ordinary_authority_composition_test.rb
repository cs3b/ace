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
    assert_same server.instance_variable_get(:@admission), observer.receiver
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
end
