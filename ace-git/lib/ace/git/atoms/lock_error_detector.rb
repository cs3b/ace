# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Pure functions for detecting git index lock errors from command output
      #
      # Git operations can fail with "Unable to create .git/index.lock" errors
      # when:
      # - Previous git operations were interrupted (Ctrl+C, crashes, timeouts)
      # - Multiple concurrent operations contend for the same lock
      # - Agents are blocked mid-operation leaving orphan lock files
      #
      # This detector identifies these errors so retry logic can handle them.
      module LockErrorDetector
        # Git error patterns that indicate index lock issues
        # These patterns appear in stderr when git cannot acquire the lock
        # Covers various git versions and platforms
        LOCK_ERROR_PATTERNS = [
          /Unable to create.*index\.lock.*File exists/i,
          /fatal:\s*cannot create.*index\.lock/i,
          /Another git process seems to be running/i,
          /git.*index\.lock.*exists/i,
          /could not open.*index\.lock/i,
          /unable to create.*index\.lock/i,
          /lock file.*index\.lock.*already exists/i
        ].freeze

        # Exit code 128 often indicates lock issues across different git versions
        LOCK_EXIT_CODE = 128

        class << self
          # Detect if a git error is related to index lock issues
          #
          # @param stderr [String] The error output from a git command
          # @return [Boolean] true if the error indicates a lock issue
          #
          # @example Detect lock error
          #   lock_error?("fatal: Unable to create '.git/index.lock': File exists.")
          #   # => true
          #
          # @example Non-lock error
          #   lock_error?("error: pathspec 'unknown' did not match")
          #   # => false
          def lock_error?(stderr)
            return false if stderr.nil? || stderr.empty?

            LOCK_ERROR_PATTERNS.any? { |pattern| pattern.match?(stderr) }
          end

          # Check if git command result indicates a lock error
          #
          # @param result [Hash] Result hash from CommandExecutor.execute
          # @return [Boolean] true if the result indicates a lock error
          #
          # @example Check result hash
          #   result = { success: false, error: "fatal: Unable to create...", exit_code: 128 }
          #   lock_error_result?(result)
          #   # => true
          def lock_error_result?(result)
            return false if result.nil? || result[:success]
            return false if result[:error].nil? || result[:error].empty?

            # Primary check: known lock error patterns
            return true if lock_error?(result[:error])

            # Fallback: exit code 128 with "lock" keyword in error
            # Handles edge cases from different git versions/locales
            if result[:exit_code] == LOCK_EXIT_CODE && result[:error] =~ /lock/i
              return true
            end

            false
          end
        end
      end
    end
  end
end
