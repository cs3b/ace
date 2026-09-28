# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class ExactResolverTest < Minitest::Test
    def resolver_for(identity)
      authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(
        principals: topology_config["authorization"]["principals"], identity: [identity]
      )
      Ace::Lab::Molecules::ExactResolver.new(
        index: Ace::Lab::Molecules::TopologyLoader.new(topology_config).load,
        authorizer: authorizer
      )
    end

    def test_resolves_exact_stable_agent_id
      result = resolver_for("operator").resolve("atlas-planner")

      assert_predicate result, :ok?
      entry = result.data["entry"]
      assert_equal "atlas-planner", entry["id"]
      assert_equal "atlas", entry["project"]
      assert_equal "available", entry["binding"]["state"]
    end

    def test_labels_never_resolve
      result = resolver_for("operator").resolve("Atlas platform")

      refute_predicate result, :ok?
      assert_equal "missing", result.error_code
    end

    def test_unknown_id_is_missing
      result = resolver_for("operator").resolve("nope")

      refute_predicate result, :ok?
      assert_equal "missing", result.error_code
    end

    def test_replaced_process_identity_is_a_stale_result
      result = resolver_for("operator").resolve("atlas-coder")

      refute_predicate result, :ok?
      assert_equal "stale", result.error_code
      assert_equal "atlas-coder", result.context[:id] || result.context["id"]
      assert_nil result.data
    end

    def test_unauthorized_entry_discloses_no_project
      result = resolver_for("intern").resolve("atlas-planner")

      # The configured project is topology the caller cannot see; the error
      # names nothing beyond the ID the caller itself supplied (review R6)
      refute_predicate result, :ok?
      assert_equal "unauthorized", result.error_code
      refute_includes result.message, "project"
      assert_empty result.context.reject { |key, _| key.to_s == "id" }
    end

    def test_project_id_resolves_for_authorized_caller
      result = resolver_for("operator").resolve("atlas")

      assert_predicate result, :ok?
      assert_equal "atlas", result.data["entry"]["id"]
    end

    def test_project_id_unauthorized_for_caller_without_principal
      result = resolver_for("intern").resolve("atlas")

      assert_equal "unauthorized", result.error_code
    end
  end
end
