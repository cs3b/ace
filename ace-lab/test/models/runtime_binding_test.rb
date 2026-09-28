# frozen_string_literal: true

require_relative "../test_helper"

module Models
  class RuntimeBindingTest < Minitest::Test
    def test_builds_from_normalized_hash
      binding = Ace::Lab::Models::RuntimeBinding.from_h(
        "kind" => "runtime", "state" => "active",
        "instance_id" => "inst-1", "attested_instance_id" => "inst-1"
      )

      assert_equal "runtime", binding.kind
      assert_equal "active", binding.state
      assert_equal "inst-1", binding.instance_id
      assert_equal "inst-1", binding.attested_instance_id
    end

    def test_defaults_missing_attestation_fields_to_nil
      binding = Ace::Lab::Models::RuntimeBinding.from_h({"kind" => "runtime"})

      assert_equal "runtime", binding.kind
      assert_nil binding.state
      assert_nil binding.instance_id
      assert_nil binding.attested_instance_id
    end

    def test_round_trips_to_h
      hash = {
        "kind" => "service", "state" => "active",
        "instance_id" => "inst-2", "attested_instance_id" => "inst-9"
      }
      binding = Ace::Lab::Models::RuntimeBinding.from_h(hash)

      assert_equal hash, binding.to_h
    end

    def test_bindings_are_immutable
      binding = Ace::Lab::Models::RuntimeBinding.from_h({"kind" => "runtime"})

      assert_predicate binding, :frozen?
    end
  end
end
