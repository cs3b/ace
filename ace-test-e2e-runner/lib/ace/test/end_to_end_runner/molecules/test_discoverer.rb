# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Discovers E2E test scenario files (*.mt.md) in packages
        #
        # Follows the convention: {package}/test/e2e/*.mt.md
        # Test IDs follow format: MT-{AREA}-{NNN}
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via Dir.glob.
        class TestDiscoverer
          # Default pattern for test scenario files
          EXTENSION = ".mt.md"
          TEST_DIR = "test/e2e"

          # Find E2E test files matching criteria
          #
          # @param package [String] Package name (e.g., "ace-lint")
          # @param test_id [String, nil] Optional specific test ID (e.g., "MT-LINT-001")
          # @param base_dir [String] Base directory to search from (default: current dir)
          # @return [Array<String>] Sorted list of matching file paths
          def find_tests(package:, test_id: nil, base_dir: Dir.pwd)
            test_ids = test_id ? test_id.split(",").map(&:strip) : [nil]
            test_ids
              .flat_map { |id| Dir.glob(build_pattern(package, id, base_dir)) }
              .uniq
              .sort
          end

          # List all packages that have E2E tests
          #
          # @param base_dir [String] Base directory to search from
          # @return [Array<String>] Sorted list of package names
          def list_packages(base_dir: Dir.pwd)
            pattern = File.join(base_dir, "*/#{TEST_DIR}/*#{EXTENSION}")
            Dir.glob(pattern)
              .map { |f| File.basename(File.dirname(File.dirname(File.dirname(f)))) }
              .uniq
              .sort
          end

          private

          # Build glob pattern for finding test files
          #
          # @param package [String] Package name
          # @param test_id [String, nil] Optional test ID
          # @param base_dir [String] Base directory
          # @return [String] Glob pattern
          def build_pattern(package, test_id, base_dir)
            test_dir = File.join(base_dir, package, TEST_DIR)

            if test_id
              # Find specific test by ID (case-insensitive match in filename)
              File.join(test_dir, "*#{test_id}*#{EXTENSION}")
            else
              # Find all tests in package
              File.join(test_dir, "*#{EXTENSION}")
            end
          end
        end
      end
    end
  end
end
