# frozen_string_literal: true

require_relative "base_runner"

module Ace
  module Lint
    module Atoms
      # Executes StandardRB linter and parses results
      class StandardrbRunner < BaseRunner
        class << self
          # Build StandardRB command
          # @param paths [Array<String>] File paths
          # @param fix [Boolean] Apply fixes
          # @param config_path [String, nil] Ignored - StandardRB is zero-config
          # @return [Array<String>] Command and arguments
          def build_command(paths, fix:, config_path: nil)
            ["standardrb", *(fix ? ["--fix"] : []), "--format", "json", *paths].compact
          end

          # Result when StandardRB is not available
          # @return [Hash] Error result
          def unavailable_result
            {
              success: false,
              errors: [{
                message: "StandardRB is not installed. Install it with: gem install standardrb"
              }],
              warnings: []
            }
          end

          protected

          def command_name
            "standardrb"
          end

          def tool_name
            "StandardRB"
          end
        end
      end
    end
  end
end
