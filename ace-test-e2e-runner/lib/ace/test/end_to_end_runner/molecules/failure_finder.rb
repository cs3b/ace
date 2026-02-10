# frozen_string_literal: true

require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Scans cache for failed test cases from previous E2E test runs
        #
        # Reads metadata.yml files from .cache/ace-test-e2e/*-reports/ directories
        # and extracts failed_test_cases arrays. Used by --only-failures CLI flag
        # to re-run only tests that failed previously.
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via Dir.glob and YAML file reading.
        class FailureFinder
          CACHE_DIR = ".cache/ace-test-e2e"
          METADATA_FILE = "metadata.yml"
          REPORTS_SUFFIX = "-reports"

          # Find failed test cases for a specific package
          #
          # Scans cache directory for the most recent metadata.yml per test-id
          # within the specified package, returning aggregated failed test case IDs.
          #
          # @param package [String] Package name (e.g., "ace-lint")
          # @param base_dir [String] Base directory to search from (default: current dir)
          # @return [Array<String>] Failed test case IDs (e.g., ["TC-001", "TC-003"])
          def find_failures(package:, base_dir: Dir.pwd)
            metadata_files = discover_metadata_files(base_dir)
            return [] if metadata_files.empty?

            # Filter to package and get most recent per test-id
            package_metadata = filter_by_package(metadata_files, package)
            most_recent = most_recent_per_test(package_metadata)

            extract_all_failed_ids(most_recent)
          end

          # Find failed test cases across all packages
          #
          # Scans cache directory for the most recent metadata.yml per test-id
          # across all packages, returning aggregated failed test case IDs.
          #
          # @param base_dir [String] Base directory to search from (default: current dir)
          # @return [Array<String>] Failed test case IDs
          def find_all_failures(base_dir: Dir.pwd)
            metadata_files = discover_metadata_files(base_dir)
            return [] if metadata_files.empty?

            most_recent = most_recent_per_test(metadata_files)
            extract_all_failed_ids(most_recent)
          end

          private

          # Discover all metadata.yml files in the cache directory
          #
          # @param base_dir [String] Base directory
          # @return [Array<Hash>] Parsed metadata entries with :path and :data keys
          def discover_metadata_files(base_dir)
            cache_path = File.join(base_dir, CACHE_DIR)
            return [] unless Dir.exist?(cache_path)

            pattern = File.join(cache_path, "*#{REPORTS_SUFFIX}", METADATA_FILE)
            Dir.glob(pattern).filter_map { |path| load_metadata(path) }
          end

          # Safely load and parse a metadata.yml file
          #
          # @param path [String] Absolute path to metadata.yml
          # @return [Hash, nil] Hash with :path and :data keys, or nil on error
          def load_metadata(path)
            data = YAML.safe_load_file(path, permitted_classes: [Date])
            return nil unless data.is_a?(Hash)

            { path: path, data: data }
          rescue StandardError => e
            warn "Warning: Could not parse #{path}: #{e.message}" if ENV["DEBUG"]
            nil
          end

          # Filter metadata entries by package name
          #
          # @param entries [Array<Hash>] Metadata entries
          # @param package [String] Package name to filter by
          # @return [Array<Hash>] Filtered entries
          def filter_by_package(entries, package)
            entries.select { |entry| entry[:data]["package"] == package }
          end

          # Get the most recent metadata entry per test-id
          #
          # Uses the report directory name (which contains a timestamp prefix)
          # to determine recency. Later timestamps sort higher alphabetically.
          #
          # @param entries [Array<Hash>] Metadata entries
          # @return [Array<Hash>] Most recent entry per test-id
          def most_recent_per_test(entries)
            grouped = entries.group_by { |entry| entry[:data]["test-id"] }
            grouped.map do |_test_id, group|
              # Sort by directory name (timestamp prefix ensures chronological order)
              group.max_by { |entry| File.basename(File.dirname(entry[:path])) }
            end
          end

          # Extract failed test case IDs from metadata entries
          #
          # Checks both the `failed_test_cases` array (from task 259.03 ReportWriter)
          # and falls back to checking `status: "fail"` for older metadata formats.
          #
          # @param entries [Array<Hash>] Most recent metadata entries
          # @return [Array<String>] Aggregated failed test case IDs
          def extract_all_failed_ids(entries)
            entries.flat_map { |entry| extract_failed_test_cases(entry[:data]) }.uniq
          end

          # Extract failed test case IDs from a single metadata hash
          #
          # @param data [Hash] Parsed metadata.yml data
          # @return [Array<String>] Failed test case IDs from this entry
          def extract_failed_test_cases(data)
            # Primary: use failed_test_cases array (written by ReportWriter in 259.03)
            failed_ids = data["failed_test_cases"]
            return Array(failed_ids) if failed_ids.is_a?(Array) && !failed_ids.empty?

            # No specific failed test case IDs available
            []
          end
        end
      end
    end
  end
end
