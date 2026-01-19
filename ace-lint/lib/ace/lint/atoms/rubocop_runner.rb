# frozen_string_literal: true

require_relative "base_runner"

module Ace
  module Lint
    module Atoms
      # Executes RuboCop linter and parses results
      # Used as fallback when StandardRB is not available
      class RuboCopRunner < BaseRunner
        class << self
          # Build RuboCop command
          # @param paths [Array<String>] File paths
          # @param fix [Boolean] Apply fixes
          # @param config_path [String, nil] Explicit config path (takes precedence)
          # @return [Array<String>] Command and arguments
          # Flag mapping: --fix → --autocorrect, --fix-unsafely → --autocorrect-all
          # Config precedence: explicit config_path > bundled defaults
          def build_command(paths, fix:, config_path: nil)
            autofix_flags = fix ? ["--autocorrect"] : []

            # Use explicit config_path if provided, otherwise fall back to bundled config
            effective_config = config_path || find_bundled_config
            config_flags = effective_config ? ["--config", effective_config] : []

            ["rubocop", *config_flags, *autofix_flags, "--format", "json", *paths].compact
          end

          # Result when neither StandardRB nor RuboCop is available
          # @return [Hash] Error result mentioning both tools
          def unavailable_result
            {
              success: false,
              errors: [{
                message: "No Ruby linter available. Install StandardRB (preferred): gem install standardrb" \
                         " - or RuboCop: gem install rubocop"
              }],
              warnings: []
            }
          end

          protected

          def command_name
            "rubocop"
          end

          def tool_name
            "RuboCop"
          end

          private

          # Find the bundled RuboCop configuration
          # @return [String, nil] Path to bundled config, or nil if not found
          def find_bundled_config
            gem_root = ::Gem.loaded_specs["ace-lint"]&.gem_dir
            return nil unless gem_root

            config_path = File.join(gem_root, ".ace-defaults", "lint", ".rubocop.yml")
            File.exist?(config_path) ? config_path : nil
          end
        end
      end
    end
  end
end
