# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/deployment"
require "ace/assign/authority/execution_scope_observation"

module Ace
  module Assign
    class DeploymentMappingDigestTest < AceAssignTestCase
      # Pure value boundary: descriptor authentication is covered separately by
      # DeploymentProvenanceTest. No filesystem/kernel observer method is called.
      def descriptor(mapping)
        value = Authority::Deployment.allocate
        data = {"launch_mappings" => {"exact" => mapping}}
        value.send(:freeze_data!, data)
        value.instance_variable_set(:@data, data)
        value.freeze
      end

      def test_mapping_digest_is_byte_identical_to_existing_scope_evidence
        mapping = {"z" => [{"b" => 2, "a" => 1}, 3], "a" => {"y" => "value", "x" => false}}
        owner = descriptor(mapping)
        observer = Authority::ExecutionScopeObservation.allocate
        expected = Digest::SHA256.hexdigest(JSON.generate(observer.send(:canonical, mapping)))
        assert_equal expected, owner.mapping_digest("exact")
        assert owner.mapping_digest("exact").frozen?
        assert owner.mapping("exact").frozen?
        assert_equal ["z", "a"], owner.mapping("exact").keys
        assert_raises(KeyError) { owner.mapping_digest("missing") }
        assert_raises(FrozenError) { owner.mapping("exact")["z"].reverse! }
      end

      def test_object_order_is_irrelevant_but_array_order_and_typed_values_bind
        baseline = descriptor({"z" => [1, 2], "a" => {"y" => true, "x" => "1"}}).mapping_digest("exact")
        assert_equal baseline, descriptor({"a" => {"x" => "1", "y" => true}, "z" => [1, 2]}).mapping_digest("exact")
        refute_equal baseline, descriptor({"z" => [2, 1], "a" => {"y" => true, "x" => "1"}}).mapping_digest("exact")
        refute_equal baseline, descriptor({"z" => [1, 2], "a" => {"y" => true, "x" => 1}}).mapping_digest("exact")
      end
    end
  end
end
