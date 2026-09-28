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
      assert_includes error.message, "duplicate stable id: topology.agents[0] and topology.services[3] define the same id"
    end

    def test_rejects_duplicate_ids_within_one_category
      config = topology_config
      config["topology"]["projects"] << {"id" => "atlas"}

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_includes error.message, "duplicate stable id: topology.projects[0] and topology.projects[2] define the same id"
    end

    def test_rejects_agent_referencing_missing_project
      config = topology_config
      config["topology"]["agents"].first["project"] = "ghost"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_includes error.message, "topology.agents[0].project references an unknown project"
    end

    def test_rejects_service_referencing_missing_project
      config = topology_config
      config["topology"]["services"].first["project"] = "ghost"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_includes error.message, "topology.services[0].project references an unknown project"
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
      assert_match(/capabilities entry must be a non-empty string/, error.message)
    end

    def test_rejects_default_for_capability_not_declared
      config = topology_config
      config["topology"]["services"].first["default_for"] = ["indexing"]

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/default_for entry does not match a declared capability/, error.message)
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
      assert_includes error.message, "authorization.principals[0].projects[2] references an unknown project"
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
      assert_includes error.message, "authorization.principals[0].projects must be an array"
    end
  end
end

module Atoms
  class TopologySchemaEndpointTest < Minitest::Test
    def config_with_endpoint_url(url)
      config = topology_config
      config["topology"]["services"].first["endpoint"]["url"] = url
      config
    end

    def test_rejects_unparseable_endpoint_urls
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config_with_endpoint_url("::not a url::"))
      end
      assert_match(/topology\.services\[0\]\.endpoint\.url must be an absolute http\(s\) URL with a host/, error.message)
    end

    def test_rejects_non_http_schemes
      assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config_with_endpoint_url("ftp://search.example.internal"))
      end
    end

    def test_rejects_urls_without_a_host
      assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config_with_endpoint_url("https:///path-only"))
      end
    end

    def test_rejects_unsupported_endpoint_kinds
      config = topology_config
      config["topology"]["services"].first["endpoint"] = {"kind" => "grpc", "url" => "https://x.example"}

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_match(/endpoint\.kind must be one of: http, https/, error.message)
    end

    def test_normalizes_endpoint_kind_case
      config = topology_config
      config["topology"]["services"].first["endpoint"]["kind"] = " HTTPS "

      normalized = Ace::Lab::Atoms::TopologySchema.normalize!(config)

      assert_equal "https", normalized["topology"]["services"].first["endpoint"]["kind"]
    end
  end
end

module Atoms
  class TopologySchemaBindingKindTest < Minitest::Test
    def test_rejects_agent_binding_kind_mismatch
      config = topology_config
      config["topology"]["agents"].first["binding"]["kind"] = "service"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_includes error.message, "topology.agents[0].binding.kind must be one of: runtime"
    end

    def test_rejects_unsupported_agent_binding_kind
      config = topology_config
      config["topology"]["agents"].first["binding"]["kind"] = "unsupported-runtime"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_includes error.message, "topology.agents[0].binding.kind must be one of: runtime"
    end

    def test_rejects_service_binding_kind_runtime
      config = topology_config
      config["topology"]["services"].first["binding"]["kind"] = "runtime"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_includes error.message, "topology.services[0].binding.kind must be one of: service"
    end

    def test_rejects_out_of_range_endpoint_ports
      config = topology_config
      config["topology"]["services"].first["endpoint"]["url"] = "https://search.example.internal:99999/query"

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        Ace::Lab::Atoms::TopologySchema.normalize!(config)
      end
      assert_includes error.message, "endpoint.url must be an absolute http(s) URL with a host and a valid port"
    end
  end
end
