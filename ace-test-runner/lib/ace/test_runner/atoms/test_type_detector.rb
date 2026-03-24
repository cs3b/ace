# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Detects whether tests need subprocess isolation based on their content and type
      class TestTypeDetector
        # Patterns that indicate a test needs subprocess isolation
        SUBPROCESS_PATTERNS = [
          /CommandExecutor/,           # Tests that execute shell commands
          /Open3\./,                   # Direct subprocess usage
          /Process\.(spawn|fork|kill)/, # Process manipulation
          /Signal\./,                  # Signal handling
          /system\(/,                  # System command execution
          /`.*`/,                      # Backtick command execution
          /\$\(.*\)/,                  # Command substitution
          /run_in_subprocess/,         # Explicit subprocess test helpers
          /run_in_clean_env/          # Environment isolation helpers
        ].freeze

        # Test directories that typically need isolation
        ISOLATION_DIRS = %w[
          integration
          system
          e2e
          end_to_end
        ].freeze

        # Test directories that typically don't need isolation
        UNIT_TEST_DIRS = %w[
          atoms
          molecules
          organisms
          models
          unit
        ].freeze

        def needs_subprocess?(file_path)
          # Check if explicitly marked as needing isolation
          return true if isolation_directory?(file_path)

          # Check if it's clearly a unit test that doesn't need isolation
          return false if unit_test_directory?(file_path)

          # Check file content for patterns that require subprocess
          check_file_content(file_path)
        end

        def test_type(file_path)
          if isolation_directory?(file_path)
            :integration
          elsif unit_test_directory?(file_path)
            :unit
          elsif check_file_content(file_path)
            :subprocess_required
          else
            :unit
          end
        end

        private

        def isolation_directory?(file_path)
          ISOLATION_DIRS.any? { |dir| file_path.include?("/#{dir}/") }
        end

        def unit_test_directory?(file_path)
          UNIT_TEST_DIRS.any? { |dir| file_path.include?("/#{dir}/") }
        end

        def check_file_content(file_path)
          return false unless File.exist?(file_path)

          content = File.read(file_path)
          SUBPROCESS_PATTERNS.any? { |pattern| content.match?(pattern) }
        rescue
          # If we can't read the file, assume it doesn't need isolation
          false
        end
      end
    end
  end
end
