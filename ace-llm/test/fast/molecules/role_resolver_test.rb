# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/llm/molecules/role_resolver"

module Ace
  module LLM
    module Molecules
      class RoleResolverTest < AceLlmTestCase
        StubConfiguration = Struct.new(:roles, :inactive) do
          def get(path)
            return roles if path == "llm.roles"

            nil
          end

          def provider_inactive?(provider)
            inactive.include?(provider)
          end
        end

        StubRegistry = Struct.new(:available, :required, :present, :aliases) do
          def resolve_alias(input)
            aliases.fetch(input, input)
          end

          def provider_available?(provider)
            available.include?(provider)
          end

          def provider_api_key_required?(provider)
            required.include?(provider)
          end

          def provider_api_key_present?(provider)
            present.include?(provider)
          end
        end

        def build_resolver(roles:, inactive: [], available: [], required: [], present: [], aliases: {})
          RoleResolver.new(
            configuration: StubConfiguration.new(roles, inactive),
            registry: StubRegistry.new(available, required, present, aliases)
          )
        end

        def test_resolves_first_available_candidate
          resolver = build_resolver(
            roles: {
              "reviewer" => ["claude:sonnet", "codex:gpt"]
            },
            available: ["claude", "codex"],
            present: ["claude", "codex"]
          )

          assert_equal "claude:sonnet", resolver.resolve("reviewer")
        end

        def test_unknown_role_errors_with_defined_roles
          resolver = build_resolver(
            roles: {"reviewer" => ["claude:sonnet"]},
            available: ["claude"],
            present: ["claude"]
          )

          error = assert_raises(Ace::LLM::ConfigurationError) do
            resolver.resolve("missing")
          end

          assert_match(/Unknown role: missing/, error.message)
          assert_match(/Defined roles: reviewer/, error.message)
        end

        def test_errors_when_no_available_candidates
          resolver = build_resolver(
            roles: {"reviewer" => ["claude:sonnet", "codex:gpt"]},
            available: [],
            present: []
          )

          error = assert_raises(Ace::LLM::ConfigurationError) do
            resolver.resolve("reviewer")
          end

          assert_match(/No available models for role 'reviewer'/, error.message)
          assert_match(/claude:sonnet, codex:gpt/, error.message)
        end

        def test_skips_inactive_candidates_and_keeps_required_key_candidates
          resolver = build_resolver(
            roles: {"reviewer" => ["claude:sonnet", "codex:gpt", "gemini:pro"]},
            inactive: ["claude"],
            available: ["claude", "codex", "gemini"],
            required: ["codex"],
            present: ["gemini"]
          )

          assert_equal "codex:gpt", resolver.resolve("reviewer")
        end

        def test_allows_provider_when_api_key_not_required
          resolver = build_resolver(
            roles: {"fast" => ["gemini:flash"]},
            available: ["gemini"],
            required: [],
            present: []
          )

          assert_equal "gemini:flash", resolver.resolve("fast")
        end

        def test_uses_alias_resolution_for_provider_detection
          resolver = build_resolver(
            roles: {"fast" => ["glite"]},
            available: ["google"],
            present: ["google"],
            aliases: {"glite" => "google:gemini-flash-lite-latest"}
          )

          assert_equal "glite", resolver.resolve("fast")
        end

        def test_does_not_skip_provider_with_missing_required_key
          resolver = build_resolver(
            roles: {"fast" => ["glite"]},
            available: ["google"],
            required: ["google"],
            present: [],
            aliases: {"glite" => "google:gemini-flash-lite-latest"}
          )

          assert_equal "glite", resolver.resolve("fast")
        end
      end
    end
  end
end
