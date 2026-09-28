# frozen_string_literal: true

require_relative "../test_helper"

module Models
  class TopologyEntryTest < Minitest::Test
    def agent_hash
      topology_config["topology"]["agents"].first
    end

    def service_hash
      topology_config["topology"]["services"].first
    end

    def test_builds_project_entry
      entry = Ace::Lab::Models::TopologyEntry.project({"id" => "atlas", "label" => "Atlas"})

      assert_equal "project", entry.kind
      assert_equal "atlas", entry.id
      assert_equal "Atlas", entry.label
      assert_nil entry.project
      assert_empty entry.capabilities
      assert_predicate entry, :project?
    end

    def test_builds_agent_entry_with_binding
      entry = Ace::Lab::Models::TopologyEntry.agent(agent_hash)

      assert_equal "agent", entry.kind
      assert_equal "atlas-planner", entry.id
      assert_equal "atlas", entry.project
      assert_equal "planner", entry.role
      assert_equal ["planning"], entry.capabilities
      assert_equal "runtime", entry.binding.kind
      assert_equal "inst-planner-1", entry.binding.instance_id
    end

    def test_builds_service_entry_with_endpoint_and_defaults
      entry = Ace::Lab::Models::TopologyEntry.service(service_hash)

      assert_equal "service", entry.kind
      assert_equal "atlas-search", entry.id
      assert_equal ["search"], entry.capabilities
      assert_equal ["search"], entry.default_for
      assert_equal "http", entry.endpoint["kind"]
      assert_equal "service", entry.binding.kind
    end

    def test_entries_are_immutable
      entry = Ace::Lab::Models::TopologyEntry.agent(agent_hash)

      assert_predicate entry, :frozen?
      assert_predicate entry.capabilities, :frozen?
      assert_raises(FrozenError) { entry.capabilities << "coding" }
    end

    def test_capability_check_is_exact_against_normalized_ids
      entry = Ace::Lab::Models::TopologyEntry.service(service_hash)

      assert entry.capable_of?("search")
      refute entry.capable_of?("Search")
      refute entry.capable_of?("index")
    end

    def test_unknown_kind_is_rejected
      assert_raises(ArgumentError) do
        Ace::Lab::Models::TopologyEntry.new(kind: "pane", id: "x")
      end
    end
  end
end

module Models
  class TopologyEntryImmutabilityTest < Minitest::Test
    def index
      @index ||= Ace::Lab::Molecules::TopologyLoader.new(topology_config).load
    end

    def test_projected_values_cannot_mutate_indexed_entries
      projected = Ace::Lab::Atoms::PublicProjection.agent(index.lookup("atlas-planner"))

      # Public projections share the model's defensively frozen strings; a
      # mutation attempt must raise, never corrupt the index key
      # (review round 15, F1)
      assert_raises(FrozenError) { projected["id"].replace("changed") }
      assert_equal "atlas-planner", index.lookup("atlas-planner").id
      assert_equal "atlas-planner", index.lookup("atlas-planner").id
    end

    def test_binding_strings_cannot_mutate_freshness_facts
      binding = index.lookup("atlas-planner").binding

      assert_raises(FrozenError) { binding.instance_id.replace("tampered") }
      assert_equal "inst-planner-1", binding.instance_id
      assert_equal "inst-planner-1", binding.attested_instance_id
    end

    def test_capability_arrays_cannot_mutate_routing
      entry = index.lookup("atlas-search")

      assert_raises(FrozenError) { entry.capabilities << "index" }
      refute entry.capable_of?("index")
    end
  end
end
