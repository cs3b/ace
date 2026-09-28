# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class TopologyLoaderTest < Minitest::Test
    def test_loads_multi_project_config_into_index
      index = Ace::Lab::Molecules::TopologyLoader.new(topology_config).load

      assert_equal %w[atlas borealis], index.projects.map(&:id)
      assert_equal %w[atlas-planner atlas-coder], index.agents.map(&:id)
      assert_equal %w[atlas-search atlas-index borealis-search], index.services.map(&:id)
    end

    def test_indexes_entries_by_globally_unique_stable_id
      index = Ace::Lab::Molecules::TopologyLoader.new(topology_config).load

      assert_equal "atlas-planner", index.lookup("atlas-planner").id
      assert_equal "borealis-search", index.lookup("borealis-search").id
      assert_equal "project", index.lookup("atlas").kind
      assert_nil index.lookup("nope")
    end

    def test_preserves_stale_attestation_as_configuration_fact
      config = topology_config
      config["topology"]["agents"].first["binding"]["attested_instance_id"] = "inst-old"

      index = Ace::Lab::Molecules::TopologyLoader.new(config).load
      binding = index.lookup("atlas-planner").binding

      # Loading succeeds: a mismatched attestation is a valid configured fact
      # classified as `stale` at query time, never a load-time error
      assert_equal "inst-planner-1", binding.instance_id
      assert_equal "inst-old", binding.attested_instance_id
    end

    def test_rejects_duplicate_stable_ids
      config = topology_config
      config["topology"]["services"] << config["topology"]["agents"].first.merge(
        "endpoint" => {"kind" => "http", "url" => "https://x"}, "role" => nil
      )

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::TopologyLoader.new(config).load
      end
      assert_match(/duplicate id/, error.message)
    end

    def test_rejects_missing_project_reference
      config = topology_config
      config["topology"]["services"].first["project"] = "ghost"

      assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::TopologyLoader.new(config).load
      end
    end

    def test_rejects_malformed_capabilities
      config = topology_config
      config["topology"]["services"].first["capabilities"] = "search"

      assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Molecules::TopologyLoader.new(config).load
      end
    end

    def test_index_is_frozen
      index = Ace::Lab::Molecules::TopologyLoader.new(topology_config).load

      assert_predicate index, :frozen?
      assert_predicate index.projects, :frozen?
      assert_predicate index.by_id, :frozen?
    end
  end
end
