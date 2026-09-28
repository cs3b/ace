# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class CapabilityRouterTest < Minitest::Test
    def router_for(identity, config = topology_config)
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(
        principals: config["authorization"]["principals"], identity: [identity]
      )
      Ace::Lab::Molecules::CapabilityRouter.new(
        index: Ace::Lab::Molecules::TopologyLoader.new(config).load,
        authorizer: authorizer
      )
    end

    def test_single_capable_service_routes_directly
      result = router_for("operator").route(project: "borealis", capability: "search")

      assert_predicate result, :ok?
      assert_equal "borealis-search", result.data["entry"]["id"]
    end

    def test_zero_capable_services_are_missing
      result = router_for("operator").route(project: "borealis", capability: "indexing")

      refute_predicate result, :ok?
      assert_equal "missing", result.error_code
    end

    def test_multiple_candidates_without_default_are_ambiguous
      # atlas has atlas-search (default_for search) and atlas-index; remove
      # the default so both are equal candidates
      config = topology_config
      config["topology"]["services"].first["default_for"] = []

      result = router_for("operator", config).route(project: "atlas", capability: "search")

      refute_predicate result, :ok?
      assert_equal "ambiguous", result.error_code
      assert_match(/atlas-search, atlas-index/, result.message)
    end

    def test_configured_default_is_selected_among_candidates
      result = router_for("operator").route(project: "atlas", capability: "search")

      assert_predicate result, :ok?
      assert_equal "atlas-search", result.data["entry"]["id"]
    end

    def test_conflicting_defaults_are_ambiguous_not_first_wins
      config = topology_config
      config["topology"]["services"].first["default_for"] = ["search"]
      config["topology"]["services"][1]["default_for"] = ["search"]

      result = router_for("operator", config).route(project: "atlas", capability: "search")

      # Two configured defaults are a configuration conflict, not a silent
      # preference for whichever entry comes first (review R1)
      assert_equal "ambiguous", result.error_code
    end

    def test_stale_candidates_are_not_routed
      config = topology_config
      config["topology"]["services"].first["binding"]["state"] = "inactive"

      result = router_for("operator", config).route(project: "atlas", capability: "search")

      # atlas-search is stale, so only the fresh atlas-index remains; a single
      # remaining candidate routes directly without a configured default
      assert_predicate result, :ok?
      assert_equal "atlas-index", result.data["entry"]["id"]
    end

    def test_services_from_another_project_are_never_candidates
      # "index" exists only on atlas services; borealis has none
      result = router_for("operator").route(project: "borealis", capability: "index")

      assert_equal "missing", result.error_code
    end

    def test_unauthorized_project_is_denied
      result = router_for("intern").route(project: "atlas", capability: "search")

      assert_equal "unauthorized", result.error_code
      assert_nil result.data
    end

    def test_requested_capability_normalizes_like_configured_ones
      result = router_for("operator").route(project: "borealis", capability: "  SEARCH ")

      assert_predicate result, :ok?
      assert_equal "borealis-search", result.data["entry"]["id"]
    end
  end
end
