# frozen_string_literal: true

require "test_helper"
require "ace/llm/models/role_config"

module Ace
  module LLM
    module Models
      class RoleConfigTest < AceLlmTestCase
        def test_from_hash_supports_string_and_symbol_keys
          config = RoleConfig.from_hash({
            "reviewer" => ["claude:sonnet"],
            fast: ["gemini:flash-latest"]
          })

          assert_equal ["fast", "reviewer"], config.role_names
          assert_equal ["claude:sonnet"], config.candidates_for("reviewer")
          assert_equal ["gemini:flash-latest"], config.candidates_for(:fast)
        end

        def test_from_hash_supports_roles_wrapper_key
          config = RoleConfig.from_hash({
            "roles" => {
              "reviewer" => ["claude:sonnet"]
            }
          })

          assert_equal ["claude:sonnet"], config.candidates_for("reviewer")
        end

        def test_rejects_empty_candidate_lists
          error = assert_raises(Ace::LLM::ConfigurationError) do
            RoleConfig.from_hash({"reviewer" => []})
          end

          assert_match(/must define at least one candidate/, error.message)
        end

        def test_rejects_nested_role_candidates
          error = assert_raises(Ace::LLM::ConfigurationError) do
            RoleConfig.from_hash({"reviewer" => ["role:fast"]})
          end

          assert_match(/cannot reference nested role candidate/, error.message)
        end
      end
    end
  end
end
