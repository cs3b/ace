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
