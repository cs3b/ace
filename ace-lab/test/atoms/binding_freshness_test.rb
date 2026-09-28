# frozen_string_literal: true

require_relative "../test_helper"

module Atoms
  class BindingFreshnessTest < Minitest::Test
    def build_binding(state:, instance_id: "inst-1", attested_instance_id: "inst-1")
      Ace::Lab::Models::RuntimeBinding.from_h(
        "kind" => "runtime", "state" => state,
        "instance_id" => instance_id, "attested_instance_id" => attested_instance_id
      )
    end

    def test_active_matching_binding_is_fresh
      freshness = Ace::Lab::Atoms::BindingFreshness.classify(build_binding(state: "active"))

      assert_equal "fresh", freshness
    end

    def test_replaced_process_identity_is_stale
      replaced = build_binding(state: "active", instance_id: "inst-new", attested_instance_id: "inst-old")

      assert_equal "stale", Ace::Lab::Atoms::BindingFreshness.classify(replaced)
    end

    def test_inactive_state_is_stale_even_when_identity_matches
      inactive = build_binding(state: "inactive")
      unattested = build_binding(state: nil)

      assert_equal "stale", Ace::Lab::Atoms::BindingFreshness.classify(inactive)
      assert_equal "stale", Ace::Lab::Atoms::BindingFreshness.classify(unattested)
    end

    def test_missing_instance_identity_is_stale
      anonymous = build_binding(state: "active", instance_id: nil, attested_instance_id: nil)

      assert_equal "stale", Ace::Lab::Atoms::BindingFreshness.classify(anonymous)
    end

    def test_nil_binding_is_stale
      assert_equal "stale", Ace::Lab::Atoms::BindingFreshness.classify(nil)
    end

    def test_fresh_predicate_matches_classification
      assert Ace::Lab::Atoms::BindingFreshness.fresh?(build_binding(state: "active"))
      refute Ace::Lab::Atoms::BindingFreshness.fresh?(build_binding(state: "inactive"))
    end
  end
end
