# frozen_string_literal: true

require_relative "../test_helper"

module Atoms
  class TopologySchemaTest < Minitest::Test
    def test_normalizes_valid_multi_project_config
      normalized = Ace::Lab::Atoms::TopologySchema.normalize!(topology_config)

      assert_equal 1, normalized["schema_version"]
      projects = normalized["topology"]["projects"]
      assert_equal %w[atlas borealis], projects.map { |p| p["id"] }
      assert_equal "Atlas platform", projects.first["label"]
      assert_nil projects.last["label"]
    end

    def test_normalizes_capabilities_to_stripped_lowercase_unique_strings
      config = topology_config
      config["topology"]["agents"].first["capabilities"] = ["  Planning ", "PLANNING", "coding"]

      normalized = Ace::Lab::Atoms::TopologySchema.normalize!(config)

      assert_equal %w[planning coding], normalized["topology"]["agents"].first["capabilities"]
    end

    def test_normalizes_binding_state_and_strips_ids
      config = topology_config
      binding = config["topology"]["agents"].first["binding"]
      binding["state"] = " Active "
      binding["instance_id"] = "  inst-7  "

      normalized = Ace::Lab::Atoms::TopologySchema.normalize!(config)

      normalized_binding = normalized["topology"]["agents"].first["binding"]
      assert_equal "active", normalized_binding["state"]
      assert_equal "inst-7", normalized_binding["instance_id"]
    end

    def test_empty_config_yields_empty_topology
      normalized = Ace::Lab::Atoms::TopologySchema.normalize!(
        "schema_version" => 1, "authorization" => {"principals" => {}}, "topology" => {}
      )

      assert_empty normalized["topology"]["projects"]
      assert_empty normalized["topology"]["agents"]
      assert_empty normalized["topology"]["services"]
      assert_empty normalized["authorization"]["principals"]
    end

    def test_rejects_unsupported_schema_version
      config = topology_config
      config["schema_version"] = 2

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/schema_version/, error.message)
    end

    def test_rejects_non_hash_configuration
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!("nope")
      end
      assert_match(/must be a mapping/, error.message)
    end

    def test_rejects_duplicate_ids_across_categories
      config = topology_config
      config["topology"]["services"] << {
        "id" => "atlas-planner", "project" => "atlas", "capabilities" => ["search"],
        "endpoint" => {"kind" => "http", "url" => "https://x.example"},
        "binding" => {"kind" => "service"}
      }

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/duplicate id "atlas-planner".*agents and services/, error.message)
    end

    def test_rejects_duplicate_ids_within_one_category
      config = topology_config
      config["topology"]["projects"] << {"id" => "atlas"}

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/duplicate id "atlas" defined in projects and projects/, error.message)
    end

    def test_rejects_agent_referencing_missing_project
      config = topology_config
      config["topology"]["agents"].first["project"] = "ghost"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/agent "atlas-planner" references unknown project "ghost"/, error.message)
    end

    def test_rejects_service_referencing_missing_project
      config = topology_config
      config["topology"]["services"].first["project"] = "ghost"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/service "atlas-search" references unknown project "ghost"/, error.message)
    end

    def test_rejects_empty_capabilities
      config = topology_config
      config["topology"]["services"].first["capabilities"] = []

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/capabilities must be a non-empty array/, error.message)
    end

    def test_rejects_non_string_capability
      config = topology_config
      config["topology"]["services"].first["capabilities"] = ["search", 42]

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/capability must be a non-empty string/, error.message)
    end

    def test_rejects_default_for_capability_not_declared
      config = topology_config
      config["topology"]["services"].first["default_for"] = ["indexing"]

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/defaults for capability "indexing" it does not declare/, error.message)
    end

    def test_rejects_service_without_endpoint
      config = topology_config
      config["topology"]["services"].first["endpoint"] = nil

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/endpoint must be a mapping with kind and url/, error.message)
    end

    def test_rejects_agent_without_binding
      config = topology_config
      config["topology"]["agents"].first["binding"] = nil

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/binding must be a mapping/, error.message)
    end

    def test_rejects_agent_without_role
      config = topology_config
      config["topology"]["agents"].first["role"] = "  "

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/role must be a non-empty string/, error.message)
    end

    def test_rejects_principal_referencing_unknown_project
      config = topology_config
      config["authorization"]["principals"]["operator"]["projects"] << "ghost"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/principal "operator" references unknown project "ghost"/, error.message)
    end

    def test_allows_binding_with_missing_attestation_fields
      config = topology_config
      config["topology"]["agents"].first["binding"] = {"kind" => "runtime"}

      normalized = Ace::Lab::Atoms::TopologySchema.normalize!(config)

      binding = normalized["topology"]["agents"].first["binding"]
      assert_equal "runtime", binding["kind"]
      assert_nil binding["state"]
      assert_nil binding["instance_id"]
      assert_nil binding["attested_instance_id"]
    end

    def test_malformed_topology_collections_classify_as_invalid_configuration
      %w[projects agents services].each do |key|
        config = topology_config
        config["topology"][key] = (key == "projects") ? "atlas" : 42

        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          Ace::Lab::Atoms::TopologySchema.normalize!(config)
        end
        assert_match(/topology\.#{key} must be an array/, error.message)
      end
    end

    def test_malformed_collection_hashes_are_rejected_not_converted
      config = topology_config
      config["topology"]["agents"] = {"id" => "sneaky"}

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/topology\.agents must be an array/, error.message)
    end

    def test_malformed_principal_projects_classify_as_invalid_configuration
      config = topology_config
      config["authorization"]["principals"]["operator"]["projects"] = "atlas"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/authorization projects for principal "operator" must be an array/, error.message)
    end
  end
end
