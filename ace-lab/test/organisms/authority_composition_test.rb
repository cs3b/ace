# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/authority_composition"

class AuthorityCompositionTest < Minitest::Test
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
    owner.const_set(:OPERATIONS, (Ace::Lab::Organisms::AuthorityComposition::REQUIRED_ENDCAP - ["finish"]).freeze)
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
