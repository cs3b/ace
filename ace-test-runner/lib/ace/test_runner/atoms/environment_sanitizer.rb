# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Pure allowlist filter from a parent environment snapshot to the
      # deterministic child base environment.
      #
      # Copies only policy-preserved keys into a fresh hash. Fixture-home
      # replacements and fixture overrides are applied later by
      # Molecules::FixtureEnvironment. Never mutates ENV or the input hash.
      module EnvironmentSanitizer
        module_function

        # @param parent_env [Hash] snapshot of the parent environment (not modified)
        # @param policy [Models::EnvironmentPolicy] hermetic environment contract
        # @return [Hash] new child base environment containing only preserved keys
        def sanitize(parent_env, policy)
          parent_env.each_with_object({}) do |(key, value), child|
            next if value.nil?

            child[key] = value if policy.preserved_key?(key)
          end
        end

        # Names of parent keys dropped by the policy (diagnostics only).
        def dropped_keys(parent_env, policy)
          parent_env.keys.reject { |key| policy.preserved_key?(key) }
        end
      end
    end
  end
end
