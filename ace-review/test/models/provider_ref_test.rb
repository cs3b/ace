# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Models
      class ProviderRefTest < AceReviewTest
        def test_from_ref_parses_llm_reference
          provider = ProviderRef.from_ref("llm:codex:codex@rw")

          assert_equal "llm:codex:codex@rw", provider.raw_ref
          assert_equal "llm", provider.kind
          assert_equal "codex", provider.target
          assert_equal "codex@rw", provider.model
          assert provider.llm?
        end

        def test_from_ref_parses_tool_reference
          provider = ProviderRef.from_ref("tool:ace-lint")

          assert_equal "tool", provider.kind
          assert_equal "ace-lint", provider.target
          assert_nil provider.model
          assert_equal "tool:ace-lint", provider.model_target
        end

        def test_from_entry_merges_default_and_inline_options
          provider = ProviderRef.from_entry(
            {
              "provider" => "llm:claude:anthropic:claude-3-7-sonnet",
              "timeout" => 180,
              "sandbox" => "read-only"
            },
            default_options: { "timeout" => 300 }
          )

          assert_equal 180, provider.options["timeout"]
          assert_equal "read-only", provider.options["sandbox"]
        end

        def test_from_entry_rejects_unknown_kind
          error = assert_raises(ArgumentError) do
            ProviderRef.from_ref("foo:bar:baz")
          end

          assert_match(/Unsupported provider kind/i, error.message)
        end

        def test_from_entry_rejects_invalid_llm_shape
          error = assert_raises(ArgumentError) do
            ProviderRef.from_ref("llm:ro")
          end

          assert_match(/llm refs must use llm:<target>:<model>/i, error.message)
        end
      end
    end
  end
end
