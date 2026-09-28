# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class InventoryQueryTest < Minitest::Test
    def index
      @index ||= Ace::Lab::Molecules::TopologyLoader.new(config).load
    end

    def config
      @config ||= begin
        cfg = topology_config
        cfg["topology"]["projects"] << {"id" => "ceres", "label" => "Unauthorized project"}
        cfg
      end
    end

    def query_for(identity)
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(
        principals: config["authorization"]["principals"], identity: [identity]
      )
      Ace::Lab::Molecules::InventoryQuery.new(index: index, authorizer: authorizer)
    end

    def test_lists_only_authorized_projects
      result = query_for("operator").projects

      assert_predicate result, :ok?
      listed = result.data["projects"].map { |p| p["id"] }
      assert_equal %w[atlas borealis], listed
      refute_includes listed, "ceres"
    end

    def test_caller_without_principal_is_unauthorized_without_metadata
      result = query_for("intruder").projects

      refute_predicate result, :ok?
      assert_equal "unauthorized", result.error_code
      assert_nil result.data
    end

    def test_agents_are_scoped_to_the_requested_project
      result = query_for("operator").agents(project: "atlas")

      assert_predicate result, :ok?
      assert_equal %w[atlas-planner atlas-coder], result.data["agents"].map { |a| a["id"] }
    end

    def test_unauthorized_project_is_classified_and_leaks_nothing
      result = query_for("operator").agents(project: "ceres")

      refute_predicate result, :ok?
      assert_equal "unauthorized", result.error_code
      assert_equal "ceres", result.context[:project] || result.context["project"]
      assert_nil result.data
    end

    def test_services_are_scoped_to_the_requested_project
      result = query_for("operator").services(project: "borealis")

      assert_predicate result, :ok?
      assert_equal %w[borealis-search], result.data["services"].map { |s| s["id"] }
    end

    def test_unknown_project_is_unauthorized_not_missing
      result = query_for("operator").services(project: "ghost")

      assert_equal "unauthorized", result.error_code
    end
  end
end
