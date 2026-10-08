# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/authority_composition"

class AuthorityCompositionTest < Minitest::Test
  def test_full_service_source_loads_fixed_protected_history_into_existing_lifecycle
    # Controlled complete-source boundary; actual missing product operations
    # remain refused by the separate completeness test below.
    original_operations = Ace::Assign::Authority::Endcap::OPERATIONS
    Ace::Assign::Authority::Endcap.send(:remove_const, :OPERATIONS)
    Ace::Assign::Authority::Endcap.const_set(:OPERATIONS, Ace::Lab::Organisms::AuthorityComposition::REQUIRED_ENDCAP)
    deployment = Object.new
    deployment.define_singleton_method(:verify_composition!) { |*args, **keywords| true }
    deployment.define_singleton_method(:data) { {"launch_mappings" => {"mapping" => {"authority_id" => "services", "project_id" => "project"}}} }
    deployment.define_singleton_method(:project) do |_id|
      {"service_receivers" => {"receiver" => {}}, "journal_repository" => "/fixed/journal",
        "evidence_checkout_root" => "/fixed/checkout", "evidence_git_ref" => "refs/ace/execution"}
    end
    history, launch, endcap, router, server = Array.new(5) { Object.new }
    publication = Object.new
    owner = Ace::Lab::Organisms::AuthorityComposition.new(authority_id: "services", deployment: deployment, kernel: Object.new)
    selected = nil
    selected_router = nil
    load_count = 0
    factory = lambda do |**arguments|
      selected = arguments
      launch
    end
    Ace::Assign::Authority::DeploymentHistory.stub(:load, -> { load_count += 1; history }) do
      Ace::Assign::Authority::LaunchLifecycle.stub(:new, factory) do
        Ace::Assign::Authority::Endcap.stub(:new, endcap) do
          Ace::Assign::Authority::Router.stub(:new, ->(**arguments) { selected_router = arguments; router }) do
            Ace::Assign::Authority::Server.stub(:new, ->(**arguments) {
              assert_same publication, arguments.fetch(:hitl_service)
              server
            }) do
              # This routing unit test controls the existing publication boundary;
              # it does not require an installed /etc authorization policy.
              owner.stub(:publication_hitl, publication) do
                assert_same server, owner.build
              end
            end
          end
        end
      end
    end
    assert_equal 1, load_count
    assert_same history, selected.fetch(:deployment_history)
    assert_same deployment, selected.fetch(:deployment)
    assert_equal :protected, selected.fetch(:journals).fetch("project").evidence_mode
    assert_equal 1, selected_router.fetch(:handlers).size
    assert_same endcap, selected_router.fetch(:handlers).first
  ensure
    if original_operations
      Ace::Assign::Authority::Endcap.send(:remove_const, :OPERATIONS)
      Ace::Assign::Authority::Endcap.const_set(:OPERATIONS, original_operations)
    end
  end

  # No positive kernel/native origin is simulated here. These startup guards
  # must refuse before any state, listener or imported evidence can be created.
  def test_entrypoint_composition_mismatch_refuses_before_other_construction
    deployment = Object.new
    deployment.define_singleton_method(:verify_composition!) do |authority, composition:|
      raise ArgumentError, "composition differs" unless authority == "services" && composition == "launch"
    end
    assert_raises(ArgumentError) do
      Ace::Lab::Organisms::AuthorityComposition.new(authority_id: "services", deployment: deployment, kernel: Object.new).build
    end
  end

  def test_incomplete_full_service_source_cannot_start_a_partial_listener
    deployment = Object.new
    calls = []
    deployment.define_singleton_method(:verify_composition!) { |authority, composition:| calls << [authority, composition] }
    deployment.define_singleton_method(:data) { raise "must not construct journals before completeness admission" }
    owner = Ace::Assign::Authority::Endcap
    original = owner::OPERATIONS
    owner.send(:remove_const, :OPERATIONS)
    owner.const_set(:OPERATIONS, (Ace::Lab::Organisms::AuthorityComposition::REQUIRED_ENDCAP - ["claim_service_settlement"]).freeze)
    error = assert_raises(Ace::Lab::InvalidConfigurationError) do
      Ace::Lab::Organisms::AuthorityComposition.new(authority_id: "services", deployment: deployment, kernel: Object.new).build
    end
    assert_match(/incomplete/, error.message)
    assert_equal [["services", "services"]], calls
  ensure
    if original
      owner.send(:remove_const, :OPERATIONS)
      owner.const_set(:OPERATIONS, original)
    end
  end
end
